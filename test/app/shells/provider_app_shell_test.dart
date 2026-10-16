import 'package:octogear/features/provider_stores/domain/entities/provider_store.dart';
import 'package:octogear/features/provider_orders/presentation/controllers/provider_offers_providers.dart';
import 'package:octogear/features/provider_orders/presentation/screens/provider_offer_screen.dart';
import '../../features/provider_orders/provider_offers_fixtures.dart';
import '../../features/provider_orders/provider_managed_orders_fixtures.dart';
import 'package:octogear/features/provider_orders/presentation/controllers/provider_managed_orders_providers.dart';
import 'package:octogear/features/provider_orders/presentation/screens/provider_managed_order_screen.dart';
import 'package:octogear/features/provider_orders/presentation/screens/provider_general_request_screen.dart';
import 'package:octogear/core/api/api_failure.dart';
import 'package:octogear/features/authentication/domain/entities/app_user.dart';
import 'package:octogear/features/authentication/presentation/controllers/registration_cities_controller.dart';
import 'package:octogear/features/provider_orders/presentation/controllers/provider_general_requests_providers.dart';
import '../../features/provider_orders/provider_general_requests_fixtures.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:octogear/app/routing/app_router.dart';
import 'package:octogear/core/config/customer_features.dart';
import 'package:octogear/core/design_system/octogear_theme.dart';
import 'package:octogear/core/localization/app_locale.dart';
import 'package:octogear/core/localization/app_locale_controller.dart';
import 'package:octogear/features/authentication/domain/entities/session_outcome.dart';
import 'package:octogear/features/authentication/presentation/controllers/session_controller.dart';
import 'package:octogear/features/customer_chats/domain/entities/chat.dart';
import 'package:octogear/features/customer_chats/presentation/controllers/chat_providers.dart';
import 'package:octogear/features/customer_chats/presentation/controllers/chat_realtime_providers.dart';
import 'package:octogear/features/customer_chats/presentation/screens/customer_chats_screen.dart';
import 'package:octogear/features/provider_portal/presentation/screens/provider_dashboard_screen.dart';
import 'package:octogear/features/provider_portal/presentation/screens/provider_orders_screen.dart';
import 'package:octogear/features/provider_portal/presentation/screens/provider_more_screen.dart';
import 'package:octogear/features/provider_stores/presentation/controllers/provider_stores_providers.dart';
import 'package:octogear/features/provider_stores/presentation/screens/provider_stores_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/provider_stores/provider_stores_fixtures.dart';

class _Translations extends AssetLoader {
  const _Translations(this.values);
  final Map<String, Map<String, dynamic>> values;
  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async =>
      values[locale.languageCode]!;
}

class _Session extends StoreSession {
  @override
  Future<void> signOut() async => replace(const SignedOutSession());
}

class _Cities extends RegistrationCitiesController {
  @override
  Future<List<AppCity>> build() async => const [
    AppCity(id: 1, name: 'Riyadh'),
    AppCity(id: 2, name: 'Jeddah'),
  ];
}

