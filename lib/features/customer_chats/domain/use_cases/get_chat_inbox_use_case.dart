import '../entities/chat.dart';
import '../repositories/chat_repository.dart';

class GetChatInboxUseCase {
  const GetChatInboxUseCase(this._repository);
  final ChatRepository _repository;

  Future<ChatInbox> call(int page) => _repository.inbox(page);
}
