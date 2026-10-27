import '../../../../core/storage/app_storage.dart';
import '../../../../core/storage/session_credentials.dart';
import '../entities/otp_verification_outcome.dart';
import '../entities/otp_verification_result.dart';
import '../entities/saudi_mobile_number.dart';
import '../repositories/authentication_repository.dart';

/// Verifies the OTP and persists only a real, existing-account access token.
/// A temporary registration token is deliberately returned in-memory instead.
class VerifyOtpUseCase {
  const VerifyOtpUseCase({
    required AuthenticationRepository repository,
    required SessionStorage sessionStorage,
    this.apiBaseUrl = '',
  }) : _repository = repository,
       _sessionStorage = sessionStorage;

  final AuthenticationRepository _repository;
  final SessionStorage _sessionStorage;
  final String apiBaseUrl;

  Future<OtpVerificationOutcome> call({
    required SaudiMobileNumber mobile,
    required String otp,
  }) async {
    final result = await _repository.verifyOtp(mobile: mobile, otp: otp);
    switch (result) {
      case ExistingAccountOtpResult(:final credentials):
        final storage = _sessionStorage;
        if (storage is RefreshSessionStorage) {
          await (storage as RefreshSessionStorage).saveSession(StoredSession(credentials, apiBaseUrl));
        } else {
          await storage.saveAccessToken(credentials.accessToken);
        }
        return const ExistingAccountVerified();
      case NewAccountOtpResult(:final temporaryRegistrationToken):
        return RegistrationRequired(temporaryRegistrationToken);
    }
  }
}
