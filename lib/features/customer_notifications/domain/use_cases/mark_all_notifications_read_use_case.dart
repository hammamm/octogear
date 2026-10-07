import '../repositories/customer_notifications_repository.dart';

class MarkAllNotificationsReadUseCase {
  const MarkAllNotificationsReadUseCase(this._repository);
  final CustomerNotificationsRepository _repository;

  Future<void> call() => _repository.markAllRead();
}
