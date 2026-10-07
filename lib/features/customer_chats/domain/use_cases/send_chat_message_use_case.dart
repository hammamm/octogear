import '../entities/chat.dart';
import '../repositories/chat_repository.dart';

class SendChatMessageUseCase {
  const SendChatMessageUseCase(this._repository);
  final ChatRepository _repository;

  Future<ChatReceipt> call(ChatTarget target, String text, String clientId) =>
      _repository.send(target, text, clientId);
}
