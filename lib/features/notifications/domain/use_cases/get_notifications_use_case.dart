import '../entities/app_notification.dart';
import '../repositories/notifications_repository.dart';

class GetNotificationsUseCase {
  const GetNotificationsUseCase(this._repository);
  final NotificationsRepository _repository;

  Future<NotificationPage> call({required bool unreadOnly, String? cursor}) =>
      _repository.page(unreadOnly: unreadOnly, cursor: cursor);
}
