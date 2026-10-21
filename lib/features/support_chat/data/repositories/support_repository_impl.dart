import '../../domain/entities/support_chat.dart';
import '../../domain/repositories/support_repository.dart';
import '../data_sources/support_remote_data_source.dart';

class SupportRepositoryImpl implements SupportRepository {
  const SupportRepositoryImpl(this.source);
  final SupportRemoteDataSource source;
  @override
  Future<SupportConversation?> summary() async =>
      (await source.summary())?.entity;
  @override
  Future<SupportPage> timeline({int? before, int? after}) async =>
      (await source.timeline(before: before, after: after)).entity;
  @override
  Future<SupportReceipt> send(String text, String clientId) async =>
      (await source.send(text, clientId)).entity;
  @override
  Future<SupportConversation> read(int through) async =>
      (await source.read(through)).entity;
  @override
  Future<SupportConversation> reopen(int version) async =>
      (await source.reopen(version)).entity;
}
