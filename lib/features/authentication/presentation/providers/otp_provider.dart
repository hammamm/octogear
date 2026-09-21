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
      }

      print(response.status);
    } catch (error) {
      state = state.copyWith(isLoading: false, isSuccess: false, isError: true);
    }
  }

  Future<void> resendOTP(String mobileNumber) async {
    state = state.copyWith(isResending: true);
    await _loginUseCase(mobileNumber);
    state = state.copyWith(isResending: false);
    state = state.copyWith(showCounter: true);
  }

  void onCountdownFinished() {
    state = state.copyWith(showCounter: false);
  }
}
