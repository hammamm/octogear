import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:octogear/features/authentication/presentation/controllers/session_controller.dart';
import 'package:octogear/features/customer_chats/presentation/controllers/chat_realtime_providers.dart';
import 'package:octogear/features/customer_chats/presentation/widgets/chat_connection_status.dart';

import '../customer_notifications/push_scope_test.dart' show PushTestSession;
import 'chat_screen_test.dart' show Translations;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final translations = <String, Map<String, dynamic>>{};
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    translations['en'] =
        jsonDecode(await rootBundle.loadString('assets/translations/en.json'))
            as Map<String, dynamic>;
  });

  testWidgets(
    'brief connections stay quiet and recovery clears the indicator',
    (tester) async {
      final connection = ValueNotifier(false);
      addTearDown(connection.dispose);
      await tester.pumpWidget(
        EasyLocalization(
          supportedLocales: const [Locale('en')],
          path: 'assets/translations',
          startLocale: const Locale('en'),
          saveLocale: false,
          assetLoader: Translations(translations),
          child: Builder(
            builder: (context) => ProviderScope(
              overrides: [
                sessionControllerProvider.overrideWith(PushTestSession.new),
                chatRealtimeConnectedProvider.overrideWith((ref) {
                  void changed() => ref.invalidateSelf();
                  connection.addListener(changed);
                  ref.onDispose(() => connection.removeListener(changed));
                  return connection.value;
                }),
              ],
              child: MaterialApp(
                locale: context.locale,
                supportedLocales: context.supportedLocales,
                localizationsDelegates: context.localizationDelegates,
                home: const Scaffold(body: ChatConnectionStatus()),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 9));
      expect(find.byIcon(Icons.sync), findsNothing);
      connection.value = true;
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      expect(find.byIcon(Icons.sync), findsNothing);
      connection.value = false;
      await tester.pump();
      await tester.pump(const Duration(seconds: 10));
      expect(find.byIcon(Icons.sync), findsOneWidget);
      expect(find.textContaining('disconnected'), findsNothing);
      connection.value = true;
      await tester.pump();
      expect(find.byIcon(Icons.sync), findsNothing);
      connection.value = false;
      await tester.pump();
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 11));
      expect(tester.takeException(), isNull);
    },
  );
}
