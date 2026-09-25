import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'session_providers.dart';

final registrationControllerProvider =
    NotifierProvider<RegistrationController, RegistrationState>(
      RegistrationController.new,
    );

class RegistrationState {
  const RegistrationState({
    this.isSubmitting = false,
    this.error,
    this.successfulSubmissionCount = 0,
  });

  final bool isSubmitting;
  final Object? error;
  final int successfulSubmissionCount;
}

class RegistrationController extends Notifier<RegistrationState> {
  @override
  RegistrationState build() => const RegistrationState();

  Future<void> register({
    required String temporaryRegistrationToken,
    required String fullName,
    required int cityId,
  }) async {
    if (state.isSubmitting) return;

    state = RegistrationState(
      isSubmitting: true,
      successfulSubmissionCount: state.successfulSubmissionCount,
    );
    try {
      await ref
          .read(registerUseCaseProvider)
          .call(
            temporaryRegistrationToken: temporaryRegistrationToken,
            fullName: fullName,
            cityId: cityId,
          );
      state = RegistrationState(
        successfulSubmissionCount: state.successfulSubmissionCount + 1,
      );
    } catch (error) {
      state = RegistrationState(
        error: error,
        successfulSubmissionCount: state.successfulSubmissionCount,
      );
    }
  }
}
