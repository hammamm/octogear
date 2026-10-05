import '../../features/customer_chats/domain/chat.dart';
import '../../features/customer_chats/presentation/screens/chat_conversation_screen.dart';
import '../../features/customer_orders/presentation/screens/edit_customer_order_screen.dart';
import '../../features/customer_orders/presentation/screens/customer_offer_details_screen.dart';
import '../../features/customer_orders/presentation/screens/refuse_customer_offer_screen.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/design_system/octogear_theme.dart';
import '../../features/customer_home/presentation/screens/customer_home_screen.dart';
import '../../core/routing/app_route_paths.dart';
import '../../core/widgets/octogear_brand_header.dart';
import '../../core/widgets/octogear_page_scaffold.dart';
import '../../core/widgets/octogear_surface_card.dart';
import '../../features/authentication/presentation/screens/otp_verification_screen.dart';
import '../../features/authentication/presentation/screens/phone_sign_in_screen.dart';
import '../../features/authentication/presentation/screens/registration_screen.dart';
import '../../features/authentication/presentation/screens/session_loading_screen.dart';
import '../../features/authentication/presentation/screens/session_unavailable_screen.dart';
import '../../features/customer_garage/presentation/screens/create_customer_car_screen.dart';
import '../../features/customer_garage/presentation/screens/customer_car_details_screen.dart';
import '../../features/customer_garage/presentation/screens/customer_cars_screen.dart';
import '../../features/customer_garage/presentation/screens/edit_customer_car_screen.dart';
import '../../features/part_requests/presentation/screens/request_part_screen.dart';
import '../../features/general_requests/presentation/screens/general_part_request_screen.dart';
import '../../features/customer_orders/presentation/screens/customer_orders_screen.dart';
import '../../features/customer_orders/presentation/screens/customer_order_details_screen.dart';
import '../../features/storefront/presentation/screens/customer_storefront_screen.dart';
import '../../features/storefront/presentation/screens/customer_store_details_screen.dart';
import '../../features/storefront/presentation/screens/customer_store_car_screen.dart';
import '../shells/customer_app_shell.dart';
import '../../features/customer_more/presentation/screens/customer_more_screen.dart';
import '../../features/customer_chats/presentation/screens/customer_chats_screen.dart';
import '../shells/role_app_shell.dart';

part 'app_routes.g.dart';

@TypedGoRoute<SessionLoadingRoute>(path: AppRoutePath.sessionLoading)
class SessionLoadingRoute extends GoRouteData with $SessionLoadingRoute {
  const SessionLoadingRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const SessionLoadingScreen();
  }
}

@TypedGoRoute<PhoneSignInRoute>(path: AppRoutePath.phoneSignIn)
class PhoneSignInRoute extends GoRouteData with $PhoneSignInRoute {
  const PhoneSignInRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const PhoneSignInScreen();
  }
}

@TypedGoRoute<OtpVerificationRoute>(path: AppRoutePath.otpVerification)
class OtpVerificationRoute extends GoRouteData with $OtpVerificationRoute {
  const OtpVerificationRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const OtpVerificationScreen();
  }
}

@TypedGoRoute<RegistrationRoute>(path: AppRoutePath.registration)
class RegistrationRoute extends GoRouteData with $RegistrationRoute {
  const RegistrationRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const RegistrationScreen();
  }
}

@TypedGoRoute<SessionUnavailableRoute>(path: AppRoutePath.sessionUnavailable)
class SessionUnavailableRoute extends GoRouteData
    with $SessionUnavailableRoute {
  const SessionUnavailableRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const SessionUnavailableScreen();
  }
}

