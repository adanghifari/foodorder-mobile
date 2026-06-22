import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../app/app_routes.dart';
import '../../../../shared/config/api_config.dart';
import '../../../../shared/widgets/app_notice.dart';
import '../../auth/data/auth_session.dart';
import '../../history/domain/history_models.dart';
import '../../payment/presentation/midtrans_webview_page.dart';
import '../../../../shared/utils/status_localizer.dart';

class PaymentReceiptPage extends StatefulWidget {
  const PaymentReceiptPage({super.key, required this.order});

  final HistoryOrderItem order;

  @override
  State<PaymentReceiptPage> createState() => _PaymentReceiptPageState();
}

class _PaymentReceiptPageState extends State<PaymentReceiptPage> {
  late HistoryOrderItem _order;
  bool _isLoadingAction = false;
  bool _isDownloading = false;
  bool _hasChanges = false;

  static const Color _accent = Color(0xFFC8641E);

  @override
  void initState() {
    super.initState();
    _order = widget.order;
  }

  void _updateOrderStatus(String newPaymentStatus, String newStatus) {
    _hasChanges = true;
    setState(() {
      _order = HistoryOrderItem(
        orderId: _order.orderId,
        orderCode: _order.orderCode,
        dateLabel: _order.dateLabel,
        eventAt: _order.eventAt,
        orderTypeLabel: _order.orderTypeLabel,
        orderTypeKey: _order.orderTypeKey,
        customerName: _order.customerName,
        customerEmail: _order.customerEmail,
        tableLabel: _order.tableLabel,
        totalItems: _order.totalItems,
        paymentMethodLabel: newPaymentStatus,
        paymentMethod: _order.paymentMethod,
        vaNumber: _order.vaNumber,
        paymentExpiry: _order.paymentExpiry,
        qrisImageUrl: _order.qrisImageUrl,
        paymentUrl: _order.paymentUrl,
        midtransOrderId: _order.midtransOrderId,
        status: newStatus,
        totalPrice: _order.totalPrice,
        extraCharge: _order.extraCharge,
        items: _order.items,
      );
    });
  }

