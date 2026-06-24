import 'dart:io';

import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../app/app.dart';
import '../../app/app_routes.dart';
import '../../features/auth/data/auth_session.dart';
import '../../shared/config/api_config.dart';

final FlutterLocalNotificationsPlugin _localNotifications =
    FlutterLocalNotificationsPlugin();

const AndroidNotificationChannel _defaultAndroidChannel = AndroidNotificationChannel(
  'order_status_updates',
  'Pesanan & Pembayaran',
  description: 'Notifikasi status pesanan dan pembayaran',
  importance: Importance.high,
);

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService instance = PushNotificationService._();

  bool _initialized = false;
  Future<void>? _initFuture;

  Future<void> init() async {
    if (_initFuture != null) {
      return _initFuture!;
    }
    _initFuture = _initInternal();
    return _initFuture!;
  }

  Future<void> _initInternal() async {
    if (_initialized) return;
    _initialized = true;

    if (kIsWeb) return;
    if (!Platform.isAndroid && !Platform.isIOS) return;

    try {
      await Firebase.initializeApp();
    } catch (_) {
      // If Firebase config is not ready on device, keep app usable.
      _initialized = false;
      _initFuture = null;
      return;
    }
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    await _initLocalNotifications();
    await _requestPermissions();
    await _registerTokenIfLoggedIn();
    _listenTokenRefresh();
    _listenForegroundMessages();
    _listenNotificationTap();
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _navigateFromPayload(initialMessage.data['type']?.toString());
    }
  }

  Future<void> syncTokenForCurrentUser() async {
    await init();
    if (!_initialized) return;
    if (kIsWeb) return;
    if (!Platform.isAndroid && !Platform.isIOS) return;
    await _registerTokenIfLoggedIn();
  }

  Future<void> _initLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    await _localNotifications.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: (response) {
        _navigateFromPayload(response.payload);
      },
    );

    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(_defaultAndroidChannel);
  }

  Future<void> _requestPermissions() async {
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  void _listenForegroundMessages() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final title = message.notification?.title?.trim().isNotEmpty == true
          ? message.notification!.title!.trim()
          : 'Pembaruan KedaiKlik';
      final body = message.notification?.body?.trim().isNotEmpty == true
          ? message.notification!.body!.trim()
          : 'Ada pembaruan status pesanan.';

      _localNotifications.show(
        message.hashCode,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _defaultAndroidChannel.id,
            _defaultAndroidChannel.name,
            channelDescription: _defaultAndroidChannel.description,
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        payload: message.data['type']?.toString(),
      );
    });
  }

  void _listenNotificationTap() {
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _navigateFromPayload(message.data['type']?.toString());
    });
  }

  void _navigateFromPayload(String? payloadType) {
    final nav = appNavigatorKey.currentState;
    if (nav == null) return;

    if (payloadType == 'order_status' || payloadType == 'payment_status') {
      nav.pushNamed(AppRoutes.orderHistory);
    }
  }

  void _listenTokenRefresh() {
    FirebaseMessaging.instance.onTokenRefresh.listen((token) async {
      await _sendTokenToBackend(token);
    });
  }

  Future<void> _registerTokenIfLoggedIn() async {
    final authToken = await AuthSession.getToken();
    if (authToken == null || authToken.isEmpty) return;

    final token = await FirebaseMessaging.instance.getToken();
    if (token == null || token.trim().isEmpty) return;

    await _sendTokenToBackend(token.trim());
  }

  Future<void> _sendTokenToBackend(String fcmToken) async {
    final authToken = await AuthSession.getToken();
    if (authToken == null || authToken.isEmpty) return;

    final platform = Platform.isIOS ? 'ios' : 'android';

    try {
      await Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 15),
          headers: const {'Accept': 'application/json'},
        ),
      ).post<Map<String, dynamic>>(
        '${ApiConfig.apiBaseUrl}/v1/notifications/device-token',
        data: {
          'token': fcmToken,
          'platform': platform,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $authToken',
            'Content-Type': 'application/json',
          },
        ),
      );
    } catch (_) {
      // Silent fail: token sync can retry on next app start/token refresh.
    }
  }
}
