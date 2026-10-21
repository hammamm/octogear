import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:octogear/core/design_system/octogear_theme.dart';
import 'package:octogear/features/authentication/presentation/controllers/session_controller.dart';
import 'package:octogear/features/customer_chats/domain/entities/chat_update.dart';
import 'package:octogear/features/customer_chats/presentation/controllers/chat_realtime_providers.dart';
import 'package:octogear/features/support_chat/domain/entities/support_chat.dart';
import 'package:octogear/features/support_chat/presentation/controllers/support_providers.dart';
import 'package:octogear/features/support_chat/presentation/screens/support_chat_screen.dart';
import 'package:octogear/features/support_chat/presentation/widgets/support_entry.dart';
import 'support_fixtures.dart';

class _Translations extends AssetLoader {
  const _Translations(this.values);
  final Map<String, Map<String, dynamic>> values;
  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async =>
      values[locale.languageCode]!;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final translations = <String, Map<String, dynamic>>{};
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    for (final code in ['ar', 'en']) {
      translations[code] = jsonDecode(
        await rootBundle.loadString('assets/translations/$code.json'),
      );
    }
  });
  Future<void> pump(
    WidgetTester tester,
    FakeSupportRepository repo, {
    bool arabic = false,
    double scale = 1,
    Stream<ChatUpdate> events = const Stream.empty(),
    bool badge = false,
  }) async {
    await tester.binding.setSurfaceSize(const Size(320, 700));
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      await tester.binding.setSurfaceSize(null);
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionControllerProvider.overrideWith(SupportSession.new),
          supportRepositoryProvider.overrideWithValue(repo),
          chatRealtimeUpdatesProvider.overrideWith((ref) => events),
        ],
        child: EasyLocalization(
          supportedLocales: const [Locale('ar'), Locale('en')],
          startLocale: Locale(arabic ? 'ar' : 'en'),
          saveLocale: false,
          path: 'assets/translations',
          assetLoader: _Translations(translations),
          child: Builder(
            builder: (context) => MaterialApp(
              theme: OctoGearTheme.forLocale(context.locale),
              locale: context.locale,
              supportedLocales: context.supportedLocales,
              localizationsDelegates: context.localizationDelegates,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(scale)),
                child: child!,
              ),
              home: badge
                  ? const Scaffold(body: SupportButton())
                  : const SupportChatScreen(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final arabic in [false, true]) {
    testWidgets(
      'welcome creates no chat and first text sends, Arabic=$arabic',
      (tester) async {
        final repo = FakeSupportRepository();
        await pump(tester, repo, arabic: arabic, scale: 2);
        expect(repo.keys, isEmpty);
        await tester.tap(find.byKey(const Key('support-start')));
        await tester.pumpAndSettle();
        expect(repo.keys, isEmpty);
        await tester.enterText(
          find.byKey(const Key('support-message')),
          'Please help',
        );
        await tester.tap(find.byKey(const Key('support-send')));
        await tester.pumpAndSettle();
        expect(repo.texts, ['Please help']);
        expect(find.text('Please help'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
    testWidgets(
      'closed history remains visible until explicit reopening, Arabic=$arabic',
      (tester) async {
        final repo = FakeSupportRepository()
          ..current = conversation(closed: true)
          ..messages = [message(1)];
        await pump(tester, repo, arabic: arabic, scale: 2);
        expect(find.text('Message 1'), findsOneWidget);
        expect(find.byKey(const Key('support-message')), findsNothing);
        expect(repo.reopens, 0);
        await tester.ensureVisible(find.byKey(const Key('support-reopen')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('support-reopen')));
        await tester.pumpAndSettle();
        expect(repo.reopens, 1);
        expect(find.byKey(const Key('support-message')), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets('header shows incoming unread count and hides zero', (
    tester,
  ) async {
    final events = StreamController<ChatUpdate>.broadcast();
    addTearDown(events.close);
    final repo = FakeSupportRepository()..current = conversation(unread: 3);
    await pump(tester, repo, badge: true, events: events.stream);
    expect(find.text('3'), findsOneWidget);
    events.add(
      ChatUpdate(
        ChatUpdateKind.support,
        support: SupportUpdate(conversation(version: 2, read: 3)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('3'), findsNothing);
  });
  testWidgets('read debounce acknowledges visible incoming messages only', (
    tester,
  ) async {
    final repo = FakeSupportRepository()
      ..current = conversation(unread: 1)
      ..messages = [message(1)];
    await pump(tester, repo);
    expect(repo.reads, 0);
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(repo.reads, 1);
    expect(repo.current!.unread, 0);
  });
}
