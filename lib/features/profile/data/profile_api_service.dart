import 'package:dio/dio.dart';

import '../../auth/data/auth_session.dart';
import '../../../shared/config/api_config.dart';

class ProfileUserDto {
  const ProfileUserDto({
    required this.name,
    required this.username,
    required this.email,
    required this.phone,
    required this.role,
    this.avatarUrl,
  });

  final String name;
  final String username;
  final String email;
  final String phone;
  final String role;
  final String? avatarUrl;
}

class ProfileApiService {
  String get _apiBaseUrl => ApiConfig.apiBaseUrl;

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

      final avatarVal = data['avatar_url'] ?? data['photo'] ?? data['profile_picture'];

      return ProfileUserDto(
        name: (data['name'] ?? '-').toString(),
        username: (data['username'] ?? '-').toString(),
        email: (data['email'] ?? '-').toString(),
        phone: (data['no_telp'] ?? '-').toString(),
        role: (data['role'] ?? '-').toString(),
        avatarUrl: (avatarVal == null || avatarVal.toString() == 'null') ? null : avatarVal.toString(),
      );
    } on DioException catch (e) {
      throw Exception(_extractDioMessage(e));
    } catch (e) {
      throw Exception('Gagal mengambil profil: $e');
    }
  }

  Future<ProfileUserDto> updateProfile({
    required String name,
    required String username,
    required String email,
    required String phone,
    String? avatarUrl,
  }) async {
    final token = await AuthSession.getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Belum login. Silakan login terlebih dahulu.');
    }

    try {
      final response = await _dio.put<Map<String, dynamic>>(
        '$_apiBaseUrl/v1/auth/update',
        data: {
          'name': name,
          'username': username,
          'email': email,
          'no_telp': phone,
          'avatar_url': avatarUrl,
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      final map = response.data ?? const <String, dynamic>{};
      final data = map['data'] as Map<String, dynamic>? ?? const {};

      final avatarVal = data['avatar_url'] ?? data['photo'] ?? data['profile_picture'];

      return ProfileUserDto(
        name: (data['name'] ?? '-').toString(),
        username: (data['username'] ?? '-').toString(),
        email: (data['email'] ?? '-').toString(),
        phone: (data['no_telp'] ?? '-').toString(),
        role: (data['role'] ?? '-').toString(),
        avatarUrl: (avatarVal == null || avatarVal.toString() == 'null') ? null : avatarVal.toString(),
      );
    } on DioException catch (e) {
      throw Exception(_extractDioMessage(e));
    } catch (e) {
      throw Exception('Gagal memperbarui profil: $e');
    }
  }

  Future<ProfileUserDto> uploadAvatar(String filePath) async {
    final token = await AuthSession.getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Belum login. Silakan login terlebih dahulu.');
    }

    try {
      final fileName = filePath.split('/').last;
      final formData = FormData.fromMap({
        'avatar': await MultipartFile.fromFile(filePath, filename: fileName),
      });

      final response = await _dio.post<Map<String, dynamic>>(
        '$_apiBaseUrl/v1/auth/upload-avatar',
        data: formData,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      final map = response.data ?? const <String, dynamic>{};
      final data = map['data'] as Map<String, dynamic>? ?? const {};
      final avatarVal = data['avatar_url'] ?? data['photo'] ?? data['profile_picture'];

      return ProfileUserDto(
        name: (data['name'] ?? '-').toString(),
        username: (data['username'] ?? '-').toString(),
        email: (data['email'] ?? '-').toString(),
        phone: (data['no_telp'] ?? '-').toString(),
        role: (data['role'] ?? '-').toString(),
        avatarUrl: (avatarVal == null || avatarVal.toString() == 'null') ? null : avatarVal.toString(),
      );
    } on DioException catch (e) {
      throw Exception(_extractDioMessage(e));
    } catch (e) {
      throw Exception('Gagal mengunggah foto profil: $e');
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String newPasswordConfirmation,
  }) async {
    final token = await AuthSession.getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Belum login. Silakan login terlebih dahulu.');
    }

    try {
      await _dio.put<Map<String, dynamic>>(
        '$_apiBaseUrl/v1/auth/change-password',
        data: {
          'current_password': currentPassword,
          'new_password': newPassword,
          'new_password_confirmation': newPasswordConfirmation,
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
    } on DioException catch (e) {
      throw Exception(_extractDioMessage(e));
    } catch (e) {
      throw Exception('Gagal mengubah password: $e');
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