@TypedStatefulShellRoute<CustomerShellRoute>(
  branches: <TypedStatefulShellBranch<StatefulShellBranchData>>[
    TypedStatefulShellBranch<CustomerHomeBranch>(
      routes: <TypedRoute<RouteData>>[
        TypedGoRoute<CustomerHomeRoute>(
          path: AppRoutePath.customerHome,
          routes: [
            TypedGoRoute<GeneralPartRequestRoute>(
              path: AppRoutePath.customerGeneralRequestSegment,
            ),
          ],
        ),
      ],
    ),
    TypedStatefulShellBranch<CustomerStoresBranch>(
      routes: <TypedRoute<RouteData>>[
        TypedGoRoute<CustomerStoresRoute>(
          path: AppRoutePath.customerStores,
          routes: <TypedRoute<RouteData>>[
            TypedGoRoute<CustomerStoreDetailsRoute>(
              path: AppRoutePath.customerStoreDetailsSegment,
              routes: <TypedRoute<RouteData>>[
                TypedGoRoute<CustomerStoreCarRoute>(
                  path: AppRoutePath.customerStoreCarSegment,
                  routes: <TypedRoute<RouteData>>[
                    TypedGoRoute<CustomerPartRequestRoute>(
                      path: AppRoutePath.customerPartRequestSegment,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    ),
    TypedStatefulShellBranch<CustomerOrdersBranch>(
      routes: <TypedRoute<RouteData>>[
        TypedGoRoute<CustomerOrdersRoute>(
          path: AppRoutePath.customerOrders,
          routes: [
            TypedGoRoute<CustomerOrderDetailsRoute>(
              path: AppRoutePath.customerOrderDetailsSegment,
              routes: [
                TypedGoRoute<EditCustomerOrderRoute>(
                  path: AppRoutePath.customerOrderEditSegment,
                ),
                TypedGoRoute<CustomerOfferDetailsRoute>(
                  path: AppRoutePath.customerOfferDetailsSegment,
                  routes: [
                    TypedGoRoute<RefuseCustomerOfferRoute>(
                      path: AppRoutePath.customerOfferRefuseSegment,
                    ),
                    TypedGoRoute<CustomerOfferChatRoute>(path: 'chat'),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    ),
    TypedStatefulShellBranch<CustomerChatsBranch>(
      routes: [
        TypedGoRoute<CustomerChatsRoute>(
          path: AppRoutePath.customerChats,
          routes: [
            TypedGoRoute<CustomerConversationRoute>(path: ':conversationId'),
          ],
        ),
      ],
    ),
    TypedStatefulShellBranch<CustomerMoreBranch>(
      routes: <TypedRoute<RouteData>>[
        TypedGoRoute<CustomerMoreRoute>(
          path: AppRoutePath.customerMore,
          routes: <TypedRoute<RouteData>>[
            TypedGoRoute<CustomerProfileRoute>(path: 'profile'),
            TypedGoRoute<CustomerSettingsRoute>(path: 'settings'),
            TypedGoRoute<CustomerCarsRoute>(
              path: 'cars',
              routes: <TypedRoute<RouteData>>[
                TypedGoRoute<CreateCustomerCarRoute>(
                  path: AppRoutePath.customerCarsAddSegment,
                ),
                TypedGoRoute<CustomerCarDetailsRoute>(
                  path: AppRoutePath.customerCarsDetailsSegment,
                  routes: <TypedRoute<RouteData>>[
                    TypedGoRoute<CustomerCarEditRoute>(
                      path: AppRoutePath.customerCarsEditSegment,
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
)
class CustomerShellRoute extends StatefulShellRouteData {
  const CustomerShellRoute();

  @override
  Widget builder(
    BuildContext context,
    GoRouterState state,
    StatefulNavigationShell navigationShell,
  ) {
    return CustomerAppShell(navigationShell: navigationShell);
  }
}

class CustomerHomeBranch extends StatefulShellBranchData {
  const CustomerHomeBranch();
}

class CustomerStoresBranch extends StatefulShellBranchData {
  const CustomerStoresBranch();
}

class CustomerOrdersBranch extends StatefulShellBranchData {
  const CustomerOrdersBranch();
}

class CustomerChatsBranch extends StatefulShellBranchData {
  const CustomerChatsBranch();
}

class CustomerMoreBranch extends StatefulShellBranchData {
  const CustomerMoreBranch();
}

class CustomerHomeRoute extends GoRouteData with $CustomerHomeRoute {
  const CustomerHomeRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const CustomerHomeScreen();
  }
}

class CustomerStoresRoute extends GoRouteData with $CustomerStoresRoute {
  const CustomerStoresRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const CustomerStorefrontScreen();
  }
}

/// A store ID is the only navigation input; this route refetches current,
/// customer-safe store information and inventory from Laravel.
class CustomerStoreDetailsRoute extends GoRouteData
    with $CustomerStoreDetailsRoute {
  const CustomerStoreDetailsRoute({required this.storeId});

  final int storeId;

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return CustomerStoreDetailsScreen(storeId: storeId);
  }
}

class CustomerStoreCarRoute extends GoRouteData with $CustomerStoreCarRoute {
  const CustomerStoreCarRoute({required this.storeId, required this.carId});
  final int storeId;
  final int carId;
  @override
  Widget build(BuildContext context, GoRouterState state) =>
      CustomerStoreCarScreen(storeId: storeId, carId: carId);
}

class CustomerPartRequestRoute extends GoRouteData
    with $CustomerPartRequestRoute {
  const CustomerPartRequestRoute({
    required this.storeId,
    required this.carId,
    required this.componentId,
  });
  final int storeId;
  final int carId;
  final int componentId;
  @override
  Widget build(BuildContext context, GoRouterState state) => RequestPartScreen(
    requestKey: (storeId: storeId, carId: carId, componentId: componentId),
  );
}

class CustomerOrdersRoute extends GoRouteData with $CustomerOrdersRoute {
  const CustomerOrdersRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const CustomerOrdersScreen();
  }
}

class CustomerOrderDetailsRoute extends GoRouteData
    with $CustomerOrderDetailsRoute {
  const CustomerOrderDetailsRoute({required this.orderId});
  final int orderId;
  @override
  Widget build(BuildContext context, GoRouterState state) =>
      CustomerOrderDetailsScreen(orderId: orderId);
}

@TypedGoRoute<CustomerAccountRoute>(path: AppRoutePath.customerAccount)
class CustomerAccountRoute extends GoRouteData with $CustomerAccountRoute {
  const CustomerAccountRoute();

  @override
  String redirect(BuildContext context, GoRouterState state) =>
      const CustomerMoreRoute().location;
}

class CustomerMoreRoute extends GoRouteData with $CustomerMoreRoute {
  const CustomerMoreRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const CustomerMoreScreen();
}

class CustomerProfileRoute extends GoRouteData with $CustomerProfileRoute {
  const CustomerProfileRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const CustomerProfileScreen();
}

class CustomerSettingsRoute extends GoRouteData with $CustomerSettingsRoute {
  const CustomerSettingsRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const CustomerSettingsScreen();
}

class CustomerChatsRoute extends GoRouteData with $CustomerChatsRoute {
  const CustomerChatsRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const CustomerChatsScreen();
  }
}

/// A child flow of More, so the customer can return to their menu after
/// reviewing saved cars while the customer shell remains in place.
class CustomerCarsRoute extends GoRouteData with $CustomerCarsRoute {
  const CustomerCarsRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const CustomerCarsScreen();
  }
}

/// A short child flow of My Cars. It returns `true` only after Laravel has
/// confirmed a created car, so the parent can refresh its server-backed list.
class CreateCustomerCarRoute extends GoRouteData with $CreateCustomerCarRoute {
  const CreateCustomerCarRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const CreateCustomerCarScreen();
  }
}

/// Authoritative detail route for one saved car. Keeping the identifier in the
/// URL makes it deep-linkable and lets the screen refetch server truth instead
/// of accepting a potentially stale list object.
class CustomerCarDetailsRoute extends GoRouteData
    with $CustomerCarDetailsRoute {
  const CustomerCarDetailsRoute({required this.carId});

  final int carId;

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return CustomerCarDetailsScreen(carId: carId);
  }
}

class CustomerCarEditRoute extends GoRouteData with $CustomerCarEditRoute {
  const CustomerCarEditRoute({required this.carId});

  final int carId;

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return EditCustomerCarScreen(carId: carId);
  }
}

@TypedGoRoute<ProviderHomeRoute>(
  path: AppRoutePath.providerHome,
  routes: [
    TypedGoRoute<ProviderChatsRoute>(
      path: 'chats',
      routes: [
        TypedGoRoute<ProviderConversationRoute>(path: ':conversationId'),
      ],
    ),
  ],
)
class ProviderHomeRoute extends GoRouteData with $ProviderHomeRoute {
  const ProviderHomeRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const ProviderAppShell();
  }
}

class UnknownRouteScreen extends StatelessWidget {
  const UnknownRouteScreen({this.error, super.key});

  final Exception? error;

  @override
  Widget build(BuildContext context) {
    return OctoGearPageScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: OctoGearSpacing.xLarge),
          const OctoGearBrandHeader(compact: true),
          const SizedBox(height: 56),
          OctoGearSurfaceCard(
            child: Column(
              children: [
                Container(
                  height: 64,
                  width: 64,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: OctoGearColors.yellowSoft,
                    borderRadius: BorderRadius.circular(OctoGearRadii.medium),
                  ),
                  child: const Icon(
                    Icons.explore_off_outlined,
                    color: OctoGearColors.navy,
                    size: 32,
                  ),
                ),
                const SizedBox(height: OctoGearSpacing.large),
                Text(
                  context.tr('routing.not_found'),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class GeneralPartRequestRoute extends GoRouteData
    with $GeneralPartRequestRoute {
  const GeneralPartRequestRoute();
  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const GeneralPartRequestScreen();
}

class CustomerOfferDetailsRoute extends GoRouteData
    with $CustomerOfferDetailsRoute {
  const CustomerOfferDetailsRoute({
    required this.orderId,
    required this.offerId,
  });
  final int orderId, offerId;
  @override
  Widget build(BuildContext context, GoRouterState state) =>
      CustomerOfferDetailsScreen(orderId: orderId, offerId: offerId);
}

class RefuseCustomerOfferRoute extends GoRouteData
    with $RefuseCustomerOfferRoute {
  const RefuseCustomerOfferRoute({
    required this.orderId,
    required this.offerId,
  });
  final int orderId, offerId;
  @override
  Widget build(BuildContext context, GoRouterState state) =>
      RefuseCustomerOfferScreen(orderId: orderId, offerId: offerId);
}

class EditCustomerOrderRoute extends GoRouteData with $EditCustomerOrderRoute {
  const EditCustomerOrderRoute({required this.orderId});
  final int orderId;
  @override
  Widget build(BuildContext context, GoRouterState state) =>
      EditCustomerOrderScreen(orderId: orderId);
}

class CustomerOfferChatRoute extends GoRouteData with $CustomerOfferChatRoute {
  const CustomerOfferChatRoute({required this.orderId, required this.offerId});
  final int orderId, offerId;
  @override
  Widget build(BuildContext context, GoRouterState state) =>
      ChatConversationScreen(target: ChatTarget.offer(orderId, offerId));
}

class CustomerConversationRoute extends GoRouteData
    with $CustomerConversationRoute {
  const CustomerConversationRoute({required this.conversationId});
  final int conversationId;
  @override
  Widget build(BuildContext context, GoRouterState state) =>
      ChatConversationScreen(target: ChatTarget.conversation(conversationId));
}

class ProviderChatsRoute extends GoRouteData with $ProviderChatsRoute {
  const ProviderChatsRoute();
  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const CustomerChatsScreen(provider: true);
}

class ProviderConversationRoute extends GoRouteData
    with $ProviderConversationRoute {
  const ProviderConversationRoute({required this.conversationId});
  final int conversationId;
  @override
  Widget build(BuildContext context, GoRouterState state) =>
      ChatConversationScreen(
        target: ChatTarget.conversation(conversationId),
        provider: true,
      );
}
