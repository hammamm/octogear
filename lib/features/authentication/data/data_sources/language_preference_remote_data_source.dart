import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_failure.dart';

class LanguagePreferenceRemoteDataSource {
  const LanguagePreferenceRemoteDataSource(this._client);
  final ApiClient _client;

  Future<void> save({
    required String language,
    required String sessionToken,
  }) async {
    final response = await _client.patch<String>(
      'profile/language',
      requiresAuthentication: true,
      expectedAccessToken: sessionToken,
      data: {'preferred_language': language},
      decode: (data) {
        if (data is! Map || data['preferred_language'] != language) {
          throw const FormatException('Language save was not confirmed.');
        }
        return language;
      },
    );
    if (response.data != language) throw const ApiFailure.unexpected();
  }
}
