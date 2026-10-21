import '../../../customer_chats/domain/entities/chat.dart';

class SupportConversation {
  const SupportConversation({
    required this.id,
    required this.version,
    required this.closed,
    required this.unread,
    required this.userReadThrough,
    required this.supportReadThrough,
    this.lastMessage,
  });
  final int id, version, unread, userReadThrough, supportReadThrough;
  final bool closed;
  final ChatMessage? lastMessage;
}

class SupportPage {
  const SupportPage(this.conversation, this.messages, this.hasMore);
  final SupportConversation conversation;
  final List<ChatMessage> messages;
  final bool hasMore;
}

class SupportReceipt {
  const SupportReceipt(this.conversation, this.message);
  final SupportConversation conversation;
  final ChatMessage message;
}

class SupportUpdate {
  const SupportUpdate(this.conversation, {this.message});
  final SupportConversation conversation;
  final ChatMessage? message;
}
