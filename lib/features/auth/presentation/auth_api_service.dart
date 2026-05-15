import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class AuthApiService {
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

  Future<void> register({
    required String name,
    required String username,
    required String email,
    required String phone,
    required String password,
  }) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        '$_apiBaseUrl/v1/auth/register',
        data: {
          'name': name,
          'username': username,
          'email': email,
          'no_telp': phone,
          'password': password,
        },
      );
    } on DioException catch (e) {
      throw Exception(_extractDioMessage(e));
    } catch (e) {
      throw Exception('Register gagal: $e');
    }
  }

  Future<String> login({
    required String username,
    required String password,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '$_apiBaseUrl/v1/auth/login',
        data: {'username': username, 'password': password},
      );
      final map = response.data ?? const <String, dynamic>{};
      final data = map['data'] as Map<String, dynamic>? ?? const {};
      final user = data['user'] as Map<String, dynamic>? ?? const {};
      final role = (user['role'] ?? '').toString().toUpperCase();

      if (role != 'CUSTOMER') {
        throw Exception(
          'Akun ini bukan customer dan tidak bisa login di mobile.',
        );
      }

      return (data['token'] ?? '').toString();
    } on DioException catch (e) {
      throw Exception(_extractDioMessage(e));
    } catch (e) {
      throw Exception('Login gagal: $e');
    }
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
    headers: const {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    },
  ),
);
