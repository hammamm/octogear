import '../entities/chat.dart';

abstract interface class ChatRepository {
  Future<ChatContext> open(ChatTarget target);
  Future<ChatInbox> inbox(int page);
  Future<ChatMessages> messages(int id, {int? before, int? after});
  Future<ChatReceipt> send(ChatTarget target, String text, String clientId);
  Future<void> markRead(int id, int through);
}
