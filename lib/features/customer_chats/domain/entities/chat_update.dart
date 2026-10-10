import 'chat.dart';

enum ChatUpdateKind { connected, disconnected, message, read }

class ChatUpdate {
  const ChatUpdate(
    this.kind, {
    this.conversationId,
    this.offerId,
    this.orderId,
    this.message,
    this.readerIsMe,
    this.throughId,
    this.conversation,
    this.snapshotAt,
  });
  final ChatUpdateKind kind;
  final int? conversationId, offerId, orderId, throughId;
  final ChatMessage? message;
  final bool? readerIsMe;
  final ChatSummary? conversation;
  final DateTime? snapshotAt;
}
