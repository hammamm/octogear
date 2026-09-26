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
  $customerShellRoute,
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

RouteBase get $customerShellRoute => StatefulShellRouteData.$route(
  factory: $CustomerShellRouteExtension._fromState,
  branches: [
    StatefulShellBranchData.$branch(
      routes: [
        GoRouteData.$route(
          path: '/customer',
          hasOverriddenOnExit: false,
          factory: $CustomerHomeRoute._fromState,
        ),
      ],
    ),
    StatefulShellBranchData.$branch(
      routes: [
        GoRouteData.$route(
          path: '/customer/stores',
          hasOverriddenOnExit: false,
          factory: $CustomerStoresRoute._fromState,
        ),
      ],
    ),
    StatefulShellBranchData.$branch(
      routes: [
        GoRouteData.$route(
          path: '/customer/orders',
          hasOverriddenOnExit: false,
          factory: $CustomerOrdersRoute._fromState,
        ),
      ],
    ),
    StatefulShellBranchData.$branch(
      routes: [
        GoRouteData.$route(
          path: '/customer/account',
          hasOverriddenOnExit: false,
          factory: $CustomerAccountRoute._fromState,
        ),
      ],
    ),
  ],
);

extension $CustomerShellRouteExtension on CustomerShellRoute {
  static CustomerShellRoute _fromState(GoRouterState state) =>
      const CustomerShellRoute();
}

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

mixin $CustomerStoresRoute on GoRouteData {
  static CustomerStoresRoute _fromState(GoRouterState state) =>
      const CustomerStoresRoute();

  @override
  String get location => GoRouteData.$location('/customer/stores');

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

mixin $CustomerOrdersRoute on GoRouteData {
  static CustomerOrdersRoute _fromState(GoRouterState state) =>
      const CustomerOrdersRoute();

  @override
  String get location => GoRouteData.$location('/customer/orders');

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

mixin $CustomerAccountRoute on GoRouteData {
  static CustomerAccountRoute _fromState(GoRouterState state) =>
      const CustomerAccountRoute();

  @override
  String get location => GoRouteData.$location('/customer/account');

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
