import '../entities/chat.dart';
import '../repositories/chat_repository.dart';

class GetChatMessagesUseCase {
  const GetChatMessagesUseCase(this._repository);
  final ChatRepository _repository;

  Future<ChatMessages> call(int id, {int? before, int? after}) =>
      _repository.messages(id, before: before, after: after);
}
