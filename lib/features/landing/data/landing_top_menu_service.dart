import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class LandingTopMenuItem {
  const LandingTopMenuItem({
    required this.id,
    required this.stock,
    required this.category,
    required this.name,
    required this.description,
    required this.imageUrl,
  });

  final String id;
  final int stock;
  final String category;
  final String name;
  final String description;
  final String imageUrl;
}

class LandingTopMenuService {
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

  Future<List<LandingTopMenuItem>> fetchTopMenusByCategory() async {
    final url = '$_apiBaseUrl/v1/menus/top-by-category';
    debugPrint('Fetching landing top menu from: $url');
    try {
      final response = await _dio.get<Map<String, dynamic>>(url);
      final jsonMap = response.data ?? const <String, dynamic>{};
      final data = (jsonMap['data'] as List<dynamic>? ?? const []);

      return data
          .map((row) => row as Map<String, dynamic>)
          .map((row) {
            final item = (row['item'] as Map<String, dynamic>? ?? const {});
            return LandingTopMenuItem(
              id: (item['_id'] ?? item['id'] ?? '').toString(),
              stock: _toInt(item['stock']),
              category: (row['category'] ?? '').toString(),
              name: (item['name'] ?? '').toString(),
              description: (item['description'] ?? '').toString(),
              imageUrl: _normalizeImageUrl(
                (item['image_url'] ?? '').toString(),
              ),
            );
          })
          .where((item) => item.name.isNotEmpty)
          .toList();
    } on DioException catch (e) {
      throw Exception(_extractDioMessage(e));
    } catch (e) {
      throw Exception('Gagal mengambil menu landing: $e');
    }
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

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}

final Dio _dio = Dio(
  BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 15),
    headers: const {'Accept': 'application/json'},
  ),
);
