class ChatTarget {
  const ChatTarget.offer(this.orderId, this.offerId) : conversationId = null;
  const ChatTarget.conversation(this.conversationId)
    : orderId = null,
      offerId = null;
  final int? orderId, offerId, conversationId;
  @override
  bool operator ==(Object other) =>
      other is ChatTarget &&
      other.orderId == orderId &&
      other.offerId == offerId &&
      other.conversationId == conversationId;
  @override
  int get hashCode => Object.hash(orderId, offerId, conversationId);
}

class ChatSummary {
  const ChatSummary({
    required this.id,
    required this.name,
    this.employeeName,
    this.storeName,
    this.orderId,
    this.offerId,
    this.latestText,
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
  final bool canSend;
}

class ChatContext {
  const ChatContext({
    this.conversation,
    this.storeName,
    this.employeeName,
    this.orderId,
    this.offerId,
    this.canStart = true,
  });
  final ChatSummary? conversation;
  final String? storeName, employeeName;
  final int? orderId, offerId;
  final bool canStart;
  bool get canSend => conversation?.canSend ?? canStart;
}

class ChatMessage {
  const ChatMessage({
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
}

class ChatMessages {
  const ChatMessages(this.messages, this.hasMore);
  final List<ChatMessage> messages;
  final bool hasMore;
}

class ChatInbox {
  const ChatInbox(this.chats, this.page, this.lastPage);
  final List<ChatSummary> chats;
  final int page, lastPage;
}

class ChatReceipt {
  const ChatReceipt(this.message, this.conversation);
  final ChatMessage message;
  final ChatSummary? conversation;
}

abstract interface class ChatRepository {
  Future<ChatContext> open(ChatTarget target);
  Future<ChatInbox> inbox(int page);
  Future<ChatMessages> messages(int id, {int? before, int? after});
  Future<ChatReceipt> send(ChatTarget target, String text, String clientId);
  Future<void> markRead(int id, int through);
}
