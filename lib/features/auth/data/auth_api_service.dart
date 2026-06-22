import 'package:dio/dio.dart';
import '../../../shared/config/api_config.dart';

class AuthApiService {
  String get _apiBaseUrl => ApiConfig.apiBaseUrl;

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

  Future<void> requestOtp(String email) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        '$_apiBaseUrl/v1/auth/forgot-password',
        data: {'email': email},
      );
    } on DioException catch (e) {
      throw Exception(_extractDioMessage(e));
    } catch (e) {
      throw Exception('Gagal mengirim OTP: $e');
    }
  }

  Future<String> verifyOtp(String email, String otp) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '$_apiBaseUrl/v1/auth/verify-otp',
        data: {'email': email, 'otp': otp},
      );
      final map = response.data ?? const <String, dynamic>{};
      final data = map['data'] as Map<String, dynamic>? ?? const {};
      return (data['token'] ?? '').toString();
    } on DioException catch (e) {
      throw Exception(_extractDioMessage(e));
    } catch (e) {
      throw Exception('Verifikasi OTP gagal: $e');
    }
  }

  Future<void> resetPassword({
    required String email,
    required String token,
    required String password,
  }) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        '$_apiBaseUrl/v1/auth/reset-password',
        data: {
          'email': email,
          'token': token,
          'password': password,
          'password_confirmation': password,
        },
      );
    } on DioException catch (e) {
      throw Exception(_extractDioMessage(e));
    } catch (e) {
      throw Exception('Gagal mengubah password: $e');
    }
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
