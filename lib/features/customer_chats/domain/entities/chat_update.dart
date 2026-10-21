import '../../../support_chat/domain/entities/support_chat.dart';
import 'chat.dart';

enum ChatUpdateKind { connected, disconnected, message, read, support }

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
    this.support,
  });
  final ChatUpdateKind kind;
  final SupportUpdate? support;
  final int? conversationId, offerId, orderId, throughId;
  final ChatMessage? message;
  final bool? readerIsMe;
  final ChatSummary? conversation;
  final DateTime? snapshotAt;
}
