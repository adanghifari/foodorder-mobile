import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthSession {
  static const String _tokenKey = 'auth_token';
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static String? _token;

  static bool get isLoggedIn => _token != null && _token!.isNotEmpty;

  static Future<void> setToken(String token) async {
    _token = token;
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
    } else {
      await _storage.write(key: _tokenKey, value: token);
    }
  }

  static Future<String?> getToken() async {
    if (_token != null && _token!.isNotEmpty) {
      return _token;
    }

    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString(_tokenKey);
      return _token;
    } else {
      _token = await _storage.read(key: _tokenKey);
      return _token;
    }
  }

  static Future<void> clear() async {
    _token = null;
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
    } else {
      await _storage.delete(key: _tokenKey);
    }
  }
}
