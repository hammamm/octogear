import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/design_system/octogear_theme.dart';
import '../../core/routing/app_route_paths.dart';
import '../../core/widgets/octogear_brand_header.dart';
import '../../core/widgets/octogear_page_scaffold.dart';
import '../../core/widgets/octogear_surface_card.dart';
import '../../features/authentication/presentation/screens/otp_verification_screen.dart';
import '../../features/authentication/presentation/screens/phone_sign_in_screen.dart';
import '../../features/authentication/presentation/screens/registration_screen.dart';
import '../../features/authentication/presentation/screens/session_loading_screen.dart';
import '../../features/authentication/presentation/screens/session_unavailable_screen.dart';
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

@TypedGoRoute<CustomerHomeRoute>(path: AppRoutePath.customerHome)
class CustomerHomeRoute extends GoRouteData with $CustomerHomeRoute {
  const CustomerHomeRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const CustomerAppShell();
  }
}

@TypedGoRoute<ProviderHomeRoute>(path: AppRoutePath.providerHome)
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
