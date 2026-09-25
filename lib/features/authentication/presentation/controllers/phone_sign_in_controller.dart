import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/saudi_mobile_number.dart';
import 'authentication_flow_controller.dart';
import 'session_providers.dart';

/// Owns only the asynchronous OTP-send operation. Text-editing state belongs
/// to the screen because it is short-lived, local UI state.
final phoneSignInControllerProvider =
    NotifierProvider<PhoneSignInController, PhoneSignInState>(
      PhoneSignInController.new,
    );

class PhoneSignInState {
  const PhoneSignInState({
    this.isSubmitting = false,
    this.error,
    this.successfulSubmissionCount = 0,
  });

  final bool isSubmitting;
  final Object? error;
  final int successfulSubmissionCount;
}

class PhoneSignInController extends Notifier<PhoneSignInState> {
  @override
  PhoneSignInState build() => const PhoneSignInState();

  void clearError() {
    if (state.error == null) return;

    state = PhoneSignInState(
      isSubmitting: state.isSubmitting,
      successfulSubmissionCount: state.successfulSubmissionCount,
    );
  }

  Future<void> sendOtp(SaudiMobileNumber mobile) async {
    if (state.isSubmitting) return;

    state = PhoneSignInState(
      isSubmitting: true,
      successfulSubmissionCount: state.successfulSubmissionCount,
    );
    try {
      await ref.read(sendOtpUseCaseProvider).call(mobile);
      ref.read(authenticationFlowProvider.notifier).startOtp(mobile);
      state = PhoneSignInState(
        successfulSubmissionCount: state.successfulSubmissionCount + 1,
      );
    } catch (error) {
      state = PhoneSignInState(
        error: error,
        successfulSubmissionCount: state.successfulSubmissionCount,
      );
    }
  }
}
