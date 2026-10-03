import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:octogear/core/api/api_providers.dart';
import 'package:octogear/core/configuration/app_configuration.dart';
import 'package:octogear/features/authentication/domain/entities/app_user.dart';
import 'package:octogear/features/authentication/domain/entities/otp_verification_result.dart';
import 'package:octogear/features/authentication/domain/entities/saudi_mobile_number.dart';
import 'package:octogear/features/authentication/domain/repositories/authentication_repository.dart';
import 'package:octogear/features/authentication/presentation/controllers/authentication_flow_controller.dart';
import 'package:octogear/features/authentication/presentation/controllers/phone_sign_in_controller.dart';
import 'package:octogear/features/authentication/presentation/controllers/otp_resend_controller.dart';
import 'package:octogear/features/authentication/presentation/controllers/session_providers.dart';

class TestingAuthRepository implements AuthenticationRepository {
  Future<String?> Function() onSend = () async => '0042';
  @override
  Future<String?> sendOtp(SaudiMobileNumber mobile) => onSend();
  @override
  Future<List<AppCity>> getRegistrationCities() => throw UnimplementedError();
  @override
  Future<String> register({
    required String temporaryRegistrationToken,
    required String fullName,
    required int cityId,
  }) => throw UnimplementedError();
  @override
  Future<OtpVerificationResult> verifyOtp({
    required SaudiMobileNumber mobile,
    required String otp,
  }) => throw UnimplementedError();
}

void main() {
  final mobile = SaudiMobileNumber.tryParse('500000001')!;
  test(
    'initial send, resend, failure and registration manage only ephemeral code',
    () async {
      final repo = TestingAuthRepository();
      final container = ProviderContainer(
        overrides: [authenticationRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);
      container.listen(otpResendControllerProvider, (_, _) {});
      await container
          .read(phoneSignInControllerProvider.notifier)
          .sendOtp(mobile);
      expect(container.read(authenticationFlowProvider).testOtp, '0042');
      final gate = Completer<String?>();
      repo.onSend = () => gate.future;
      final resend = container
          .read(otpResendControllerProvider.notifier)
          .resend(mobile);
      expect(container.read(authenticationFlowProvider).testOtp, isNull);
      gate.complete('0071');
      await resend;
      expect(container.read(authenticationFlowProvider).testOtp, '0071');
      repo.onSend = () async => throw Exception('connection failure');
      await container.read(otpResendControllerProvider.notifier).resend(mobile);
      expect(container.read(authenticationFlowProvider).testOtp, isNull);
      final flow = container.read(authenticationFlowProvider.notifier);
      flow.setTestOtp(mobile, '0010');
      flow.requireRegistration('temporary');
      expect(container.read(authenticationFlowProvider).testOtp, isNull);
      flow.setTestOtp(mobile, '0042');
      expect(container.read(authenticationFlowProvider).testOtp, isNull);
      flow.clear();
      expect(container.read(authenticationFlowProvider).hasPhone, false);
    },
  );
  for (final environment in [
    AppEnvironment.production,
    AppEnvironment.staging,
  ]) {
    test('codes are discarded in $environment', () {
      final container = ProviderContainer(
        overrides: [
          appConfigurationProvider.overrideWithValue(
            AppConfiguration(
              environment: environment,
              apiBaseUrl: 'https://example.test/api',
            ),
          ),
        ],
      );
      addTearDown(container.dispose);
      container
          .read(authenticationFlowProvider.notifier)
          .startOtp(mobile, testOtp: '0042');
      expect(container.read(authenticationFlowProvider).testOtp, isNull);
    });
  }
  test('resend cannot populate another phone or a cleared flow', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final flow = container.read(authenticationFlowProvider.notifier);
    flow.startOtp(SaudiMobileNumber.tryParse('500000002')!);
    flow.setTestOtp(mobile, '0042');
    expect(container.read(authenticationFlowProvider).testOtp, isNull);
    flow.clear();
    flow.setTestOtp(mobile, '0042');
    expect(container.read(authenticationFlowProvider).testOtp, isNull);
  });
}
