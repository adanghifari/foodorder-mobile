import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../app/app_routes.dart';
import '../../../shared/widgets/app_back_button.dart';
import '../../../shared/widgets/app_bottom_nav_bar.dart';
import '../../../shared/widgets/app_dropdown_field.dart';
import '../../auth/data/auth_session.dart';
import '../domain/history_models.dart';
import 'widgets/order_history_list.dart';
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
  _HistoryTab _activeTab = _HistoryTab.payment;
  _PaymentSortFilter _paymentFilter = _PaymentSortFilter.newest;
  _OrderSortFilter _orderFilter = _OrderSortFilter.latest;
  bool _showPreviousHistory = false;
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
    if (tab == 'order') {
      _activeTab = _HistoryTab.order;
    } else if (tab == 'payment') {
      _activeTab = _HistoryTab.payment;
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
      final message = '$e';
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

    final allFilteredOrders = _filteredOrdersByActiveTab;
    final todayOrders = _todayOrdersFrom(allFilteredOrders);
    final previousOrders = _previousOrdersFrom(allFilteredOrders);
    if (allFilteredOrders.isEmpty) {
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
          _buildCategoryTabs(),
          _buildSortDropdown(),
          _buildTodaySectionHeader(todayCount: 0),
          _buildPreviousHistoryToggle(previousCount: 0),
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
                      'Belum ada riwayat',
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
        _buildCategoryTabs(),
        _buildSortDropdown(),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(0, 0, 0, 12),
            children: [
              _buildTodaySectionHeader(todayCount: todayOrders.length),
              if (todayOrders.isEmpty)
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Text(
                    'Belum ada riwayat hari ini',
                    style: TextStyle(
                      color: Color(0xFF666666),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              else
                _buildHistorySectionList(orders: todayOrders),
              _buildPreviousHistoryToggle(previousCount: previousOrders.length),
              if (_showPreviousHistory && previousOrders.isNotEmpty)
                _buildHistorySectionList(orders: previousOrders),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHistorySectionList({required List<HistoryOrderItem> orders}) {
    if (_activeTab == _HistoryTab.payment) {
      return PaymentHistoryList(
        orders: orders,
        onRefreshRequested: _loadOrders,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
      );
    }
    return OrderHistoryList(
      orders: orders,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
    );
  }

  Widget _buildTodaySectionHeader({required int todayCount}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFEDEFF2),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFD8DEE6)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Riwayat Hari Ini',
              style: TextStyle(
                color: Color(0xFF334155),
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              '$todayCount data untuk hari ini',
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryTabs() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: const Color(0xFFE9E9E9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: _CategoryTabButton(
                label: 'Riwayat Pembayaran',
                isActive: _activeTab == _HistoryTab.payment,
                onTap: () {
                  setState(() => _activeTab = _HistoryTab.payment);
                },
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _CategoryTabButton(
                label: 'Riwayat Pesanan',
                isActive: _activeTab == _HistoryTab.order,
                onTap: () {
                  setState(() => _activeTab = _HistoryTab.order);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<HistoryOrderItem> get _filteredOrdersByActiveTab {
    final list = List<HistoryOrderItem>.from(_orders);
    if (_activeTab == _HistoryTab.payment) {
      final filtered = list.where((order) {
        switch (_paymentFilter) {
          case _PaymentSortFilter.newest:
          case _PaymentSortFilter.oldest:
            return true;
          case _PaymentSortFilter.paid:
            return _isPaidStatus(order.paymentMethodLabel);
          case _PaymentSortFilter.pending:
            return _isPendingStatus(order.paymentMethodLabel);
          case _PaymentSortFilter.failed:
            return _isFailedStatus(order.paymentMethodLabel);
        }
      }).toList();

      filtered.sort((a, b) {
        final ad = a.eventAt;
        final bd = b.eventAt;
        if (_paymentFilter == _PaymentSortFilter.oldest) {
          return ad.compareTo(bd);
        }
        return bd.compareTo(ad);
      });
      return filtered;
    }

    final filtered = list.where((order) {
      switch (_orderFilter) {
        case _OrderSortFilter.latest:
        case _OrderSortFilter.oldest:
          return true;
        case _OrderSortFilter.booking:
          return order.orderTypeKey == 'booking';
        case _OrderSortFilter.dineInDirect:
          return order.orderTypeKey == 'dine_in';
        case _OrderSortFilter.takeawayPickup:
          return order.orderTypeKey == 'pickup';
      }
    }).toList();

    filtered.sort((a, b) {
      final ad = a.eventAt;
      final bd = b.eventAt;
      if (_orderFilter == _OrderSortFilter.oldest) {
        return ad.compareTo(bd);
      }
      return bd.compareTo(ad);
    });
    return filtered;
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

  Widget _buildPreviousHistoryToggle({required int previousCount}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: InkWell(
        onTap: previousCount < 1
            ? null
            : () => setState(() => _showPreviousHistory = !_showPreviousHistory),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFEDEFF2),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFD8DEE6)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Riwayat Sebelumnya',
                      style: TextStyle(
                        color: Color(0xFF4B5563),
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      previousCount < 1
                          ? 'Tidak ada riwayat hari sebelumnya'
                          : '$previousCount data dari hari sebelumnya',
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (previousCount > 0)
                Icon(
                  _showPreviousHistory
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: const Color(0xFF64748B),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSortDropdown() {
    final isPayment = _activeTab == _HistoryTab.payment;
    final options = isPayment
        ? _paymentSortLabels.entries.toList()
        : _orderSortLabels.entries.toList();
    final selected = isPayment ? _paymentFilter.name : _orderFilter.name;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Row(
        children: [
          const Text(
            'Sort by:',
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
              menuMaxHeight: 240,
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
                  if (isPayment) {
                    _paymentFilter = _PaymentSortFilter.values.firstWhere(
                      (e) => e.name == value,
                      orElse: () => _PaymentSortFilter.newest,
                    );
                  } else {
                    _orderFilter = _OrderSortFilter.values.firstWhere(
                      (e) => e.name == value,
                      orElse: () => _OrderSortFilter.latest,
                    );
                  }
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Map<String, String> get _paymentSortLabels => const {
    'newest': 'Terbaru',
    'oldest': 'Terlama',
    'paid': 'Lunas',
    'pending': 'Menunggu',
    'failed': 'Gagal',
  };

  Map<String, String> get _orderSortLabels => const {
    'latest': 'Terbaru',
    'oldest': 'Terlama',
    'booking': 'Booking',
    'dineInDirect': 'Dine In Langsung',
    'takeawayPickup': 'Takeaway/Pickup',
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

  bool _isFailedStatus(String status) =>
      _matchesAny(status, const ['failed', 'expire', 'cancel', 'deny', 'gagal']);

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

class _CategoryTabButton extends StatelessWidget {
  const _CategoryTabButton({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: isActive
              ? Border.all(color: const Color(0xFFD45A00))
              : Border.all(color: Colors.transparent),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isActive ? const Color(0xFFD45A00) : const Color(0xFF666666),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

enum _HistoryTab { order, payment }

enum _PaymentSortFilter { newest, oldest, paid, pending, failed }

enum _OrderSortFilter {
  latest,
  oldest,
  booking,
  dineInDirect,
  takeawayPickup,
}
