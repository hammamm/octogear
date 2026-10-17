import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';

import '../../../../core/storage/app_storage.dart';
import '../../domain/entities/push_notification.dart';
import '../../domain/repositories/push_repository.dart';
import '../data_sources/push_remote_data_source.dart';
import '../models/push_notification_dto.dart';

class FirebasePushRepository implements PushRepository {
  FirebasePushRepository(this.messaging, this.remote, this.storage);
  final FirebaseMessaging messaging;
  final PushRemoteDataSource remote;
  final AppStorage storage;
  static const _platform = MethodChannel('com.octogear.app/notifications');

  Stream<PushNotification> _parse(Stream<RemoteMessage> stream) => stream
      .map((message) => parsePushNotification(message.data))
      .where((message) => message != null)
      .cast<PushNotification>();

  @override
  Stream<PushNotification> get foreground =>
      _parse(FirebaseMessaging.onMessage);
  @override
  Stream<PushNotification> get opened =>
      _parse(FirebaseMessaging.onMessageOpenedApp);
  @override
  Stream<String> get tokenChanges => messaging.onTokenRefresh;
  @override
  Future<PushNotification?> initialNotification() async {
    final message = await messaging.getInitialMessage();
    return message == null ? null : parsePushNotification(message.data);
  }

  @override
  Future<bool> permission({required bool request}) async {
    var settings = await messaging.getNotificationSettings();
    if (request && !storage.pushPermissionRequested) {
      await storage.markPushPermissionRequested();
      settings = await messaging.requestPermission();
    }
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  @override
  Future<String?> token() async {
    await messaging.setAutoInitEnabled(true);
    return messaging.getToken();
  }

  @override
  Future<void> register(String token, String locale) =>
      remote.register(token, locale);
  @override
  Future<void> unregister() => remote.unregister();
  @override
  Future<void> deleteToken() async {
    try {
      await _platform.invokeMethod<void>('clear');
    } catch (_) {
      // A platform notification tray failure must not skip token invalidation.
    }
    await messaging.setAutoInitEnabled(false);
    await messaging.deleteToken();
  }

  @override
  Future<void> openSettings() => _platform.invokeMethod<void>('settings');
}
