import 'package:dio/dio.dart';

import '../../auth/data/auth_session.dart';
import '../../../shared/config/api_config.dart';
import 'chatbot_models.dart';

class ChatbotApiService {
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

  String get _apiBaseUrl => ApiConfig.apiBaseUrl;

  Future<ChatbotResponse> sendMessage({
    required String message,
    String action = '',
  }) async {
    final envelope = await _postEnvelope(
      path: '/v1/chatbot/message',
      message: message,
      action: action,
    );
    return envelope.data;
  }

  Future<Map<String, dynamic>> sendMessageDebug({
    required String message,
    String action = '',
  }) async {
    final token = await _requireToken();
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '$_apiBaseUrl/v1/chatbot/message-debug',
        data: <String, dynamic>{'message': message, 'action': action},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      final payload = response.data ?? const <String, dynamic>{};
      if (_asString(payload['status']).toLowerCase() != 'success') {
        throw Exception(
          _asString(payload['message']).isEmpty
              ? 'Debug chatbot gagal'
              : _asString(payload['message']),
        );
      }

      return _asMap(payload['data']);
    } on DioException catch (e) {
      throw Exception(_extractDioMessage(e));
    } catch (e) {
      throw Exception('Gagal mengirim pesan debug chatbot: $e');
    }
  }

  Future<ChatbotEnvelope> _postEnvelope({
    required String path,
    required String message,
    required String action,
  }) async {
    final token = await _requireToken();
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '$_apiBaseUrl$path',
        data: <String, dynamic>{'message': message, 'action': action},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      final payload = response.data ?? const <String, dynamic>{};
      final status = _asString(payload['status']).toLowerCase();
      if (status != 'success') {
        final backendMessage = _asString(payload['message']);
        throw Exception(
          backendMessage.isEmpty ? 'Request chatbot gagal' : backendMessage,
        );
      }

      return ChatbotEnvelope.fromJson(payload);
    } on DioException catch (e) {
      throw Exception(_extractDioMessage(e));
    } catch (e) {
      throw Exception('Gagal mengirim pesan chatbot: $e');
    }
  }

  Future<String> _requireToken() async {
    final token = await AuthSession.getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Belum login.');
    }
    return token;
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

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, val) => MapEntry(key.toString(), val));
  }
  return const <String, dynamic>{};
}

String _asString(dynamic value) {
  if (value == null) return '';
  return value.toString();
}
