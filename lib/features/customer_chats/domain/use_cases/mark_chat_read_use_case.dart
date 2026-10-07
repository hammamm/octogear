import '../repositories/chat_repository.dart';

class MarkChatReadUseCase {
  const MarkChatReadUseCase(this._repository);
  final ChatRepository _repository;

  Future<void> call(int id, int through) => _repository.markRead(id, through);
}
