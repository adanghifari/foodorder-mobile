import 'package:dio/dio.dart';

import '../../auth/data/auth_session.dart';
import '../../../shared/config/api_config.dart';
import '../../history/domain/history_models.dart';
import '../../../shared/utils/status_localizer.dart';
import '../../../shared/utils/indonesian_date_formatter.dart';

class CartItemDto {
  const CartItemDto({
    required this.menuId,
    required this.name,
    required this.description,
    required this.price,
    required this.quantity,
    required this.subtotal,
    required this.imageUrl,
  });

  final String menuId;
  final String name;
  final String description;
  final int price;
  final int quantity;
  final int subtotal;
  final String imageUrl;
}

class BookingAvailabilityDto {
  const BookingAvailabilityDto({
    required this.bookingStartAt,
    required this.bookingEndAt,
    required this.durationHours,
    required this.extraCharge,
    required this.availableTables,
    required this.unavailableTables,
  });

  final String bookingStartAt;
  final String bookingEndAt;
  final int durationHours;
  final int extraCharge;
  final List<int> availableTables;
  final List<int> unavailableTables;
}

class OnSpotTableAdvisoryDto {
  const OnSpotTableAdvisoryDto({
    required this.hasAdvisory,
    required this.level,
    required this.message,
    required this.nextBookingStartAt,
    required this.blockedStartAt,
    required this.availableDurationLabel,
    required this.minutesUntilBlocked,
  });

  final bool hasAdvisory;
  final String level;
  final String message;
  final String nextBookingStartAt;
  final String blockedStartAt;
  final String availableDurationLabel;
  final int minutesUntilBlocked;
}

