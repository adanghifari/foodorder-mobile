import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../auth/presentation/auth_session.dart';

class ProfileUserDto {
  const ProfileUserDto({
    required this.name,
    required this.username,
    required this.email,
    required this.phone,
    required this.role,
  });

  final String name;
  final String username;
  final String email;
  final String phone;
  final String role;
}

class ProfileApiService {
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

  Future<ProfileUserDto> fetchMe() async {
    final token = await AuthSession.getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Belum login. Silakan login terlebih dahulu.');
    }

    final response = await http.get(
      Uri.parse('$_apiBaseUrl/v1/auth/me'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_extractMessage(response.body));
    }

    final map = jsonDecode(response.body) as Map<String, dynamic>;
    final data = map['data'] as Map<String, dynamic>? ?? const {};

    return ProfileUserDto(
      name: (data['name'] ?? '-').toString(),
      username: (data['username'] ?? '-').toString(),
      email: (data['email'] ?? '-').toString(),
      phone: (data['no_telp'] ?? '-').toString(),
      role: (data['role'] ?? '-').toString(),
    );
  }

  String _extractMessage(String body) {
    try {
      final map = jsonDecode(body) as Map<String, dynamic>;
      return (map['message'] ?? 'Request failed').toString();
    } catch (_) {
      return 'Request failed';
    }
  }
}
