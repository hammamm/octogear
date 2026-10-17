import '../entities/app_notification.dart';

abstract interface class NotificationsRepository {
  Future<NotificationPage> page({required bool unreadOnly, String? cursor});
  Future<int> unreadCount();
  Future<void> markRead(String id);
  Future<void> markAllRead();
  Future<NotificationReadReceipt> markPageRead(Set<String> ids);
}
