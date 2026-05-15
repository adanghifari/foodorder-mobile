import 'package:flutter/material.dart';

import '../../../app/app_routes.dart';
import '../../landing/presentation/order_type_session.dart';
import '../../payment/presentation/midtrans_webview_page.dart';
import 'cart_api_service.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  static const Color _lightBrownColor = Color(0xFFC7985F);
  static const Color _whiteColor = Color(0xFFFFFFFF);

  final CartApiService _cartApiService = CartApiService();
  final TextEditingController _tableController = TextEditingController();
  final Set<String> _updatingMenuIds = <String>{};
  static const String _mobileFinishRedirectUrl =
      'https://mobile.kedaiklik.app/payment-finish';

  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _error;
  OrderType? _orderType;
  List<CartItemDto> _items = const [];

  int get _subtotal => _items.fold(0, (sum, e) => sum + e.subtotal);

  @override
  void initState() {
    super.initState();
    _initPage();
  }

  Future<void> _initPage() async {
    _orderType = await OrderTypeSession.get();
    await _loadCart();
  }

  @override
  void dispose() {
    _tableController.dispose();
    super.dispose();
  }

  Future<void> _loadCart() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final items = await _cartApiService.getCartItems();
      if (!mounted) return;
      setState(() {
        _items = items;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _isLoading = false;
      });
    }
  }

  Future<void> _changeQty(CartItemDto item, int delta) async {
    if (_updatingMenuIds.contains(item.menuId)) return;
    final nextQty = item.quantity + delta;
    if (nextQty < 0) return;

    setState(() => _updatingMenuIds.add(item.menuId));
    try {
      if (nextQty == 0) {
        await _cartApiService.removeItem(menuItemId: item.menuId);
      } else {
        await _cartApiService.setItemQuantity(
          menuItemId: item.menuId,
          quantity: nextQty,
        );
      }
      await _loadCart();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) {
        setState(() => _updatingMenuIds.remove(item.menuId));
      }
    }
  }

  Future<void> _payNow() async {
    final orderType = _orderType;
    if (orderType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih tipe pesanan terlebih dahulu.')),
      );
      return;
    }

    int? tableNumber;
    if (orderType == OrderType.dineIn) {
      tableNumber = int.tryParse(_tableController.text.trim());
      if (tableNumber == null || tableNumber < 1) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nomor meja wajib diisi dengan benar.')),
        );
        return;
      }
    }
    if (_items.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Keranjang masih kosong.')));
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final orderId = await _cartApiService.checkout(
        orderType: OrderTypeSession.toApiValue(orderType),
        tableNumber: tableNumber,
      );
      final redirectUrl = await _cartApiService.createPayment(
        orderId: orderId,
        finishRedirectUrl: _mobileFinishRedirectUrl,
      );
      if (!mounted) return;
      if (redirectUrl == null || redirectUrl.isEmpty) {
        throw Exception('URL pembayaran Midtrans tidak tersedia.');
      }

      if (Uri.tryParse(redirectUrl) == null) {
        throw Exception('URL pembayaran Midtrans tidak valid.');
      }

      final finished = await Navigator.push<bool>(
        context,
        MaterialPageRoute<bool>(
          builder: (_) => MidtransWebViewPage(
            url: redirectUrl,
            finishRedirectUrl: _mobileFinishRedirectUrl,
          ),
        ),
      );

      if (finished != true) {
        return;
      }

      await OrderTypeSession.clear();
      await _loadCart();
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.landing,
        (route) => route.isFirst,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e'), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _whiteColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.black,
            size: 20,
          ),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text(
          'Pesanan saya',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        backgroundColor: _whiteColor,
        elevation: 0,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
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
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _loadCart,
                child: const Text('Coba lagi'),
              ),
            ],
          ),
        ),
      );
    }
    if (_items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Keranjang kosong'),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, AppRoutes.menu),
              child: const Text('Pilih Menu'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ..._items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildOrderItem(item),
            ),
          ),
          const SizedBox(height: 15),
          _buildLabel('Tipe Pesanan'),
          Text(
            _orderType == null
                ? 'Belum dipilih'
                : OrderTypeSession.toLabel(_orderType!),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          if (_orderType == OrderType.dineIn) ...[
            const SizedBox(height: 14),
            _buildLabel('Nomor Meja'),
            _buildTextField(
              controller: _tableController,
              hintText: 'Contoh: 7',
            ),
          ],
          const SizedBox(height: 30),
          const Text(
            'Detail Pembayaran',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 15),
          _buildPaymentRow('Subtotal', _subtotal),
          _buildPaymentRow('Biaya Layanan', 0),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(thickness: 1),
          ),
          _buildPaymentRow('Total Pembayaran', _subtotal, isTotal: true),
          const SizedBox(height: 30),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pushNamed(context, AppRoutes.menu),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: _lightBrownColor),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Tambah Item',
                    style: TextStyle(
                      color: _lightBrownColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _payNow,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _lightBrownColor,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _isSubmitting ? 'Memproses...' : 'Bayar',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.grey.shade400),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 15,
            vertical: 15,
          ),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildOrderItem(CartItemDto item) {
    final isUpdating = _updatingMenuIds.contains(item.menuId);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: item.imageUrl.isNotEmpty
                ? Image.network(
                    item.imageUrl,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        _imgFallback(),
                  )
                : _imgFallback(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  item.description,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Rp ${_idr(item.subtotal)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Row(
                      children: [
                        _qtyBtn(
                          Icons.remove,
                          onTap: isUpdating ? null : () => _changeQty(item, -1),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            '${item.quantity}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        _qtyBtn(
                          Icons.add,
                          onTap: isUpdating ? null : () => _changeQty(item, 1),
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

  Widget _imgFallback() {
    return Container(
      width: 80,
      height: 80,
      color: Colors.grey[300],
      child: const Icon(Icons.fastfood, color: Colors.grey),
    );
  }

  Widget _qtyBtn(IconData icon, {required VoidCallback? onTap}) {
    final disabled = onTap == null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: disabled ? Colors.grey[300] : _lightBrownColor,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, color: Colors.white, size: 16),
      ),
    );
  }

  Widget _buildPaymentRow(String label, int amount, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            'Rp ${_idr(amount)}',
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  String _idr(int value) => value.toString().replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (m) => '${m[1]}.',
  );
}
