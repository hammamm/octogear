import 'package:octogear/features/customer_chats/domain/repositories/chat_repository.dart';

import '../../domain/entities/chat.dart';
import '../data_sources/chat_remote_data_source.dart';

class ChatRepositoryImpl implements ChatRepository {
  const ChatRepositoryImpl(this.remote);
  final ChatRemoteDataSource remote;
  @override
  Future<ChatContext> open(ChatTarget target) async =>
      (await remote.open(target)).toEntity();
  @override
  Future<ChatInbox> inbox(int page) async =>
      (await remote.inbox(page)).toEntity();
  @override
  Future<ChatMessages> messages(int id, {int? before, int? after}) async =>
      (await remote.messages(id, before: before, after: after)).toEntity();
  @override
  Future<ChatReceipt> send(
    ChatTarget target,
    String text,
    String clientId,
  ) async => (await remote.send(target, text, clientId)).toEntity();
  @override
  Future<void> markRead(int id, int through) => remote.markRead(id, through);
}
