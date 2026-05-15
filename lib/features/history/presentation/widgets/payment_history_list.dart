import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../auth/data/auth_session.dart';
import '../../../payment/presentation/midtrans_webview_page.dart';
import '../../../../shared/widgets/app_notice.dart';
import '../../domain/history_models.dart';
import 'payment_receipt_page.dart';

class PaymentHistoryList extends StatelessWidget {
  const PaymentHistoryList({
    super.key,
    required this.orders,
    this.onRefreshRequested,
  });

  final List<HistoryOrderItem> orders;
  final Future<void> Function()? onRefreshRequested;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: orders.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _PaymentHistoryCard(
        order: orders[index],
        onRefreshRequested: onRefreshRequested,
      ),
    );
  }
}

class _PaymentHistoryCard extends StatelessWidget {
  const _PaymentHistoryCard({
    required this.order,
    this.onRefreshRequested,
  });

  final HistoryOrderItem order;
  final Future<void> Function()? onRefreshRequested;

  static const Color _accent = Color(0xFFD45A00);
  static const Color _dark = Color(0xFF2E2E2E);
  static const Color _danger = Color(0xFFDC2626);
  static const String _finishRedirectUrl =
      'https://mobile.kedaiklik.app/payment-finish';

  bool get _isPaid {
    final s = order.paymentMethodLabel.toUpperCase();
    return s == 'PAID' || s == 'SUCCESS' || s == 'SETTLEMENT';
  }

  bool get _isActionablePending {
    final s = order.paymentMethodLabel.toUpperCase();
    return s == 'PENDING' || s == 'UNPAID';
  }

