import 'package:flutter/material.dart';

import '../../../app/app_routes.dart';
import '../../../shared/widgets/app_back_button.dart';
import 'menu_api_service.dart';

class MenuPage extends StatefulWidget {
  const MenuPage({super.key});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  final MenuApiService _menuApiService = MenuApiService();

  int cartCount = 0;
  String activeTab = 'Semua';
  String _query = '';
  bool _isLoading = true;
  String? _error;
  List<MenuItemDto> _allMenus = const [];

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

  Future<void> _loadMenus() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final menus = await _menuApiService.fetchMenus();
      if (!mounted) return;
      setState(() {
        _allMenus = menus;
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

  void _tambahKeKeranjang() {
    setState(() {
      cartCount++;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Berhasil ditambah!'),
        duration: Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                Expanded(
                  child: _buildBody(),
                ),
              ],
            ),
            Positioned(
              bottom: 30,
              left: 24,
              right: 24,
              child: _buildCartButton(),
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
              const Icon(Icons.error_outline, color: Colors.redAccent, size: 40),
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
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
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
                onPressed: () => Navigator.pushNamed(context, AppRoutes.profile),
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
                    errorBuilder: (context, error, stackTrace) => _imageFallback(),
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
                  children: [
                    Text(
                      'Rp ${_idr(menu.price)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFC8641E),
                      ),
                    ),
                    IconButton.filled(
                      onPressed: menu.stock > 0 ? _tambahKeKeranjang : null,
                      icon: const Icon(Icons.add),
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFFC8641E),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
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
      onTap: () => Navigator.pushNamed(context, AppRoutes.cart),
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
            const Row(
              children: [
                Icon(Icons.shopping_bag_outlined, color: Colors.white),
                SizedBox(width: 10),
                Text(
                  'Lihat Keranjang',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
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
}
