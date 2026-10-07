import 'dart:convert';
import 'dart:io';

import 'dart:ui' as ui;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:octogear/core/design_system/octogear_theme.dart';
import 'package:octogear/core/localization/app_locale.dart';
import 'package:octogear/core/localization/app_locale_controller.dart';
import 'package:octogear/features/authentication/presentation/controllers/session_controller.dart';
import 'package:octogear/features/customer_chats/domain/entities/chat.dart';
import 'package:octogear/features/customer_chats/presentation/controllers/chat_providers.dart';
import 'package:octogear/features/customer_chats/presentation/screens/chat_conversation_screen.dart';
import 'package:octogear/features/customer_chats/presentation/widgets/chat_message_bubble.dart';
import 'chat_fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final translations = <String, Map<String, dynamic>>{};
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
    for (final code in ['ar', 'en']) {
      translations[code] =
          jsonDecode(
                await rootBundle.loadString('assets/translations/$code.json'),
              )
              as Map<String, dynamic>;
    }
    for (final name in ['NotoSansArabic', 'NotoSans']) {
      final loader = FontLoader(
        name == 'NotoSans' ? 'Noto Sans' : 'Noto Sans Arabic',
      )..addFont(rootBundle.load('assets/fonts/$name.ttf'));
      await loader.load();
    }
  });
  Future<void> pump(
    WidgetTester tester,
    FakeChatRepository repo, {
    bool arabic = false,
    double scale = 1,
  }) async {
    await tester.binding.setSurfaceSize(Size(scale == 1 ? 390 : 320, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) =>
              const ChatConversationScreen(target: ChatTarget.offer(17, 42)),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          chatRepositoryProvider.overrideWithValue(repo),
          sessionControllerProvider.overrideWith(ChatTestSession.new),
          appLocaleProvider.overrideWith(arabic ? Arabic.new : English.new),
        ],
        child: EasyLocalization(
          supportedLocales: const [Locale('en'), Locale('ar')],
          path: 'assets/translations',
          startLocale: Locale(arabic ? 'ar' : 'en'),
          saveLocale: false,
          assetLoader: Translations(translations),
          child: App(router, scale),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'open has no writes; first send creates a message and shows employee',
    (tester) async {
      final repo = FakeChatRepository();
      await pump(tester, repo);
      expect(repo.sends, 0);
      expect(find.text('Ahmed'), findsOneWidget);
      expect(find.text('Octo Parts'), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('chat-composer')),
        'Is this available?',
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('chat-send')));
      await tester.pumpAndSettle();
      expect(repo.sends, 1);
      expect(find.text('Is this available?'), findsOneWidget);
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('chat-composer')))
            .controller!
            .text,
        isEmpty,
      );
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets('failed send retains draft and retries the same message', (
    tester,
  ) async {
    final repo = FakeChatRepository()..failSend = true;
    await pump(tester, repo);
    await tester.enterText(find.byKey(const Key('chat-composer')), 'Hello');
    await tester.pump();
    await tester.tap(find.byKey(const Key('chat-send')));
    await tester.pumpAndSettle();
    expect(find.text('Message not confirmed. Retry safely.'), findsOneWidget);
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('chat-composer')))
          .controller!
          .text,
      'Hello',
    );
    repo.failSend = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(repo.keys.toSet(), hasLength(1));
    expect(find.byType(ChatMessageBubble), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('empty chat fits large text with keyboard open', (tester) async {
    final repo = FakeChatRepository();
    await pump(tester, repo, arabic: true, scale: 2);
    tester.view.viewInsets = FakeViewPadding(
      bottom: 320 * tester.view.devicePixelRatio,
    );
    addTearDown(tester.view.resetViewInsets);
    await tester.tap(find.byKey(const Key('chat-composer')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(repo.sends, 0);
    await tester.pumpWidget(const SizedBox());
  });
  for (final arabic in [false, true]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'chat day groups and times render ${arabic ? 'Arabic' : 'English'} scale $scale',
        (tester) async {
          final now = DateTime.now();
          final repo = FakeChatRepository()
            ..context = const ChatContext(
              conversation: sampleChat,
              storeName: 'Octo Parts',
              employeeName: 'Ahmed',
              orderId: 17,
              offerId: 42,
            )
            ..page = ChatMessages([
              ChatMessage(
                id: 3,
                text: arabic
                    ? 'شكرًا، هل القطعة أصلية؟'
                    : 'Thank you. Is this an original part?',
                mine: true,
                read: false,
                createdAt: DateTime(now.year, now.month, now.day, 10, 32),
              ),
              ChatMessage(
                id: 2,
                text: arabic
                    ? 'أهلًا، القطعة متوفرة وبحالة جيدة.'
                    : 'Hello! The part is available and in good condition.',
                mine: false,
                read: false,
                createdAt: DateTime(now.year, now.month, now.day, 10, 30),
              ),
              ChatMessage(
                id: 1,
                text: arabic
                    ? 'مرحبًا، أود الاستفسار عن العرض.'
                    : 'Hi, I have a question about your offer.',
                mine: true,
                read: true,
                createdAt: DateTime(now.year, now.month, now.day - 1, 17, 15),
              ),
            ], false);
          await pump(tester, repo, arabic: arabic, scale: scale);
          expect(find.text(arabic ? 'اليوم' : 'Today'), findsOneWidget);
          expect(find.byType(ChatMessageBubble), findsWidgets);
          expect(tester.takeException(), isNull);
          if (scale == 1) {
            expect(find.text(arabic ? 'أمس' : 'Yesterday'), findsOneWidget);
            final own =
                tester
                        .widget<Container>(
                          find.byKey(const ValueKey('message-3')),
                        )
                        .decoration!
                    as BoxDecoration;
            final other =
                tester
                        .widget<Container>(
                          find.byKey(const ValueKey('message-2')),
                        )
                        .decoration!
                    as BoxDecoration;
            expect(own.color, isNot(other.color));
            final boundary = tester.renderObject<RenderRepaintBoundary>(
              find.byKey(const Key('chat-preview')),
            );
            await tester.runAsync(() async {
              final image = await boundary.toImage(pixelRatio: 2);
              final bytes = await image.toByteData(
                format: ui.ImageByteFormat.png,
              );
              await File(
                'build/chat-${arabic ? 'ar' : 'en'}.png',
              ).writeAsBytes(bytes!.buffer.asUint8List());
              image.dispose();
            });
          }
          final context = tester.element(find.byType(ChatConversationScreen));
          expect(
            chatDayLabel(
              context,
              DateTime(2026, 10, 3, 12),
              now: DateTime(2026, 10, 4, 1),
            ),
            arabic ? 'أمس' : 'Yesterday',
          );
          expect(
            chatDayLabel(
              context,
              DateTime(2026, 10, 2),
              now: DateTime(2026, 10, 4),
            ),
            DateFormat.EEEE(arabic ? 'ar' : 'en').format(DateTime(2026, 10, 2)),
          );
          expect(
            chatDayLabel(
              context,
              DateTime(2026, 9, 20),
              now: DateTime(2026, 10, 4),
            ),
            DateFormat.yMMMd(
              arabic ? 'ar' : 'en',
            ).format(DateTime(2026, 9, 20)),
          );
          await tester.pumpWidget(const SizedBox());
        },
      );
    }
  }
}

class App extends StatelessWidget {
  const App(this.router, this.scale, {super.key});
  final GoRouter router;
  final double scale;
  @override
  Widget build(BuildContext context) => RepaintBoundary(
    key: const Key('chat-preview'),
    child: MaterialApp.router(
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: OctoGearTheme.forLocale(context.locale),
      locale: context.locale,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
    ),
  );
}

class Translations extends AssetLoader {
  const Translations(this.values);
  final Map<String, Map<String, dynamic>> values;
  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async =>
      values[locale.languageCode]!;
}

class English extends AppLocaleController {
  @override
  AppLocale build() => AppLocale.english;
}

class Arabic extends AppLocaleController {
  @override
  AppLocale build() => AppLocale.arabic;
}
