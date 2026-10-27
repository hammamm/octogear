import '../../../../core/storage/session_credentials.dart';

/// Raw business result from verifying an OTP before the application decides
/// what to persist. It never reaches a widget directly.
sealed class OtpVerificationResult {
  const OtpVerificationResult();
}

class ExistingAccountOtpResult extends OtpVerificationResult {
  const ExistingAccountOtpResult(this.credentials);

  final SessionCredentials credentials;
  String get accessToken => credentials.accessToken;
}

class NewAccountOtpResult extends OtpVerificationResult {
  const NewAccountOtpResult(this.temporaryRegistrationToken);

  final String temporaryRegistrationToken;
}
