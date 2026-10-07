import '../../domain/entities/customer_notification.dart';
import '../../domain/repositories/customer_notifications_repository.dart';
import '../data_sources/notifications_remote_data_source.dart';

class CustomerNotificationsRepositoryImpl
    implements CustomerNotificationsRepository {
  const CustomerNotificationsRepositoryImpl(this._remote);
  final NotificationsRemoteDataSource _remote;
  @override
  Future<NotificationPage> page({
    required bool unreadOnly,
    String? cursor,
  }) async =>
      (await _remote.page(unreadOnly: unreadOnly, cursor: cursor)).toEntity();
  @override
  Future<int> unreadCount() => _remote.unreadCount();
  @override
  Future<void> markRead(String id) => _remote.markRead(id);
  @override
  Future<void> markAllRead() => _remote.markAllRead();
}
