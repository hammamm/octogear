import '../entities/support_chat.dart';

abstract interface class SupportRepository {
  Future<SupportConversation?> summary();
  Future<SupportPage> timeline({int? before, int? after});
  Future<SupportReceipt> send(String text, String clientId);
  Future<SupportConversation> read(int through);
  Future<SupportConversation> reopen(int version);
}
