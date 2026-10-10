import '../../domain/entities/chat.dart';

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

ChatSummaryDto chatSummary(Object? value) {
  final json = chatMap(value);
  final store = json['store'] == null ? null : chatMap(json['store']);
  final latest = json['latest_message'] == null
      ? null
      : chatMap(json['latest_message']);
  final unread = json['unread_count'];
  if (unread is! int || unread < 0 || json['can_send'] is! bool) {
    throw const FormatException('Invalid chat state');
  }
  return ChatSummaryDto(
    id: chatId(json['id']),
    name: chatText(chatMap(json['other_user'])['name']) ?? '',
    storeName: chatText(store?['name']),
    employeeName: chatText(store?['employee_name']),
    orderId: json['order_id'] == null ? null : chatId(json['order_id']),
    offerId: json['offer_id'] == null ? null : chatId(json['offer_id']),
    latestText: chatText(latest?['content']),
    latestMessageId: latest == null ? 0 : chatId(latest['id']),
    updatedAt: chatDate(json['updated_at']),
    unread: unread,
    canSend: json['can_send'] as bool,
  );
}

ChatMessageDto chatMessage(Object? value) {
  final json = chatMap(value);
  if (json['is_mine'] is! bool || json['is_read'] is! bool) {
    throw const FormatException('Invalid message state');
  }
  final text = chatText(json['content']);
  if (text == null) throw const FormatException('Empty message');
  return ChatMessageDto(
    id: chatId(json['id']),
    text: text,
    mine: json['is_mine'] as bool,
    read: json['is_read'] as bool,
    createdAt: chatDate(json['created_at']),
    clientId: chatText(json['client_message_id']),
  );
}

class ChatSummaryDto {
  const ChatSummaryDto({
    required this.id,
    required this.name,
    this.employeeName,
    this.storeName,
    this.orderId,
    this.offerId,
    this.latestText,
    this.latestMessageId = 0,
    this.updatedAt,
    this.unread = 0,
    this.canSend = true,
  });
  final int id;
  final String name;
  final String? storeName, employeeName, latestText;
  final int? orderId, offerId;
  final DateTime? updatedAt;
  final int unread;
  final int latestMessageId;
  final bool canSend;
  ChatSummary toEntity() => ChatSummary(
    id: id,
    name: name,
    employeeName: employeeName,
    storeName: storeName,
    orderId: orderId,
    offerId: offerId,
    latestText: latestText,
    latestMessageId: latestMessageId,
    updatedAt: updatedAt,
    unread: unread,
    canSend: canSend,
  );
}

class ChatMessageDto {
  const ChatMessageDto({
    required this.id,
    required this.text,
    required this.mine,
    required this.read,
    required this.createdAt,
    this.clientId,
  });
  final int id;
  final String text;
  final bool mine, read;
  final DateTime createdAt;
  final String? clientId;
  ChatMessage toEntity() => ChatMessage(
    id: id,
    text: text,
    mine: mine,
    read: read,
    createdAt: createdAt,
    clientId: clientId,
  );
}

class ChatContextDto {
  const ChatContextDto({
    this.conversation,
    this.storeName,
    this.employeeName,
    this.orderId,
    this.offerId,
    this.canStart = true,
  });
  final ChatSummaryDto? conversation;
  final String? storeName, employeeName;
  final int? orderId, offerId;
  final bool canStart;
  bool get canSend => conversation?.canSend ?? canStart;
  ChatContext toEntity() => ChatContext(
    conversation: conversation?.toEntity(),
    storeName: storeName,
    employeeName: employeeName,
    orderId: orderId,
    offerId: offerId,
    canStart: canStart,
  );
}

class ChatInboxDto {
  const ChatInboxDto(this.chats, this.page, this.lastPage);
  final List<ChatSummaryDto> chats;
  final int page, lastPage;
  ChatInbox toEntity() => ChatInbox(
    List.unmodifiable(chats.map((chat) => chat.toEntity())),
    page,
    lastPage,
  );
}

class ChatMessagesDto {
  const ChatMessagesDto(this.messages, this.hasMore, {this.readThroughId = 0});
  final List<ChatMessageDto> messages;
  final bool hasMore;
  final int readThroughId;
  ChatMessages toEntity() => ChatMessages(
    List.unmodifiable(messages.map((message) => message.toEntity())),
    hasMore,
    readThroughId: readThroughId,
  );
}

class ChatReceiptDto {
  const ChatReceiptDto(this.message, this.conversation);
  final ChatMessageDto message;
  final ChatSummaryDto? conversation;
  ChatReceipt toEntity() =>
      ChatReceipt(message.toEntity(), conversation?.toEntity());
}
