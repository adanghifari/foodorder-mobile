import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class LandingTopMenuItem {
  const LandingTopMenuItem({
    required this.category,
    required this.name,
    required this.description,
    required this.imageUrl,
  });

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
    return kIsWeb ? 'http://127.0.0.1:8000/api' : 'http://10.0.2.2:8000/api';
  }

  String get _serverBaseUrl {
    if (_apiBaseUrl.endsWith('/api')) {
      return _apiBaseUrl.substring(0, _apiBaseUrl.length - 4);
    }
    return _apiBaseUrl;
  }

  Future<List<LandingTopMenuItem>> fetchTopMenusByCategory() async {
    final uri = Uri.parse('$_apiBaseUrl/v1/menus/top-by-category');
    debugPrint('Fetching landing top menu from: $uri');

    final response = await http.get(
      uri,
      headers: const {'Accept': 'application/json'},
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('HTTP ${response.statusCode}: ${response.body}');
    }

    final jsonMap = jsonDecode(response.body) as Map<String, dynamic>;
    final data = (jsonMap['data'] as List<dynamic>? ?? const []);

    return data
        .map((row) => row as Map<String, dynamic>)
        .map((row) {
          final item = (row['item'] as Map<String, dynamic>? ?? const {});
          return LandingTopMenuItem(
            category: (row['category'] ?? '').toString(),
            name: (item['name'] ?? '').toString(),
            description: (item['description'] ?? '').toString(),
            imageUrl: _normalizeImageUrl((item['image_url'] ?? '').toString()),
          );
        })
        .where((item) => item.name.isNotEmpty)
        .toList();
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
}
