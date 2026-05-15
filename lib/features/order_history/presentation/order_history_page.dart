import 'package:flutter/material.dart';

import '../../../app/app_routes.dart';
import '../../../shared/widgets/app_back_button.dart';
import '../../../shared/widgets/app_bottom_nav_bar.dart';

class OrderHistoryPage extends StatelessWidget {
  const OrderHistoryPage({super.key});

  static const Color _bg = Color(0xFFF2F2F2);
  static const Color _accent = Color(0xFFD45A00);
  static const Color _textDark = Color(0xFF2E2E2E);

  @override
  Widget build(BuildContext context) {
    final orders = _mockOrders;

    return Scaffold(
      backgroundColor: _bg,
      bottomNavigationBar: AppBottomNavBar(
        activeItem: AppBottomNavItem.history,
        onHomeTap: () => Navigator.pushNamed(context, AppRoutes.landing),
        onMenuTap: () => Navigator.pushNamed(context, AppRoutes.menu),
        onScanTap: () => ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Fitur scan akan segera tersedia.'),
            duration: Duration(seconds: 1),
          ),
        ),
        onHistoryTap: () {},
        onAccountTap: () => Navigator.pushNamed(context, AppRoutes.profile),
      ),
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        titleSpacing: 0,
        leading: const AppBackButton(
          color: _textDark,
        ),
        title: const Text(
          'Riwayat Pesanan',
          style: TextStyle(
            color: _textDark,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: orders.isEmpty
          ? _buildEmptyState()
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: orders.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final order = orders[index];
                return _OrderHistoryCard(order: order);
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long_outlined, color: Color(0xFF9C9C9C), size: 44),
            SizedBox(height: 10),
            Text(
              'Belum ada riwayat pesanan',
              style: TextStyle(
                color: Color(0xFF666666),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderHistoryCard extends StatelessWidget {
  const _OrderHistoryCard({required this.order});

  final _OrderHistoryItem order;

  static const Color _accent = Color(0xFFD45A00);
  static const Color _dark = Color(0xFF2E2E2E);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x13000000),
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  order.orderCode,
                  style: const TextStyle(
                    color: _dark,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _StatusChip(status: order.status),
            ],
          ),
          const SizedBox(height: 10),
          _kv('Tanggal', order.dateLabel),
          _kv('Tipe', order.orderTypeLabel),
          _kv('Jumlah Item', '${order.totalItems} item'),
          _kv('Metode Bayar', order.paymentMethodLabel),
          const SizedBox(height: 10),
          Row(
            children: [
              const Text(
                'Total',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF666666),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                _idr(order.totalPrice),
                style: const TextStyle(
                  color: _accent,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFD7D7D7)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Detail',
                    style: TextStyle(
                      color: _dark,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Pesan Lagi',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _kv(String key, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              key,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF666666),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF333333),
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final isDone = status.toUpperCase() == 'SELESAI';
    final bg = isDone ? const Color(0xFFE8F7EC) : const Color(0xFFFFF4E8);
    final fg = isDone ? const Color(0xFF2E7D32) : const Color(0xFFAF5A00);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _OrderHistoryItem {
  const _OrderHistoryItem({
    required this.orderCode,
    required this.dateLabel,
    required this.orderTypeLabel,
    required this.totalItems,
    required this.paymentMethodLabel,
    required this.status,
    required this.totalPrice,
  });

  final String orderCode;
  final String dateLabel;
  final String orderTypeLabel;
  final int totalItems;
  final String paymentMethodLabel;
  final String status;
  final int totalPrice;
}

String _idr(int value) {
  final number = value.toString().replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (match) => '${match[1]}.',
  );
  return 'Rp $number';
}

const List<_OrderHistoryItem> _mockOrders = [
  _OrderHistoryItem(
    orderCode: 'ORD-89AF12',
    dateLabel: '15 Mei 2026, 19:45',
    orderTypeLabel: 'Dine-in • Meja 07',
    totalItems: 4,
    paymentMethodLabel: 'QRIS Midtrans',
    status: 'SELESAI',
    totalPrice: 91000,
  ),
  _OrderHistoryItem(
    orderCode: 'ORD-35CB90',
    dateLabel: '13 Mei 2026, 12:08',
    orderTypeLabel: 'Take-away',
    totalItems: 2,
    paymentMethodLabel: 'GoPay Midtrans',
    status: 'SELESAI',
    totalPrice: 43000,
  ),
  _OrderHistoryItem(
    orderCode: 'ORD-11AE77',
    dateLabel: '11 Mei 2026, 18:20',
    orderTypeLabel: 'Dine-in • Meja 03',
    totalItems: 3,
    paymentMethodLabel: 'Bank Transfer',
    status: 'DIPROSES',
    totalPrice: 76000,
  ),
];
