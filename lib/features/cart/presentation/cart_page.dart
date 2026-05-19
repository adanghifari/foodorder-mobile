import 'package:flutter/material.dart';

import '../../../app/app_routes.dart';
import '../../../shared/widgets/app_notice.dart';
import '../../landing/data/order_type_session.dart';
import '../../payment/presentation/midtrans_webview_page.dart';
import '../../scan/data/table_session.dart';
import '../../scan/presentation/scan_page.dart';
import '../data/cart_api_service.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  static const Color _lightBrownColor = Color(0xFFC7985F);
  static const Color _whiteColor = Color(0xFFFFFFFF);
  static const int _serviceFee = 5000;

  final CartApiService _cartApiService = CartApiService();
  final Set<String> _updatingMenuIds = <String>{};
  final List<int> _bookingStartHours = const [8, 10, 12, 14, 16, 18];
  final List<int> _bookingDurations = const [2, 4, 6, 8];
  final List<int> _fallbackTableNumbers = List<int>.generate(20, (i) => i + 1);
  static const String _mobileFinishRedirectUrl =
      'https://mobile.kedaiklik.app/payment-finish';

  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _error;
  OrderType? _orderType;
  List<CartItemDto> _items = const [];
  late DateTime _bookingDate;
  int? _selectedBookingHour;
  int? _selectedDurationHours;
  int? _selectedTableNumber;
  bool _isLoadingBookingAvailability = false;
  String? _bookingAvailabilityError;
  bool _isAvailabilityEndpointMissing = false;
  Set<int> _availableTables = <int>{};
  Map<int, Set<int>> _tableAvailabilityByHour = <int, Set<int>>{};
  Map<int, Set<int>> _tableUnavailabilityByHour = <int, Set<int>>{};
  List<int> _tableNumbers = const [];

  int get _subtotal => _items.fold(0, (sum, e) => sum + e.subtotal);
  int get _totalPayment => _subtotal + _serviceFee;

  @override
  void initState() {
    super.initState();
    _bookingDate = DateTime.now();
    _selectedBookingHour = null;
    _selectedDurationHours = null;
    _tableNumbers = _fallbackTableNumbers;
    _initPage();
  }

  Future<void> _initPage() async {
    _orderType = await OrderTypeSession.get();
    if (_orderType == OrderType.onSpotDineIn) {
      final scannedTableId = await TableSession.get();
      if (scannedTableId != null && scannedTableId > 0) {
        _selectedTableNumber = scannedTableId;
      }
    }
    await _loadCart();
  }

  @override
  void dispose() {
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
      AppNotice.show(context, '$e', type: AppNoticeType.error);
    } finally {
      if (mounted) {
        setState(() => _updatingMenuIds.remove(item.menuId));
      }
    }
  }

  String _buildBookingStartAt(int hour) {
    final localBookingStart = DateTime(
      _bookingDate.year,
      _bookingDate.month,
      _bookingDate.day,
      hour,
    );

    // Send UTC timestamp so backend timezone conversion stays deterministic.
    return localBookingStart.toUtc().toIso8601String();
  }

  Future<void> _reloadBookingAvailability() async {
    final bookingHour = _selectedBookingHour;
    final duration = _selectedDurationHours;
    if (bookingHour == null ||
        duration == null ||
        _orderType != OrderType.bookingDineIn) {
      setState(() {
        _availableTables = <int>{};
        _tableAvailabilityByHour = <int, Set<int>>{};
        _tableUnavailabilityByHour = <int, Set<int>>{};
        _bookingAvailabilityError = null;
        _isLoadingBookingAvailability = false;
        _selectedTableNumber = null;
      });
      return;
    }

    setState(() {
      _isLoadingBookingAvailability = true;
      _bookingAvailabilityError = null;
      _isAvailabilityEndpointMissing = false;
    });

    try {
      final result = await _cartApiService.getBookingAvailability(
        bookingStartAt: _buildBookingStartAt(bookingHour),
        durationHours: duration,
      );
      if (!mounted) return;

      final tableNumbers = <int>{}
        ..addAll(result.availableTables)
        ..addAll(result.unavailableTables);
      final tableAvailabilityByHour = <int, Set<int>>{
        bookingHour: result.availableTables.toSet(),
      };
      final tableUnavailabilityByHour = <int, Set<int>>{
        bookingHour: result.unavailableTables.toSet(),
      };

      final selectedTable = _selectedTableNumber;
      final finalTableNumbers = tableNumbers.isEmpty
          ? _fallbackTableNumbers
          : (tableNumbers.toList()..sort());
      final selectedAvailability = _resolveAvailableTablesForHour(
        bookingHour,
        finalTableNumbers,
        tableAvailabilityByHour,
        tableUnavailabilityByHour,
      );

      setState(() {
        _tableNumbers = finalTableNumbers;
        _tableAvailabilityByHour = tableAvailabilityByHour;
        _tableUnavailabilityByHour = tableUnavailabilityByHour;
        _availableTables = selectedAvailability;
        if (selectedTable != null &&
            !finalTableNumbers.contains(selectedTable)) {
          _selectedTableNumber = null;
        } else if (!_isAvailabilityEndpointMissing &&
            selectedTable != null &&
            !selectedAvailability.contains(selectedTable)) {
          _selectedTableNumber = null;
        }
        _isLoadingBookingAvailability = false;
      });
    } catch (e) {
      if (!mounted) return;
      final message = '$e';
      setState(() {
        _isLoadingBookingAvailability = false;
        _isAvailabilityEndpointMissing =
            message.contains('Endpoint ketersediaan booking belum tersedia di backend.');
        _bookingAvailabilityError =
            _isAvailabilityEndpointMissing ? null : message;
      });
    }
  }

  Future<void> _payNow() async {
    final orderType = _orderType;
    if (orderType == null) {
      AppNotice.show(
        context,
        'Pilih tipe pesanan terlebih dahulu.',
        type: AppNoticeType.error,
      );
      return;
    }

    int? tableNumber;
    String? bookingStartAt;
    int? durationHours;
    if (orderType == OrderType.bookingDineIn) {
      tableNumber = _selectedTableNumber;
      if (tableNumber == null || tableNumber < 1) {
        AppNotice.show(
          context,
          'Nomor meja wajib diisi dengan benar.',
          type: AppNoticeType.error,
        );
        return;
      }

      final bookingHour = _selectedBookingHour;
      final selectedDuration = _selectedDurationHours;
      if (bookingHour == null || selectedDuration == null) {
        AppNotice.show(
          context,
          'Waktu booking dan durasi wajib dipilih.',
          type: AppNoticeType.error,
        );
        return;
      }

      if (!_availableTables.contains(tableNumber)) {
        AppNotice.show(
          context,
          'Meja $tableNumber sedang dipakai di jam booking tersebut.',
          type: AppNoticeType.error,
        );
        return;
      }

      bookingStartAt = _buildBookingStartAt(bookingHour);
      durationHours = selectedDuration;
    } else if (orderType == OrderType.onSpotDineIn) {
      tableNumber = _selectedTableNumber;
      if (tableNumber == null || tableNumber < 1) {
        AppNotice.show(
          context,
          'Untuk dine-in, silakan scan QR meja terlebih dahulu.',
          type: AppNoticeType.error,
        );
        return;
      }
    }
    if (_items.isEmpty) {
      AppNotice.show(context, 'Keranjang masih kosong.', type: AppNoticeType.error);
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final orderId = await _cartApiService.checkout(
        orderType: OrderTypeSession.toApiValue(orderType),
        tableNumber: tableNumber,
        bookingStartAt: bookingStartAt,
        durationHours: durationHours,
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
      await TableSession.clear();
      await _loadCart();
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.landing,
        (route) => route.isFirst,
      );
    } catch (e) {
      if (!mounted) return;
      AppNotice.show(context, '$e', type: AppNoticeType.error);
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _onOrderTypeChanged(OrderType? value) async {
    if (value == null) return;
    setState(() {
      _orderType = value;
      if (value != OrderType.bookingDineIn) {
        _selectedTableNumber = null;
      } else {
        _selectedBookingHour = null;
        _selectedDurationHours = null;
        _selectedTableNumber = null;
        _availableTables = <int>{};
        _tableAvailabilityByHour = <int, Set<int>>{};
        _tableUnavailabilityByHour = <int, Set<int>>{};
        _bookingAvailabilityError = null;
        _isAvailabilityEndpointMissing = false;
      }
    });
    await OrderTypeSession.set(value);
    if (value == OrderType.onSpotDineIn) {
      final scannedTableId = await TableSession.get();
      if (!mounted) return;
      setState(() {
        _selectedTableNumber =
            (scannedTableId != null && scannedTableId > 0) ? scannedTableId : null;
      });
      return;
    }
    if (value == OrderType.pickup) {
      await TableSession.clear();
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
          if (_orderType == OrderType.onSpotDineIn ||
              _orderType == OrderType.bookingDineIn)
            Container(
              height: 52,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFE8E8E8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  Icon(
                    _orderType == OrderType.onSpotDineIn
                        ? Icons.qr_code_scanner
                        : Icons.restaurant,
                    size: 18,
                    color: const Color(0xFF9CA3AF),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _orderType == OrderType.onSpotDineIn
                          ? 'Dine-in'
                          : 'Booking meja',
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<OrderType>(
                  value: _orderType,
                  isExpanded: true,
                  itemHeight: 56,
                  menuMaxHeight: 220,
                  borderRadius: BorderRadius.circular(12),
                  icon: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: Color(0xFF6B7280),
                  ),
                  hint: const Text(
                    'Pilih tipe pesanan',
                    style: TextStyle(
                      color: Color(0xFF9CA3AF),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  style: const TextStyle(
                    color: Color(0xFF1F2937),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  selectedItemBuilder: (context) => const [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Booking meja'),
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Pesan & ambil'),
                    ),
                  ],
                  items: [
                    DropdownMenuItem<OrderType>(
                      value: OrderType.bookingDineIn,
                      child: Container(
                        height: 56,
                        alignment: Alignment.centerLeft,
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Color(0xFFD1D5DB),
                              width: 1.6,
                            ),
                          ),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.restaurant, size: 18, color: Color(0xFFC7985F)),
                            SizedBox(width: 10),
                            Text('Booking meja'),
                          ],
                        ),
                      ),
                    ),
                    const DropdownMenuItem<OrderType>(
                      value: OrderType.pickup,
                      child: Row(
                        children: [
                          Icon(Icons.storefront, size: 18, color: Color(0xFFC7985F)),
                          SizedBox(width: 10),
                          Text('Pesan & ambil'),
                        ],
                      ),
                    ),
                  ],
                  onChanged: (value) => _onOrderTypeChanged(value),
                ),
              ),
            ),
          if (_orderType == OrderType.bookingDineIn) ...[
            const SizedBox(height: 14),
            _buildLabel('Waktu Booking'),
            _buildDatePickerField(),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _buildHourDropdownField(),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDurationDropdownField(),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _buildLabel('Nomor Meja'),
            _buildTableDropdownField(),
            if (_isLoadingBookingAvailability) ...[
              const SizedBox(height: 8),
              const Text(
                'Memuat ketersediaan meja...',
                style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
              ),
            ],
            if (_bookingAvailabilityError != null) ...[
              const SizedBox(height: 8),
              Text(
                _bookingAvailabilityError!,
                style: const TextStyle(fontSize: 12, color: Colors.red),
              ),
            ],
            if (_isAvailabilityEndpointMissing) ...[
              const SizedBox(height: 8),
              const Text(
                'Sinkronisasi ketersediaan meja belum aktif di server yang terhubung.',
                style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
              ),
            ],
          ],
          if (_orderType == OrderType.onSpotDineIn) ...[
            const SizedBox(height: 14),
            _buildLabel('Nomor Meja (hasil scan QR)'),
            _buildOnSpotTableInfo(),
          ],
          const SizedBox(height: 30),
          const Text(
            'Detail Pembayaran',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 15),
          _buildPaymentRow('Subtotal', _subtotal),
          _buildPaymentRow('Biaya Layanan', _serviceFee),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(thickness: 1),
          ),
          _buildPaymentRow('Total Pembayaran', _totalPayment, isTotal: true),
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

  Widget _buildTableDropdownField() {
    final canSelectTable =
        _selectedBookingHour != null && _selectedDurationHours != null;

    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: canSelectTable ? Colors.white : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _selectedTableNumber,
          isExpanded: true,
          borderRadius: BorderRadius.circular(12),
          hint: Text(
            canSelectTable ? 'Pilih meja' : 'Pilih waktu booking dulu',
            style: const TextStyle(color: Color(0xFF6B7280)),
          ),
          items: _tableNumbers.map((tableNumber) {
            final available = _isAvailabilityEndpointMissing
                ? true
                : _availableTables.contains(tableNumber);
            return DropdownMenuItem<int>(
              value: tableNumber,
              enabled: available,
              child: Text(
                available ? 'Meja $tableNumber' : 'Meja $tableNumber (Dipakai)',
                style: TextStyle(
                  color: available ? const Color(0xFF1F2937) : Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }).toList(),
          onChanged: canSelectTable
              ? (value) {
            if (value == null) return;
            setState(() => _selectedTableNumber = value);
          }
              : null,
        ),
      ),
    );
  }

  Future<void> _openScanForTable() async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => const ScanPage(redirectToCart: true),
      ),
    );
    if (!mounted) return;
    final scannedTableId = await TableSession.get();
    final newOrderType = await OrderTypeSession.get();
    if (!mounted) return;
    setState(() {
      if (scannedTableId != null && scannedTableId > 0) {
        _selectedTableNumber = scannedTableId;
      }
      if (newOrderType != null) {
        _orderType = newOrderType;
      }
    });
  }

  Widget _buildOnSpotTableInfo() {
    final tableNumber = _selectedTableNumber;
    return Container(
      height: 52,
      width: double.infinity,
      padding: const EdgeInsets.only(left: 14, right: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              tableNumber == null
                  ? 'Belum ada meja. Scan QR meja dulu.'
                  : 'Meja $tableNumber',
              style: TextStyle(
                color: tableNumber == null
                    ? const Color(0xFF6B7280)
                    : const Color(0xFF1F2937),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (tableNumber == null)
            SizedBox(
              height: 40,
              width: 40,
              child: IconButton(
                onPressed: _openScanForTable,
                icon: const Icon(
                  Icons.qr_code_scanner,
                  size: 20,
                  color: Color(0xFFC7985F),
                ),
                tooltip: 'Scan QR Meja',
                padding: EdgeInsets.zero,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDatePickerField() {
    final displayDate =
        '${_bookingDate.day.toString().padLeft(2, '0')}/${_bookingDate.month.toString().padLeft(2, '0')}/${_bookingDate.year}';

    return InkWell(
      onTap: _pickBookingDate,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, size: 18, color: Color(0xFF6B7280)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                displayDate,
                style: const TextStyle(
                  color: Color(0xFF1F2937),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF6B7280)),
          ],
        ),
      ),
    );
  }

  Widget _buildHourDropdownField() {
    final hours = _getAvailableBookingHours();
    final selectedHour = _selectedBookingHour;
    final hasSelectedHour =
        selectedHour != null && hours.contains(selectedHour);

    return _buildDropdownField<int>(
      label: 'Jam',
      value: hasSelectedHour ? selectedHour : null,
      items: hours
          .map(
            (hour) => DropdownMenuItem<int>(
              value: hour,
              child: Text('${hour.toString().padLeft(2, '0')}:00'),
            ),
          )
          .toList(),
      onChanged: (value) {
        setState(() {
          _selectedBookingHour = value;
          final nextDurations = _getAvailableDurations(value);
          if (_selectedDurationHours != null &&
              !nextDurations.contains(_selectedDurationHours)) {
            _selectedDurationHours = null;
          }
          _selectedTableNumber = null;
          if (value == null) {
            _availableTables = <int>{};
            return;
          }
          final selectedAvailability = _resolveAvailableTablesForHour(
            value,
            _tableNumbers,
            _tableAvailabilityByHour,
            _tableUnavailabilityByHour,
          );
          _availableTables = selectedAvailability;
        });
        if (value == null) return;
        _reloadBookingAvailability();
      },
    );
  }

  Widget _buildDurationDropdownField() {
    final durations = _getAvailableDurations(_selectedBookingHour);
    final selectedDuration = _selectedDurationHours;
    final hasSelectedDuration =
        selectedDuration != null && durations.contains(selectedDuration);

    return _buildDropdownField<int>(
      label: 'Durasi',
      value: hasSelectedDuration ? selectedDuration : null,
      items: durations
          .map(
            (duration) => DropdownMenuItem<int>(
              value: duration,
              child: Text(
                duration >= 5
                    ? '$duration jam (Biaya Tambahan)'
                    : '$duration jam',
              ),
            ),
          )
          .toList(),
      onChanged: (value) {
        setState(() {
          _selectedDurationHours = value;
          _selectedTableNumber = null;
        });
        if (value == null) return;
        _reloadBookingAvailability();
      },
    );
  }

  Widget _buildDropdownField<T>({
    required String label,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          borderRadius: BorderRadius.circular(12),
          hint: Text(label),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }

  Set<int> _resolveAvailableTablesForHour(
    int hour,
    List<int> tableNumbers,
    Map<int, Set<int>> availableByHour,
    Map<int, Set<int>> unavailableByHour,
  ) {
    final available = availableByHour[hour] ?? <int>{};
    if (available.isNotEmpty) {
      return available;
    }

    final unavailable = unavailableByHour[hour] ?? <int>{};
    if (unavailable.isEmpty) {
      return <int>{};
    }

    return tableNumbers
        .where((tableNumber) => !unavailable.contains(tableNumber))
        .toSet();
  }

  List<int> _getAvailableBookingHours() {
    final now = DateTime.now();
    final isToday =
        _bookingDate.year == now.year &&
        _bookingDate.month == now.month &&
        _bookingDate.day == now.day;

    return _bookingStartHours.where((hour) {
      if (!isToday) return true;
      return hour > now.hour;
    }).toList();
  }

  List<int> _getAvailableDurations(int? bookingHour) {
    if (bookingHour == null) return const [];
    return _bookingDurations
        .where((duration) => bookingHour + duration <= 20)
        .toList();
  }

  Future<void> _pickBookingDate() async {
    final today = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _bookingDate,
      firstDate: DateTime(today.year, today.month, today.day),
      lastDate: DateTime(today.year + 1),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _bookingDate = DateTime(picked.year, picked.month, picked.day);
      final availableHours = _getAvailableBookingHours();
      if (_selectedBookingHour != null &&
          !availableHours.contains(_selectedBookingHour)) {
        _selectedBookingHour = null;
      }
      final availableDurations = _getAvailableDurations(_selectedBookingHour);
      if (_selectedDurationHours != null &&
          !availableDurations.contains(_selectedDurationHours)) {
        _selectedDurationHours = null;
      }
      _selectedTableNumber = null;
    });
    await _reloadBookingAvailability();
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
