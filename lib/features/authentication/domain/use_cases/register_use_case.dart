import '../../../../core/storage/app_storage.dart';
import '../repositories/authentication_repository.dart';

/// Finishes first-time registration and persists the new real access token.
class RegisterUseCase {
  const RegisterUseCase({
    required AuthenticationRepository repository,
    required SessionStorage sessionStorage,
  }) : _repository = repository,
       _sessionStorage = sessionStorage;

  final AuthenticationRepository _repository;
  final SessionStorage _sessionStorage;

  Future<void> call({
    required String temporaryRegistrationToken,
    required String fullName,
    required int cityId,
  }) async {
    final accessToken = await _repository.register(
      temporaryRegistrationToken: temporaryRegistrationToken,
      fullName: fullName,
      cityId: cityId,
    );
    await _sessionStorage.saveAccessToken(accessToken);
  }
}
