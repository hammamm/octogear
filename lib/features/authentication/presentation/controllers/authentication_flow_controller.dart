import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/saudi_mobile_number.dart';

/// Ephemeral hand-off state between sign-in, OTP, and registration routes.
/// It deliberately lives only in memory: OTPs and temporary registration
/// tokens must never be put in a URL, preferences, or secure session storage.
final authenticationFlowProvider =
    NotifierProvider<AuthenticationFlowController, AuthenticationFlowState>(
      AuthenticationFlowController.new,
    );

class AuthenticationFlowState {
  const AuthenticationFlowState({this.mobile, this.temporaryRegistrationToken});

  final SaudiMobileNumber? mobile;
  final String? temporaryRegistrationToken;

  bool get hasPhone => mobile != null;
  bool get hasTemporaryRegistrationToken =>
      temporaryRegistrationToken?.isNotEmpty ?? false;
}

class AuthenticationFlowController extends Notifier<AuthenticationFlowState> {
  @override
  AuthenticationFlowState build() => const AuthenticationFlowState();

  void startOtp(SaudiMobileNumber mobile) {
    state = AuthenticationFlowState(mobile: mobile);
  }

  void requireRegistration(String temporaryRegistrationToken) {
    state = AuthenticationFlowState(
      mobile: state.mobile,
      temporaryRegistrationToken: temporaryRegistrationToken,
    );
  }

  void clear() => state = const AuthenticationFlowState();
}
