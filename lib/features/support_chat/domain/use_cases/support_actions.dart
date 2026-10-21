import '../../../../core/api/api_failure.dart';
import '../repositories/support_repository.dart';
import '../entities/support_chat.dart';

class SupportActions {
  const SupportActions(this.repository);
  final SupportRepository repository;
  Future<SupportConversation?> summary() => repository.summary();
  Future<SupportPage> timeline({int? before, int? after}) =>
      repository.timeline(before: before, after: after);
  Future<SupportReceipt> send(String text, String clientId) {
    if (text.trim().isEmpty || text.trim().runes.length > 2000) {
      throw const ApiFailure(type: ApiFailureType.validation);
    }
    return repository.send(text.trim(), clientId);
  }

  Future<SupportConversation> read(int through) => repository.read(through);
  Future<SupportConversation> reopen(int version) => repository.reopen(version);
}
