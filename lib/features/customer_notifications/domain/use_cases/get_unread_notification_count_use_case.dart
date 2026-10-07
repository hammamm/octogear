import '../repositories/customer_notifications_repository.dart';

class GetUnreadNotificationCountUseCase {
  const GetUnreadNotificationCountUseCase(this._repository);
  final CustomerNotificationsRepository _repository;

  Future<int> call() => _repository.unreadCount();
}
