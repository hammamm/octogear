enum NotificationKind {
  offer,
  message,
  supportReply,
  orderPaid,
  orderCompleted,
  order,
  offerAccepted,
  storeApproved,
  storeRejected,
  unknown,
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.kind,
    required this.isRead,
    required this.createdAt,
    this.orderId,
    this.offerId,
    this.conversationId,
    this.requestId,
    this.orderType,
  });
  final String id;
  final NotificationKind kind;
  final bool isRead;
  final DateTime createdAt;
  final int? orderId, offerId, conversationId, requestId;
  final String? orderType;

  bool get canOpen => switch (kind) {
    NotificationKind.offer ||
    NotificationKind.offerAccepted => orderId != null && offerId != null,
    NotificationKind.message ||
    NotificationKind.supportReply => conversationId != null,
    NotificationKind.orderPaid ||
    NotificationKind.orderCompleted ||
    NotificationKind.order => orderId != null,
    NotificationKind.storeApproved ||
    NotificationKind.storeRejected => requestId != null,
    NotificationKind.unknown => false,
  };

  AppNotification read() => AppNotification(
    id: id,
    kind: kind,
    isRead: true,
    createdAt: createdAt,
    orderId: orderId,
    offerId: offerId,
    conversationId: conversationId,
    requestId: requestId,
    orderType: orderType,
  );
}

class NotificationPage {
  const NotificationPage({
    required this.items,
    required this.unreadCount,
    this.nextCursor,
  });
  final List<AppNotification> items;
  final int unreadCount;
  final String? nextCursor;
}

class NotificationReadReceipt {
  const NotificationReadReceipt({required this.ids, required this.unreadCount});
  final Set<String> ids;
  final int unreadCount;
}
