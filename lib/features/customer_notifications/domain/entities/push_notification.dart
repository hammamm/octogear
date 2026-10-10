import 'customer_notification.dart';

class PushNotification {
  const PushNotification({
    required this.recipientId,
    required this.item,
    this.messageId,
  });
  final int recipientId;
  final CustomerNotification item;
  final int? messageId;
}
