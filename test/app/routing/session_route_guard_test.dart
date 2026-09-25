import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:octogear/app/routing/session_route_guard.dart';
import 'package:octogear/core/api/api_failure.dart';
import 'package:octogear/core/routing/app_route_paths.dart';
import 'package:octogear/features/authentication/domain/entities/app_user.dart';
import 'package:octogear/features/authentication/domain/entities/saudi_mobile_number.dart';
import 'package:octogear/features/authentication/domain/entities/session_outcome.dart';
import 'package:octogear/features/authentication/presentation/controllers/authentication_flow_controller.dart';

void main() {
  const noFlow = AuthenticationFlowState();

  group('redirectForSession', () {
    test('holds every route on session loading until validation finishes', () {
      final target = redirectForSession(
        session: const AsyncLoading<SessionOutcome>(),
        authenticationFlow: noFlow,
        currentPath: AppRoutePath.phoneSignIn,
      );

      expect(target, AppRoutePath.sessionLoading);
    });

    test('sends a visitor away from protected customer pages', () {
      final target = redirectForSession(
        session: const AsyncData<SessionOutcome>(SignedOutSession()),
        authenticationFlow: noFlow,
        currentPath: AppRoutePath.customerHome,
      );

      expect(target, AppRoutePath.phoneSignIn);
    });

    test('allows OTP only after an in-memory phone flow starts', () {
      final mobile = SaudiMobileNumber.tryParse('500000000')!;
      final target = redirectForSession(
        session: const AsyncData<SessionOutcome>(SignedOutSession()),
        authenticationFlow: AuthenticationFlowState(mobile: mobile),
        currentPath: AppRoutePath.otpVerification,
      );

      expect(target, isNull);
    });

    test('sends a verified customer to the customer shell', () {
      final target = redirectForSession(
        session: const AsyncData<SessionOutcome>(
          AuthenticatedSession(_customer),
        ),
        authenticationFlow: noFlow,
        currentPath: AppRoutePath.phoneSignIn,
      );

      expect(target, AppRoutePath.customerHome);
    });

    test('sends a verified provider to the provider shell', () {
      final target = redirectForSession(
        session: const AsyncData<SessionOutcome>(
          AuthenticatedSession(_provider),
        ),
        authenticationFlow: noFlow,
        currentPath: AppRoutePath.customerHome,
      );

      expect(target, AppRoutePath.providerHome);
    });

    test('keeps a retryable session failure out of authentication', () {
      final target = redirectForSession(
        session: const AsyncData<SessionOutcome>(
          UnavailableSession(ApiFailure(type: ApiFailureType.timeout)),
        ),
        authenticationFlow: noFlow,
        currentPath: AppRoutePath.phoneSignIn,
      );

      expect(target, AppRoutePath.sessionUnavailable);
    });
  });
}

const _customer = AppUser(
  id: 1,
  fullName: 'Customer',
  mobile: '500000000',
  role: AppUserRole.customer,
);

const _provider = AppUser(
  id: 2,
  fullName: 'Provider',
  mobile: '500000001',
  role: AppUserRole.provider,
);
