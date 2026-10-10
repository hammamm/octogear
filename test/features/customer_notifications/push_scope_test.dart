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
import 'package:octogear/core/storage/app_storage.dart';
import 'package:octogear/core/storage/storage_providers.dart';
import 'package:octogear/features/authentication/domain/entities/app_user.dart';
import 'package:octogear/features/authentication/domain/entities/session_outcome.dart';
import 'package:octogear/features/authentication/presentation/controllers/session_controller.dart';
import 'package:octogear/features/customer_notifications/data/models/push_notification_dto.dart';
import 'package:octogear/features/customer_notifications/presentation/controllers/notification_providers.dart';
import 'package:octogear/features/customer_notifications/presentation/controllers/push_providers.dart';
import 'package:octogear/features/customer_notifications/presentation/widgets/push_delivery_scope.dart';

import '../customer_chats/chat_screen_test.dart' show English, Translations;
import 'notification_fixtures.dart';
import 'push_delivery_test.dart' show FakePushRepository, payload;

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
  testWidgets(
    'foreground banner opens the typed destination without fetching an inbox',
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
      final push = FakePushRepository();
      final inbox = FakeNotificationsRepository();
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => const Scaffold(body: Text('Home')),
          ),
          GoRoute(
            path: const CustomerOfferDetailsRoute(
              orderId: 17,
              offerId: 42,
            ).location,
            builder: (_, _) => const Scaffold(body: Text('Offer destination')),
          ),
        ],
      );
      addTearDown(router.dispose);
      addTearDown(push.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sessionControllerProvider.overrideWith(PushTestSession.new),
            sessionStorageProvider.overrideWithValue(PushTestStorage()),
            appLocaleProvider.overrideWith(English.new),
            appRouterProvider.overrideWithValue(router),
            chatRealtimeUpdatesProvider.overrideWith(
              (_) => const Stream.empty(),
            ),
            pushRepositoryProvider.overrideWithValue(push),
            customerNotificationsRepositoryProvider.overrideWithValue(inbox),
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
      push.foregroundEvents.add(
        parsePushNotification(payload(recipient: '2'))!,
      );
      await tester.pumpAndSettle();
      expect(find.text('You have a new offer.'), findsNothing);
      push.foregroundEvents.add(parsePushNotification(payload())!);
      await tester.pumpAndSettle();
      expect(find.text('You have a new offer.'), findsOneWidget);
      expect(inbox.pageCalls, 0);
      expect(inbox.countCalls, 0);
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('Offer destination'), findsOneWidget);
      expect(inbox.readCalls, 1);
      expect(inbox.pageCalls, 0);
      expect(inbox.countCalls, 0);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );
}
