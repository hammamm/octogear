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
  $customerAccountRoute,
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
          routes: [
            GoRouteData.$route(
              path: 'request',
              hasOverriddenOnExit: false,
              factory: $GeneralPartRequestRoute._fromState,
            ),
          ],
        ),
      ],
    ),
    StatefulShellBranchData.$branch(
      routes: [
        GoRouteData.$route(
          path: '/customer/stores',
          hasOverriddenOnExit: false,
          factory: $CustomerStoresRoute._fromState,
          routes: [
            GoRouteData.$route(
              path: ':storeId',
              hasOverriddenOnExit: false,
              factory: $CustomerStoreDetailsRoute._fromState,
              routes: [
                GoRouteData.$route(
                  path: 'cars/:carId',
                  hasOverriddenOnExit: false,
                  factory: $CustomerStoreCarRoute._fromState,
                  routes: [
                    GoRouteData.$route(
                      path: 'components/:componentId/request',
                      hasOverriddenOnExit: false,
                      factory: $CustomerPartRequestRoute._fromState,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    ),
    StatefulShellBranchData.$branch(
      routes: [
        GoRouteData.$route(
          path: '/customer/orders',
          hasOverriddenOnExit: false,
          factory: $CustomerOrdersRoute._fromState,
          routes: [
            GoRouteData.$route(
              path: ':orderId',
              hasOverriddenOnExit: false,
              factory: $CustomerOrderDetailsRoute._fromState,
              routes: [
                GoRouteData.$route(
                  path: 'offers/:offerId',
                  hasOverriddenOnExit: false,
                  factory: $CustomerOfferDetailsRoute._fromState,
                  routes: [
                    GoRouteData.$route(
                      path: 'refuse',
                      hasOverriddenOnExit: false,
                      factory: $RefuseCustomerOfferRoute._fromState,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    ),
    StatefulShellBranchData.$branch(
      routes: [
        GoRouteData.$route(
          path: '/customer/chats',
          hasOverriddenOnExit: false,
          factory: $CustomerChatsRoute._fromState,
        ),
      ],
    ),
    StatefulShellBranchData.$branch(
      routes: [
        GoRouteData.$route(
          path: '/customer/more',
          hasOverriddenOnExit: false,
          factory: $CustomerMoreRoute._fromState,
          routes: [
            GoRouteData.$route(
              path: 'profile',
              hasOverriddenOnExit: false,
              factory: $CustomerProfileRoute._fromState,
            ),
            GoRouteData.$route(
              path: 'settings',
              hasOverriddenOnExit: false,
              factory: $CustomerSettingsRoute._fromState,
            ),
            GoRouteData.$route(
              path: 'cars',
              hasOverriddenOnExit: false,
              factory: $CustomerCarsRoute._fromState,
              routes: [
                GoRouteData.$route(
                  path: 'add',
                  hasOverriddenOnExit: false,
                  factory: $CreateCustomerCarRoute._fromState,
                ),
                GoRouteData.$route(
                  path: ':carId',
                  hasOverriddenOnExit: false,
                  factory: $CustomerCarDetailsRoute._fromState,
                  routes: [
                    GoRouteData.$route(
                      path: 'edit',
                      hasOverriddenOnExit: false,
                      factory: $CustomerCarEditRoute._fromState,
                    ),
                  ],
                ),
              ],
            ),
          ],
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

mixin $GeneralPartRequestRoute on GoRouteData {
  static GeneralPartRequestRoute _fromState(GoRouterState state) =>
      const GeneralPartRequestRoute();

  @override
  String get location => GoRouteData.$location('/customer/request');

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

mixin $CustomerStoreDetailsRoute on GoRouteData {
  static CustomerStoreDetailsRoute _fromState(GoRouterState state) =>
      CustomerStoreDetailsRoute(
        storeId: int.parse(state.pathParameters['storeId']!),
      );

  CustomerStoreDetailsRoute get _self => this as CustomerStoreDetailsRoute;

  @override
  String get location => GoRouteData.$location(
    '/customer/stores/${Uri.encodeComponent(_self.storeId.toString())}',
  );

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

mixin $CustomerStoreCarRoute on GoRouteData {
  static CustomerStoreCarRoute _fromState(GoRouterState state) =>
      CustomerStoreCarRoute(
        storeId: int.parse(state.pathParameters['storeId']!),
        carId: int.parse(state.pathParameters['carId']!),
      );

  CustomerStoreCarRoute get _self => this as CustomerStoreCarRoute;

  @override
  String get location => GoRouteData.$location(
    '/customer/stores/${Uri.encodeComponent(_self.storeId.toString())}/cars/${Uri.encodeComponent(_self.carId.toString())}',
  );

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

mixin $CustomerPartRequestRoute on GoRouteData {
  static CustomerPartRequestRoute _fromState(GoRouterState state) =>
      CustomerPartRequestRoute(
        storeId: int.parse(state.pathParameters['storeId']!),
        carId: int.parse(state.pathParameters['carId']!),
        componentId: int.parse(state.pathParameters['componentId']!),
      );

  CustomerPartRequestRoute get _self => this as CustomerPartRequestRoute;

  @override
  String get location => GoRouteData.$location(
    '/customer/stores/${Uri.encodeComponent(_self.storeId.toString())}/cars/${Uri.encodeComponent(_self.carId.toString())}/components/${Uri.encodeComponent(_self.componentId.toString())}/request',
  );

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

mixin $CustomerOrderDetailsRoute on GoRouteData {
  static CustomerOrderDetailsRoute _fromState(GoRouterState state) =>
      CustomerOrderDetailsRoute(
        orderId: int.parse(state.pathParameters['orderId']!),
      );

  CustomerOrderDetailsRoute get _self => this as CustomerOrderDetailsRoute;

  @override
  String get location => GoRouteData.$location(
    '/customer/orders/${Uri.encodeComponent(_self.orderId.toString())}',
  );

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

mixin $CustomerOfferDetailsRoute on GoRouteData {
  static CustomerOfferDetailsRoute _fromState(GoRouterState state) =>
      CustomerOfferDetailsRoute(
        orderId: int.parse(state.pathParameters['orderId']!),
        offerId: int.parse(state.pathParameters['offerId']!),
      );

  CustomerOfferDetailsRoute get _self => this as CustomerOfferDetailsRoute;

  @override
  String get location => GoRouteData.$location(
    '/customer/orders/${Uri.encodeComponent(_self.orderId.toString())}/offers/${Uri.encodeComponent(_self.offerId.toString())}',
  );

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

mixin $RefuseCustomerOfferRoute on GoRouteData {
  static RefuseCustomerOfferRoute _fromState(GoRouterState state) =>
      RefuseCustomerOfferRoute(
        orderId: int.parse(state.pathParameters['orderId']!),
        offerId: int.parse(state.pathParameters['offerId']!),
      );

  RefuseCustomerOfferRoute get _self => this as RefuseCustomerOfferRoute;

  @override
  String get location => GoRouteData.$location(
    '/customer/orders/${Uri.encodeComponent(_self.orderId.toString())}/offers/${Uri.encodeComponent(_self.offerId.toString())}/refuse',
  );

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

mixin $CustomerChatsRoute on GoRouteData {
  static CustomerChatsRoute _fromState(GoRouterState state) =>
      const CustomerChatsRoute();

  @override
  String get location => GoRouteData.$location('/customer/chats');

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

mixin $CustomerMoreRoute on GoRouteData {
  static CustomerMoreRoute _fromState(GoRouterState state) =>
      const CustomerMoreRoute();

  @override
  String get location => GoRouteData.$location('/customer/more');

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

mixin $CustomerProfileRoute on GoRouteData {
  static CustomerProfileRoute _fromState(GoRouterState state) =>
      const CustomerProfileRoute();

  @override
  String get location => GoRouteData.$location('/customer/more/profile');

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

mixin $CustomerSettingsRoute on GoRouteData {
  static CustomerSettingsRoute _fromState(GoRouterState state) =>
      const CustomerSettingsRoute();

  @override
  String get location => GoRouteData.$location('/customer/more/settings');

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

mixin $CustomerCarsRoute on GoRouteData {
  static CustomerCarsRoute _fromState(GoRouterState state) =>
      const CustomerCarsRoute();

  @override
  String get location => GoRouteData.$location('/customer/more/cars');

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

mixin $CreateCustomerCarRoute on GoRouteData {
  static CreateCustomerCarRoute _fromState(GoRouterState state) =>
      const CreateCustomerCarRoute();

  @override
  String get location => GoRouteData.$location('/customer/more/cars/add');

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

mixin $CustomerCarDetailsRoute on GoRouteData {
  static CustomerCarDetailsRoute _fromState(GoRouterState state) =>
      CustomerCarDetailsRoute(carId: int.parse(state.pathParameters['carId']!));

  CustomerCarDetailsRoute get _self => this as CustomerCarDetailsRoute;

  @override
  String get location => GoRouteData.$location(
    '/customer/more/cars/${Uri.encodeComponent(_self.carId.toString())}',
  );

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

mixin $CustomerCarEditRoute on GoRouteData {
  static CustomerCarEditRoute _fromState(GoRouterState state) =>
      CustomerCarEditRoute(carId: int.parse(state.pathParameters['carId']!));

  CustomerCarEditRoute get _self => this as CustomerCarEditRoute;

  @override
  String get location => GoRouteData.$location(
    '/customer/more/cars/${Uri.encodeComponent(_self.carId.toString())}/edit',
  );

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

RouteBase get $customerAccountRoute => GoRouteData.$route(
  path: '/customer/account',
  hasOverriddenOnExit: false,
  factory: $CustomerAccountRoute._fromState,
);

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
