import '../../../../core/api/api_client.dart';
import '../models/chat_realtime_dto.dart';

class ChatRealtimeDataSource {
  const ChatRealtimeDataSource(this.api, {required this.allowInsecure});
  final ApiClient api;
  final bool allowInsecure;

  Future<ChatSocketConfiguration?> configuration() async {
    final response = await api.get(
      'chat/realtime',
      requiresAuthentication: true,
      decode: (value) =>
          ChatSocketConfiguration.parse(value, allowInsecure: allowInsecure),
    );
    return response.data;
  }

  Future<String> authorize(String socketId, String channel) async {
    final response = await api.post<String>(
      'chat/realtime/auth',
      requiresAuthentication: true,
      data: {'socket_id': socketId, 'channel_name': channel},
      decode: (value) {
        if (value is! Map ||
            value['auth'] is! String ||
            (value['auth'] as String).isEmpty) {
          throw const FormatException('Invalid channel authorization');
        }
        return value['auth'] as String;
      },
    );
    return response.data ??
        (throw const FormatException('Missing channel authorization'));
  }
}
