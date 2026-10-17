import 'package:octogear/features/notifications/domain/entities/app_notification.dart';
import 'package:octogear/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:octogear/features/authentication/domain/entities/app_user.dart';
import 'package:octogear/features/authentication/domain/entities/session_outcome.dart';

const notificationSession = AuthenticatedSession(
  AppUser(
    id: 1,
    fullName: 'Customer',
    mobile: '+966500000001',
    role: AppUserRole.customer,
  ),
);
const providerNotificationSession = AuthenticatedSession(
  AppUser(
    id: 44,
    fullName: 'Provider',
    mobile: '+966500000044',
    role: AppUserRole.provider,
  ),
);

AppNotification notification(
  int id, {
  NotificationKind kind = NotificationKind.offer,
  bool read = false,
}) => AppNotification(
  id: '00000000-0000-0000-0000-${id.toString().padLeft(12, '0')}',
  kind: kind,
  isRead: read,
  createdAt: DateTime.now().subtract(Duration(minutes: id)),
  orderId: 17,
  offerId: 42,
  conversationId: 7,
);

class FakeNotificationsRepository implements NotificationsRepository {
  List<AppNotification> items = [
    notification(1),
    notification(2, kind: NotificationKind.message),
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

  final List<Set<String>> pageReads = [];
  Future<NotificationReadReceipt> Function(Set<String>)? onPageRead;
  @override
  Future<NotificationReadReceipt> markPageRead(Set<String> ids) async {
    pageReads.add(ids);
    if (failRead) throw Exception('offline');
    if (onPageRead != null) return onPageRead!(ids);
    items = [for (final n in items) ids.contains(n.id) ? n.read() : n];
    return NotificationReadReceipt(
      ids: ids,
      unreadCount: items.where((n) => !n.isRead).length,
    );
  }

  @override
  Future<void> markAllRead() async {
    ++allCalls;
    if (failRead) throw Exception('offline');
    await onRead?.call();
    items = items.map((n) => n.read()).toList();
  }
}
