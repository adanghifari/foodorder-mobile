import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class AuthApiService {
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

  Future<void> register({
    required String name,
    required String username,
    required String email,
    required String phone,
    required String password,
  }) async {
    final uri = Uri.parse('$_apiBaseUrl/v1/auth/register');
    final response = await http.post(
      uri,
      headers: const {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'name': name,
        'username': username,
        'email': email,
        'no_telp': phone,
        'password': password,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_extractMessage(response.body));
    }
  }

  Future<String> login({
    required String username,
    required String password,
  }) async {
    final uri = Uri.parse('$_apiBaseUrl/v1/auth/login');
    final response = await http.post(
      uri,
      headers: const {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'username': username,
        'password': password,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_extractMessage(response.body));
    }

    final map = jsonDecode(response.body) as Map<String, dynamic>;
    final data = map['data'] as Map<String, dynamic>? ?? const {};
    final user = data['user'] as Map<String, dynamic>? ?? const {};
    final role = (user['role'] ?? '').toString().toUpperCase();

    if (role != 'CUSTOMER') {
      throw Exception('Akun ini bukan customer dan tidak bisa login di mobile.');
    }

    return (data['token'] ?? '').toString();
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
