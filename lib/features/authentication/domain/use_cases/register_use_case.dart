import '../../../../core/storage/app_storage.dart';
import '../../../../core/storage/session_credentials.dart';
import '../repositories/authentication_repository.dart';

/// Finishes first-time registration and persists the new real access token.
class RegisterUseCase {
  const RegisterUseCase({
    required AuthenticationRepository repository,
    required SessionStorage sessionStorage,
    this.apiBaseUrl = '',
  }) : _repository = repository,
       _sessionStorage = sessionStorage;

  final AuthenticationRepository _repository;
  final SessionStorage _sessionStorage;
  final String apiBaseUrl;

  Future<void> call({
    required String temporaryRegistrationToken,
    required String fullName,
    required int cityId,
  }) async {
    final credentials = await _repository.register(
      temporaryRegistrationToken: temporaryRegistrationToken,
      fullName: fullName,
      cityId: cityId,
    );
    final storage = _sessionStorage;
    if (storage is RefreshSessionStorage) {
      await (storage as RefreshSessionStorage).saveSession(StoredSession(credentials, apiBaseUrl));
    } else {
      await storage.saveAccessToken(credentials.accessToken);
    }
  }
}
