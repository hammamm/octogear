import '../entities/app_user.dart';
import '../entities/otp_verification_result.dart';
import '../entities/saudi_mobile_number.dart';

/// Business contract for the authentication capability.
abstract interface class AuthenticationRepository {
  Future<void> sendOtp(SaudiMobileNumber mobile);
  Future<OtpVerificationResult> verifyOtp({
    required SaudiMobileNumber mobile,
    required String otp,
  });
  Future<String> register({
    required String temporaryRegistrationToken,
    required String fullName,
    required int cityId,
  });
  Future<List<AppCity>> getRegistrationCities();
}
