import 'package:flutter/material.dart';

import '../../../app/app_routes.dart';
import '../../scan/presentation/scan_page.dart';
import '../data/order_type_session.dart';

class OrderTypePickerPage extends StatelessWidget {
  const OrderTypePickerPage({
    super.key,
    this.redirectToCart = false,
  });

  final bool redirectToCart;

  static const Color _bg = Color(0xFFF2F2F2);
  static const Color _accent = Color(0xFFD45A00);
  static const Color _textDark = Color(0xFF343434);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        title: const Text(
          'Pilih Tipe Pesanan',
          style: TextStyle(
            color: _textDark,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        iconTheme: const IconThemeData(color: _textDark),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        child: Column(
          children: [
            _orderTypeCard(
              context,
              icon: Icons.restaurant,
              label: 'Booking\nmeja',
              orderType: OrderType.bookingDineIn,
            ),
            const SizedBox(height: 16),
            _orderTypeCard(
              context,
              icon: Icons.storefront,
              label: 'Pesan &\nambil',
              orderType: OrderType.pickup,
            ),
            const SizedBox(height: 16),
            _scanQrCard(context),
          ],
        ),
      ),
    );
  }

  Widget _scanQrCard(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => ScanPage(redirectToCart: redirectToCart),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        height: 170,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F8F8),
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
              color: Color(0x10000000),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              height: 74,
              width: 74,
              decoration: const BoxDecoration(
                color: _accent,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.qr_code_scanner, color: Colors.white, size: 36),
            ),
            const SizedBox(width: 18),
            const Expanded(
              child: Text(
                'Pindai\nQR',
                style: TextStyle(
                  color: _textDark,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  height: 1.25,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _orderTypeCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required OrderType orderType,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () async {
        await OrderTypeSession.set(orderType);
        if (!context.mounted) return;
        final targetRoute = redirectToCart ? AppRoutes.cart : AppRoutes.menu;
        Navigator.pushNamed(context, targetRoute);
      },
      child: Container(
        width: double.infinity,
        height: 170,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F8F8),
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
              color: Color(0x10000000),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              height: 74,
              width: 74,
              decoration: const BoxDecoration(
                color: _accent,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 36),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: _textDark,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  height: 1.25,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
