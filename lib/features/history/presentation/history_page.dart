import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../app/app_routes.dart';
import '../../../shared/widgets/app_back_button.dart';
import '../../../shared/widgets/app_bottom_nav_bar.dart';
import '../../../shared/widgets/app_dropdown_field.dart';
import '../../../shared/widgets/app_notice.dart';
import '../../auth/data/auth_session.dart';
import '../domain/history_models.dart';
import 'widgets/payment_history_list.dart';
import '../../../shared/config/api_config.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  static const Color _bg = Color(0xFFF2F2F2);
  static const Color _textDark = Color(0xFF2E2E2E);

  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: const {'Accept': 'application/json'},
    ),
  );

  bool _isLoading = true;
  String? _error;
  bool _requireLogin = false;
  List<HistoryOrderItem> _orders = const [];
  DateTime _selectedDate = DateTime.now();
  _UnifiedFilter _filter = _UnifiedFilter.latest;
  bool _isInitialTabApplied = false;

  String get _apiBaseUrl => ApiConfig.apiBaseUrl;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInitialTabApplied) return;
    _isInitialTabApplied = true;

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is! Map) return;
    final tab = (args['tab'] ?? '').toString().toLowerCase();
    if (tab == 'payment') {
      _filter = _UnifiedFilter.pending;
    }
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _requireLogin = false;
    });

    final token = await AuthSession.getToken();
    if (token == null || token.isEmpty) {
      if (!mounted) return;
      setState(() {
        _orders = const [];
        _isLoading = false;
        _requireLogin = true;
      });
      return;
    }

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '$_apiBaseUrl/v1/orders/me',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      final map = response.data ?? const <String, dynamic>{};
      final rows = map['data'] as List<dynamic>? ?? const [];

      final orders = rows.map((row) {
        final item = row as Map<String, dynamic>;
        final orderId = (item['orderId'] ?? '').toString();
        final customer = item['customer'];
        final customerMap = customer is Map<String, dynamic>
            ? customer
            : const <String, dynamic>{};
        final customerName = _toText(customerMap['name']);
        final customerEmail = _toText(customerMap['email']);
        final status = (item['status'] ?? '-').toString();
        final paymentStatus = (item['paymentStatus'] ?? '-').toString();
        final paymentMethod = _toText(
          item['paymentMethod'] ?? item['method'] ?? item['paymentType'],
        );
        final paymentUrl = _toText(item['paymentUrl']);
        final midtransOrderId = _toText(item['midtransOrderId']);
        final paymentExpiry = _toText(item['paymentExpiry']);
        final qrisImageUrl = _toText(item['qrisImageUrl']);
        final vaNumber = _toText(
          item['vaNumber'] ??
              item['virtualAccountNumber'] ??
              item['nomorVa'] ??
              item['nomorVA'],
        );
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
          final name = (e['name'] ??
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

        final orderTypeKey = switch (orderTypeRaw) {
          'booking_dine_in' => 'booking',
          'dine_in' => 'dine_in',
          _ => 'pickup',
        };
        final bookingScheduleLabel = _formatBookingSchedule(
          bookingStartAtRaw: bookingStartAtRaw,
          durationHours: durationHours,
        );
        final orderTypeLabel = switch (orderTypeKey) {
          'booking' =>
            'Booking${tableNumber != null ? ' • Meja $tableNumber' : ''}${bookingScheduleLabel.isNotEmpty ? ' • $bookingScheduleLabel' : ''}',
          'dine_in' =>
            'Dine In Langsung${tableNumber != null ? ' • Meja $tableNumber' : ''}',
          _ => 'Takeaway/Pickup',
        };
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

      if (!mounted) return;
      setState(() {
        _orders = orders;
        _isLoading = false;
      });
    } on DioException catch (e) {
      if (!mounted) return;
      final message = _extractDioMessage(e);
      setState(() {
        _error = _isUnauthorizedMessage(message)
            ? 'Anda belum login. Silakan login terlebih dahulu untuk melihat riwayat.'
            : message;
        _requireLogin = _isUnauthorizedMessage(message);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      final message = AppNotice.humanizeMessage(e);
      setState(() {
        _error = _isUnauthorizedMessage(message)
            ? 'Anda belum login. Silakan login terlebih dahulu untuk melihat riwayat.'
            : message;
        _requireLogin = _isUnauthorizedMessage(message);
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      bottomNavigationBar: AppBottomNavBar(
        activeItem: AppBottomNavItem.history,
        onHomeTap: () => Navigator.pushNamed(context, AppRoutes.landing),
        onMenuTap: () => Navigator.pushNamed(context, AppRoutes.menu),
        onScanTap: () => Navigator.pushNamed(context, AppRoutes.scan),
        onHistoryTap: () {},
        onAccountTap: () => Navigator.pushNamed(context, AppRoutes.profile),
      ),
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        titleSpacing: 0,
        leading: const AppBackButton(color: _textDark),
        title: const Text(
          'Riwayat',
          style: TextStyle(
            color: _textDark,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: _buildBody(),
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
              Icon(
                _requireLogin ? Icons.lock_outline : Icons.error_outline,
                color: _requireLogin ? const Color(0xFF9C9C9C) : Colors.redAccent,
                size: 40,
              ),
              const SizedBox(height: 10),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              if (_requireLogin)
                ElevatedButton(
                  onPressed: () => Navigator.pushNamed(context, AppRoutes.login),
                  child: const Text('Login'),
                )
              else
                ElevatedButton(
                  onPressed: _loadOrders,
                  child: const Text('Coba lagi'),
                ),
            ],
          ),
        ),
      );
    }

    final filtered = _filteredOrders;
    if (filtered.isEmpty) {
      if (_requireLogin) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.lock_outline,
                  color: Color(0xFF9C9C9C),
                  size: 44,
                ),
                const SizedBox(height: 10),
                const Text(
                  'Anda belum login. Silakan login terlebih dahulu untuk melihat riwayat.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF666666),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => Navigator.pushNamed(context, AppRoutes.login),
                  child: const Text('Login'),
                ),
              ],
            ),
          ),
        );
      }
      return Column(
        children: [
          _buildDateFilter(),
          _buildSortDropdown(),
          const Expanded(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.receipt_long_outlined,
                      color: Color(0xFF9C9C9C),
                      size: 44,
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Belum ada riwayat pada tanggal ini',
                      style: TextStyle(
                        color: Color(0xFF666666),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
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
        _buildDateFilter(),
        _buildSortDropdown(),
        Expanded(
          child: PaymentHistoryList(
            orders: filtered,
            onRefreshRequested: _loadOrders,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildDateFilter() {
    final formattedDate = DateFormat('dd MMMM yyyy').format(_selectedDate);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: InkWell(
        onTap: _selectDate,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFCBD5E1)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.calendar_today_rounded, color: Color(0xFFD45A00), size: 18),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Filter Tanggal',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formattedDate,
                      style: const TextStyle(
                        color: Color(0xFF1E293B),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_drop_down_rounded, color: Color(0xFF64748B)),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFD45A00),
              onPrimary: Colors.white,
              onSurface: Color(0xFF2E2E2E),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  List<HistoryOrderItem> get _filteredOrders {
    final list = List<HistoryOrderItem>.from(_orders);
    
    // 1. Filter by Selected Date
    var filtered = list.where((order) {
      final d = order.eventAt;
      return d.year == _selectedDate.year &&
             d.month == _selectedDate.month &&
             d.day == _selectedDate.day;
    }).toList();

    // 2. Filter by dropdown option
    filtered = filtered.where((order) {
      switch (_filter) {
        case _UnifiedFilter.latest:
        case _UnifiedFilter.oldest:
          return true;
        case _UnifiedFilter.paid:
          return _isPaidStatus(order.paymentMethodLabel);
        case _UnifiedFilter.pending:
          return _isPendingStatus(order.paymentMethodLabel);
        case _UnifiedFilter.booking:
          return order.orderTypeKey == 'booking';
        case _UnifiedFilter.dineInDirect:
          return order.orderTypeKey == 'dine_in';
        case _UnifiedFilter.takeawayPickup:
          return order.orderTypeKey == 'pickup';
      }
    }).toList();

    // 3. Sort
    filtered.sort((a, b) {
      final ad = a.eventAt;
      final bd = b.eventAt;
      if (_filter == _UnifiedFilter.oldest) {
        return ad.compareTo(bd);
      }
      return bd.compareTo(ad); // default: newest first
    });

    return filtered;
  }

  Widget _buildSortDropdown() {
    final options = _sortLabels.entries.toList();
    final selected = _filter.name;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          const Text(
            'Filter & Sort:',
            style: TextStyle(
              color: Color(0xFF666666),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: AppDropdownField<String>(
              value: selected,
              menuMaxHeight: 280,
              dividerWidth: 2.2,
              borderRadius: 10,
              borderColor: const Color(0xFFE3E3E3),
              textStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF4B5563),
              ),
              options: options
                  .map((e) => AppDropdownOption<String>(value: e.key, label: e.value))
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _filter = _UnifiedFilter.values.firstWhere(
                    (e) => e.name == value,
                    orElse: () => _UnifiedFilter.latest,
                  );
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Map<String, String> get _sortLabels => const {
    'latest': 'Terbaru',
    'oldest': 'Terlama',
    'paid': 'Hanya Lunas',
    'pending': 'Hanya Belum Bayar',
    'booking': 'Hanya Booking Meja',
    'dineInDirect': 'Hanya Dine In',
    'takeawayPickup': 'Hanya Takeaway/Pickup',
  };

  bool _matchesAny(String raw, List<String> keys) {
    final value = raw.toLowerCase();
    for (final key in keys) {
      if (value.contains(key)) return true;
    }
    return false;
  }

  bool _isPaidStatus(String status) =>
      _matchesAny(status, const ['paid', 'success', 'settlement', 'lunas']);

  bool _isPendingStatus(String status) =>
      _matchesAny(status, const ['pending', 'unpaid', 'menunggu']);



  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  String _toText(dynamic value) {
    if (value == null) return '';
    final text = value.toString().trim();
    return text;
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
    return e.message ?? 'Gagal memuat riwayat pesanan';
  }

  bool _isUnauthorizedMessage(String message) {
    final raw = message.toLowerCase();
    return raw.contains('401') ||
        raw.contains('unauthorized') ||
        raw.contains('unauth') ||
        raw.contains('belum login');
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

  DateTime _resolvePaymentEventAt({
    required String paymentStatus,
    required String paidAtRaw,
    required String createdAtRaw,
  }) {
    final usePaidAt = _isPaidStatus(paymentStatus);
    final selectedRaw = usePaidAt
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
}

enum _UnifiedFilter {
  latest,
  oldest,
  paid,
  pending,
  booking,
  dineInDirect,
  takeawayPickup,
}
