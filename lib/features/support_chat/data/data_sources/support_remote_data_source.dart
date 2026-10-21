import '../../../../core/api/api_failure.dart';
import '../../../../core/api/api_client.dart';
import '../models/support_dto.dart';

class SupportRemoteDataSource {
  const SupportRemoteDataSource(this.api, this.token);
  final ApiClient api;
  final String? token;
  static const _path = 'support/conversation';
  Future<SupportConversationDto?> summary() async => (await api.get(
    _path,
    requiresAuthentication: true,
    decode: (data) => data == null ? null : SupportConversationDto(data),
  )).data;
  Future<SupportPageDto> timeline({int? before, int? after}) async =>
      (await api.get(
        '$_path/timeline',
        requiresAuthentication: true,
        queryParameters: {'before_id': ?before, 'after_id': ?after},
        decode: SupportPageDto.new,
      )).data ??
      (throw const ApiFailure.unexpected());
  Future<SupportReceiptDto> send(String text, String clientId) async =>
      (await api.post(
        '$_path/messages',
        requiresAuthentication: true,
        expectedAccessToken: token,
        data: {'content': text, 'client_message_id': clientId},
        decode: SupportReceiptDto.new,
      )).data ??
      (throw const ApiFailure.unexpected());
  Future<SupportConversationDto> read(int through) async =>
      (await api.patch(
        '$_path/read',
        requiresAuthentication: true,
        expectedAccessToken: token,
        data: {'through_id': through},
        decode: SupportConversationDto.new,
      )).data ??
      (throw const ApiFailure.unexpected());
  Future<SupportConversationDto> reopen(int version) async =>
      (await api.patch(
        '$_path/reopen',
        requiresAuthentication: true,
        expectedAccessToken: token,
        data: {'version': version},
        decode: SupportConversationDto.new,
      )).data ??
      (throw const ApiFailure.unexpected());
}
