import '../entities/customer_notification.dart';

abstract interface class CustomerNotificationsRepository {
  Future<NotificationPage> page({required bool unreadOnly, String? cursor});
  Future<int> unreadCount();
  Future<void> markRead(String id);
  Future<void> markAllRead();
}
