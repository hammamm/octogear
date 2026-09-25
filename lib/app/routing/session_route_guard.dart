import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/routing/app_route_paths.dart';
import '../../features/authentication/domain/entities/app_user.dart';
import '../../features/authentication/domain/entities/session_outcome.dart';
import '../../features/authentication/presentation/controllers/authentication_flow_controller.dart';

/// A pure routing policy: easy to test and the only place that decides which
/// root experience a session state may access.
String? redirectForSession({
  required AsyncValue<SessionOutcome> session,
  required AuthenticationFlowState authenticationFlow,
  required String currentPath,
}) {
  if (session.isLoading) {
    return currentPath == AppRoutePath.sessionLoading
        ? null
        : AppRoutePath.sessionLoading;
  }

  if (session.hasError) {
    return currentPath == AppRoutePath.sessionUnavailable
        ? null
        : AppRoutePath.sessionUnavailable;
  }

  final outcome = session.asData?.value;
  if (outcome == null) return AppRoutePath.sessionLoading;

  return switch (outcome) {
    SignedOutSession() => _redirectForVisitor(
      authenticationFlow: authenticationFlow,
      currentPath: currentPath,
    ),
    AuthenticatedSession(:final user) => _redirectForUser(
      role: user.role,
      currentPath: currentPath,
    ),
    UnavailableSession() =>
      currentPath == AppRoutePath.sessionUnavailable
          ? null
          : AppRoutePath.sessionUnavailable,
  };
}

String? _redirectForVisitor({
  required AuthenticationFlowState authenticationFlow,
  required String currentPath,
}) {
  if (currentPath == AppRoutePath.otpVerification &&
      !authenticationFlow.hasPhone) {
    return AppRoutePath.phoneSignIn;
  }

  if (currentPath == AppRoutePath.registration &&
      !authenticationFlow.hasTemporaryRegistrationToken) {
    return AppRoutePath.phoneSignIn;
  }

  const visitorPaths = {
    AppRoutePath.phoneSignIn,
    AppRoutePath.otpVerification,
    AppRoutePath.registration,
  };
  return visitorPaths.contains(currentPath) ? null : AppRoutePath.phoneSignIn;
}

String? _redirectForUser({
  required AppUserRole role,
  required String currentPath,
}) {
  final homePath = switch (role) {
    AppUserRole.customer => AppRoutePath.customerHome,
    AppUserRole.provider => AppRoutePath.providerHome,
  };

  return _isInsideRoute(currentPath, homePath) ? null : homePath;
}

bool _isInsideRoute(String currentPath, String routeRoot) {
  return currentPath == routeRoot || currentPath.startsWith('$routeRoot/');
}
