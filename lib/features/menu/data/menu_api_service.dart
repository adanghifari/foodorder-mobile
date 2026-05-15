import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class MenuItemDto {
  const MenuItemDto({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.stock,
    required this.categoryBackend,
    required this.imageUrl,
  });

  final String id;
  final String name;
  final String description;
  final int price;
  final int stock;
  final String categoryBackend;
  final String imageUrl;

  String get categoryUi {
    final c = categoryBackend.toLowerCase();
    if (c == 'makanan utama') return 'Makanan utama';
    if (c == 'cemilan') return 'Cemilan';
    if (c == 'minuman') return 'Minuman';
    return 'Lainnya';
  }
}

class MenuApiService {
  static const String _apiBaseUrlFromEnv = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  String get _apiBaseUrl {
    if (_apiBaseUrlFromEnv.isNotEmpty) {
      return _apiBaseUrlFromEnv;
    }
    return kIsWeb ? 'http://127.0.0.1:8000/api' : 'http://192.168.1.5:8000/api';
  }

  String get _serverBaseUrl {
    if (_apiBaseUrl.endsWith('/api')) {
      return _apiBaseUrl.substring(0, _apiBaseUrl.length - 4);
    }
    return _apiBaseUrl;
  }

  Future<List<MenuItemDto>> fetchMenus({int perPage = 100}) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '$_apiBaseUrl/v1/menus',
        queryParameters: {'per_page': perPage},
      );
      final jsonMap = response.data ?? const <String, dynamic>{};
      final data = jsonMap['data'] as Map<String, dynamic>? ?? const {};
      final rows = data['data'] as List<dynamic>? ?? const [];

      return rows.map((row) {
        final map = row as Map<String, dynamic>;
        return MenuItemDto(
          id: (map['_id'] ?? map['id'] ?? '').toString(),
          name: (map['name'] ?? '').toString(),
          description: (map['description'] ?? '').toString(),
          price: _toInt(map['price']),
          stock: _toInt(map['stock']),
          categoryBackend: (map['category'] ?? '').toString(),
          imageUrl: _normalizeImageUrl((map['image_url'] ?? '').toString()),
        );
      }).toList();
    } on DioException catch (e) {
      throw Exception(_extractDioMessage(e));
    } catch (e) {
      throw Exception('Gagal mengambil menu: $e');
    }
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  String _normalizeImageUrl(String raw) {
    if (raw.isEmpty) {
      return '';
    }
    if (raw.startsWith('http://') || raw.startsWith('https://')) {
      return raw;
    }
    if (raw.startsWith('/storage/menu/')) {
      final filename = raw.split('/').last;
      return '$_apiBaseUrl/v1/menus/image/$filename';
    }
    if (raw.startsWith('/')) {
      return '$_serverBaseUrl$raw';
    }
    return '$_serverBaseUrl/$raw';
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

final Dio _dio = Dio(
  BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 15),
    headers: const {'Accept': 'application/json'},
  ),
);
