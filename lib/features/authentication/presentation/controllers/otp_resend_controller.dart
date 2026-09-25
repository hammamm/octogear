import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/saudi_mobile_number.dart';
import 'session_providers.dart';

/// Separate from the phone-screen action so resending a code cannot trigger a
/// second navigation to the OTP route underneath the current route.
final otpResendControllerProvider =
    NotifierProvider.autoDispose<OtpResendController, OtpResendState>(
      OtpResendController.new,
    );

class OtpResendState {
  const OtpResendState({
    this.isSubmitting = false,
    this.error,
    this.successfulSubmissionCount = 0,
  });

  final bool isSubmitting;
  final Object? error;
  final int successfulSubmissionCount;
}

class OtpResendController extends Notifier<OtpResendState> {
  @override
  OtpResendState build() => const OtpResendState();

  Future<void> resend(SaudiMobileNumber mobile) async {
    if (state.isSubmitting) return;

    state = OtpResendState(
      isSubmitting: true,
      successfulSubmissionCount: state.successfulSubmissionCount,
    );
    try {
      await ref.read(sendOtpUseCaseProvider).call(mobile);
      state = OtpResendState(
        successfulSubmissionCount: state.successfulSubmissionCount + 1,
      );
    } catch (error) {
      state = OtpResendState(
        error: error,
        successfulSubmissionCount: state.successfulSubmissionCount,
      );
    }
  }
}
