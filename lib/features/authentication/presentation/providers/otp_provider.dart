import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sahala/core/service/app_logger.dart';
import 'package:sahala/dependency_injection.dart';
import 'package:sahala/features/authentication/data/models/otp_verify_request_model.dart';
import 'package:sahala/features/authentication/domain/use_cases/login_use_case.dart';
import 'package:sahala/features/authentication/domain/use_cases/otp_use_case.dart';

final otpProvider = NotifierProvider.autoDispose<OtpNotifier, OtpState>(
  OtpNotifier.new,
);

class OtpState {
  final bool isLoading;
  final bool isResending;
  final bool isSuccess;
  final bool isError;
  final bool showCounter;

  const OtpState({
    this.isLoading = false,
    this.isResending = false,
    this.isSuccess = false,
    this.isError = false,
    this.showCounter = true,
  });

  OtpState copyWith({
    bool? isLoading,
    bool? isResending,
    bool? isSuccess,
    bool? isError,
    bool? showCounter,
  }) {
    return OtpState(
      isLoading: isLoading ?? this.isLoading,
      isResending: isResending ?? this.isResending,
      isSuccess: isSuccess ?? this.isSuccess,
      isError: isError ?? this.isError,
      showCounter: showCounter ?? this.showCounter,
    );
  }
}

class OtpNotifier extends Notifier<OtpState> {
  late final OtpUseCase _otpUseCase = sl<OtpUseCase>();
  late final LoginUseCase _loginUseCase = sl<LoginUseCase>();
  @override
  OtpState build() {
    return const OtpState(showCounter: true, isResending: false);
  }

  Future<void> otpVerify(OtpVerifyRequestModel body) async {
    try {
      if (state.isLoading) return;

      state = state.copyWith(isLoading: true, isSuccess: false, isError: false);

      final response = await _otpUseCase(body);

      if (response.status == "success") {
        state = state.copyWith(
          isLoading: false,
          isSuccess: true,
          isError: false,
        );
      } else {
        // Expected business outcome (wrong/expired code, etc.) - the backend
        // already returned a message meant for the customer, not a code
        // defect, so this is not logged. See AppLogger.error's doc comment.
        state = state.copyWith(
          isLoading: false,
          isSuccess: false,
          isError: true,
        );
      }
    } catch (error, stackTrace) {
      // Reaching here means the request itself failed (network, parsing,
      // an unexpected server error, ...) rather than an expected "wrong
      // OTP" business outcome - that's a real defect/incident, so it is
      // logged. See AppLogger.error's doc comment.
      await AppLogger.error(
        error,
        stackTrace: stackTrace,
        reason: 'OTP verify failed',
      );
      state = state.copyWith(isLoading: false, isSuccess: false, isError: true);
    }
  }

  Future<void> resendOTP(String mobileNumber) async {
    try {
      state = state.copyWith(isResending: true);
      await _loginUseCase(mobileNumber);
      state = state.copyWith(isResending: false, showCounter: true);
    } catch (error, stackTrace) {
      await AppLogger.error(
        error,
        stackTrace: stackTrace,
        reason: 'OTP resend failed',
      );
      state = state.copyWith(isResending: false);
    }
  }

  void onCountdownFinished() {
    state = state.copyWith(showCounter: false);
  }
}
