import '../domain/chat.dart';
import 'chat_remote_data_source.dart';

class ApiChatRepository implements ChatRepository {
  const ApiChatRepository(this.remote);
  final ChatRemoteDataSource remote;
  @override
  Future<ChatContext> open(ChatTarget target) => remote.open(target);
  @override
  Future<ChatInbox> inbox(int page) => remote.inbox(page);
  @override
  Future<ChatMessages> messages(int id, {int? before, int? after}) =>
      remote.messages(id, before: before, after: after);
  @override
  Future<ChatReceipt> send(ChatTarget target, String text, String clientId) =>
      remote.send(target, text, clientId);
  @override
  Future<void> markRead(int id, int through) => remote.markRead(id, through);
}
