import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../../shared/config/api_config.dart';
import '../../../../shared/widgets/app_back_button.dart';
import '../../../../shared/widgets/app_notice.dart';
import '../../auth/data/auth_session.dart';
import '../../../../app/app_routes.dart';
import '../../history/domain/history_models.dart';
import 'payment_receipt_page.dart';
import '../../../../shared/widgets/app_dropdown_field.dart';
import '../../../../shared/utils/indonesian_date_formatter.dart';
import '../../../../shared/utils/status_localizer.dart';

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
  _FilterMode _mode = _FilterMode.today;
  DateTime? _selectedPastDate;

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
        final paymentMethod =
            (item['paymentMethod'] ??
                    item['method'] ??
                    item['paymentType'] ??
                    '')
                .toString();
        final paymentUrl = (item['paymentUrl'] ?? '').toString();
        final midtransOrderId = (item['midtransOrderId'] ?? '').toString();
        final paymentExpiry = (item['paymentExpiry'] ?? '').toString();
        final qrisImageUrl = (item['qrisImageUrl'] ?? '').toString();
        final vaNumber =
            (item['vaNumber'] ??
                    item['virtualAccountNumber'] ??
                    item['nomorVa'] ??
                    item['nomorVA'] ??
                    '')
                .toString();
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
          final menuName = menu is Map<String, dynamic>
              ? (menu['name'] ?? '').toString()
              : '';
          final name =
              (e['name'] ??
                      e['menuName'] ??
                      e['itemName'] ??
                      e['foodName'] ??
                      menuName)
                  .toString();
          final qty = _toInt(e['quantity']);
          final unitPriceRaw = _toInt(e['unitPrice']);
          final priceRaw = _toInt(e['price']);
          final subtotalRaw = _toInt(e['subtotal']);
          final unitPrice = unitPriceRaw > 0
              ? unitPriceRaw
              : (qty > 0 ? (priceRaw / qty).round() : priceRaw);
          final subtotal = subtotalRaw > 0
              ? subtotalRaw
              : (priceRaw > 0 ? priceRaw : unitPrice * qty);
          orderItems.add(
            HistoryLineItem(
              name: name.isEmpty ? 'Item' : name,
              quantity: qty,
              unitPrice: unitPrice,
              subtotal: subtotal > 0 ? subtotal : unitPrice * qty,
            ),
          );
        }
        final totalItems = orderItems.fold<int>(
          0,
          (sum, e) => sum + e.quantity,
        );
        final orderTypeKey = orderTypeRaw == 'booking_dine_in'
            ? 'booking'
            : (orderTypeRaw == 'dine_in' ? 'dine_in' : 'pickup');
        final bookingScheduleLabel = _formatBookingSchedule(
          bookingStartAtRaw: bookingStartAtRaw,
          durationHours: durationHours,
        );
        final orderTypeLabel = localizedOrderTypeLabel(
          orderTypeKey,
          tableNumber: tableNumber,
          bookingScheduleLabel: bookingScheduleLabel,
        );
        final tableLabel = tableNumber == null ? '-' : '$tableNumber';

        return HistoryOrderItem(
          orderId: orderId,
          orderCode: orderId.isEmpty
              ? '-'
              : 'ORD-${orderId.substring(orderId.length > 6 ? orderId.length - 6 : 0).toUpperCase()}',
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
          paymentExpiry: paymentExpiry.isEmpty
              ? '-'
              : formatIndonesianDateTimeFromRaw(paymentExpiry),
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
        return statusUp == 'PAID' ||
            statusUp == 'SUCCESS' ||
            statusUp == 'SETTLEMENT';
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
    final isPaid =
        paymentStatus.toUpperCase() == 'PAID' ||
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
    return formatIndonesianDateTime(eventAt);
  }

  String _formatBookingSchedule({
    required String bookingStartAtRaw,
    required int durationHours,
  }) {
    if (bookingStartAtRaw.trim().isEmpty || durationHours < 1) return '';
    final parsed = DateTime.tryParse(bookingStartAtRaw);
    if (parsed == null) return '';
    final local = parsed.toLocal();
    final date = formatIndonesianDate(local);
    final startTime =
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
    return '$date $startTime • $durationHours jam';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const AppBackButton(color: Colors.black, size: 20),
        title: const Text(
          'Struk Saya',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
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
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
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
              Icon(Icons.receipt_outlined, color: Colors.grey, size: 48),
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

    final filtered = _filteredOrders;
    if (filtered.isEmpty) {
      return Column(
        children: [
          _buildFilterBar(),
          const Expanded(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.receipt_outlined, color: Colors.grey, size: 48),
                    SizedBox(height: 12),
                    Text(
                      'Belum ada struk pembayaran pada tanggal ini.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        _buildFilterBar(),
        Expanded(child: _buildReceiptsList(filtered)),
      ],
    );
  }

  List<HistoryOrderItem> get _filteredOrders {
    final list = List<HistoryOrderItem>.from(_paidOrders);
    final now = DateTime.now();

    return list.where((order) {
      final d = order.eventAt;
      final isToday =
          d.year == now.year && d.month == now.month && d.day == now.day;

      if (_mode == _FilterMode.today) {
        return isToday;
      } else {
        if (_selectedPastDate == null) {
          // Show all past orders (before today)
          final todayStart = DateTime(now.year, now.month, now.day);
          return d.isBefore(todayStart);
        } else {
          // Show orders on specific past date
          return d.year == _selectedPastDate!.year &&
              d.month == _selectedPastDate!.month &&
              d.day == _selectedPastDate!.day;
        }
      }
    }).toList();
  }

  Widget _buildFilterBar() {
    final todayStr = formatIndonesianDate(DateTime.now());
    final pastStr = _selectedPastDate != null
        ? formatIndonesianDate(_selectedPastDate!)
        : '';

    final dropdownOptions = [
      AppDropdownOption<String>(value: 'today', label: 'Hari ini ($todayStr)'),
      AppDropdownOption<String>(
        value: 'past',
        label: _selectedPastDate != null ? pastStr : 'Sebelum Hari ini',
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          Expanded(
            child: AppDropdownField<String>(
              value: _mode == _FilterMode.today ? 'today' : 'past',
              borderRadius: 10,
              borderColor: const Color(0xFFE3E3E3),
              textStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF4B5563),
              ),
              options: dropdownOptions,
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _mode = value == 'today'
                      ? _FilterMode.today
                      : _FilterMode.past;
                  if (_mode == _FilterMode.past) {
                    _selectedPastDate = null;
                  }
                });
              },
            ),
          ),
          if (_mode == _FilterMode.past) ...[
            const SizedBox(width: 8),
            SizedBox(
              height: 40,
              width: 40,
              child: OutlinedButton(
                onPressed: _selectPastDate,
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  side: const BorderSide(color: Color(0xFFD45A00)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Icon(
                  Icons.calendar_month_rounded,
                  color: Color(0xFFD45A00),
                  size: 20,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _selectPastDate() async {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final initial =
        _selectedPastDate != null && !_selectedPastDate!.isAfter(yesterday)
        ? _selectedPastDate!
        : yesterday;

    final picked = await showDialog<dynamic>(
      context: context,
      builder: (context) {
        return _CustomDatePickerDialog(
          initialDate: initial,
          firstDate: DateTime(2020),
          lastDate: yesterday,
        );
      },
    );

    if (picked == 'all_past') {
      setState(() {
        _selectedPastDate = null;
      });
    } else if (picked is DateTime && picked != _selectedPastDate) {
      setState(() {
        _selectedPastDate = picked;
      });
    }
  }

  Widget _buildReceiptsList(List<HistoryOrderItem> orders) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Buka Struk',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

enum _FilterMode { today, past }

class _CustomDatePickerDialog extends StatefulWidget {
  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;

  const _CustomDatePickerDialog({
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
  });

  @override
  State<_CustomDatePickerDialog> createState() =>
      _CustomDatePickerDialogState();
}

class _CustomDatePickerDialogState extends State<_CustomDatePickerDialog> {
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      clipBehavior: Clip.antiAlias,
      backgroundColor: Colors.white,
      child: Container(
        width: 328,
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 300,
              child: Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: const ColorScheme.light(
                    primary: Color(0xFFD45A00),
                    onPrimary: Colors.white,
                    onSurface: Color(0xFF2E2E2E),
                  ),
                ),
                child: CalendarDatePicker(
                  initialDate: _selectedDate,
                  firstDate: widget.firstDate,
                  lastDate: widget.lastDate,
                  onDateChanged: (date) {
                    setState(() {
                      _selectedDate = date;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop('all_past');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD45A00),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Tampilkan semua dimasa lalu',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF666666),
                  ),
                  child: const Text(
                    'Batal',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(_selectedDate),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFD45A00),
                  ),
                  child: const Text(
                    'OK',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
