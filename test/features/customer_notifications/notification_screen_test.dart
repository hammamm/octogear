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
import 'package:octogear/features/notifications/domain/entities/app_notification.dart';
import 'package:octogear/features/notifications/presentation/controllers/notification_providers.dart';
import 'package:octogear/features/notifications/presentation/screens/notifications_screen.dart';
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
    bool provider = false,
    double scale = 1,
    bool settle = true,
  }) async {
    await tester.binding.setSurfaceSize(Size(scale == 1 ? 390 : 320, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => Scaffold(
            body: SafeArea(child: NotificationsScreen(provider: provider)),
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
          notificationSessionProvider.overrideWithValue(
            provider ? providerNotificationSession : notificationSession,
          ),
          notificationsRepositoryProvider.overrideWithValue(repo),
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

  for (final provider in [false, true]) {
    testWidgets(
      '${provider ? 'provider' : 'customer'} entry reads the displayed page once and keeps rows visible',
      (tester) async {
        final repo = FakeNotificationsRepository()
          ..items = [
            notification(
              1,
              kind: provider
                  ? NotificationKind.offerAccepted
                  : NotificationKind.offer,
            ),
          ];
        await pump(tester, repo, provider: provider);
        expect(repo.pageReads, hasLength(1));
        expect(repo.pageReads.single, {notification(1).id});
        expect(
          find.text(
            provider ? 'Your offer was accepted' : 'A new offer for you',
          ),
          findsOneWidget,
        );
        expect(repo.readCalls, 0);
        expect(repo.allCalls, 0);
        expect(find.text('0 unread notifications'), findsOneWidget);
        expect(find.byKey(const Key('notifications-read-all')), findsNothing);
        await tester.pump(const Duration(minutes: 2));
        expect(repo.pageReads, hasLength(1));
        expect(repo.pageCalls, 1);
        expect(repo.countCalls, 1);
        await tester.pumpWidget(const SizedBox());
      },
    );

    testWidgets(
      '${provider ? 'provider' : 'customer'} read failure offers retry without losing visible notifications',
      (tester) async {
        final repo = FakeNotificationsRepository()..failRead = true;
        await pump(tester, repo, provider: provider);
        expect(repo.pageReads, hasLength(1));
        expect(find.textContaining('Could not mark this page'), findsOneWidget);
        await tester.pump(const Duration(minutes: 2));
        expect(repo.pageReads, hasLength(1));
        repo.failRead = false;
        await tester.tap(find.byKey(const Key('notifications-refresh')));
        await tester.pumpAndSettle();
        expect(repo.pageReads, hasLength(2));
        expect(find.text('0 unread notifications'), findsOneWidget);
        await tester.pumpWidget(const SizedBox());
      },
    );

    testWidgets(
      '${provider ? 'provider' : 'customer'} page loaded behind another route is read only after returning',
      (tester) async {
        final pending = Completer<NotificationPage>();
        final repo = FakeNotificationsRepository()
          ..onPage = (_, _) => pending.future;
        final router = await pump(
          tester,
          repo,
          provider: provider,
          settle: false,
        );
        await tester.pump();
        unawaited(
          router.push(const CustomerOrderDetailsRoute(orderId: 17).location),
        );
        await tester.pumpAndSettle();
        pending.complete(NotificationPage(items: repo.items, unreadCount: 2));
        await tester.pumpAndSettle();
        expect(repo.pageReads, isEmpty);
        router.pop();
        await tester.pumpAndSettle();
        expect(repo.pageReads, hasLength(1));
        await tester.pumpWidget(const SizedBox());
      },
    );

    testWidgets(
      '${provider ? 'provider' : 'customer'} page fetched in background waits until foreground to mark read',
      (tester) async {
        final pending = Completer<NotificationPage>();
        final repo = FakeNotificationsRepository()
          ..onPage = (_, _) => pending.future;
        await pump(tester, repo, provider: provider, settle: false);
        await tester.pump();
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
        pending.complete(NotificationPage(items: repo.items, unreadCount: 2));
        await tester.pumpAndSettle();
        expect(repo.pageReads, isEmpty);
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await tester.pumpAndSettle();
        expect(repo.pageReads, hasLength(1));
        await tester.pumpWidget(const SizedBox());
      },
    );
  }

  for (final arabic in [false, true]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('provider inbox layout $arabic $scale', (tester) async {
        final repo = FakeNotificationsRepository()
          ..items = [
            notification(1, kind: NotificationKind.offerAccepted),
            notification(2, kind: NotificationKind.orderPaid),
            notification(3, kind: NotificationKind.message),
          ];
        await pump(tester, repo, provider: true, arabic: arabic, scale: scale);
        expect(tester.takeException(), isNull);
        if (scale == 1) {
          final boundary = tester.renderObject<RenderRepaintBoundary>(
            find.byKey(const Key('chat-preview')),
          );
          await tester.runAsync(() async {
            final image = await boundary.toImage(pixelRatio: 2);
            final data = await image.toByteData(format: ui.ImageByteFormat.png);
            await File(
              'build/provider-notifications-${arabic ? 'ar' : 'en'}.png',
            ).writeAsBytes(data!.buffer.asUint8List());
            image.dispose();
          });
        }
        await tester.drag(find.byType(ListView), const Offset(0, -800));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      });
    }
  }

  testWidgets(
    'customer filters preserve read history without marking unseen notifications',
    (tester) async {
      final repo = FakeNotificationsRepository();
      await pump(tester, repo);
      expect(repo.pageReads, hasLength(1));
      expect(repo.readCalls, 0);
      expect(repo.allCalls, 0);
      expect(find.text('0 unread notifications'), findsOneWidget);
      expect(find.byKey(const Key('notifications-read-all')), findsNothing);
      await tester.tap(find.text('Unread'));
      await tester.pumpAndSettle();
      expect(find.text('You’re all caught up'), findsOneWidget);
      await tester.tap(find.text('All'));
      await tester.pumpAndSettle();
      expect(find.text('A new offer for you'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );
  for (final kind in [
    NotificationKind.offer,
    NotificationKind.message,
    NotificationKind.orderCompleted,
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
          NotificationKind.offer => 'Offer destination',
          NotificationKind.message => 'Chat destination',
          _ => 'Order destination',
        };
        expect(find.text(label), findsOneWidget);
        expect(repo.readCalls, 0);
        expect(repo.pageReads, hasLength(2));
        if (kind == NotificationKind.message) {
          expect(router.canPop(), isFalse);
          router.go('/');
        } else {
          router.pop();
        }
        await tester.pumpAndSettle();
        expect(repo.items.single.isRead, false);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }
  testWidgets('unknown updates can be read without navigation', (tester) async {
    final repo = FakeNotificationsRepository()
      ..items = [notification(1, kind: NotificationKind.unknown)];
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
    final repo = FakeNotificationsRepository();
    final router = await pump(tester, repo);
    final tile = find.byKey(ValueKey('notification-${notification(1).id}'));
    await tester.tap(tile);
    await tester.tap(tile);
    await tester.pumpAndSettle();
    expect(repo.readCalls, 0);
    expect(repo.pageReads, hasLength(1));
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
    'customer reads 20 loaded notifications, then only the next page on load older',
    (tester) async {
      final rows = List.generate(
        25,
        (i) => notification(i + 1, kind: NotificationKind.unknown),
      );
      final repo = FakeNotificationsRepository()..items = rows;
      repo.onPage = (_, cursor) async => NotificationPage(
        items: cursor == null
            ? repo.items.take(20).toList()
            : repo.items.skip(20).toList(),
        unreadCount: repo.items.where((n) => !n.isRead).length,
        nextCursor: cursor == null ? 'older' : null,
      );
      await pump(tester, repo);
      expect(repo.pageReads.single, rows.take(20).map((n) => n.id).toSet());
      expect(repo.items.skip(20).every((n) => !n.isRead), true);
      expect(find.text('5 unread notifications'), findsOneWidget);
      final more = find.byKey(const Key('notifications-more'));
      await tester.scrollUntilVisible(more, 500);
      await tester.tap(more);
      await tester.pumpAndSettle();
      expect(repo.pageReads, hasLength(2));
      expect(repo.pageReads.last, rows.skip(20).map((n) => n.id).toSet());
      expect(repo.items.every((n) => n.isRead), true);
      expect(repo.allCalls, 0);
      expect(repo.readCalls, 0);
      expect(repo.pageCalls, 2);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'inbox loads on entry and explicit refresh, never on badge changes',
    (tester) async {
      final repo = FakeNotificationsRepository();
      await pump(tester, repo);
      expect(repo.pageCalls, 1);
      expect(repo.countCalls, 1);
      final container = ProviderScope.containerOf(
        tester.element(find.byType(NotificationsScreen)),
      );
      container
          .read(notificationCountProvider.notifier)
          .received('12345678-1234-1234-1234-123456789abc');
      await tester.pump(const Duration(minutes: 2));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(repo.pageCalls, 1);
      expect(repo.countCalls, 1);
      await container.read(notificationInboxProvider(false).notifier).refresh();
      await tester.pumpAndSettle();
      expect(repo.pageCalls, 2);
      expect(repo.countCalls, 1);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('badges never poll or fetch on app resume', (tester) async {
    final repo = FakeNotificationsRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          notificationSessionProvider.overrideWithValue(notificationSession),
          notificationsRepositoryProvider.overrideWithValue(repo),
        ],
        child: Consumer(
          builder: (_, ref, _) {
            ref.watch(notificationCountProvider);
            return const SizedBox();
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(repo.countCalls, 1);
    expect(repo.pageCalls, 0);
    await tester.pump(const Duration(minutes: 2));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(repo.countCalls, 1);
    expect(repo.pageCalls, 0);
    await tester.pumpWidget(const SizedBox());
  });
  for (final arabic in [false, true]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        '${arabic ? 'Arabic' : 'English'} inbox fits text scale $scale',
        (tester) async {
          final repo = FakeNotificationsRepository()
            ..items.add(
              notification(
                3,
                kind: NotificationKind.orderCompleted,
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
