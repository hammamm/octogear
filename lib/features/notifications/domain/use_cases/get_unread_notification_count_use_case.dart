import '../repositories/notifications_repository.dart';

class GetUnreadNotificationCountUseCase {
  const GetUnreadNotificationCountUseCase(this._repository);
  final NotificationsRepository _repository;

  Future<int> call() => _repository.unreadCount();
}
