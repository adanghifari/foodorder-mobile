import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

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
    return kIsWeb ? 'http://127.0.0.1:8000/api' : 'http://192.168.1.5:8000/api';
  }

  Future<ProfileUserDto> fetchMe() async {
    final token = await AuthSession.getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Belum login. Silakan login terlebih dahulu.');
    }

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '$_apiBaseUrl/v1/auth/me',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      final map = response.data ?? const <String, dynamic>{};
      final data = map['data'] as Map<String, dynamic>? ?? const {};

      return ProfileUserDto(
        name: (data['name'] ?? '-').toString(),
        username: (data['username'] ?? '-').toString(),
        email: (data['email'] ?? '-').toString(),
        phone: (data['no_telp'] ?? '-').toString(),
        role: (data['role'] ?? '-').toString(),
      );
    } on DioException catch (e) {
      throw Exception(_extractDioMessage(e));
    } catch (e) {
      throw Exception('Gagal mengambil profil: $e');
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
    headers: const {'Accept': 'application/json'},
  ),
);
