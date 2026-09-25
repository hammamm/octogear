import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:octogear/features/authentication/domain/entities/app_user.dart';
import 'package:octogear/features/authentication/domain/entities/otp_verification_result.dart';
import 'package:octogear/features/authentication/domain/entities/saudi_mobile_number.dart';
import 'package:octogear/features/authentication/domain/repositories/authentication_repository.dart';
import 'package:octogear/features/authentication/presentation/controllers/otp_resend_controller.dart';
import 'package:octogear/features/authentication/presentation/controllers/session_providers.dart';

void main() {
  test(
    'discards a resend success after the OTP screen stops watching',
    () async {
      final container = ProviderContainer(
        overrides: [
          authenticationRepositoryProvider.overrideWithValue(
            _FakeAuthenticationRepository(),
          ),
        ],
      );
      addTearDown(container.dispose);

      final subscription = container.listen(
        otpResendControllerProvider,
        (_, _) {},
      );
      final mobile = SaudiMobileNumber.tryParse('500000001')!;

      await container.read(otpResendControllerProvider.notifier).resend(mobile);

      expect(
        container.read(otpResendControllerProvider).successfulSubmissionCount,
        1,
      );

      subscription.close();
      await Future<void>.delayed(Duration.zero);

      expect(
        container.read(otpResendControllerProvider).successfulSubmissionCount,
        0,
      );
    },
  );
}

class _FakeAuthenticationRepository implements AuthenticationRepository {
  @override
  Future<List<AppCity>> getRegistrationCities() => throw UnimplementedError();

  @override
  Future<String> register({
    required String temporaryRegistrationToken,
    required String fullName,
    required int cityId,
  }) => throw UnimplementedError();

  @override
  Future<void> sendOtp(SaudiMobileNumber mobile) async {}

  @override
  Future<OtpVerificationResult> verifyOtp({
    required SaudiMobileNumber mobile,
    required String otp,
  }) => throw UnimplementedError();
}
