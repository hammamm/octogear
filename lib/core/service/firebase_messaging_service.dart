import 'dart:async';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:sahala/core/service/app_logger.dart';

class FirebaseMessagingService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  StreamSubscription<String>? _tokenRefreshSubscription;
  Future<void> initialize() async {
    // Android 13+ also requires runtime notification permission. The Firebase
    // plugin handles this safely on older Android versions.
    if (Platform.isIOS || Platform.isAndroid) {
      await _requestPermission();
    }

    final token = await _messaging.getToken();

    await AppLogger.log(
      'FCM token ${token == null ? 'was not available' : 'was retrieved'}',
      category: 'PUSH',
    );
    _listenToTokenRefresh();
  }

  Future<void> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    await AppLogger.log(
      'Notification permission: '
      '${settings.authorizationStatus}',
      category: 'PUSH',
    );
  }

  void _listenToTokenRefresh() {
    _tokenRefreshSubscription?.cancel();

    _tokenRefreshSubscription = _messaging.onTokenRefresh.listen((newToken) {
      AppLogger.log('FCM token refreshed', category: 'PUSH');
    });
  }

  Future<String?> getToken() async {
    return await _messaging.getToken();
  }

  Future<void> dispose() async {
    await _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = null;
  }
}
