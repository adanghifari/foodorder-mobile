import 'package:flutter/material.dart';

import '../../../app/app_routes.dart';
import '../../auth/data/auth_session.dart';
import '../../cart/data/cart_api_service.dart';
import '../../landing/presentation/order_type_picker_page.dart';
import '../../landing/data/order_type_session.dart';
import '../../../shared/widgets/app_back_button.dart';
import '../../../shared/widgets/app_bottom_nav_bar.dart';
import '../../../shared/widgets/app_notice.dart';
import '../data/menu_api_service.dart';

class MenuPage extends StatefulWidget {
  const MenuPage({super.key});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  final MenuApiService _menuApiService = MenuApiService();
  final CartApiService _cartApiService = CartApiService();

  int cartCount = 0;
  int _cartTotal = 0;
  String activeTab = 'Semua';
  String _query = '';
  bool _isLoading = true;
  String? _error;
  bool _isSyncingCart = false;
  List<MenuItemDto> _allMenus = const [];
  final Map<String, int> _itemQty = {};
  final Set<String> _updatingMenuKeys = <String>{};

  String _menuKey(MenuItemDto menu) {
    if (menu.id.trim().isNotEmpty) return menu.id;
    return '${menu.name}|${menu.categoryBackend}|${menu.price}|${menu.imageUrl}';
  }