  Future<void> _cancelPayment() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Batalkan Pembayaran'),
        content: const Text('Apakah Anda yakin ingin membatalkan pembayaran untuk pesanan ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ya, Batalkan', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isLoadingAction = true;
    });

    final token = await AuthSession.getToken();
    if (token == null || token.isEmpty) {
      if (mounted) {
        AppNotice.show(context, 'Sesi telah berakhir, silakan login kembali.', type: AppNoticeType.error);
        setState(() {
          _isLoadingAction = false;
        });
      }
      return;
    }

    try {
      final dio = Dio();
      await dio.post(
        '${ApiConfig.apiBaseUrl}/v1/payments/cancel/${_order.orderId}',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (!mounted) return;
      AppNotice.show(context, 'Pembayaran berhasil dibatalkan.', type: AppNoticeType.success);
      _updateOrderStatus('CANCELED', 'PAYMENT_FAILED');
    } catch (e) {
      if (!mounted) return;
      AppNotice.show(context, AppNotice.humanizeMessage(e), type: AppNoticeType.error);
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingAction = false;
        });
      }
    }
  }

  Future<void> _continueOrChangePayment() async {
    setState(() {
      _isLoadingAction = true;
    });

    final token = await AuthSession.getToken();
    if (token == null || token.isEmpty) {
      if (mounted) {
        AppNotice.show(context, 'Sesi telah berakhir, silakan login kembali.', type: AppNoticeType.error);
        setState(() {
          _isLoadingAction = false;
        });
      }
      return;
    }

    try {
      final dio = Dio();
      final path = _order.paymentMethod == '-' || _order.paymentMethod.isEmpty
          ? '/v1/payments/continue/${_order.orderId}'
          : '/v1/payments/change-method/${_order.orderId}';

      final response = await dio.post<Map<String, dynamic>>(
        '${ApiConfig.apiBaseUrl}$path',
        data: {'finish_redirect_url': 'foodorder://pembayaran/selesai'},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      final root = response.data ?? const <String, dynamic>{};
      final data = root['data'];
      final redirectUrl = data is Map ? data['redirect_url']?.toString() : null;

      if (redirectUrl == null || redirectUrl.isEmpty) {
        throw Exception('URL pembayaran tidak tersedia.');
      }

      if (!mounted) return;
      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => MidtransWebViewPage(
            url: redirectUrl,
            finishRedirectUrl: 'foodorder://pembayaran/selesai',
          ),
        ),
      );

      if (result == true && mounted) {
        _updateOrderStatus('PAID', 'CONFIRMED');
      }
    } catch (e) {
      if (!mounted) return;
      AppNotice.show(context, AppNotice.humanizeMessage(e), type: AppNoticeType.error);
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingAction = false;
        });
      }
    }
  }

  Future<void> _downloadPdf() async {
    if (_isDownloading) return;
    setState(() {
      _isDownloading = true;
    });

    final token = await AuthSession.getToken();
    if (token == null || token.isEmpty) {
      if (mounted) {
        AppNotice.show(context, 'Sesi telah berakhir, silakan login kembali.', type: AppNoticeType.error);
        setState(() {
          _isDownloading = false;
        });
      }
      return;
    }

    try {
      final dio = Dio();
      final url = '${ApiConfig.apiBaseUrl}/v1/orders/${_order.orderId}/receipt/pdf';
      final response = await dio.get<List<int>>(
        url,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          responseType: ResponseType.bytes,
        ),
      );

      final bytes = response.data;
      if (bytes == null || bytes.isEmpty) {
        throw Exception('Gagal mengunduh file PDF atau file kosong.');
      }

      final tempDir = await getTemporaryDirectory();
      final displayId = 'ORD-${_order.orderId.length > 6 ? _order.orderId.substring(_order.orderId.length - 6).toUpperCase() : _order.orderId.toUpperCase()}';
      final filePath = '${tempDir.path}/struk-$displayId.pdf';
      final file = File(filePath);
      await file.writeAsBytes(bytes);

      if (!mounted) return;
      
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(filePath, mimeType: 'application/pdf')],
          subject: 'Struk Pembelian $displayId',
        ),
      );
    } catch (e) {
      if (!mounted) return;
      AppNotice.show(context, 'Gagal mengunduh PDF: ${e.toString()}', type: AppNoticeType.error);
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
      }
    }
  }

  Widget _receiptRow(String key, String value,
      {bool isLast = false, FontWeight fontWeight = FontWeight.w600, Color textColor = const Color(0xFF374151)}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 112,
            child: Text(
              key,
              style: const TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 14,
              ),
            ),
          ),
          const Text(
            ': ',
            style: TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 14,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: textColor,
                fontWeight: fontWeight,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _priceRow(String label, String value) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF4B5563),
            fontSize: 14,
            fontWeight: FontWeight.normal,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF1F2937),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final subtotal = _order.items.fold<int>(0, (sum, e) => sum + e.subtotal);
    final serviceFee = (_order.totalPrice - subtotal - _order.extraCharge).clamp(0, 1 << 30);

    final paymentStatus = _order.paymentMethodLabel.toUpperCase();
    final isPaid = paymentStatus == 'PAID' || paymentStatus == 'SUCCESS' || paymentStatus == 'SETTLEMENT';
    final isFailed = paymentStatus == 'FAILED' || paymentStatus == 'CANCELED';
    final isPending = paymentStatus == 'PENDING';

    final paymentSubtitle = isPaid
        ? 'Terima kasih, pembayaran kamu sudah kami terima.'
        : (isFailed
            ? 'Pembayaran gagal.'
            : (isPending ? 'Menunggu Pembayaran.' : 'Status pembayaran sedang diperbarui.'));

    final Color paymentBgColor = isPaid ? const Color(0xFFD1FAE5) : const Color(0xFFFEF3C7);
    final Color paymentBorderColor = isPaid ? const Color(0xFFA7F3D0) : const Color(0xFFFDE68A);
    final Color paymentTextColor = isPaid ? const Color(0xFF047857) : const Color(0xFFB45309);
    final String paymentLabel = localizedPaymentStatusLabel(_order.paymentMethodLabel);

    final canResumePaymentMethod = isPending;
    final canCancelPayment = isPending;
    final resumePaymentLabel = _order.paymentMethod == '-' || _order.paymentMethod.isEmpty
        ? 'Pilih Metode Pembayaran'
        : 'Ganti Metode Pembayaran';

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop && _hasChanges) {
          // Just returns the changes to the parent
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF3F4F6),
        appBar: AppBar(
          backgroundColor: _accent,
          elevation: 0,
          leading: BackButton(
            color: Colors.white,
            onPressed: () => Navigator.of(context).pop(_hasChanges),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            Container(
              color: _accent,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'KEDAIKLIK',
                    style: TextStyle(
                      color: Color(0xFFFFEDD5), // orange-100
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Struk Pembelian',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    paymentSubtitle,
                    style: const TextStyle(
                      color: Color(0xFFFFEDD5), // orange-100
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                children: [
                  // General Details Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB), // bg-gray-50
                      border: Border.all(color: const Color(0xFFE5E7EB)), // border-gray-200
                      borderRadius: BorderRadius.circular(16), // rounded-2xl
                    ),
                    child: Column(
                      children: [
                        _receiptRow('ID Pesanan', _order.orderCode,
                            fontWeight: FontWeight.w800, textColor: const Color(0xFF1F2937)),
                        _receiptRow('Nama Pemesan', _order.customerName),
                        _receiptRow('Email Pemesan', _order.customerEmail),
                        _receiptRow('ID Midtrans', _order.midtransOrderId.isEmpty ? '-' : _order.midtransOrderId),
                        _receiptRow('Meja', _order.tableLabel,
                            fontWeight: FontWeight.bold, textColor: const Color(0xFF1F2937)),
                        _receiptRow('Waktu Pembayaran', _order.dateLabel),
                        _receiptRow('Metode Pembayaran', _order.paymentMethod),
                        _receiptRow('Nomor VA', _order.vaNumber.isEmpty ? '-' : _order.vaNumber, isLast: true),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Status Payment & Status Pesanan Grid
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: paymentBgColor,
                            border: Border.all(color: paymentBorderColor),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'STATUS PEMBAYARAN',
                                style: TextStyle(
                                  color: paymentTextColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                paymentLabel,
                                style: TextStyle(
                                  color: paymentTextColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDBEAFE),
                            border: Border.all(color: const Color(0xFFBFDBFE)),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'STATUS PESANAN',
                                style: TextStyle(
                                  color: Color(0xFF1D4ED8),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                localizedOrderStatusLabel(_order.status),
                                style: const TextStyle(
                                  color: Color(0xFF1D4ED8),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Detail Item Card
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: const BoxDecoration(
                            color: Color(0xFFF9FAFB),
                            border: Border(
                              bottom: BorderSide(color: Color(0xFFE5E7EB)),
                            ),
                          ),
                          child: const Text(
                            'Rincian Item',
                            style: TextStyle(
                              color: Color(0xFF1F2937),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        if (_order.items.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            child: Text(
                              'Tidak ada item.',
                              style: TextStyle(
                                color: Color(0xFF6B7280),
                                fontSize: 14,
                              ),
                            ),
                          )
                        else
                          ...List.generate(_order.items.length, (index) {
                            final item = _order.items[index];
                            final isLast = index == _order.items.length - 1;
                            return Container(
                              decoration: BoxDecoration(
                                border: isLast
                                    ? null
                                    : const Border(
                                        bottom: BorderSide(
                                          color: Color(0xFFF3F4F6),
                                        ),
                                      ),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
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
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF1F2937),
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${item.quantity} x ${idr(item.unitPrice)}',
                                          style: const TextStyle(
                                            color: Color(0xFF6B7280),
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    idr(item.subtotal),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF374151),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Price Breakdown Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        _priceRow('Subtotal', idr(subtotal)),
                        const SizedBox(height: 8),
                        _priceRow('Biaya Layanan', idr(serviceFee)),
                        if (_order.extraCharge > 0) ...[
                          const SizedBox(height: 8),
                          _priceRow('Biaya Booking', idr(_order.extraCharge)),
                        ],
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.only(top: 8),
                          decoration: const BoxDecoration(
                            border: Border(
                              top: BorderSide(color: Color(0xFFE5E7EB)),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Text(
                                'Total Pembayaran',
                                style: TextStyle(
                                  color: Color(0xFF1F2937),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                idr(_order.totalPrice),
                                style: const TextStyle(
                                  color: _accent,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Action Buttons (Footer style matching Web)
                  if (_isLoadingAction)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: CircularProgressIndicator(color: _accent),
                      ),
                    )
                  else ...[
                    if (canResumePaymentMethod) ...[
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton(
                          onPressed: _continueOrChangePayment,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _accent,
                            side: const BorderSide(color: _accent),
                            backgroundColor: const Color(0xFFFFF7ED), // bg-orange-50
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            resumePaymentLabel,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (canCancelPayment) ...[
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton(
                          onPressed: _cancelPayment,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFB91C1C), // text-red-700
                            side: const BorderSide(color: Color(0xFFFECACA)), // border-red-200
                            backgroundColor: const Color(0xFFFEF2F2), // bg-red-50
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            'Batalkan Pembayaran',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (isPaid) ...[
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: _isDownloading
                            ? const Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Color(0xFF1D4ED8),
                                    strokeWidth: 2.5,
                                  ),
                                ),
                              )
                            : OutlinedButton(
                                onPressed: _downloadPdf,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF1D4ED8),
                                  side: const BorderSide(color: Color(0xFF1D4ED8)),
                                  backgroundColor: const Color(0xFFEFF6FF),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: const Text(
                                  'Unduh PDF',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pushNamedAndRemoveUntil(
                          context,
                          AppRoutes.landing,
                          (route) => false,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _accent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Kembali ke Menu',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
