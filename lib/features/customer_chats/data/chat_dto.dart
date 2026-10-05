import '../domain/chat.dart';

Map chatMap(Object? value) {
  if (value is! Map) throw const FormatException('Invalid chat object');
  return value;
}

int chatId(Object? value) {
  if (value is! int || value < 1) {
    throw const FormatException('Invalid chat ID');
  }
  return value;
}

String? chatText(Object? value) {
  if (value == null) return null;
  if (value is! String) throw const FormatException('Invalid chat text');
  return value.trim().isEmpty ? null : value;
}

DateTime chatDate(Object? value) {
  final result = value is String ? DateTime.tryParse(value) : null;
  if (result == null) throw const FormatException('Invalid chat date');
  return result;
}

ChatSummary chatSummary(Object? value) {
  final json = chatMap(value);
  final store = json['store'] == null ? null : chatMap(json['store']);
  final latest = json['latest_message'] == null
      ? null
      : chatMap(json['latest_message']);
  final unread = json['unread_count'];
  if (unread is! int || unread < 0 || json['can_send'] is! bool) {
    throw const FormatException('Invalid chat state');
  }
  return ChatSummary(
    id: chatId(json['id']),
    name: chatText(chatMap(json['other_user'])['name']) ?? '',
    storeName: chatText(store?['name']),
    employeeName: chatText(store?['employee_name']),
    orderId: json['order_id'] == null ? null : chatId(json['order_id']),
    offerId: json['offer_id'] == null ? null : chatId(json['offer_id']),
    latestText: chatText(latest?['content']),
    updatedAt: chatDate(json['updated_at']),
    unread: unread,
    canSend: json['can_send'] as bool,
  );
}

ChatMessage chatMessage(Object? value) {
  final json = chatMap(value);
  if (json['is_mine'] is! bool || json['is_read'] is! bool) {
    throw const FormatException('Invalid message state');
  }
  final text = chatText(json['content']);
  if (text == null) throw const FormatException('Empty message');
  return ChatMessage(
    id: chatId(json['id']),
    text: text,
    mine: json['is_mine'] as bool,
    read: json['is_read'] as bool,
    createdAt: chatDate(json['created_at']),
    clientId: chatText(json['client_message_id']),
  );
}
