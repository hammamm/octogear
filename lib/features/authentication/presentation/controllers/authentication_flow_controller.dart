import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_providers.dart';

import '../../domain/entities/saudi_mobile_number.dart';

/// Ephemeral hand-off state between sign-in, OTP, and registration routes.
/// It deliberately lives only in memory: OTPs and temporary registration
/// tokens must never be put in a URL, preferences, or secure session storage.
final authenticationFlowProvider =
    NotifierProvider<AuthenticationFlowController, AuthenticationFlowState>(
      AuthenticationFlowController.new,
    );

class AuthenticationFlowState {
  const AuthenticationFlowState({
    this.mobile,
    this.temporaryRegistrationToken,
    this.testOtp,
  });

  final SaudiMobileNumber? mobile;
  final String? temporaryRegistrationToken;
  final String? testOtp;

  bool get hasPhone => mobile != null;
  bool get hasTemporaryRegistrationToken =>
      temporaryRegistrationToken?.isNotEmpty ?? false;
}

class AuthenticationFlowController extends Notifier<AuthenticationFlowState> {
  @override
  AuthenticationFlowState build() => const AuthenticationFlowState();

  void startOtp(SaudiMobileNumber mobile, {String? testOtp}) {
    state = AuthenticationFlowState(
      mobile: mobile,
      testOtp: _visibleTestCode(testOtp),
    );
  }

  void setTestOtp(SaudiMobileNumber mobile, String? testOtp) {
    if (state.mobile?.nationalNumber != mobile.nationalNumber ||
        state.hasTemporaryRegistrationToken) {
      return;
    }
    state = AuthenticationFlowState(
      mobile: state.mobile,
      testOtp: _visibleTestCode(testOtp),
    );
  }

  String? _visibleTestCode(String? code) {
    return ref.read(appConfigurationProvider).allowsTestingOtp &&
            code != null &&
            RegExp(r'^[0-9]{4}$').hasMatch(code)
        ? code
        : null;
  }

  void requireRegistration(String temporaryRegistrationToken) {
    state = AuthenticationFlowState(
      mobile: state.mobile,
      temporaryRegistrationToken: temporaryRegistrationToken,
    );
  }

  void clear() => state = const AuthenticationFlowState();
}
