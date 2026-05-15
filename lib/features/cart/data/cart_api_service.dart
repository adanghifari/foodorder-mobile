import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../auth/data/auth_session.dart';

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

class CartApiService {
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
        return CartItemDto(
          menuId: (item['menuId'] ?? '').toString(),
          name: (item['name'] ?? '').toString(),
          description: (item['description'] ?? '').toString(),
          price: _toInt(item['price']),
          quantity: _toInt(item['quantity']),
          subtotal: _toInt(item['subtotal']),
          imageUrl: (item['imageUrl'] ?? '').toString(),
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

  Future<String> checkout({required String orderType, int? tableNumber}) async {
    final token = await _requireToken();
    try {
      final payload = <String, dynamic>{'orderType': orderType};
      if (tableNumber != null) {
        payload['tableNumber'] = tableNumber;
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

  String _extractDioMessage(DioException e) {
    final statusCode = e.response?.statusCode;
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
}
