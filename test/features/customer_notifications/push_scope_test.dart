import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:octogear/app/routing/app_router.dart';
import 'package:octogear/features/customer_chats/presentation/controllers/chat_realtime_providers.dart';
import 'package:octogear/app/routing/app_routes.dart';
import 'package:octogear/core/localization/app_locale_controller.dart';
import 'package:octogear/core/localization/app_locale.dart';
import 'package:octogear/core/storage/app_storage.dart';
import 'package:octogear/core/storage/storage_providers.dart';
import 'package:octogear/features/authentication/domain/entities/app_user.dart';
import 'package:octogear/features/authentication/domain/entities/session_outcome.dart';
import 'package:octogear/features/authentication/presentation/controllers/session_controller.dart';
import 'package:octogear/features/notifications/data/models/push_notification_dto.dart';
import 'package:octogear/features/notifications/presentation/controllers/notification_providers.dart';
import 'package:octogear/features/notifications/presentation/controllers/push_providers.dart';
import 'package:octogear/features/notifications/presentation/widgets/push_delivery_scope.dart';

import '../customer_chats/chat_screen_test.dart' show Translations;
import 'notification_fixtures.dart';
import 'push_delivery_test.dart' show FakePushRepository, payload;

class PushTestLocale extends AppLocaleController {
  @override
  AppLocale build() => AppLocale.english;

  @override
  Future<void> select(AppLocale locale) async {
    state = locale;
  }
}

class PushTestSession extends SessionController {
  @override
  Future<SessionOutcome> build() async => const AuthenticatedSession(
    AppUser(
      id: 1,
      fullName: 'Customer',
      mobile: '+966500000001',
      role: AppUserRole.customer,
    ),
  );
}

class ProviderPushTestSession extends SessionController {
  @override
  Future<SessionOutcome> build() async => const AuthenticatedSession(
    AppUser(
      id: 1,
      fullName: 'Provider',
      mobile: '+966500000001',
      role: AppUserRole.provider,
    ),
  );
}

class PushTestStorage implements SessionStorage {
  @override
  String? cachedAccessToken = 'session-one';
  @override
  Future<String?> readAccessToken() async => cachedAccessToken;
  @override
  Future<void> saveAccessToken(String value) async {
    cachedAccessToken = value;
  }

  @override
  Future<void> clearSession() async {
    cachedAccessToken = null;
  }
}

class PushTestApp extends StatelessWidget {
  const PushTestApp(this.router, {super.key});
  final GoRouter router;
  @override
  Widget build(BuildContext context) => MaterialApp.router(
    routerConfig: router,
    locale: context.locale,
    supportedLocales: context.supportedLocales,
    localizationsDelegates: context.localizationDelegates,
    builder: (_, child) => PushDeliveryScope(child: child!),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final provider in [false, true]) {
    testWidgets(
      'foreground banner opens typed destination without inbox fetch; provider: $provider',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        await EasyLocalization.ensureInitialized();
        final translations = <String, Map<String, dynamic>>{};
        await tester.runAsync(() async {
          for (final language in ['en', 'ar']) {
            translations[language] =
                jsonDecode(
                      await rootBundle.loadString(
                        'assets/translations/$language.json',
                      ),
                    )
                    as Map<String, dynamic>;
          }
        });
        Map<String, dynamic> event({String recipient = '1'}) => {
          ...payload(recipient: recipient),
          if (provider) 'type': 'offer_accepted',
        };
        final banner = provider
            ? 'A customer accepted your offer.'
            : 'You have a new offer.';
        final push = FakePushRepository();
        final inbox = FakeNotificationsRepository();
        final router = GoRouter(
          routes: [
            GoRoute(
              path: '/',
              builder: (_, _) => const Scaffold(body: Text('Home')),
            ),
            GoRoute(
              path: provider
                  ? const ProviderOfferRoute(offerId: 42).location
                  : const CustomerOfferDetailsRoute(
                      orderId: 17,
                      offerId: 42,
                    ).location,
              builder: (_, _) =>
                  const Scaffold(body: Text('Offer destination')),
            ),
          ],
        );
        addTearDown(router.dispose);
        addTearDown(push.dispose);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sessionControllerProvider.overrideWith(
                provider ? ProviderPushTestSession.new : PushTestSession.new,
              ),
              sessionStorageProvider.overrideWithValue(PushTestStorage()),
              appLocaleProvider.overrideWith(PushTestLocale.new),
              appRouterProvider.overrideWithValue(router),
              chatRealtimeUpdatesProvider.overrideWith(
                (_) => const Stream.empty(),
              ),
              pushRepositoryProvider.overrideWithValue(push),
              notificationsRepositoryProvider.overrideWithValue(inbox),
            ],
            child: EasyLocalization(
              supportedLocales: const [Locale('en'), Locale('ar')],
              path: 'assets/translations',
              startLocale: const Locale('en'),
              saveLocale: false,
              assetLoader: Translations(translations),
              child: PushTestApp(router),
            ),
          ),
        );
        await tester.pumpAndSettle();
        // Startup counts load even without a bell on this deep-link landing page.
        expect(inbox.countCalls, 1);
        final container = ProviderScope.containerOf(
          tester.element(find.byType(PushDeliveryScope)),
        );
        expect(container.read(notificationCountProvider).requireValue, 2);
        await container.read(appLocaleProvider.notifier).toggle();
        await tester.pumpAndSettle();
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await tester.pumpAndSettle();
        expect(inbox.countCalls, 1);
        push.foregroundEvents.add(
          parsePushNotification(event(recipient: '2'))!,
        );
        await tester.pumpAndSettle();
        expect(find.text(banner), findsNothing);
        push.foregroundEvents.add(parsePushNotification(event())!);
        await tester.pumpAndSettle();
        expect(find.text(banner), findsOneWidget);
        expect(inbox.pageCalls, 0);
        expect(inbox.countCalls, 1);
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
        expect(find.text('Offer destination'), findsOneWidget);
        expect(inbox.readCalls, 1);
        expect(inbox.pageCalls, 0);
        expect(inbox.countCalls, 1);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
      },
    );
  }
}
