import '../entities/customer_notification.dart';
import '../repositories/customer_notifications_repository.dart';

class GetNotificationsUseCase {
  const GetNotificationsUseCase(this._repository);
  final CustomerNotificationsRepository _repository;

  Future<NotificationPage> call({required bool unreadOnly, String? cursor}) =>
      _repository.page(unreadOnly: unreadOnly, cursor: cursor);
}
