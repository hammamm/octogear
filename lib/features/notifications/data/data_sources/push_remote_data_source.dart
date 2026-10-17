import '../../../../core/api/api_client.dart';

class PushRemoteDataSource {
  const PushRemoteDataSource(this.api);
  final ApiClient api;

  Future<void> register(String token, String locale) async {
    await api.post<void>(
      'push/device',
      requiresAuthentication: true,
      data: {'token': token, 'platform': 'android', 'locale': locale},
      decode: (_) {},
    );
  }

  Future<void> unregister() async {
    await api.delete<void>(
      'push/device',
      requiresAuthentication: true,
      decode: (_) {},
    );
  }
}