class CartApiService {
  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 60),
      headers: const {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ),
  );

  String get _apiBaseUrl => ApiConfig.apiBaseUrl;

  String get _assetBaseUrl {
    return ApiConfig.serverBaseUrl;
  }

  Future<List<CartItemDto>> getCartItems() async {
    final token = await _requireToken();
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '$_apiBaseUrl/v1/cart',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      final map = response.data ?? const <String, dynamic>{};
      final rows = map['data'] as List<dynamic>? ?? const [];
      return rows.map((row) {
        final item = row as Map<String, dynamic>;
        final rawImage =
            (item['imageUrl'] ??
                    item['image_url'] ??
                    item['image'] ??
                    item['photo'] ??
                    '')
                .toString();
        return CartItemDto(
          menuId: (item['menuId'] ?? '').toString(),
          name: (item['name'] ?? '').toString(),
          description: (item['description'] ?? '').toString(),
          price: _toInt(item['price']),
          quantity: _toInt(item['quantity']),
          subtotal: _toInt(item['subtotal']),
          imageUrl: _normalizeImageUrl(rawImage),
        );
      }).toList();
    } on DioException catch (e) {
      throw Exception(_extractDioMessage(e));
    }
  }

  Future<void> setItemQuantity({
    required String menuItemId,
    required int quantity,
  }) async {
    final token = await _requireToken();
    try {
      await _dio.post<Map<String, dynamic>>(
        '$_apiBaseUrl/v1/cart',
        data: {'menuItemId': menuItemId, 'quantity': quantity},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
    } on DioException catch (e) {
      throw Exception(_extractDioMessage(e));
    }
  }

  Future<void> removeItem({required String menuItemId}) async {
    final token = await _requireToken();
    try {
      await _dio.delete<Map<String, dynamic>>(
        '$_apiBaseUrl/v1/cart',
        data: {'menuItemId': menuItemId},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
    } on DioException catch (e) {
      throw Exception(_extractDioMessage(e));
    }
  }

  Future<String> checkout({
    required String orderType,
    int? tableNumber,
    String? bookingStartAt,
    int? durationHours,
    String? firstCustomerName,
  }) async {
    final token = await _requireToken();
    try {
      final payload = <String, dynamic>{'orderType': orderType};
      if (tableNumber != null) {
        payload['tableNumber'] = tableNumber;
      }
      if (bookingStartAt != null && bookingStartAt.isNotEmpty) {
        payload['bookingStartAt'] = bookingStartAt;
      }
      if (durationHours != null) {
        payload['durationHours'] = durationHours;
      }
      if (firstCustomerName != null && firstCustomerName.trim().isNotEmpty) {
        payload['firstCustomerName'] = firstCustomerName.trim();
      }
      final response = await _dio.post<Map<String, dynamic>>(
        '$_apiBaseUrl/v1/cart/checkout',
        data: payload,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      final map = response.data ?? const <String, dynamic>{};
      final data = map['data'] as Map<String, dynamic>? ?? const {};
      return (data['orderId'] ?? '').toString();
    } on DioException catch (e) {
      throw Exception(_extractDioMessage(e));
    }
  }

  Future<String?> createPayment({
    required String orderId,
    String? finishRedirectUrl,
  }) async {
    final token = await _requireToken();
    try {
      final payload = <String, dynamic>{'order_id': orderId};
      if (finishRedirectUrl != null && finishRedirectUrl.isNotEmpty) {
        payload['finish_redirect_url'] = finishRedirectUrl;
      }
      final response = await _dio.post<Map<String, dynamic>>(
        '$_apiBaseUrl/v1/payments/create',
        data: payload,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      final map = response.data ?? const <String, dynamic>{};
      final data = map['data'] as Map<String, dynamic>? ?? const {};
      return data['redirect_url']?.toString();
    } on DioException catch (e) {
      throw Exception(_extractDioMessage(e));
    }
  }

  /// Sync status pembayaran dari Midtrans ke DB (dipanggil setelah webview selesai).
  Future<void> checkStatus({required String orderId}) async {
    final token = await _requireToken();
    try {
      await _dio.post<Map<String, dynamic>>(
        '$_apiBaseUrl/v1/payments/check-status/$orderId',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
    } on DioException catch (_) {
      // Best-effort — abaikan error, list tetap refresh
    }
  }

  Future<BookingAvailabilityDto> getBookingAvailability({
    required String bookingStartAt,
    required int durationHours,
  }) async {
    final token = await _requireToken();
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '$_apiBaseUrl/v1/bookings/availability',
        queryParameters: {
          'bookingStartAt': bookingStartAt,
          'durationHours': durationHours,
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      final map = response.data ?? const <String, dynamic>{};
      final data = map['data'] as Map<String, dynamic>? ?? const {};
      return BookingAvailabilityDto(
        bookingStartAt: (data['bookingStartAt'] ?? '').toString(),
        bookingEndAt: (data['bookingEndAt'] ?? '').toString(),
        durationHours: _toInt(data['durationHours']),
        extraCharge: _toInt(data['extraCharge']),
        availableTables: _toIntList(data['availableTables']),
        unavailableTables: _toIntList(data['unavailableTables']),
      );
    } on DioException catch (e) {
      throw Exception(_extractDioMessage(e));
    }
  }

  Future<OnSpotTableAdvisoryDto> getOnSpotTableAdvisory({
    required int tableNumber,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '$_apiBaseUrl/v1/tables/$tableNumber/onspot-advisory',
      );
      final map = response.data ?? const <String, dynamic>{};
      final data = map['data'] as Map<String, dynamic>? ?? const {};
      return OnSpotTableAdvisoryDto(
        hasAdvisory: data['hasAdvisory'] == true,
        level: (data['level'] ?? 'none').toString(),
        message: (data['message'] ?? '').toString(),
        nextBookingStartAt: (data['nextBookingStartAt'] ?? '').toString(),
        blockedStartAt: (data['blockedStartAt'] ?? '').toString(),
        availableDurationLabel: (data['availableDurationLabel'] ?? '')
            .toString(),
        minutesUntilBlocked: _toInt(data['minutesUntilBlocked']),
      );
    } on DioException catch (e) {
      throw Exception(_extractDioMessage(e));
    }
  }

  Future<String> _requireToken() async {
    final token = await AuthSession.getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Belum login.');
    }
    return token;
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  List<int> _toIntList(dynamic value) {
    if (value is! List) return const [];
    return value
        .map((item) {
          if (item is Map<String, dynamic>) {
            return _toInt(
              item['tableNumber'] ??
                  item['table_number'] ??
                  item['tableId'] ??
                  item['table_id'] ??
                  item['id'] ??
                  item['number'],
            );
          }
          return _toInt(item);
        })
        .where((item) => item > 0)
        .toSet()
        .toList()
      ..sort();
  }

  String _extractDioMessage(DioException e) {
    final statusCode = e.response?.statusCode;
    if (statusCode == 404) {
      return 'Endpoint ketersediaan booking belum tersedia di backend.';
    }
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      final message = data['message']?.toString();
      if (message != null && message.isNotEmpty) {
        return statusCode == null ? message : 'HTTP $statusCode: $message';
      }
    }
    if (statusCode != null) {
      return 'HTTP $statusCode: ${e.message ?? 'Request gagal'}';
    }
    return e.message ?? 'Tidak bisa terhubung ke server';
  }

  String _normalizeImageUrl(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return '';
    final uri = Uri.tryParse(value);
    if (uri != null && uri.hasScheme) return value;

    final normalized = value.startsWith('/') ? value : '/$value';
    return '$_assetBaseUrl$normalized';
  }

  Future<HistoryOrderItem?> getOrderReceipt(String orderId) async {
    final token = await _requireToken();
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '$_apiBaseUrl/v1/orders/me',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      final map = response.data ?? const <String, dynamic>{};
      final rows = map['data'] as List<dynamic>? ?? const [];

      for (final row in rows) {
        final item = row as Map<String, dynamic>;
        final curOrderId = (item['orderId'] ?? '').toString();
        if (curOrderId != orderId) continue;

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
          orderId: curOrderId,
          orderCode: curOrderId.isEmpty
              ? '-'
              : 'ORD-${curOrderId.substring(curOrderId.length > 6 ? curOrderId.length - 6 : 0).toUpperCase()}',
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
      }
      return null;
    } on DioException catch (e) {
      throw Exception(_extractDioMessage(e));
    }
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
}
