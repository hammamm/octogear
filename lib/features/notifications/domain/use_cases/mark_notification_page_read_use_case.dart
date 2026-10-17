import '../entities/app_notification.dart';
import '../repositories/notifications_repository.dart';

class MarkNotificationPageReadUseCase {
  const MarkNotificationPageReadUseCase(this._repository);
  final NotificationsRepository _repository;
  Future<NotificationReadReceipt> call(Set<String> ids) {
    if (ids.isEmpty || ids.length > 20) {
      throw ArgumentError.value(ids.length, 'ids');
    }
    return _repository.markPageRead(Set.unmodifiable(ids));
  }
}
