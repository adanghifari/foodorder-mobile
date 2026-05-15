import 'package:flutter/material.dart';

import '../../domain/history_models.dart';

class PaymentReceiptPage extends StatelessWidget {
  const PaymentReceiptPage({super.key, required this.order});

  final HistoryOrderItem order;

  static const Color _accent = Color(0xFFD45A00);
  static const Color _dark = Color(0xFF1F2937);

  @override
  Widget build(BuildContext context) {
    final subtotal = order.items.fold<int>(0, (sum, e) => sum + e.subtotal);
    final serviceFee = (order.totalPrice - subtotal).clamp(0, 1 << 30);

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      appBar: AppBar(
        title: const Text('Struk Pembelian'),
        backgroundColor: _accent,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 24),
        children: [
          Container(
            color: _accent,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'KEDAIKLIK',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Struk Pembelian',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Terima kasih, pembayaran kamu sudah kami terima.',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _section(
                  child: Column(
                    children: [
                      _receiptRow('Order ID', order.orderCode),
                      _receiptRow('Nama Pemesan', order.customerName),
                      _receiptRow('Email Pemesan', order.customerEmail),
                      _receiptRow('Midtrans ID', order.midtransOrderId),
                      _receiptRow('Meja', order.tableLabel),
                      _receiptRow('Waktu Bayar', order.dateLabel),
                      _receiptRow('Metode Bayar', order.paymentMethod),
                      _receiptRow('Nomor VA', order.vaNumber, isLast: true),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFB7E4C7),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Text(
                    'STATUS PAYMENT\nLUNAS',
                    style: TextStyle(
                      color: Color(0xFF0F766E),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _section(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Detail Item',
                        style: TextStyle(
                          color: _dark,
                          fontSize: 27,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Divider(height: 1),
                      const SizedBox(height: 8),
                      ...order.items.map((item) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: _dark,
                                      ),
                                    ),
                                    Text(
                                      '${item.quantity} x ${idr(item.unitPrice)}',
                                      style: const TextStyle(
                                        color: Color(0xFF6B7280),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                idr(item.subtotal),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: _dark,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _section(
                  child: Column(
                    children: [
                      _totalRow('Subtotal', idr(subtotal)),
                      _totalRow('Biaya Layanan', idr(serviceFee)),
                      const SizedBox(height: 4),
                      _totalRow(
                        'Total Pembayaran',
                        idr(order.totalPrice),
                        isTotal: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _section({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFD1D5DB)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }

  Widget _receiptRow(String key, String value, {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(key, style: const TextStyle(color: Color(0xFF6B7280))),
          ),
          const Text(': ', style: TextStyle(color: Color(0xFF6B7280))),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: _dark, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _totalRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              color: _dark,
              fontWeight: isTotal ? FontWeight.w800 : FontWeight.w600,
              fontSize: isTotal ? 18 : 14,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              color: isTotal ? _accent : _dark,
              fontWeight: FontWeight.w800,
              fontSize: isTotal ? 18 : 14,
            ),
          ),
        ],
      ),
    );
  }
}
