import 'package:octogear/features/customer_notifications/domain/entities/customer_notification.dart';
import 'package:octogear/features/customer_notifications/domain/repositories/customer_notifications_repository.dart';

CustomerNotification notification(
  int id, {
  CustomerNotificationKind kind = CustomerNotificationKind.offer,
  bool read = false,
}) => CustomerNotification(
  id: '00000000-0000-0000-0000-${id.toString().padLeft(12, '0')}',
  kind: kind,
  isRead: read,
  createdAt: DateTime.now().subtract(Duration(minutes: id)),
  orderId: 17,
  offerId: 42,
  conversationId: 7,
);

class FakeNotificationsRepository implements CustomerNotificationsRepository {
  List<CustomerNotification> items = [
    notification(1),
    notification(2, kind: CustomerNotificationKind.message),
  ];
  int pageCalls = 0, countCalls = 0, readCalls = 0, allCalls = 0;
  bool failPage = false, failCount = false, failRead = false;
  Future<NotificationPage> Function(bool, String?)? onPage;
  Future<void> Function()? onRead;
  @override
  Future<NotificationPage> page({
    required bool unreadOnly,
    String? cursor,
  }) async {
    ++pageCalls;
    if (failPage) throw Exception('offline');
    if (onPage != null) return onPage!(unreadOnly, cursor);
    return NotificationPage(
      items: items.where((n) => !unreadOnly || !n.isRead).toList(),
      unreadCount: items.where((n) => !n.isRead).length,
    );
  }

  @override
  Future<int> unreadCount() async {
    ++countCalls;
    if (failCount) throw Exception('offline');
    return items.where((n) => !n.isRead).length;
  }

  @override
  Future<void> markRead(String id) async {
    ++readCalls;
    if (failRead) throw Exception('offline');
    await onRead?.call();
    items = [for (final n in items) n.id == id ? n.read() : n];
  }

  @override
  Future<void> markAllRead() async {
    ++allCalls;
    if (failRead) throw Exception('offline');
    await onRead?.call();
    items = items.map((n) => n.read()).toList();
  }
}
