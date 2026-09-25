import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/routing/app_route_paths.dart';
import '../../core/service/app_logger.dart';
import '../../features/authentication/domain/entities/session_outcome.dart';
import '../../features/authentication/presentation/controllers/authentication_flow_controller.dart';
import '../../features/authentication/presentation/controllers/session_controller.dart';
import 'app_routes.dart';
import 'session_route_guard.dart';

/// The single router for OctoGear. Feature widgets never own global session or
/// role redirects; they request a typed route and this router applies policy.
final appRouterProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = _RouteRefreshNotifier(ref);
  ref.onDispose(refreshNotifier.dispose);

  return GoRouter(
    initialLocation: AppRoutePath.sessionLoading,
    routes: $appRoutes,
    observers: [AppRouteObserver()],
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      return redirectForSession(
        session: ref.read(sessionControllerProvider),
        authenticationFlow: ref.read(authenticationFlowProvider),
        currentPath: state.uri.path,
      );
    },
    errorBuilder: (context, state) => UnknownRouteScreen(error: state.error),
  );
});

/// Converts Riverpod changes into GoRouter redirect checks. `Ref` owns both
/// subscriptions, while this notifier is disposed with the router provider.
class _RouteRefreshNotifier extends ChangeNotifier {
  _RouteRefreshNotifier(Ref ref) {
    ref.listen<AsyncValue<SessionOutcome>>(
      sessionControllerProvider,
      (_, _) => notifyListeners(),
      fireImmediately: true,
    );
    ref.listen<AuthenticationFlowState>(
      authenticationFlowProvider,
      (_, _) => notifyListeners(),
    );
  }
}
