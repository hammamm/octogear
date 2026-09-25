/// Raw business result from verifying an OTP before the application decides
/// what to persist. It never reaches a widget directly.
sealed class OtpVerificationResult {
  const OtpVerificationResult();
}

class ExistingAccountOtpResult extends OtpVerificationResult {
  const ExistingAccountOtpResult(this.accessToken);

  final String accessToken;
}

class NewAccountOtpResult extends OtpVerificationResult {
  const NewAccountOtpResult(this.temporaryRegistrationToken);

  final String temporaryRegistrationToken;
}
