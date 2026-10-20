import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';

import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:octogear/core/api/api_client.dart';
import 'package:octogear/core/api/api_failure.dart';
import 'package:octogear/core/localization/app_locale.dart';
import 'package:octogear/core/localization/app_locale_controller.dart';
import 'package:octogear/features/authentication/domain/entities/session_outcome.dart';
import 'package:octogear/features/authentication/presentation/controllers/session_controller.dart';
import 'package:octogear/features/customer_chats/domain/entities/chat.dart';
import 'package:octogear/features/customer_chats/presentation/controllers/chat_providers.dart';
import 'package:octogear/features/customer_chats/presentation/controllers/chat_realtime_providers.dart';
import 'package:octogear/features/customer_chats/presentation/screens/chat_conversation_screen.dart';
import 'package:octogear/features/provider_orders/data/data_sources/provider_offers_remote_data_source.dart';
import 'package:octogear/features/provider_orders/domain/entities/provider_offer.dart';
import 'package:octogear/features/provider_orders/presentation/controllers/provider_offers_providers.dart';
import 'package:octogear/features/provider_orders/presentation/screens/provider_offer_form_screen.dart';
import 'package:octogear/features/provider_orders/presentation/widgets/provider_chat_offers.dart';
import '../customer_chats/chat_fixtures.dart';
import '../customer_chats/chat_screen_test.dart' show App, Translations;
import '../provider_stores/provider_stores_fixtures.dart';
import 'provider_offers_fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final translations = <String, Map<String, dynamic>>{};
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    for (final name in ['NotoSansArabic', 'NotoSans']) {
      final loader = FontLoader(
        name == 'NotoSans' ? 'Noto Sans' : 'Noto Sans Arabic',
      )..addFont(rootBundle.load('assets/fonts/$name.ttf'));
      await loader.load();
    }
    for (final code in ['en', 'ar']) {
      translations[code] =
          jsonDecode(
                await rootBundle.loadString('assets/translations/$code.json'),
              )
              as Map<String, dynamic>;
    }
  });

  Future<ProviderContainer> container(FakeOffers repo) async {
    final result = ProviderContainer(
      overrides: [
        providerOffersRepositoryProvider.overrideWithValue(repo),
        sessionControllerProvider.overrideWith(StoreSession.new),
        appLocaleProvider.overrideWith(StoreLocale.new),
      ],
    );
    addTearDown(result.dispose);
    await result.read(sessionControllerProvider.future);
    return result;
  }

  test(
    'chat query uses a dedicated authenticated route and rejects noneditable results',
    () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api/'));
      addTearDown(dio.close);
      final remote = ProviderOffersRemoteDataSource(
        ApiClient(
          dio: dio,
          accessTokenResolver: () => 'test-token',
          localeResolver: () => 'ar',
        ),
      );
      final requests = <RequestOptions>[];
      var editable = true;
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (request, handler) {
            requests.add(request);
            handler.resolve(
              Response(
                requestOptions: request,
                statusCode: 200,
                data: {
                  'success': true,
                  'data': [
                    {...offerJson(), 'can_edit': editable},
                  ],
                  'meta': {
                    'current_page': 1,
                    'last_page': 1,
                    'per_page': 15,
                    'total': 1,
                  },
                },
              ),
            );
          },
        ),
      );
      await remote.list(conversationId: 7);
      expect(requests.single.path, 'provider/conversations/7/offers');
      expect(requests.single.queryParameters, {'page': 1});
      expect(requests.single.headers['Authorization'], 'Bearer test-token');
      expect(requests.single.headers['Accept-Language'], 'ar');
      editable = false;
      await expectLater(
        remote.list(conversationId: 7),
        throwsA(isA<ApiFailure>()),
      );
    },
  );

  test(
    'chat pagination retains rows on failure and retries the same customer scope',
    () async {
      var fail = true;
      final repo = FakeOffers()
        ..onList = (page, _) async {
          if (page == 1) return ProviderOffersPage([testOffer()], 1, 2, 2);
          if (fail) throw const ApiFailure(type: ApiFailureType.noConnection);
          return ProviderOffersPage([testOffer(id: 12, orderId: 2)], 2, 2, 2);
        };
      final c = await container(repo);
      final provider = providerChatOffersProvider(7);
      final sub = c.listen(provider, (_, _) {});
      addTearDown(sub.close);
      await c.read(provider.future);
      await c.read(provider.notifier).loadMore();
      expect(c.read(provider).requireValue.page.items.single.id, 11);
      expect(c.read(provider).requireValue.error, isA<ApiFailure>());
      fail = false;
      await c.read(provider.notifier).loadMore();
      expect(c.read(provider).requireValue.page.items.map((e) => e.id), [
        11,
        12,
      ]);
      expect(repo.conversations, [7, 7, 7]);
      expect(repo.calls.map((e) => e.$1), [1, 2, 2]);
    },
  );

  for (final replacement in ['session', 'locale', 'refresh']) {
    test(
      'chat pagination discards stale results after $replacement replacement',
      () async {
        final pending = Completer<ProviderOffersPage>();
        final repo = FakeOffers()
          ..onList = (page, _) async => page == 1
              ? ProviderOffersPage([testOffer()], 1, 2, 2)
              : pending.future;
        final c = await container(repo);
        final provider = providerChatOffersProvider(7);
        final sub = c.listen(provider, (_, _) {});
        addTearDown(sub.close);
        await c.read(provider.future);
        final more = c.read(provider.notifier).loadMore();
        if (replacement == 'session') {
          (c.read(sessionControllerProvider.notifier) as StoreSession).replace(
            AuthenticatedSession(
              (c.read(sessionControllerProvider).requireValue
                      as AuthenticatedSession)
                  .user,
            ),
          );
        } else if (replacement == 'locale') {
          await c.read(appLocaleProvider.notifier).select(AppLocale.arabic);
        } else {
          c.invalidate(provider);
        }
        await c.read(provider.future);
        pending.complete(ProviderOffersPage([testOffer(id: 99)], 2, 2, 2));
        await more;
        expect(c.read(provider).requireValue.page.items.single.id, 11);
      },
    );
  }

  Future<FakeChatRepository> pump(
    WidgetTester tester,
    FakeOffers offers, {
    bool arabic = false,
    double scale = 1,
    bool provider = true,
    bool settle = true,
  }) async {
    await tester.binding.setSurfaceSize(Size(scale == 1 ? 390 : 320, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final chats = FakeChatRepository()
      ..context = const ChatContext(
        conversation: ChatSummary(
          id: 7,
          name: 'Customer',
          orderId: 1,
          offerId: 11,
        ),
        orderId: 1,
        offerId: 11,
        storeName: 'Al Faris Parts',
      );
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => ChatConversationScreen(
            target: const ChatTarget.conversation(7),
            provider: provider,
          ),
        ),
        GoRoute(
          path: '/provider/chats/offers/:offerId/edit',
          builder: (_, state) => Scaffold(
            body: ProviderOfferFormScreen(
              orderId: int.parse(state.uri.queryParameters['order-id']!),
              offerId: int.parse(state.pathParameters['offerId']!),
            ),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          providerOffersRepositoryProvider.overrideWithValue(offers),
          chatRepositoryProvider.overrideWithValue(chats),
          sessionControllerProvider.overrideWith(StoreSession.new),
          appLocaleProvider.overrideWith(
            () => StoreLocale(arabic ? AppLocale.arabic : AppLocale.english),
          ),
          chatRealtimeUpdatesProvider.overrideWith((_) => const Stream.empty()),
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
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      for (var frame = 0; frame < 10; frame++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
    }
    return chats;
  }

  testWidgets(
    'single offer edits directly and returns to the preserved chat draft after saving',
    (tester) async {
      final offers = FakeOffers()..items = [testOffer()];
      final chats = await pump(tester, offers);
      expect(find.textContaining('Request #1 · Offer #11'), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('chat-composer')),
        'I can lower the price',
      );
      await tester.tap(find.byKey(const Key('chat-edit-offer')));
      await tester.pumpAndSettle();
      expect(find.text('Choose an offer to edit'), findsNothing);
      expect(find.byKey(const Key('provider-offer-price')), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('provider-offer-price')),
        '100.00',
      );
      await tester.enterText(
        find.byKey(const Key('provider-offer-notes')),
        'Discount agreed',
      );
      await tester.ensureVisible(
        find.byKey(const Key('provider-offer-submit')),
      );
      await tester.tap(find.byKey(const Key('provider-offer-submit')));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Confirm and submit'));
      await tester.pumpAndSettle();
      expect(offers.saves.single.offerId, 11);
      expect(offers.saves.single.price, 10000);
      expect(offers.saves.single.notes, 'Discount agreed');
      expect(offers.saves.single.photos, isNull);
      expect(find.byKey(const Key('chat-composer')), findsOneWidget);
      expect(find.text('I can lower the price'), findsOneWidget);
      expect(chats.sends, 0);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'multiple offers identify request/store and open the chosen offer',
    (tester) async {
      final offers = FakeOffers()
        ..items = [testOffer(), testOffer(id: 12, orderId: 2, storeId: 2)];
      await pump(tester, offers);
      await tester.tap(find.byKey(const Key('chat-edit-offer')));
      await tester.pumpAndSettle();
      expect(find.text('Choose an offer to edit'), findsOneWidget);
      expect(find.text('This chat’s offer'), findsOneWidget);
      expect(find.text('Request #2 · Offer #12'), findsOneWidget);
      await tester.ensureVisible(
        find.byKey(const ValueKey('chat-choose-offer-12')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('chat-choose-offer-12')));
      await tester.pumpAndSettle();
      final editor = tester.widget<ProviderOfferFormScreen>(
        find.byType(ProviderOfferFormScreen),
      );
      expect(editor.offerId, 12);
      expect(editor.orderId, 2);
      expect(offers.saves, isEmpty);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('offer selected by customer after list read cannot open editor', (
    tester,
  ) async {
    final offers = FakeOffers()
      ..items = [testOffer()]
      ..onGet = (_) async =>
          testOffer(status: 'accepted', orderStatus: 'awaiting_payment');
    await pump(tester, offers);
    await tester.tap(find.byKey(const Key('chat-edit-offer')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('provider-offer-price')), findsNothing);
    expect(offers.saves, isEmpty);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'lookup failure retries without interrupting chat; empty result hides the strip',
    (tester) async {
      final offers = FakeOffers()
        ..onList = (_, _) async =>
            throw const ApiFailure(type: ApiFailureType.noConnection);
      final chats = await pump(tester, offers);
      expect(find.text('Could not load editable offers.'), findsOneWidget);
      expect(find.byKey(const Key('chat-composer')), findsOneWidget);
      offers.onList = null;
      await tester.tap(find.byTooltip('Retry'));
      await tester.pumpAndSettle();
      expect(find.textContaining('No editable offers.'), findsNothing);
      expect(find.byTooltip('Refresh offers'), findsNothing);
      expect(tester.getSize(find.byType(ProviderChatOffers)).height, 0);
      expect(find.byKey(const Key('chat-edit-offer')), findsNothing);
      expect(chats.sends, 0);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'offer lookup stays hidden until available, hides after empty refresh, and excludes customers',
    (tester) async {
      final pending = Completer<ProviderOffersPage>();
      final offers = FakeOffers()..onList = (_, _) => pending.future;
      await pump(tester, offers, settle: false);
      expect(find.text('Loading editable offers…'), findsNothing);
      expect(find.byKey(const Key('chat-edit-offer')), findsNothing);
      expect(tester.getSize(find.byType(ProviderChatOffers)).height, 0);
      expect(find.byKey(const Key('chat-composer')), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('chat-composer')),
        'Keep draft',
      );
      pending.complete(ProviderOffersPage([testOffer()], 1, 1, 1));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('chat-edit-offer')), findsOneWidget);
      final refreshed = Completer<ProviderOffersPage>();
      offers.onList = (_, _) => refreshed.future;
      await tester.tap(find.byTooltip('Refresh offers'));
      await tester.pump();
      expect(tester.getSize(find.byType(ProviderChatOffers)).height, 0);
      expect(find.text('Loading editable offers…'), findsNothing);
      refreshed.complete(const ProviderOffersPage([], 1, 1, 0));
      await tester.pumpAndSettle();
      expect(find.textContaining('No editable offers.'), findsNothing);
      expect(find.byKey(const Key('chat-edit-offer')), findsNothing);
      expect(find.byTooltip('Refresh offers'), findsNothing);
      expect(tester.getSize(find.byType(ProviderChatOffers)).height, 0);
      expect(find.text('Keep draft'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      final customerOffers = FakeOffers();
      await pump(tester, customerOffers, provider: false);
      expect(customerOffers.calls, isEmpty);
      await tester.pumpWidget(const SizedBox());
    },
  );

  Future<void> capture(WidgetTester tester, String name) async {
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const Key('chat-preview')),
    );
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 1.5);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await File(
        'build/provider-chat-$name.png',
      ).writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
  }

  for (final arabic in [false, true]) {
    testWidgets(
      'render single offer and chooser in ${arabic ? 'Arabic' : 'English'}',
      (tester) async {
        final offers = FakeOffers()..items = [testOffer()];
        await pump(tester, offers, arabic: arabic);
        await capture(tester, '${arabic ? 'ar' : 'en'}-single');
        offers.items.add(testOffer(id: 12, orderId: 2));
        await tester.tap(
          find.byTooltip(arabic ? 'تحديث العروض' : 'Refresh offers'),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('chat-edit-offer')));
        await tester.pumpAndSettle();
        await capture(tester, '${arabic ? 'ar' : 'en'}-chooser');
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }
  for (final arabic in [false, true]) {
    testWidgets(
      'single and multiple offers fit 320dp at 200% text, keyboard and ${arabic ? 'Arabic' : 'English'}',
      (tester) async {
        final offers = FakeOffers()..items = [testOffer()];
        await pump(tester, offers, arabic: arabic, scale: 2);
        expect(tester.takeException(), isNull);
        tester.view.viewInsets = FakeViewPadding(
          bottom: 320 * tester.view.devicePixelRatio,
        );
        addTearDown(tester.view.resetViewInsets);
        await tester.tap(find.byKey(const Key('chat-composer')));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        tester.view.resetViewInsets();
        await tester.pumpAndSettle();
        offers.items.add(testOffer(id: 12, orderId: 2));
        await tester.tap(
          find.byTooltip(arabic ? 'تحديث العروض' : 'Refresh offers'),
        );
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.byKey(const Key('chat-edit-offer')));
        await tester.tap(find.byKey(const Key('chat-edit-offer')));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }
}
