import '../../domain/entities/customer_notification.dart';
import '../../domain/entities/push_notification.dart';
import 'notification_dto.dart';

PushNotification? parsePushNotification(Map<String, dynamic> data) {
  int? id(String key) {
    final value = data[key];
    if (value is! String || !RegExp(r'^[1-9][0-9]*$').hasMatch(value)) {
      return null;
    }
    final parsed = int.tryParse(value);
    return parsed != null && parsed > 0 ? parsed : null;
  }

  final notificationId = data['notification_id'];
  final recipient = id('recipient_id');
  final kind = switch (data['type']) {
    'new_offer' => CustomerNotificationKind.offer,
    'new_message' => CustomerNotificationKind.message,
    _ => CustomerNotificationKind.unknown,
  };
  if (notificationId is! String ||
      !isNotificationId(notificationId) ||
      recipient == null ||
      kind == CustomerNotificationKind.unknown) {
    return null;
  }
  final item = CustomerNotification(
    id: notificationId,
    kind: kind,
    isRead: false,
    createdAt: DateTime.now(),
    orderId: id('order_id'),
    offerId: id('offer_id'),
    conversationId: id('conversation_id'),
  );
  return item.canOpen
      ? PushNotification(
          recipientId: recipient,
          item: item,
          messageId: id('message_id'),
        )
      : null;
}
