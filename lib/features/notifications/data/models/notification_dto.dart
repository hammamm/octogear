import '../../domain/entities/app_notification.dart';

bool isNotificationId(String value) => RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
).hasMatch(value);

Map notificationMap(Object? value) {
  if (value is! Map) {
    throw const FormatException('Expected notification object.');
  }
  return value;
}

int notificationCount(Object? value) {
  if (value is! int || value < 0) {
    throw const FormatException('Invalid unread count.');
  }
  return value;
}

NotificationDto notificationFromJson(Object? value) {
  final json = notificationMap(value);
  final id = json['id'];
  final date = json['created_at'] is String
      ? DateTime.tryParse(json['created_at'] as String)
      : null;
  if (id is! String ||
      !isNotificationId(id) ||
      date == null ||
      json['is_read'] is! bool) {
    throw const FormatException('Invalid notification.');
  }
  // Old/unknown payloads stay readable as a generic update, never as a URL.
  final payload = json['payload'] is Map ? json['payload'] as Map : const {};
  int? target(Object? value) => value is int && value > 0 ? value : null;
  return NotificationDto(
    id: id,
    isRead: json['is_read'] as bool,
    createdAt: date,
    kind: switch (payload['type']) {
      'new_offer' => NotificationKind.offer,
      'new_message' => NotificationKind.message,
      'support_reply' => NotificationKind.supportReply,
      'order_paid' => NotificationKind.orderPaid,
      'order_completed' => NotificationKind.orderCompleted,
      'new_order' => NotificationKind.order,
      'offer_accepted' => NotificationKind.offerAccepted,
      'store_approved' => NotificationKind.storeApproved,
      'store_rejected' => NotificationKind.storeRejected,
      _ => NotificationKind.unknown,
    },
    orderId: target(payload['order_id']),
    offerId: target(payload['offer_id']),
    conversationId: target(
      payload[payload['type'] == 'support_reply'
          ? 'support_conversation_id'
          : 'conversation_id'],
    ),
    requestId: target(payload['request_id']),
    orderType: ['general', 'specific'].contains(payload['order_type'])
        ? payload['order_type'] as String
        : null,
  );
}

NotificationPageDto notificationPageFromJson(Object? value) {
  final json = notificationMap(value);
  final items = json['items'];
  final cursor = json['next_cursor'];
  if (items is! List ||
      (cursor != null &&
          (cursor is! String || cursor.isEmpty || cursor.length > 2048))) {
    throw const FormatException('Invalid notification page.');
  }
  return NotificationPageDto(
    items: List.unmodifiable(items.map(notificationFromJson)),
    unreadCount: notificationCount(json['unread_count']),
    nextCursor: cursor as String?,
  );
}

class NotificationDto {
  const NotificationDto({
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
  AppNotification toEntity() => AppNotification(
    id: id,
    kind: kind,
    isRead: isRead,
    createdAt: createdAt,
    orderId: orderId,
    offerId: offerId,
    conversationId: conversationId,
    requestId: requestId,
    orderType: orderType,
  );
}

class NotificationPageDto {
  const NotificationPageDto({
    required this.items,
    required this.unreadCount,
    this.nextCursor,
  });
  final List<NotificationDto> items;
  final int unreadCount;
  final String? nextCursor;
  NotificationPage toEntity() => NotificationPage(
    items: List.unmodifiable(items.map((item) => item.toEntity())),
    unreadCount: unreadCount,
    nextCursor: nextCursor,
  );
}

class NotificationReadReceiptDto {
  const NotificationReadReceiptDto(this.ids, this.unreadCount);
  final Set<String> ids;
  final int unreadCount;
  factory NotificationReadReceiptDto.fromJson(
    Object? value,
    Set<String> expected,
  ) {
    final json = notificationMap(value);
    final ids = json['ids'];
    if (ids is! List ||
        ids.length != expected.length ||
        ids.any((id) => id is! String || !expected.contains(id)) ||
        ids.toSet().length != expected.length) {
      throw const FormatException('Invalid page read receipt.');
    }
    return NotificationReadReceiptDto(
      Set.unmodifiable(ids.cast<String>()),
      notificationCount(json['unread_count']),
    );
  }
  NotificationReadReceipt toEntity() =>
      NotificationReadReceipt(ids: ids, unreadCount: unreadCount);
}
