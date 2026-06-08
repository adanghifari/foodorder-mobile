import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../shared/config/api_config.dart';
import '../../../../shared/widgets/app_back_button.dart';
import '../../../../shared/widgets/app_notice.dart';
import '../../auth/data/auth_session.dart';
import '../../../../app/app_routes.dart';
import '../../history/domain/history_models.dart';
import 'payment_receipt_page.dart';

class StrukPage extends StatefulWidget {
  const StrukPage({super.key});

  @override
  State<StrukPage> createState() => _StrukPageState();
}

class _StrukPageState extends State<StrukPage> {
  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: const {'Accept': 'application/json'},
    ),
  );

  bool _isLoading = true;
  String? _error;
  List<HistoryOrderItem> _paidOrders = const [];
  bool _showPreviousStruk = false;

  @override
  void initState() {
    super.initState();
    _loadStruk();
  }

  Future<void> _loadStruk() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final token = await AuthSession.getToken();
    if (token == null || token.isEmpty) {
      if (!mounted) return;
      setState(() {
        _paidOrders = const [];
        _isLoading = false;
        _error = 'Anda belum login. Silakan login terlebih dahulu.';
      });
      return;
    }

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '${ApiConfig.apiBaseUrl}/v1/orders/me',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      final map = response.data ?? const <String, dynamic>{};
      final rows = map['data'] as List<dynamic>? ?? const [];

      final allOrders = rows.map((row) {
        final item = row as Map<String, dynamic>;
        final orderId = (item['orderId'] ?? '').toString();
        final customer = item['customer'];
        final customerMap = customer is Map<String, dynamic>
            ? customer
            : const <String, dynamic>{};
        final customerName = (customerMap['name'] ?? '').toString();
        final customerEmail = (customerMap['email'] ?? '').toString();
        final status = (item['status'] ?? '-').toString();
        final paymentStatus = (item['paymentStatus'] ?? '-').toString();
        final paymentMethod = (item['paymentMethod'] ?? item['method'] ?? item['paymentType'] ?? '').toString();
        final paymentUrl = (item['paymentUrl'] ?? '').toString();
        final midtransOrderId = (item['midtransOrderId'] ?? '').toString();
        final paymentExpiry = (item['paymentExpiry'] ?? '').toString();
        final qrisImageUrl = (item['qrisImageUrl'] ?? '').toString();
        final vaNumber = (item['vaNumber'] ?? item['virtualAccountNumber'] ?? item['nomorVa'] ?? item['nomorVA'] ?? '').toString();
        final orderTypeRaw = (item['orderType'] ?? 'dine_in').toString();
        final bookingStartAtRaw = (item['bookingStartAt'] ?? '').toString();
        final durationHours = _toInt(item['durationHours']);
        final tableNumber = item['tableNumber'];
        final totalPrice = _toInt(item['totalPrice']);
        final paidAt = (item['paidAt'] ?? '').toString();
        final createdAt = (item['createdAt'] ?? '').toString();

        final eventAt = _resolvePaymentEventAt(
          paymentStatus: paymentStatus,
          paidAtRaw: paidAt,
          createdAtRaw: createdAt,
        );
        final displayDateLabel = _formatEventDateLabel(eventAt);

        final rawItems = item['items'];
        final items = rawItems is List ? rawItems : const <dynamic>[];
        final orderItems = <HistoryLineItem>[];
        for (final e in items) {
          if (e is! Map<String, dynamic>) continue;
          final menu = e['menu'];
          final menuName = menu is Map<String, dynamic> ? (menu['name'] ?? '').toString() : '';
          final name = (e['name'] ?? e['menuName'] ?? e['itemName'] ?? e['foodName'] ?? menuName).toString();
          final qty = _toInt(e['quantity']);
          final unitPriceRaw = _toInt(e['unitPrice']);
          final priceRaw = _toInt(e['price']);
          final subtotalRaw = _toInt(e['subtotal']);
          final unitPrice = unitPriceRaw > 0 ? unitPriceRaw : (qty > 0 ? (priceRaw / qty).round() : priceRaw);
          final subtotal = subtotalRaw > 0 ? subtotalRaw : (priceRaw > 0 ? priceRaw : unitPrice * qty);
          orderItems.add(
            HistoryLineItem(
              name: name.isEmpty ? 'Item' : name,
              quantity: qty,
              unitPrice: unitPrice,
              subtotal: subtotal > 0 ? subtotal : unitPrice * qty,
            ),
          );
        }
        final totalItems = orderItems.fold<int>(0, (sum, e) => sum + e.quantity);
        final orderTypeKey = orderTypeRaw == 'booking_dine_in' ? 'booking' : (orderTypeRaw == 'dine_in' ? 'dine_in' : 'pickup');
        final bookingScheduleLabel = _formatBookingSchedule(
          bookingStartAtRaw: bookingStartAtRaw,
          durationHours: durationHours,
        );
        final orderTypeLabel = orderTypeKey == 'booking'
            ? 'Booking${tableNumber != null ? ' • Meja $tableNumber' : ''}${bookingScheduleLabel.isNotEmpty ? ' • $bookingScheduleLabel' : ''}'
            : (orderTypeKey == 'dine_in'
                ? 'Dine In Langsung${tableNumber != null ? ' • Meja $tableNumber' : ''}'
                : 'Takeaway/Pickup');
        final tableLabel = tableNumber == null ? '-' : '$tableNumber';

        return HistoryOrderItem(
          orderId: orderId,
          orderCode: orderId.isEmpty ? '-' : 'ORD-${orderId.substring(orderId.length > 6 ? orderId.length - 6 : 0).toUpperCase()}',
          dateLabel: displayDateLabel,
          eventAt: eventAt,
          orderTypeLabel: orderTypeLabel,
          orderTypeKey: orderTypeKey,
          customerName: customerName.isEmpty ? '-' : customerName,
          customerEmail: customerEmail.isEmpty ? '-' : customerEmail,
          tableLabel: tableLabel,
          totalItems: totalItems,
          paymentMethodLabel: paymentStatus,
          paymentMethod: paymentMethod.isEmpty ? '-' : paymentMethod,
          vaNumber: vaNumber.isEmpty ? '-' : vaNumber,
          paymentExpiry: paymentExpiry.isEmpty ? '-' : paymentExpiry.replaceFirst('T', ' '),
          qrisImageUrl: qrisImageUrl,
          paymentUrl: paymentUrl,
          midtransOrderId: midtransOrderId,
          status: status,
          totalPrice: totalPrice,
          extraCharge: _toInt(item['extraCharge']),
          items: orderItems,
        );
      }).toList();

      final paidOrders = allOrders.where((order) {
        final statusUp = order.paymentMethodLabel.toUpperCase();
        return statusUp == 'PAID' || statusUp == 'SUCCESS' || statusUp == 'SETTLEMENT';
      }).toList();

      if (!mounted) return;
      setState(() {
        _paidOrders = paidOrders;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = AppNotice.humanizeMessage(e);
        _isLoading = false;
      });
    }
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  DateTime _resolvePaymentEventAt({
    required String paymentStatus,
    required String paidAtRaw,
    required String createdAtRaw,
  }) {
    final isPaid = paymentStatus.toUpperCase() == 'PAID' ||
        paymentStatus.toUpperCase() == 'SUCCESS' ||
        paymentStatus.toUpperCase() == 'SETTLEMENT';
    final selectedRaw = isPaid
        ? (paidAtRaw.trim().isEmpty ? createdAtRaw : paidAtRaw)
        : createdAtRaw;
    final fallbackRaw = selectedRaw.trim().isEmpty ? paidAtRaw : selectedRaw;
    if (fallbackRaw.trim().isEmpty) {
      return DateTime.fromMillisecondsSinceEpoch(0);
    }
    final parsed = DateTime.tryParse(fallbackRaw);
    if (parsed == null) return DateTime.fromMillisecondsSinceEpoch(0);
    return parsed.toLocal();
  }

  String _formatEventDateLabel(DateTime eventAt) {
    if (eventAt.millisecondsSinceEpoch == 0) return '-';
    return DateFormat('dd-MM-yyyy (HH:mm:ss)').format(eventAt);
  }

  String _formatBookingSchedule({
    required String bookingStartAtRaw,
    required int durationHours,
  }) {
    if (bookingStartAtRaw.trim().isEmpty || durationHours < 1) return '';
    final parsed = DateTime.tryParse(bookingStartAtRaw);
    if (parsed == null) return '';
    final local = parsed.toLocal();
    final date = DateFormat('dd/MM/yyyy').format(local);
    final startTime = DateFormat('HH:mm').format(local);
    return '$date $startTime • $durationHours jam';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const AppBackButton(
          color: Colors.black,
          size: 20,
        ),
        title: const Text(
          'Struk Saya',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNavBarButton(context),
    );
  }

  Widget _buildBottomNavBarButton(BuildContext context) {
    if (_isLoading) return const SizedBox.shrink();
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: () => Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.landing,
              (route) => false,
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD45A00),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Kembali ke Beranda',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
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
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _loadStruk,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD45A00),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Coba lagi'),
              ),
            ],
          ),
        ),
      );
    }
    if (_paidOrders.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.receipt_outlined,
                color: Colors.grey,
                size: 48,
              ),
              SizedBox(height: 12),
              Text(
                'Belum ada struk pembayaran yang berhasil.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    final todayOrders = _todayOrdersFrom(_paidOrders);
    final previousOrders = _previousOrdersFrom(_paidOrders);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      children: [
        _buildUnifiedSection(
          title: 'Struk Hari Ini',
          subtitle: '${todayOrders.length} struk hari ini',
          orders: todayOrders,
          emptyMessage: 'Belum ada struk pembayaran hari ini',
        ),
        _buildUnifiedSection(
          title: 'Struk Sebelum Hari Ini',
          subtitle: previousOrders.isEmpty
              ? 'Tidak ada struk hari sebelumnya'
              : '${previousOrders.length} struk dari hari sebelumnya',
          orders: previousOrders,
          emptyMessage: 'Belum ada struk pembayaran hari sebelumnya',
          isExpandable: true,
          isExpanded: _showPreviousStruk,
          onTap: previousOrders.isEmpty
              ? null
              : () => setState(() => _showPreviousStruk = !_showPreviousStruk),
        ),
      ],
    );
  }

  List<HistoryOrderItem> _todayOrdersFrom(List<HistoryOrderItem> source) {
    final now = DateTime.now();
    return source.where((order) {
      final d = order.eventAt;
      return d.year == now.year && d.month == now.month && d.day == now.day;
    }).toList();
  }

  List<HistoryOrderItem> _previousOrdersFrom(List<HistoryOrderItem> source) {
    final now = DateTime.now();
    return source.where((order) {
      final d = order.eventAt;
      final isToday = d.year == now.year && d.month == now.month && d.day == now.day;
      return !isToday;
    }).toList();
  }

  Widget _buildUnifiedSection({
    required String title,
    required String subtitle,
    required List<HistoryOrderItem> orders,
    required String emptyMessage,
    bool isExpandable = false,
    bool isExpanded = true,
    VoidCallback? onTap,
  }) {
    final showContent = !isExpandable || isExpanded;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.vertical(
              top: const Radius.circular(15),
              bottom: Radius.circular(showContent ? 0 : 15),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.vertical(
                  top: const Radius.circular(15),
                  bottom: Radius.circular(showContent ? 0 : 15),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: Color(0xFF334155),
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isExpandable && orders.isNotEmpty)
                    Icon(
                      isExpanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: const Color(0xFF64748B),
                    ),
                ],
              ),
            ),
          ),
          if (showContent)
            Padding(
              padding: const EdgeInsets.all(12),
              child: orders.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          emptyMessage,
                          style: const TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    )
                  : _buildReceiptsList(orders),
            ),
        ],
      ),
    );
  }

  Widget _buildReceiptsList(List<HistoryOrderItem> orders) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: orders.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final order = orders[index];
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.dateLabel,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2E2E2E),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      idr(order.totalPrice),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFD45A00),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PaymentReceiptPage(order: order),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD45A00),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Buka Struk',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