  bool get _hasPaymentMethod {
    final value = order.paymentMethod.trim();
    return value.isNotEmpty && value != '-';
  }

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
              _PaymentStatusChip(status: order.paymentMethodLabel),
            ],
          ),
          const SizedBox(height: 10),
          _kv('Tanggal Bayar', order.dateLabel),
          _kv('Metode/Status', order.paymentMethodLabel),
          _kv('Metode Bayar', order.paymentMethod),
          _kv('Status Order', order.status),
          const SizedBox(height: 10),
          Row(
            children: [
              const Text(
                'Nominal',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF666666),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                idr(order.totalPrice),
                style: const TextStyle(
                  color: _accent,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => _showPaymentDetail(context),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: _accent),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              child: const Text(
                'Lihat Detail',
                style: TextStyle(
                  color: _accent,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          if (_isPaid) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PaymentReceiptPage(order: order),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Lihat Struk',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
          ..._buildCardActionButtons(context),
        ],
      ),
    );
  }

  void _showPaymentDetail(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF4E8),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.payments_rounded,
                        color: _accent,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Detail Pembayaran',
                        style: TextStyle(
                          color: _dark,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F8F8),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _detailRow('Kode', order.orderCode),
                      _detailRow('Tanggal Bayar', order.dateLabel),
                      _detailRow('Metode/Status', order.paymentMethodLabel),
                      _detailRow('Payment Method', order.paymentMethod),
                      _detailRow('Nomor VA', order.vaNumber),
                      _detailRow('Status Order', order.status),
                      _detailRow('Nominal', idr(order.totalPrice), isLast: true),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Tutup',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildCardActionButtons(BuildContext context) {
    if (_isPaid) {
      return const [];
    }
    if (!_isActionablePending) {
      return const [];
    }

    final buttons = <Widget>[];

    if (!_hasPaymentMethod) {
      buttons.add(const SizedBox(height: 8));
      buttons.add(
        _actionButton(
          label: 'Pilih Payment Method',
          onTap: () => _continuePayment(context),
        ),
      );
      buttons.add(const SizedBox(height: 8));
      buttons.add(
        _actionButton(
          label: 'Batalkan Pembayaran',
          danger: true,
          onTap: () => _cancelPayment(context),
        ),
      );
      return buttons;
    }

    buttons.add(const SizedBox(height: 8));
    buttons.add(
      _actionButton(
        label: 'Bayar Sekarang',
        onTap: () => _showPayNowInfo(context),
      ),
    );
    buttons.add(const SizedBox(height: 8));
    buttons.add(
      _actionButton(
        label: 'Batalkan Pembayaran',
        danger: true,
        onTap: () => _cancelPayment(context),
      ),
    );
    return buttons;
  }

  Widget _actionButton({
    required String label,
    required Future<void> Function() onTap,
    bool outlined = false,
    bool danger = false,
  }) {
    final color = danger ? _danger : _accent;
    if (outlined) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: onTap,
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: color),
            foregroundColor: color,
            padding: const EdgeInsets.symmetric(vertical: 11),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 11),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }

  Future<void> _continuePayment(BuildContext context) async {
    final api = _HistoryPaymentApi();
    try {
      final redirect = await api.continuePayment(
        orderId: order.orderId,
        finishRedirectUrl: _finishRedirectUrl,
      );
      if (redirect == null || redirect.isEmpty) {
        throw Exception('URL pembayaran tidak tersedia.');
      }
      await _openMidtrans(context, redirect);
      await onRefreshRequested?.call();
    } catch (e) {
      if (!context.mounted) return;
      AppNotice.show(context, '$e', type: AppNoticeType.error);
    }
  }

  Future<void> _showPayNowInfo(BuildContext context) async {
    final isQris = order.paymentMethod.toLowerCase().contains('qris');
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Informasi Pembayaran',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: _dark,
                  ),
                ),
                const SizedBox(height: 12),
                _detailRow('Metode', order.paymentMethod),
                _vaRow(context),
                _detailRow('Batas Waktu', order.paymentExpiry, isLast: !isQris),
                if (isQris && order.qrisImageUrl.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        order.qrisImageUrl,
                        width: 180,
                        height: 180,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Text(
                          'QR tidak tersedia',
                          style: TextStyle(color: Color(0xFF666666)),
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () async {
                      Navigator.of(sheetContext).pop();
                      await _changeMethod(context);
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: _accent),
                      foregroundColor: _accent,
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Ganti Metode Pembayaran',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(sheetContext).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Tutup',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _changeMethod(BuildContext context) async {
    final api = _HistoryPaymentApi();
    try {
      final redirect = await api.changeMethod(
        orderId: order.orderId,
        finishRedirectUrl: _finishRedirectUrl,
      );
      if (redirect == null || redirect.isEmpty) {
        throw Exception('URL pembayaran tidak tersedia.');
      }
      await _openMidtrans(context, redirect);
      await onRefreshRequested?.call();
    } catch (e) {
      if (!context.mounted) return;
      AppNotice.show(context, '$e', type: AppNoticeType.error);
    }
  }

  Future<void> _cancelPayment(BuildContext context) async {
    final api = _HistoryPaymentApi();
    try {
      await api.cancel(orderId: order.orderId);
      if (!context.mounted) return;
      AppNotice.show(
        context,
        'Pembayaran berhasil dibatalkan.',
        type: AppNoticeType.success,
      );
      await onRefreshRequested?.call();
    } catch (e) {
      if (!context.mounted) return;
      AppNotice.show(context, '$e', type: AppNoticeType.error);
    }
  }

  Future<void> _openMidtrans(BuildContext context, String redirectUrl) async {
    final uri = Uri.tryParse(redirectUrl);
    if (uri == null || !uri.hasScheme) {
      throw Exception('URL pembayaran Midtrans tidak valid.');
    }

    if (!context.mounted) return;
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => MidtransWebViewPage(
          url: redirectUrl,
          finishRedirectUrl: _finishRedirectUrl,
        ),
      ),
    );

    if (result == true) {
      await onRefreshRequested?.call();
    }
  }

  Widget _kv(String key, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        children: [
          SizedBox(
            width: 110,
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

  Widget _detailRow(String label, String value, {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF666666),
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Text(
            ': ',
            style: TextStyle(
              color: Color(0xFF666666),
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: _dark,
                fontSize: 12.8,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _vaRow(BuildContext context) {
    final va = order.vaNumber.trim();
    final canCopy = va.isNotEmpty && va != '-';

    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(
            width: 110,
            child: Text(
              'Nomor VA',
              style: TextStyle(
                color: Color(0xFF666666),
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Text(
            ': ',
            style: TextStyle(
              color: Color(0xFF666666),
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          Expanded(
            child: Text(
              va.isEmpty ? '-' : va,
              style: const TextStyle(
                color: _dark,
                fontSize: 12.8,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (canCopy)
            TextButton(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: va));
                if (!context.mounted) return;
                await showDialog<void>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Berhasil'),
                    content: const Text('Nomor VA disalin'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
              },
              style: TextButton.styleFrom(
                foregroundColor: _accent,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                minimumSize: const Size(0, 0),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Salin',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
        ],
      ),
    );
  }
}

class _HistoryPaymentApi {
  static const String _apiBaseUrlFromEnv = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: const {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ),
  );

  String get _apiBaseUrl {
    if (_apiBaseUrlFromEnv.isNotEmpty) return _apiBaseUrlFromEnv;
    return kIsWeb ? 'http://127.0.0.1:8000/api' : 'http://192.168.1.5:8000/api';
  }

  Future<String?> continuePayment({
    required String orderId,
    String? finishRedirectUrl,
  }) async {
    final map = await _postPaymentAction(
      path: '/v1/payments/continue/$orderId',
      finishRedirectUrl: finishRedirectUrl,
    );
    return map['redirect_url']?.toString();
  }

  Future<String?> changeMethod({
    required String orderId,
    String? finishRedirectUrl,
  }) async {
    final map = await _postPaymentAction(
      path: '/v1/payments/change-method/$orderId',
      finishRedirectUrl: finishRedirectUrl,
    );
    return map['redirect_url']?.toString();
  }

  Future<void> cancel({required String orderId}) async {
    await _postPaymentAction(path: '/v1/payments/cancel/$orderId');
  }

  Future<Map<String, dynamic>> _postPaymentAction({
    required String path,
    String? finishRedirectUrl,
  }) async {
    final token = await AuthSession.getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Belum login.');
    }

    final payload = <String, dynamic>{};
    if (finishRedirectUrl != null && finishRedirectUrl.isNotEmpty) {
      payload['finish_redirect_url'] = finishRedirectUrl;
    }

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '$_apiBaseUrl$path',
        data: payload,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      final root = response.data ?? const <String, dynamic>{};
      final data = root['data'];
      if (data is Map<String, dynamic>) return data;
      return const <String, dynamic>{};
    } on DioException catch (e) {
      throw Exception(_extractDioMessage(e));
    }
  }

  String _extractDioMessage(DioException e) {
    final statusCode = e.response?.statusCode;
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      final message = data['message']?.toString();
      if (message != null && message.isNotEmpty) {
        return statusCode == null ? message : 'HTTP $statusCode: $message';
      }
    }
    return e.message ?? 'Tidak bisa terhubung ke server';
  }
}

class _PaymentStatusChip extends StatelessWidget {
  const _PaymentStatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final statusUp = status.toUpperCase();
    final isPaid =
        statusUp == 'PAID' || statusUp == 'SUCCESS' || statusUp == 'SETTLEMENT';
    final bg = isPaid ? const Color(0xFFE8F7EC) : const Color(0xFFFFF4E8);
    final fg = isPaid ? const Color(0xFF2E7D32) : const Color(0xFFAF5A00);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status,
        style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w800),
      ),
    );
  }
}
