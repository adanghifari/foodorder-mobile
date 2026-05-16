class ApiConfig {
  // Default API production (Railway). This makes `flutter run` work without
  // passing --dart-define on every run.
  static const String _defaultApiBaseUrl = 'https://kedaiklik.up.railway.app/api';

  static const String _apiBaseUrlFromEnv = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static String get apiBaseUrl {
    final fromEnv = _apiBaseUrlFromEnv.trim();
    if (fromEnv.isNotEmpty) {
      return _normalize(fromEnv);
    }

    return _defaultApiBaseUrl;
  }

  static String get serverBaseUrl {
    final base = apiBaseUrl;
    if (base.endsWith('/api')) {
      return base.substring(0, base.length - 4);
    }
    return base;
  }

  static String _normalize(String url) {
    if (url.endsWith('/')) {
      return url.substring(0, url.length - 1);
    }
    return url;
  }
}
