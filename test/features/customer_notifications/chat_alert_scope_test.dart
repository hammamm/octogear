import 'dart:async';
import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:octogear/app/routing/app_router.dart';
import 'package:octogear/core/localization/app_locale_controller.dart';
import 'package:octogear/core/storage/storage_providers.dart';
import 'package:octogear/features/authentication/presentation/controllers/session_controller.dart';
import 'package:octogear/features/customer_chats/domain/entities/chat.dart';
import 'package:octogear/features/customer_chats/domain/entities/chat_update.dart';
import 'package:octogear/features/customer_chats/presentation/controllers/chat_activity_controller.dart';
import 'package:octogear/features/customer_chats/presentation/controllers/chat_realtime_providers.dart';
import 'package:octogear/features/customer_notifications/data/models/push_notification_dto.dart';
import 'package:octogear/features/customer_notifications/presentation/controllers/notification_providers.dart';
import 'package:octogear/features/customer_notifications/presentation/controllers/push_providers.dart';
import '../customer_chats/chat_screen_test.dart' show English, Translations;
import 'notification_fixtures.dart';
import 'push_delivery_test.dart' show FakePushRepository, payload;
import 'push_scope_test.dart'
    show PushTestApp, PushTestSession, PushTestStorage;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final translations = <String, Map<String, dynamic>>{};
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    for (final code in ['en', 'ar']) {
      translations[code] =
          jsonDecode(
                await rootBundle.loadString('assets/translations/$code.json'),
              )
              as Map<String, dynamic>;
    }
  });
  for (final inChats in [false, true]) {
    testWidgets(
      'message alerts are deduplicated and suppressed in Chats ($inChats)',
      (tester) async {
        final push = FakePushRepository();
        final events = StreamController<ChatUpdate>.broadcast();
        final inbox = FakeNotificationsRepository();
        final router = GoRouter(
          initialLocation: inChats ? '/customer/chats' : '/customer',
          routes: [
            for (final path in [
              '/customer',
              '/customer/chats',
              '/customer/chats/7',
            ])
              GoRoute(
                path: path,
                builder: (_, _) => Scaffold(body: Text(path)),
              ),
          ],
        );
        addTearDown(router.dispose);
        addTearDown(push.dispose);
        addTearDown(events.close);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sessionControllerProvider.overrideWith(PushTestSession.new),
              sessionStorageProvider.overrideWithValue(PushTestStorage()),
              appLocaleProvider.overrideWith(English.new),
              appRouterProvider.overrideWithValue(router),
              pushRepositoryProvider.overrideWithValue(push),
              chatRealtimeUpdatesProvider.overrideWith((_) => events.stream),
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
        final container = ProviderScope.containerOf(
          tester.element(find.byType(PushTestApp)),
        );
        events.add(
          ChatUpdate(
            ChatUpdateKind.message,
            conversationId: 7,
            message: ChatMessage(
              id: 99,
              text: 'private',
              mine: false,
              read: false,
              createdAt: DateTime(2026),
            ),
          ),
        );
        await tester.pumpAndSettle();
        push.foregroundEvents.add(
          parsePushNotification({
            ...payload(),
            'type': 'new_message',
            'conversation_id': '7',
            'message_id': '99',
          })!,
        );
        await tester.pumpAndSettle();
        expect(
          find.text('You have a new message.'),
          inChats ? findsNothing : findsOneWidget,
        );
        expect(container.read(chatActivityProvider), !inChats);
        expect(inbox.pageCalls, 0);
        expect(inbox.countCalls, 0);
        // Entering Chats removes a banner already visible on another tab.
        router.go('/customer/chats');
        await tester.pumpAndSettle();
        expect(find.text('You have a new message.'), findsNothing);
        expect(container.read(chatActivityProvider), isFalse);
        router.go('/customer');
        await tester.pumpAndSettle();
        events.add(
          ChatUpdate(
            ChatUpdateKind.message,
            conversationId: 7,
            message: ChatMessage(
              id: 100,
              text: 'own echo',
              mine: true,
              read: false,
              createdAt: DateTime(2026),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(container.read(chatActivityProvider), isFalse);
        events.add(
          ChatUpdate(
            ChatUpdateKind.message,
            conversationId: 7,
            message: ChatMessage(
              id: 101,
              text: 'new',
              mine: false,
              read: false,
              createdAt: DateTime(2026),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
        expect(find.text('/customer/chats/7'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
      },
    );
  }
}
