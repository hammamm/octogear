import '../repositories/customer_notifications_repository.dart';

class MarkNotificationReadUseCase {
  const MarkNotificationReadUseCase(this._repository);
  final CustomerNotificationsRepository _repository;

  Future<void> call(String id) => _repository.markRead(id);
}