class _Inbox extends ChatInboxController {
  @override
  Future<ChatInbox> build() async => const ChatInbox([], 1, 1);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final translations = <String, Map<String, dynamic>>{};
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    for (final code in ['en', 'ar']) {
      translations[code] = jsonDecode(
        await rootBundle.loadString('assets/translations/$code.json'),
      );
    }
    for (final font in [
      ('Noto Sans', 'NotoSans.ttf'),
      ('Noto Sans Arabic', 'NotoSansArabic.ttf'),
      ('MaterialIcons', null),
    ]) {
      await (FontLoader(font.$1)..addFont(
            rootBundle.load(
              font.$2 == null
                  ? 'fonts/MaterialIcons-Regular.otf'
                  : 'assets/fonts/${font.$2}',
            ),
          ))
          .load();
    }
  });

  Future<ProviderContainer> pump(
    WidgetTester tester,
    FakeStores stores, {
    FakeGeneralRequests? requests,
    FakeOffers? offers,
    FakeManagedOrders? managedOrders,
    bool arabic = false,
    double scale = 1,
  }) async {
    await tester.binding.setSurfaceSize(Size(scale == 1 ? 390 : 320, 844));
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      await tester.binding.setSurfaceSize(null);
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionControllerProvider.overrideWith(_Session.new),
          appLocaleProvider.overrideWith(
            () => StoreLocale(arabic ? AppLocale.arabic : AppLocale.english),
          ),
          customerStoresEnabledProvider.overrideWithValue(false),
          providerStoresRepositoryProvider.overrideWithValue(stores),
          providerGeneralRequestsRepositoryProvider.overrideWithValue(
            requests ?? FakeGeneralRequests(),
          ),
          providerOffersRepositoryProvider.overrideWithValue(
            offers ?? FakeOffers(),
          ),
          providerManagedOrdersRepositoryProvider.overrideWithValue(
            managedOrders ?? FakeManagedOrders(),
          ),
          providerOrderFilterStorageProvider.overrideWithValue(
            MemoryOrderFilterStorage(),
          ),
          registrationCitiesProvider.overrideWith(_Cities.new),
          chatInboxProvider.overrideWith(_Inbox.new),
          chatRealtimeConnectedProvider.overrideWithValue(true),
        ],
        child: EasyLocalization(
          supportedLocales: const [Locale('en'), Locale('ar')],
          startLocale: Locale(arabic ? 'ar' : 'en'),
          saveLocale: false,
          path: 'assets/translations',
          assetLoader: _Translations(translations),
          child: Consumer(
            builder: (context, ref, _) => RepaintBoundary(
              key: const Key('provider-preview'),
              child: MaterialApp.router(
                debugShowCheckedModeBanner: false,
                theme: OctoGearTheme.forLocale(context.locale),
                locale: context.locale,
                supportedLocales: context.supportedLocales,
                localizationsDelegates: context.localizationDelegates,
                routerConfig: ref.watch(appRouterProvider),
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(textScaler: TextScaler.linear(scale)),
                  child: child!,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
  }

  Future<void> tab(WidgetTester tester, String name) async {
    await tester.tap(find.byKey(Key('provider-nav-$name')));
    await tester.pumpAndSettle();
  }

  Future<void> scrollOrderTo(WidgetTester tester, Finder target) =>
      tester.scrollUntilVisible(
        target,
        300,
        scrollable: find
            .descendant(
              of: find.byType(ProviderManagedOrderScreen),
              matching: find.byType(Scrollable),
            )
            .first,
        maxScrolls: 80,
      );

  testWidgets(
    'provider starts on dashboard; orders tabs preserve selection without fetching stores',
    (tester) async {
      final stores = FakeStores();
      final container = await pump(tester, stores);
      expect(find.byType(ProviderDashboardScreen), findsOneWidget);
      expect(find.byType(ProviderStoresScreen), findsNothing);
      expect(stores.calls, 0);
      expect(find.byType(NavigationDestination), findsNWidgets(4));
      await _preview(tester, 'provider-dashboard-en');
      await tab(tester, 'orders');
      expect(find.byType(ProviderOrdersScreen), findsOneWidget);
      expect(find.byType(Tab), findsNWidgets(4));
      await tester.ensureVisible(
        find.byKey(const ValueKey('provider-orders-offers')),
      );
      await tester.tap(find.byKey(const ValueKey('provider-orders-offers')));
      await tester.pumpAndSettle();
      expect(
        find.text(translations['en']!['provider_offers']['empty']),
        findsOneWidget,
      );
      await _preview(tester, 'provider-orders-en');
      await tab(tester, 'more');
      await tab(tester, 'orders');
      final controller = DefaultTabController.of(
        tester.element(find.byType(TabBar)),
      );
      expect(controller.index, 2);
      expect(stores.calls, 0);
      // A provider cannot enter the customer app through a direct URL.
      container.read(appRouterProvider).go('/customer/orders');
      await tester.pumpAndSettle();
      expect(
        container
            .read(appRouterProvider)
            .routeInformationProvider
            .value
            .uri
            .path,
        '/provider',
      );
      expect(find.byType(ProviderDashboardScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'More owns store details, refresh, profile and settings; tab changes preserve child route',
    (tester) async {
      final stores = FakeStores();
      final container = await pump(tester, stores);
      await tab(tester, 'more');
      expect(find.byType(ProviderMoreScreen), findsOneWidget);
      await _preview(tester, 'provider-more-en');
      await tester.tap(find.byKey(const Key('provider-more-stores')));
      await tester.pumpAndSettle();
      expect(find.byType(ProviderStoresScreen), findsOneWidget);
      expect(find.text(store.name), findsOneWidget);
      expect(stores.calls, 1);
      expect(
        container
            .read(appRouterProvider)
            .routeInformationProvider
            .value
            .uri
            .path,
        '/provider/more/stores',
      );
      await tester.tap(find.byTooltip('Refresh stores'));
      await tester.pumpAndSettle();
      expect(stores.calls, 2);
      await tab(tester, 'dashboard');
      await tab(tester, 'more');
      expect(find.byType(ProviderStoresScreen), findsOneWidget);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.byType(ProviderMoreScreen), findsOneWidget);
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();
      expect(find.byType(ProviderProfileScreen), findsOneWidget);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();
      expect(find.byType(ProviderSettingsScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Chats keeps provider mode in the shell; store shortcut activates More',
    (tester) async {
      final stores = FakeStores();
      final container = await pump(tester, stores);
      await tab(tester, 'chats');
      final chats = tester.widget<CustomerChatsScreen>(
        find.byType(CustomerChatsScreen),
      );
      expect(chats.provider, isTrue);
      expect(chats.embeddedInShell, isTrue);
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(
        container
            .read(appRouterProvider)
            .routeInformationProvider
            .value
            .uri
            .path,
        '/provider/chats',
      );
      await tab(tester, 'dashboard');
      await tester.ensureVisible(
        find.byKey(const Key('provider-shortcut-stores')),
      );
      await tester.tap(find.byKey(const Key('provider-shortcut-stores')));
      await tester.pumpAndSettle();
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        3,
      );
      expect(find.byType(ProviderStoresScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'General requests filter, refresh and open details inside the provider shell',
    (tester) async {
      final repo = FakeGeneralRequests();
      await pump(tester, FakeStores(), requests: repo);
      await tab(tester, 'orders');
      expect(repo.calls, [(null, 1)]);
      expect(find.text('Front headlight'), findsOneWidget);
      expect(find.text('Riyadh'), findsOneWidget);
      await _preview(tester, 'provider-general-en');
      await tester.tap(find.byKey(const Key('provider-city-select')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('registration-city-search')),
        'Jeddah',
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('registration-city-1')), findsNothing);
      await tester.tap(find.byKey(const ValueKey('registration-city-2')));
      await tester.pumpAndSettle();
      expect(repo.calls.last, (2, 1));
      await tester.tap(find.byKey(const Key('provider-city-all')));
      await tester.pumpAndSettle();
      expect(repo.calls.last, (null, 1));
      final count = repo.calls.length;
      await tester.tap(find.byTooltip('Refresh requests'));
      await tester.pumpAndSettle();
      expect(repo.calls.length, count + 1);
      await tester.tap(find.byKey(const ValueKey('provider-request-1')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<ProviderGeneralRequestScreen>(
              find.byType(ProviderGeneralRequestScreen),
            )
            .orderId,
        1,
      );
      expect(repo.detailCalls, [1]);
      expect(find.text('Right side headlight'), findsOneWidget);
      expect(find.byType(NavigationBar), findsOneWidget);
      await _preview(tester, 'provider-general-detail-en');
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('provider-request-1')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'General requests recover from error and empty results through refresh',
    (tester) async {
      final repo = FakeGeneralRequests()
        ..onList = (_, _) async =>
            throw const ApiFailure(type: ApiFailureType.noConnection);
      await pump(tester, FakeStores(), requests: repo);
      await tab(tester, 'orders');
      expect(find.text('Front headlight'), findsNothing);
      repo.onList = (_, _) async => requestPage([]);
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(find.text('No open requests'), findsOneWidget);
      repo.onList = null;
      await tester.tap(find.byTooltip('Refresh requests'));
      await tester.pumpAndSettle();
      expect(find.text('Front headlight'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'My store city uses owned stores and load more appends requests',
    (tester) async {
      final repo = FakeGeneralRequests()
        ..onList = (city, page) async => requestPage(
          [generalRequest(id: page, cityId: city ?? 1)],
          page: page,
          lastPage: 2,
          total: 2,
        );
      final stores = FakeStores();
      await pump(tester, stores, requests: repo);
      await tab(tester, 'orders');
      expect(stores.calls, 0);
      await tester.tap(find.byKey(const Key('provider-city-store')));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ListTile, 'Riyadh'));
      await tester.pumpAndSettle();
      expect(stores.calls, 1);
      expect(repo.calls.last, (1, 1));
      await tester.scrollUntilVisible(
        find.byKey(const Key('provider-requests-more')),
        250,
        scrollable: find.descendant(
          of: find.byType(CustomScrollView),
          matching: find.byType(Scrollable),
        ),
      );
      await tester.tap(find.byKey(const Key('provider-requests-more')));
      await tester.pumpAndSettle();
      expect(repo.calls.last, (1, 2));
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('provider-request-2')),
        200,
        scrollable: find.descendant(
          of: find.byType(CustomScrollView),
          matching: find.byType(Scrollable),
        ),
      );
      expect(find.byKey(const ValueKey('provider-request-2')), findsOneWidget);
      expect(find.byKey(const Key('provider-requests-more')), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Provider creates, reviews, edits and withdraws an offer', (
    tester,
  ) async {
    final offers = FakeOffers();
    final container = await pump(tester, FakeStores(), offers: offers);
    container.read(appRouterProvider).go('/provider/orders/general/1');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('provider-create-offer')));
    await tester.pumpAndSettle();
    await _preview(tester, 'provider-offer-form-en');
    await tester.enterText(
      find.byKey(const Key('provider-offer-price')),
      '123.45',
    );
    await tester.enterText(
      find.byKey(const Key('provider-offer-notes')),
      'Available today',
    );
    await tester.ensureVisible(find.byKey(const Key('provider-offer-submit')));
    await tester.tap(find.byKey(const Key('provider-offer-submit')));
    await tester.pumpAndSettle();
    expect(offers.saves, isEmpty);
    await tester.tap(find.text('Confirm and submit'));
    await tester.pumpAndSettle();
    expect(offers.saves.single.price, 12345);
    expect(offers.saves.single.storeId, 1);
    expect(find.byType(ProviderOfferScreen), findsOneWidget);
    expect(find.text('Available today'), findsOneWidget);
    await _preview(tester, 'provider-offer-detail-en');
    await tester.ensureVisible(find.byKey(const Key('provider-offer-edit')));
    await tester.tap(find.byKey(const Key('provider-offer-edit')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('provider-offer-price')),
      '200',
    );
    await tester.ensureVisible(find.byKey(const Key('provider-offer-submit')));
    await tester.tap(find.byKey(const Key('provider-offer-submit')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirm and submit'));
    await tester.pumpAndSettle();
    expect(offers.saves.last.offerId, 11);
    expect(offers.saves.last.price, 20000);
    expect(offers.saves.last.photos, isNull);
    await tester.ensureVisible(
      find.byKey(const Key('provider-offer-withdraw')),
    );
    await tester.tap(find.byKey(const Key('provider-offer-withdraw')));
    await tester.pumpAndSettle();
    expect(offers.withdrawals, 0);
    await tester.tap(find.widgetWithText(FilledButton, 'Withdraw offer'));
    await tester.pumpAndSettle();
    expect(offers.withdrawals, 1);
    expect(offers.items, isEmpty);
    expect(find.byType(ProviderGeneralRequestScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Arabic offer form fits narrow screens and accepted offers hide mutations',
    (tester) async {
      final offers = FakeOffers()
        ..items = [
          testOffer(status: 'accepted', orderStatus: 'awaiting_payment'),
        ];
      final container = await pump(
        tester,
        FakeStores(),
        offers: offers,
        arabic: true,
        scale: 2,
      );
      container.read(appRouterProvider).go('/provider/orders/offers/11');
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('provider-offer-edit')), findsNothing);
      expect(find.byKey(const Key('provider-offer-withdraw')), findsNothing);
      expect(tester.takeException(), isNull);
      container.read(appRouterProvider).go('/provider/orders/general/1/offer');
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('provider-offer-price')),
        '١٢٫٥٠',
      );
      await tester.ensureVisible(
        find.byKey(const Key('provider-offer-submit')),
      );
      await tester.pumpAndSettle();
      await _preview(tester, 'provider-offer-form-ar-large');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Multiple stores require a choice and My Offers opens the correct offer',
    (tester) async {
      final stores = FakeStores()
        ..response = () async => [
          store,
          const ProviderStore(
            id: 2,
            name: 'Second store',
            status: ProviderStoreStatus.active,
            brands: [],
          ),
          const ProviderStore(
            id: 3,
            name: 'Inactive store',
            status: ProviderStoreStatus.inactive,
            brands: [],
          ),
        ];
      final offers = FakeOffers()..items = [testOffer()];
      final container = await pump(tester, stores, offers: offers);
      await tab(tester, 'orders');
      await tester.ensureVisible(
        find.byKey(const ValueKey('provider-orders-offers')),
      );
      await tester.tap(find.byKey(const ValueKey('provider-orders-offers')));
      await tester.pumpAndSettle();
      await _preview(tester, 'provider-my-offers-en');
      await tester.tap(find.text('View my offer'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<ProviderOfferScreen>(find.byType(ProviderOfferScreen))
            .offerId,
        11,
      );
      container.read(appRouterProvider).go('/provider/orders/general/1/offer');
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('provider-offer-price')),
        '1.001',
      );
      await tester.ensureVisible(
        find.byKey(const Key('provider-offer-submit')),
      );
      await tester.tap(find.byKey(const Key('provider-offer-submit')));
      await tester.pumpAndSettle();
      expect(offers.saves, isEmpty);
      expect(find.text('Choose a store'), findsOneWidget);
      await tester.ensureVisible(find.byType(DropdownButtonFormField<int>));
      await tester.tap(find.byType(DropdownButtonFormField<int>));
      await tester.pumpAndSettle();
      expect(find.text('Inactive store'), findsNothing);
      await tester.tap(find.text('Second store').last);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('provider-offer-price')),
        '12.50',
      );
      await tester.ensureVisible(
        find.byKey(const Key('provider-offer-submit')),
      );
      await tester.tap(find.byKey(const Key('provider-offer-submit')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirm and submit'));
      await tester.pumpAndSettle();
      expect(offers.saves.single.storeId, 2);
      expect(offers.saves.single.price, 1250);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Direct requests require confirmation and move to awaiting payment',
    (tester) async {
      final orders = FakeManagedOrders()..items = [testManagedOrder()];
      await pump(tester, FakeStores(), managedOrders: orders);
      await tab(tester, 'orders');
      await tester.tap(find.byKey(const ValueKey('provider-orders-direct')));
      await tester.pumpAndSettle();
      await _preview(tester, 'provider-direct-orders');
      final card = find.byKey(const ValueKey('provider-direct-order-31'));
      final open = find.descendant(
        of: card,
        matching: find.byType(OutlinedButton),
      );
      await tester.ensureVisible(open);
      await tester.tap(open);
      await tester.pumpAndSettle();
      expect(find.byType(ProviderManagedOrderScreen), findsOneWidget);
      await _preview(tester, 'provider-direct-details');
      final accept = find.byKey(const Key('provider-order-accept'));
      await scrollOrderTo(tester, accept);
      await tester.tap(accept);
      await tester.pumpAndSettle();
      expect(orders.responses, isEmpty);
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(TextButton),
        ),
      );
      await tester.pumpAndSettle();
      expect(orders.responses, isEmpty);
      await tester.tap(accept);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('provider-order-confirm')));
      await tester.pumpAndSettle();
      expect(orders.responses, [(31, true)]);
      expect(find.byKey(const Key('provider-order-accept')), findsNothing);
      expect(find.byKey(const Key('provider-order-reject')), findsNothing);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('provider-direct-filter-awaiting_payment')),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('provider-direct-order-31')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Direct request rejection refreshes list and paid history shows completed orders',
    (tester) async {
      final orders = FakeManagedOrders()
        ..items = [
          testManagedOrder(),
          testManagedOrder(id: 32, status: 'paid'),
          testManagedOrder(id: 33, status: 'completed'),
        ];
      final container = await pump(tester, FakeStores(), managedOrders: orders);
      container.read(appRouterProvider).go('/provider/orders/direct/31');
      await tester.pumpAndSettle();
      final reject = find.byKey(const Key('provider-order-reject'));
      await scrollOrderTo(tester, reject);
      await tester.tap(reject);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('provider-order-confirm')));
      await tester.pumpAndSettle();
      expect(orders.responses, [(31, false)]);
      expect(find.byKey(const Key('provider-order-accept')), findsNothing);
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      container.read(appRouterProvider).go('/provider/orders');
      await tester.pumpAndSettle();
      final paid = find.byKey(const ValueKey('provider-orders-paid'));
      await tester.ensureVisible(paid);
      await tester.tap(paid);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('provider-paid-order-32')),
        findsOneWidget,
      );
      await _preview(tester, 'provider-paid-orders');
      await tester.tap(
        find.byKey(const ValueKey('provider-paid-filter-completed')),
      );
      await tester.pumpAndSettle();
      final open = find.descendant(
        of: find.byKey(const ValueKey('provider-paid-order-33')),
        matching: find.byType(OutlinedButton),
      );
      await tester.ensureVisible(open);
      await tester.tap(open);
      await tester.pumpAndSettle();
      expect(find.byType(ProviderManagedOrderScreen), findsOneWidget);
      expect(find.byKey(const Key('provider-order-accept')), findsNothing);
      expect(find.byKey(const Key('provider-order-reject')), findsNothing);
      expect(
        find.text(translations['en']!['provider_orders']['commission']),
        findsOneWidget,
      );
      await _preview(tester, 'provider-paid-details');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Arabic paid details and direct actions fit narrow large-text screens',
    (tester) async {
      final orders = FakeManagedOrders()
        ..items = [
          testManagedOrder(),
          testManagedOrder(id: 32, status: 'paid'),
        ];
      final container = await pump(
        tester,
        FakeStores(),
        managedOrders: orders,
        arabic: true,
        scale: 2,
      );
      container.read(appRouterProvider).go('/provider/orders/paid/32');
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await _preview(tester, 'provider-paid-details-ar-large');
      container.read(appRouterProvider).go('/provider/orders/direct/31');
      await tester.pumpAndSettle();
      final accept = find.byKey(const Key('provider-order-accept'));
      await scrollOrderTo(tester, accept);
      await tester.tap(accept);
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(tester.takeException(), isNull);
      await _preview(tester, 'provider-direct-confirm-ar-large');
    },
  );

  testWidgets('Direct request loading errors can be retried', (tester) async {
    final orders = FakeManagedOrders()
      ..onList = (_, _) async =>
          throw const ApiFailure(type: ApiFailureType.noConnection);
    await pump(tester, FakeStores(), managedOrders: orders);
    await tab(tester, 'orders');
    await tester.tap(find.byKey(const ValueKey('provider-orders-direct')));
    await tester.pumpAndSettle();
    expect(
      find.text(translations['en']!['errors']['no_connection']),
      findsOneWidget,
    );
    orders.onList = null;
    orders.items = [testManagedOrder()];
    await tester.tap(find.text(translations['en']!['common']['retry']));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('provider-direct-order-31')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Arabic navigation and orders work at narrow width and double text scale',
    (tester) async {
      await pump(tester, FakeStores(), arabic: true, scale: 2);
      expect(
        Directionality.of(tester.element(find.byType(NavigationBar))),
        ui.TextDirection.rtl,
      );
      expect(tester.takeException(), isNull);
      await _preview(tester, 'provider-dashboard-ar-large');
      await tab(tester, 'orders');
      expect(tester.takeException(), isNull);
      await _preview(tester, 'provider-general-ar-large');
      await tester.ensureVisible(
        find.byKey(const ValueKey('provider-orders-paid')),
      );
      await tester.tap(find.byKey(const ValueKey('provider-orders-paid')));
      await tester.pumpAndSettle();
      expect(
        find.text(translations['ar']!['provider_orders']['paid_empty']),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await tab(tester, 'more');
      expect(find.byType(ProviderMoreScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

Future<void> _preview(WidgetTester tester, String name) async {
  if (!const bool.fromEnvironment('CAPTURE_PROVIDER_NAV_PREVIEWS')) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const Key('provider-preview')),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    final directory = Directory('build/provider-navigation-previews')
      ..createSync(recursive: true);
    await File(
      '${directory.path}/$name.png',
    ).writeAsBytes(bytes!.buffer.asUint8List());
  });
}
