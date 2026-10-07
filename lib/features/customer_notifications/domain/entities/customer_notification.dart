enum CustomerNotificationKind {
  offer,
  message,
  orderPaid,
  orderCompleted,
  order,
  unknown,
}

class CustomerNotification {
  const CustomerNotification({
    required this.id,
    required this.kind,
    required this.isRead,
    required this.createdAt,
    this.orderId,
    this.offerId,
    this.conversationId,
  });
  final String id;
  final CustomerNotificationKind kind;
  final bool isRead;
  final DateTime createdAt;
  final int? orderId, offerId, conversationId;

  bool get canOpen => switch (kind) {
    CustomerNotificationKind.offer => orderId != null && offerId != null,
    CustomerNotificationKind.message => conversationId != null,
    CustomerNotificationKind.orderPaid ||
    CustomerNotificationKind.orderCompleted ||
    CustomerNotificationKind.order => orderId != null,
    CustomerNotificationKind.unknown => false,
  };

  CustomerNotification read() => CustomerNotification(
    id: id,
    kind: kind,
    isRead: true,
    createdAt: createdAt,
    orderId: orderId,
    offerId: offerId,
    conversationId: conversationId,
  );
}

class NotificationPage {
  const NotificationPage({
    required this.items,
    required this.unreadCount,
    this.nextCursor,
  });
  final List<CustomerNotification> items;
  final int unreadCount;
  final String? nextCursor;
}
