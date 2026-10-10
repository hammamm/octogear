import '../entities/push_notification.dart';

abstract interface class PushRepository {
  Stream<PushNotification> get foreground;
  Stream<PushNotification> get opened;
  Stream<String> get tokenChanges;
  Future<PushNotification?> initialNotification();
  Future<bool> permission({required bool request});
  Future<String?> token();
  Future<void> register(String token, String locale);
  Future<void> unregister();
  Future<void> deleteToken();
  Future<void> openSettings();
}
