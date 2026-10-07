import '../entities/chat.dart';
import '../repositories/chat_repository.dart';

class OpenChatUseCase {
  const OpenChatUseCase(this._repository);
  final ChatRepository _repository;

  Future<ChatContext> call(ChatTarget target) => _repository.open(target);
}
