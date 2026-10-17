import '../repositories/notifications_repository.dart';

class MarkAllNotificationsReadUseCase {
  const MarkAllNotificationsReadUseCase(this._repository);
  final NotificationsRepository _repository;

  Future<void> call() => _repository.markAllRead();
}
