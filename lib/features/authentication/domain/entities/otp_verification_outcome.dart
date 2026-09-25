sealed class OtpVerificationOutcome {
  const OtpVerificationOutcome();
}

/// An existing account has completed OTP verification and has a real access
/// token. The use case writes it to secure storage before this is emitted.
class ExistingAccountVerified extends OtpVerificationOutcome {
  const ExistingAccountVerified();
}

/// A first-time visitor must complete registration. The temporary value is
/// held only in memory by the authentication flow controller.
class RegistrationRequired extends OtpVerificationOutcome {
  const RegistrationRequired(this.temporaryRegistrationToken);

  final String temporaryRegistrationToken;
}
