import '../../../../core/api/api_failure.dart';
import '../../../../core/storage/app_storage.dart';
import '../entities/session_outcome.dart';
import '../repositories/session_repository.dart';

class RestoreSessionUseCase {
  const RestoreSessionUseCase({
    required SessionStorage sessionStorage,
    required SessionRepository sessionRepository,
  }) : _sessionStorage = sessionStorage,
       _sessionRepository = sessionRepository;

  final SessionStorage _sessionStorage;
  final SessionRepository _sessionRepository;

  Future<SessionOutcome> call() async {
    final accessToken = await _sessionStorage.readAccessToken();
    if (accessToken == null) return const SignedOutSession();

    try {
      final user = await _sessionRepository.getProfile();
      return AuthenticatedSession(user);
    } on ApiFailure catch (failure) {
      if (failure.type == ApiFailureType.unauthorized) {
        await _clearInvalidSession();
        return const SignedOutSession();
      }
      return UnavailableSession(failure);
    } catch (_) {
      return const UnavailableSession(ApiFailure.unexpected());
    }
  }

  Future<void> _clearInvalidSession() async {
    try {
      await _sessionStorage.clearSession();
    } catch (_) {
      // AppStorage clears the in-memory token before its platform writes, so
      // a confirmed 401 still returns the visitor to authentication.
    }
  }
}
