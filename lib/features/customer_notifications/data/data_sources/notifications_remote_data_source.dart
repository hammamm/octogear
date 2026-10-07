import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_failure.dart';
import '../models/notification_dto.dart';

class NotificationsRemoteDataSource {
  const NotificationsRemoteDataSource(this.api);
  final ApiClient api;

  Future<NotificationPageDto> page({
    required bool unreadOnly,
    String? cursor,
  }) async {
    final response = await api.get<NotificationPageDto>(
      'notifications/inbox',
      requiresAuthentication: true,
      queryParameters: {'unread': unreadOnly ? 1 : 0, 'cursor': ?cursor},
      decode: notificationPageFromJson,
    );
    if (response.data == null) throw const ApiFailure.unexpected();
    return response.data!;
  }

  Future<int> unreadCount() async {
    final response = await api.get<int>(
      'notifications/unread-count',
      requiresAuthentication: true,
      decode: (value) =>
          notificationCount(notificationMap(value)['unread_count']),
    );
    if (response.data == null) throw const ApiFailure.unexpected();
    return response.data!;
  }

  Future<void> markRead(String id) async {
    if (!isNotificationId(id)) throw const ApiFailure.unexpected();
    final response = await api.patch<bool>(
      'notifications/$id/read',
      requiresAuthentication: true,
      decode: (value) =>
          value is Map && value['id'] == id && value['is_read'] == true,
    );
    if (response.data != true) throw const ApiFailure.unexpected();
  }

  Future<void> markAllRead() async {
    final response = await api.patch<bool>(
      'notifications/read-all',
      requiresAuthentication: true,
      decode: (value) => value is String,
    );
    if (response.data != true) throw const ApiFailure.unexpected();
  }
}
