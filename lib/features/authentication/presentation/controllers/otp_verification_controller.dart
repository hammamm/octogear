import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/otp_verification_outcome.dart';
import '../../domain/entities/saudi_mobile_number.dart';
import 'session_providers.dart';

final otpVerificationControllerProvider =
    AsyncNotifierProvider<OtpVerificationController, OtpVerificationOutcome?>(
      OtpVerificationController.new,
    );

class OtpVerificationController extends AsyncNotifier<OtpVerificationOutcome?> {
  @override
  OtpVerificationOutcome? build() => null;

  Future<void> verify({
    required SaudiMobileNumber mobile,
    required String otp,
  }) async {
    if (state.isLoading) return;

    state = const AsyncLoading();
    try {
      final outcome = await ref
          .read(verifyOtpUseCaseProvider)
          .call(mobile: mobile, otp: otp);
      state = AsyncData(outcome);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  void reset() => state = const AsyncData(null);
}
