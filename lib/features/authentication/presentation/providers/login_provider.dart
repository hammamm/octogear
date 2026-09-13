import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sahala/dependency_injection.dart';
import 'package:sahala/features/authentication/domain/use_cases/login_use_case.dart';

final loginProvider = NotifierProvider<LoginNotifier, LoginState>(
  LoginNotifier.new,
);

class LoginState {
  final bool isLoading;
  final bool loginSuccess;

  const LoginState({this.isLoading = false, this.loginSuccess = false});

  LoginState copyWith({bool? isLoading, bool? loginSuccess}) {
    return LoginState(
      isLoading: isLoading ?? this.isLoading,
      loginSuccess: loginSuccess ?? this.loginSuccess,
    );
  }
}

class LoginNotifier extends Notifier<LoginState> {
  late final LoginUseCase _loginUseCase;
  final phoneController = TextEditingController();
  @override
  LoginState build() {
    _loginUseCase = sl<LoginUseCase>();

    ref.onDispose(() {
      phoneController.dispose();
    });

    return const LoginState();
  }

  bool get isPhoneValid => phoneController.text.length == 9;

  void onPhoneChanged(String value) {
    state = state.copyWith();
  }

  Future<void> login() async {
    if (!isPhoneValid || state.isLoading) return;
    state = state.copyWith(isLoading: true, loginSuccess: false);

    try {
      final response = await _loginUseCase(phoneController.text);

      if (response.data['status'] == 'success') {
        state = state.copyWith(loginSuccess: true);
      }
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }
}
