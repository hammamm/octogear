import 'dart:async';
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
import 'package:octogear/app/routing/app_routes.dart';
import 'package:octogear/core/localization/app_locale_controller.dart';
import 'package:octogear/features/customer_notifications/domain/entities/customer_notification.dart';
import 'package:octogear/features/customer_notifications/presentation/controllers/notification_providers.dart';
import 'package:octogear/features/customer_notifications/presentation/screens/customer_notifications_screen.dart';
import 'package:octogear/features/customer_notifications/presentation/widgets/notification_entry.dart';
import '../customer_chats/chat_screen_test.dart'
    show App, Translations, English, Arabic;
import 'notification_fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final translations = <String, Map<String, dynamic>>{};
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    for (final code in ['en', 'ar']) {
      translations[code] =
          jsonDecode(
                await rootBundle.loadString('assets/translations/$code.json'),
              )
              as Map<String, dynamic>;
    }
    for (final name in ['NotoSansArabic', 'NotoSans']) {
      await (FontLoader(
        name == 'NotoSans' ? 'Noto Sans' : 'Noto Sans Arabic',
      )..addFont(rootBundle.load('assets/fonts/$name.ttf'))).load();
    }
  });
  Future<GoRouter> pump(
    WidgetTester tester,
    FakeNotificationsRepository repo, {
    bool arabic = false,
    double scale = 1,
    bool settle = true,
  }) async {
    await tester.binding.setSurfaceSize(Size(scale == 1 ? 390 : 320, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(
            body: SafeArea(child: CustomerNotificationsScreen()),
          ),
        ),
        GoRoute(
          path: const CustomerOfferDetailsRoute(
            orderId: 17,
            offerId: 42,
          ).location,
          builder: (_, _) => const Scaffold(body: Text('Offer destination')),
        ),
        GoRoute(
          path: const CustomerConversationRoute(conversationId: 7).location,
          builder: (_, _) => const Scaffold(body: Text('Chat destination')),
        ),
        GoRoute(
          path: const CustomerOrderDetailsRoute(orderId: 17).location,
          builder: (_, _) => const Scaffold(body: Text('Order destination')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          notificationCustomerIdProvider.overrideWithValue(1),
          customerNotificationsRepositoryProvider.overrideWithValue(repo),
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
    if (settle) await tester.pumpAndSettle();
    return router;
  }

  testWidgets(
    'viewing does not mark read; filters and mark all update the inbox',
    (tester) async {
      final repo = FakeNotificationsRepository();
      await pump(tester, repo);
      expect(repo.readCalls, 0);
      expect(find.text('2 unread notifications'), findsOneWidget);
      await tester.tap(find.text('Unread'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('notifications-read-all')));
      await tester.pumpAndSettle();
      expect(repo.allCalls, 1);
      expect(find.text('You’re all caught up'), findsOneWidget);
      await tester.tap(find.text('All'));
      await tester.pumpAndSettle();
      expect(find.text('A new offer for you'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );
  for (final kind in [
    CustomerNotificationKind.offer,
    CustomerNotificationKind.message,
    CustomerNotificationKind.orderCompleted,
  ]) {
    testWidgets(
      '${kind.name} opens the correct target even when marking read fails',
      (tester) async {
        final repo = FakeNotificationsRepository()
          ..items = [notification(1, kind: kind)]
          ..failRead = true;
        final router = await pump(tester, repo);
        await tester.tap(
          find.byKey(ValueKey('notification-${notification(1).id}')),
        );
        await tester.pumpAndSettle();
        final label = switch (kind) {
          CustomerNotificationKind.offer => 'Offer destination',
          CustomerNotificationKind.message => 'Chat destination',
          _ => 'Order destination',
        };
        expect(find.text(label), findsOneWidget);
        expect(repo.readCalls, 1);
        router.pop();
        await tester.pumpAndSettle();
        expect(repo.items.single.isRead, false);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }
  testWidgets('unknown updates can be read without navigation', (tester) async {
    final repo = FakeNotificationsRepository()
      ..items = [notification(1, kind: CustomerNotificationKind.unknown)];
    final router = await pump(tester, repo);
    await tester.tap(
      find.byKey(ValueKey('notification-${notification(1).id}')),
    );
    await tester.pumpAndSettle();
    expect(router.canPop(), false);
    expect(repo.items.single.isRead, true);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('rapid taps open only one page', (tester) async {
    final pending = Completer<void>();
    final repo = FakeNotificationsRepository()..onRead = () => pending.future;
    final router = await pump(tester, repo);
    final tile = find.byKey(ValueKey('notification-${notification(1).id}'));
    await tester.tap(tile);
    await tester.tap(tile);
    pending.complete();
    await tester.pumpAndSettle();
    expect(repo.readCalls, 1);
    router.pop();
    await tester.pumpAndSettle();
    expect(router.canPop(), false);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('initial error retries to empty state', (tester) async {
    final repo = FakeNotificationsRepository()
      ..failPage = true
      ..items = [];
    await pump(tester, repo);
    expect(find.text('Couldn’t load notifications'), findsOneWidget);
    repo.failPage = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('No notifications yet'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets(
    'reading the visible unread history still allows loading older unread rows',
    (tester) async {
      final rows = [
        for (var i = 1; i <= 3; i++)
          notification(i, kind: CustomerNotificationKind.unknown),
      ];
      final repo = FakeNotificationsRepository()..items = rows;
      repo.onPage = (_, cursor) async => NotificationPage(
        items: [
          rows[cursor == null
              ? 0
              : cursor == 'second'
              ? 1
              : 2],
        ],
        unreadCount: repo.items.where((n) => !n.isRead).length,
        nextCursor: cursor == null
            ? 'second'
            : cursor == 'second'
            ? 'third'
            : null,
      );
      await pump(tester, repo);
      await tester.tap(find.text('Unread'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('notifications-more')));
      await tester.pumpAndSettle();
      for (final row in rows.take(2)) {
        await tester.tap(find.byKey(ValueKey('notification-${row.id}')));
        await tester.pumpAndSettle();
      }
      expect(find.text('You’re all caught up'), findsNothing);
      await tester.tap(find.byKey(const Key('notifications-more')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(ValueKey('notification-${rows.last.id}')),
        findsOneWidget,
      );
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'foreground polling pauses in background and after errors; resume retries',
    (tester) async {
      final repo = FakeNotificationsRepository();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            notificationCustomerIdProvider.overrideWithValue(1),
            customerNotificationsRepositoryProvider.overrideWithValue(repo),
          ],
          child: const NotificationRefreshScope(child: SizedBox()),
        ),
      );
      await tester.pumpAndSettle();
      expect(repo.countCalls, 1);
      await tester.pump(const Duration(seconds: 31));
      await tester.pumpAndSettle();
      expect(repo.countCalls, 2);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump(const Duration(seconds: 61));
      expect(repo.countCalls, 2);
      repo.failCount = true;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(repo.countCalls, 3);
      await tester.pump(const Duration(seconds: 61));
      expect(repo.countCalls, 3);
      repo.failCount = false;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(repo.countCalls, 4);
      await tester.pumpWidget(const SizedBox());
    },
  );
  for (final arabic in [false, true]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        '${arabic ? 'Arabic' : 'English'} inbox fits text scale $scale',
        (tester) async {
          final repo = FakeNotificationsRepository()
            ..items.add(
              notification(
                3,
                kind: CustomerNotificationKind.orderCompleted,
                read: true,
              ),
            );
          await pump(tester, repo, arabic: arabic, scale: scale);
          expect(tester.takeException(), isNull);
          if (scale == 1) {
            final boundary = tester.renderObject<RenderRepaintBoundary>(
              find.byKey(const Key('chat-preview')),
            );
            await tester.runAsync(() async {
              final image = await boundary.toImage(pixelRatio: 2);
              final data = await image.toByteData(
                format: ui.ImageByteFormat.png,
              );
              final file = File(
                'build/notification-preview-${arabic ? 'ar' : 'en'}.png',
              );
              await file.parent.create(recursive: true);
              await file.writeAsBytes(data!.buffer.asUint8List());
              image.dispose();
            });
          }
          await tester.drag(find.byType(ListView), const Offset(0, -800));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
        },
      );
    }
  }
}