  List<MenuItemDto> get filteredMenus {
    return _allMenus.where((menu) {
      final sameCategory = activeTab == 'Semua'
          ? true
          : (menu.categoryUi == activeTab);
      final name = menu.name.toLowerCase();
      final desc = menu.description.toLowerCase();
      final q = _query.trim().toLowerCase();
      final sameQuery = q.isEmpty || name.contains(q) || desc.contains(q);
      return sameCategory && sameQuery;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadMenus();
  }

  @override
  void dispose() {
    OrderTypeSession.clear();
    super.dispose();
  }

  Future<void> _loadMenus() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final menus = await _menuApiService.fetchMenus();
      if (!mounted) return;
      _allMenus = menus;
      await _syncCartFromServer();
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _tambahKeKeranjang(MenuItemDto menu) async {
    final token = await AuthSession.getToken();
    if (token == null || token.isEmpty) {
      if (!mounted) return;
      final shouldLogin = await _showLoginRequiredDialog();
      if (!mounted || !shouldLogin) return;

      final loginSuccess = await Navigator.pushNamed(
        context,
        AppRoutes.login,
        arguments: const {'returnToPrevious': true},
      );
      if (!mounted || loginSuccess != true) return;
    }

    if (!mounted) return;
    final menuId = menu.id.trim();
    if (menuId.isEmpty) {
      AppNotice.show(context, 'Menu tidak valid. Silakan refresh.', type: AppNoticeType.error);
      return;
    }

    final key = _menuKey(menu);
    if (_updatingMenuKeys.contains(key)) return;
    final prev = _itemQty[key] ?? 0;
    final next = prev + 1;
    setState(() => _updatingMenuKeys.add(key));
    try {
      await _cartApiService.setItemQuantity(menuItemId: menuId, quantity: next);
      if (!mounted) return;
      setState(() {
        _itemQty[key] = next;
        cartCount += 1;
        _cartTotal += menu.price;
      });
      AppNotice.show(context, 'Berhasil ditambah!', type: AppNoticeType.success);
    } catch (e) {
      if (!mounted) return;
      final isUnauthorized = _isUnauthorizedError(e);
      if (isUnauthorized) {
        final shouldLogin = await _showLoginRequiredDialog();
        if (!mounted || !shouldLogin) return;
        await Navigator.pushNamed(context, AppRoutes.login);
        return;
      }
      AppNotice.show(context, '$e', type: AppNoticeType.error);
    } finally {
      if (mounted) {
        setState(() => _updatingMenuKeys.remove(key));
      }
    }
  }

  Future<void> _kurangiDariKeranjang(MenuItemDto menu) async {
    final menuId = menu.id.trim();
    if (menuId.isEmpty) return;

    final key = _menuKey(menu);
    if (_updatingMenuKeys.contains(key)) return;
    final prev = _itemQty[key] ?? 0;
    if (prev <= 0) return;
    setState(() => _updatingMenuKeys.add(key));
    try {
      if (prev == 1) {
        await _cartApiService.removeItem(menuItemId: menuId);
      } else {
        await _cartApiService.setItemQuantity(
          menuItemId: menuId,
          quantity: prev - 1,
        );
      }
      if (!mounted) return;
      setState(() {
        if (prev == 1) {
          _itemQty.remove(key);
        } else {
          _itemQty[key] = prev - 1;
        }
        cartCount = (cartCount - 1).clamp(0, 1 << 31);
        _cartTotal = (_cartTotal - menu.price).clamp(0, 1 << 31);
      });
    } catch (e) {
      if (!mounted) return;
      final isUnauthorized = _isUnauthorizedError(e);
      if (isUnauthorized) {
        final shouldLogin = await _showLoginRequiredDialog();
        if (!mounted || !shouldLogin) return;
        await Navigator.pushNamed(context, AppRoutes.login);
        return;
      }
      AppNotice.show(context, '$e', type: AppNoticeType.error);
    } finally {
      if (mounted) {
        setState(() => _updatingMenuKeys.remove(key));
      }
    }
  }

  Future<bool> _showLoginRequiredDialog() async {
    final result = await AppNotice.confirm(
      context,
      type: AppNoticeType.info,
      bodyTitle: 'Login Diperlukan',
      message: 'Anda belum login. Silakan login terlebih dahulu untuk melanjutkan.',
      confirmLabel: 'Login',
    );
    return result;
  }

  bool _isUnauthorizedError(Object e) {
    final raw = e.toString().toLowerCase();
    return raw.contains('401') ||
        raw.contains('unauthorized') ||
        raw.contains('unauth') ||
        raw.contains('belum login');
  }

  Future<void> _syncCartFromServer() async {
    final token = await AuthSession.getToken();
    if (token == null || token.isEmpty) return;
    if (_isSyncingCart) return;

    _isSyncingCart = true;
    try {
      final cartItems = await _cartApiService.getCartItems();
      if (!mounted) return;

      final nextQty = <String, int>{};
      var total = 0;
      var totalPrice = 0;
      for (final item in cartItems) {
        if (item.menuId.trim().isEmpty) continue;
        final matchedMenu = _allMenus.cast<MenuItemDto?>().firstWhere(
          (menu) => menu?.id == item.menuId,
          orElse: () => null,
        );
        if (matchedMenu != null) {
          nextQty[_menuKey(matchedMenu)] = item.quantity;
          total += item.quantity;
          totalPrice += item.subtotal;
        }
      }
      setState(() {
        _itemQty
          ..clear()
          ..addAll(nextQty);
        cartCount = total;
        _cartTotal = totalPrice;
      });
    } catch (_) {
      // Keep UI usable even when cart sync fails.
    } finally {
      _isSyncingCart = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final cartBottomOffset =  bottomInset;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      bottomNavigationBar: AppBottomNavBar(
        activeItem: AppBottomNavItem.menu,
        onHomeTap: () => Navigator.pushNamed(context, AppRoutes.landing),
        onMenuTap: () {},
        onScanTap: () => Navigator.pushNamed(context, AppRoutes.scan),
        onHistoryTap: () => Navigator.pushNamed(context, AppRoutes.orderHistory),
        onAccountTap: () => Navigator.pushNamed(context, AppRoutes.profile),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                Expanded(child: _buildBody()),
              ],
            ),
            Positioned(
              bottom: cartBottomOffset,
              left: 24,
              right: 24,
              child: cartCount > 0
                  ? _buildCartButton()
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.redAccent,
                size: 40,
              ),
              const SizedBox(height: 10),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Colors.redAccent),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _loadMenus,
                child: const Text('Coba lagi'),
              ),
            ],
          ),
        ),
      );
    }

    if (filteredMenus.isEmpty) {
      return const Center(
        child: Text(
          'Menu tidak ditemukan',
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(
        24,
        0,
        24,
        cartCount > 0 ? (96 + MediaQuery.of(context).padding.bottom) : 24,
      ),
      itemCount: filteredMenus.length,
      itemBuilder: (context, index) => _buildMenuCard(filteredMenus[index]),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const AppBackButton(
                tooltip: 'Kembali ke Beranda',
                icon: Icons.arrow_back,
              ),
              const Text(
                'Menu',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1F2937),
                ),
              ),
              const Spacer(),
              IconButton(
                tooltip: 'Chatbot',
                onPressed: () => Navigator.pushNamed(context, AppRoutes.chat),
                icon: const Icon(Icons.chat_bubble_outline),
              ),
              IconButton(
                tooltip: 'Profil',
                onPressed: () =>
                    Navigator.pushNamed(context, AppRoutes.profile),
                icon: const Icon(Icons.person_outline),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                'Semua',
                'Makanan utama',
                'Cemilan',
                'Minuman',
              ].map(_buildTabItem).toList(),
            ),
          ),
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10),
              ],
            ),
            child: TextField(
              onChanged: (value) => setState(() => _query = value),
              decoration: const InputDecoration(
                icon: Icon(Icons.search, color: Colors.grey),
                hintText: 'Cari menu favoritmu...',
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabItem(String name) {
    final isActive = activeTab == name;
    return GestureDetector(
      onTap: () => setState(() => activeTab = name),
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFC8641E) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? Colors.transparent : Colors.grey[200]!,
          ),
        ),
        child: Text(
          name,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildMenuCard(MenuItemDto menu) {
    final menuKey = _menuKey(menu);
    final qty = _itemQty[menuKey] ?? 0;
    final isUpdating = _updatingMenuKeys.contains(menuKey);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: menu.imageUrl.isNotEmpty
                ? Image.network(
                    menu.imageUrl,
                    width: 90,
                    height: 90,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        _imageFallback(),
                  )
                : _imageFallback(),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  menu.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  menu.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Rp ${_idr(menu.price)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFC8641E),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          menu.stock > 0
                              ? 'Stok tersedia: ${menu.stock}'
                              : 'Stok habis',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: menu.stock > 0
                                ? const Color(0xFF2E7D32)
                                : Colors.redAccent,
                          ),
                        ),
                      ],
                    ),
                    qty == 0
                        ? IconButton.filled(
                            onPressed: menu.stock > 0 && !isUpdating
                                ? () => _tambahKeKeranjang(menu)
                                : null,
                            icon: const Icon(Icons.add),
                            style: IconButton.styleFrom(
                              backgroundColor: const Color(0xFFC8641E),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          )
                        : Row(
                            children: [
                              _qtyButton(
                                icon: Icons.remove,
                                onTap: isUpdating
                                    ? null
                                    : () => _kurangiDariKeranjang(menu),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),
                                child: Text(
                                  '$qty',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              _qtyButton(
                                icon: Icons.add,
                                onTap: menu.stock > qty && !isUpdating
                                    ? () => _tambahKeKeranjang(menu)
                                    : null,
                              ),
                            ],
                          ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _qtyButton({required IconData icon, required VoidCallback? onTap}) {
    final isDisabled = onTap == null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: isDisabled ? Colors.grey[300] : const Color(0xFFC8641E),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 16,
          color: isDisabled ? Colors.grey[500] : Colors.white,
        ),
      ),
    );
  }

  Widget _imageFallback() {
    return Container(
      width: 90,
      height: 90,
      color: Colors.grey[300],
      child: const Icon(Icons.broken_image),
    );
  }

  Widget _buildCartButton() {
    return InkWell(
      onTap: _onCartTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        decoration: BoxDecoration(
          color: const Color(0xFFC8641E),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFC8641E).withAlpha(102),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.shopping_cart_outlined, color: Colors.white),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ke Keranjang',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'Rp ${_idr(_cartTotal)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(51),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$cartCount Item',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _idr(int value) => value.toString().replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (m) => '${m[1]}.',
  );

  Future<void> _onCartTap() async {
    final orderType = await OrderTypeSession.get();
    if (!mounted) return;

    if (orderType == null) {
      await Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => const OrderTypePickerPage(redirectToCart: true),
        ),
      );
      if (!mounted) return;
      final selected = await OrderTypeSession.get();
      if (selected == null) return;
    }

    if (!mounted) return;
    Navigator.pushNamed(context, AppRoutes.cart);
  }
}
