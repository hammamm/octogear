// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_routes.dart';

// **************************************************************************
// GoRouterGenerator
// **************************************************************************

List<RouteBase> get $appRoutes => [
  $sessionLoadingRoute,
  $phoneSignInRoute,
  $otpVerificationRoute,
  $registrationRoute,
  $sessionUnavailableRoute,
  $customerHomeRoute,
  $providerHomeRoute,
];

RouteBase get $sessionLoadingRoute => GoRouteData.$route(
  path: '/',
  hasOverriddenOnExit: false,
  factory: $SessionLoadingRoute._fromState,
);

mixin $SessionLoadingRoute on GoRouteData {
  static SessionLoadingRoute _fromState(GoRouterState state) =>
      const SessionLoadingRoute();

  @override
  String get location => GoRouteData.$location('/');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $phoneSignInRoute => GoRouteData.$route(
  path: '/auth/phone',
  hasOverriddenOnExit: false,
  factory: $PhoneSignInRoute._fromState,
);

mixin $PhoneSignInRoute on GoRouteData {
  static PhoneSignInRoute _fromState(GoRouterState state) =>
      const PhoneSignInRoute();

  @override
  String get location => GoRouteData.$location('/auth/phone');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $otpVerificationRoute => GoRouteData.$route(
  path: '/auth/otp',
  hasOverriddenOnExit: false,
  factory: $OtpVerificationRoute._fromState,
);

mixin $OtpVerificationRoute on GoRouteData {
  static OtpVerificationRoute _fromState(GoRouterState state) =>
      const OtpVerificationRoute();

  @override
  String get location => GoRouteData.$location('/auth/otp');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $registrationRoute => GoRouteData.$route(
  path: '/auth/register',
  hasOverriddenOnExit: false,
  factory: $RegistrationRoute._fromState,
);

mixin $RegistrationRoute on GoRouteData {
  static RegistrationRoute _fromState(GoRouterState state) =>
      const RegistrationRoute();

  @override
  String get location => GoRouteData.$location('/auth/register');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $sessionUnavailableRoute => GoRouteData.$route(
  path: '/session-unavailable',
  hasOverriddenOnExit: false,
  factory: $SessionUnavailableRoute._fromState,
);

mixin $SessionUnavailableRoute on GoRouteData {
  static SessionUnavailableRoute _fromState(GoRouterState state) =>
      const SessionUnavailableRoute();

  @override
  String get location => GoRouteData.$location('/session-unavailable');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $customerHomeRoute => GoRouteData.$route(
  path: '/customer',
  hasOverriddenOnExit: false,
  factory: $CustomerHomeRoute._fromState,
);

mixin $CustomerHomeRoute on GoRouteData {
  static CustomerHomeRoute _fromState(GoRouterState state) =>
      const CustomerHomeRoute();

  @override
  String get location => GoRouteData.$location('/customer');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $providerHomeRoute => GoRouteData.$route(
  path: '/provider',
  hasOverriddenOnExit: false,
  factory: $ProviderHomeRoute._fromState,
);

mixin $ProviderHomeRoute on GoRouteData {
  static ProviderHomeRoute _fromState(GoRouterState state) =>
      const ProviderHomeRoute();

  @override
  String get location => GoRouteData.$location('/provider');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}
