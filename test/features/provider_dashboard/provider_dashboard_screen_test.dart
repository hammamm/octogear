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
import 'package:octogear/app/routing/app_router.dart';
import 'package:octogear/app/routing/app_routes.dart';
import 'package:octogear/core/api/api_failure.dart';
import 'package:octogear/core/config/customer_features.dart';
import 'package:octogear/core/design_system/octogear_theme.dart';
import 'package:octogear/core/localization/app_locale.dart';
import 'package:octogear/core/localization/app_locale_controller.dart';
import 'package:octogear/features/authentication/domain/entities/app_user.dart';
import 'package:octogear/features/authentication/presentation/controllers/registration_cities_controller.dart';
import 'package:octogear/features/authentication/presentation/controllers/session_controller.dart';
import 'package:octogear/features/customer_chats/domain/entities/chat.dart';
import 'package:octogear/features/customer_chats/domain/entities/chat_update.dart';
import 'package:octogear/features/customer_chats/presentation/controllers/chat_providers.dart';
import 'package:octogear/features/customer_chats/presentation/controllers/chat_realtime_providers.dart';
import 'package:octogear/features/customer_chats/presentation/screens/chat_conversation_screen.dart';
import 'package:octogear/features/provider_dashboard/data/models/provider_dashboard_dto.dart';
import 'package:octogear/features/provider_dashboard/domain/entities/provider_dashboard.dart';
import 'package:octogear/features/provider_dashboard/presentation/controllers/provider_dashboard_providers.dart';
import 'package:octogear/features/provider_dashboard/presentation/screens/provider_dashboard_activity_screen.dart';
import 'package:octogear/features/provider_dashboard/presentation/widgets/provider_dashboard_widgets.dart';
import 'package:octogear/features/provider_orders/presentation/controllers/provider_general_requests_providers.dart';
import 'package:octogear/features/provider_orders/presentation/controllers/provider_managed_orders_providers.dart';
import 'package:octogear/features/provider_orders/presentation/controllers/provider_offers_providers.dart';
import 'package:octogear/features/provider_orders/presentation/screens/provider_managed_order_screen.dart';
import 'package:octogear/features/provider_portal/presentation/screens/provider_dashboard_screen.dart';
import 'package:octogear/features/provider_portal/presentation/screens/provider_orders_screen.dart';
import 'package:octogear/features/provider_stores/presentation/controllers/provider_stores_providers.dart';
import 'package:octogear/features/provider_stores/presentation/screens/provider_stores_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../customer_chats/chat_fixtures.dart';
import '../provider_orders/provider_general_requests_fixtures.dart';
import '../provider_orders/provider_managed_orders_fixtures.dart';
import '../provider_orders/provider_offers_fixtures.dart';
import '../provider_stores/provider_stores_fixtures.dart';
import 'provider_dashboard_fixtures.dart';

class _Translations extends AssetLoader {
  const _Translations(this.values);
  final Map<String, Map<String, dynamic>> values;
  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async =>
      values[locale.languageCode]!;
}

class _Cities extends RegistrationCitiesController {
  @override
  Future<List<AppCity>> build() async => const [AppCity(id: 1, name: 'Riyadh')];
}

class _DashboardChats extends FakeChatRepository {
  final targets = <ChatTarget>[];
  @override
  Future<ChatContext> open(ChatTarget target) async {
    targets.add(target);
    opens++;
    return ChatContext(
      orderId: target.orderId,
      otherUserName: 'Customer One',
      storeName: 'Al Faris Parts',
    );
  }
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

  String tr(String key, {bool arabic = false}) =>
      translations[arabic ? 'ar' : 'en']!['provider_dashboard'][key] as String;

  Future<ProviderContainer> pump(
    WidgetTester tester,
    FakeDashboard dashboard, {
    _DashboardChats? chats,
    FakeManagedOrders? managedOrders,
    bool arabic = false,
    double scale = 1,
    bool settle = true,
  }) async {
    await tester.binding.setSurfaceSize(Size(scale == 1 ? 390 : 320, 844));
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      await tester.binding.setSurfaceSize(null);
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionControllerProvider.overrideWith(StoreSession.new),
          appLocaleProvider.overrideWith(
            () => StoreLocale(arabic ? AppLocale.arabic : AppLocale.english),
          ),
          customerStoresEnabledProvider.overrideWithValue(false),
          providerDashboardRepositoryProvider.overrideWithValue(dashboard),
          providerStoresRepositoryProvider.overrideWithValue(FakeStores()),
          providerGeneralRequestsRepositoryProvider.overrideWithValue(
            FakeGeneralRequests(),
          ),
          providerOffersRepositoryProvider.overrideWithValue(FakeOffers()),
          providerManagedOrdersRepositoryProvider.overrideWithValue(
            managedOrders ?? FakeManagedOrders(),
          ),
          providerOrderFilterStorageProvider.overrideWithValue(
            MemoryOrderFilterStorage(),
          ),
          registrationCitiesProvider.overrideWith(_Cities.new),
          chatRepositoryProvider.overrideWithValue(chats ?? _DashboardChats()),
          chatRealtimeConnectedProvider.overrideWithValue(true),
          chatRealtimeUpdatesProvider.overrideWith(
            (_) => const Stream<ChatUpdate>.empty(),
          ),
        ],
        child: EasyLocalization(
          supportedLocales: const [Locale('en'), Locale('ar')],
          startLocale: Locale(arabic ? 'ar' : 'en'),
          saveLocale: false,
          path: 'assets/translations',
          assetLoader: _Translations(translations),
          child: Consumer(
            builder: (context, ref, _) => RepaintBoundary(
              key: const Key('dashboard-preview'),
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
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      for (var i = 0; i < 5; i++) {
        await tester.pump();
      }
    }
    return ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
  }

  Future<void> reveal(
    WidgetTester tester,
    Finder target, {
    bool activity = false,
    double delta = 350,
  }) async {
    await tester.scrollUntilVisible(
      target,
      delta,
      scrollable: find
          .descendant(
            of: find.byType(
              activity
                  ? ProviderDashboardActivityScreen
                  : ProviderDashboardScreen,
            ),
            matching: find.byType(Scrollable),
          )
          .first,
      maxScrolls: 120,
    );
    await tester.pumpAndSettle();
  }

  for (final section in [
    ProviderDashboardSection.paid,
    ProviderDashboardSection.awaitingPayment,
    ProviderDashboardSection.pendingDirect,
  ]) {
    for (final storeId in <int?>[null, 2]) {
      testWidgets(
        'Show all ${section.name} opens within provider shell for store $storeId',
        (tester) async {
          final dashboard = FakeDashboard();
          dashboard.activityResponse = (query, page) async =>
              ProviderDashboardActivityPage(
                items: [
                  testDashboardOrder(
                    storeId: query.storeId ?? 1,
                    type: section == ProviderDashboardSection.awaitingPayment
                        ? 'general'
                        : 'specific',
                    status: section == ProviderDashboardSection.pendingDirect
                        ? 'pending'
                        : section.apiValue,
                  ),
                ],
                page: page,
                lastPage: 1,
                total: 1,
              );
          final container = await pump(tester, dashboard);
          if (storeId != null) {
            await tester.tap(
              find.byKey(const ValueKey('dashboard-store-null')),
            );
            await tester.pumpAndSettle();
            await tester.tap(find.text('Second Store').last);
            await tester.pumpAndSettle();
          }
          final button = find.byKey(
            ValueKey('dashboard-view-${section.apiValue}'),
          );
          await reveal(tester, button);
          await tester.tap(button);
          await tester.pumpAndSettle();
          expect(find.byType(UnknownRouteScreen), findsNothing);
          expect(find.byType(ProviderDashboardActivityScreen), findsOneWidget);
          expect(find.byType(NavigationBar), findsOneWidget);
          expect(dashboard.activityQueries.last.query, (
            section: section,
            storeId: storeId,
          ));
          container.read(appRouterProvider).pop();
          await tester.pumpAndSettle();
          expect(find.byType(ProviderDashboardScreen), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets(
    'General Requests is visible immediately and selects General after manual Orders tab changes',
    (tester) async {
      final container = await pump(tester, FakeDashboard());
      final general = find.byKey(const Key('provider-shortcut-orders'));
      expect(general.hitTestable(), findsOneWidget);
      await tester.tap(general);
      await tester.pumpAndSettle();
      expect(tester.widget<TabBar>(find.byType(TabBar)).controller!.index, 0);
      // Swiping must also update the route, without losing the selection
      // when switching between bottom-navigation branches.
      await tester.drag(find.byType(TabBarView), const Offset(-350, 0));
      await tester.pumpAndSettle();
      expect(tester.widget<TabBar>(find.byType(TabBar)).controller!.index, 1);
      expect(
        container
            .read(appRouterProvider)
            .routeInformationProvider
            .value
            .uri
            .queryParameters['section'],
        'direct',
      );
      await tester.tap(find.byKey(const Key('provider-nav-dashboard')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('provider-nav-orders')));
      await tester.pumpAndSettle();
      expect(tester.widget<TabBar>(find.byType(TabBar)).controller!.index, 1);
      await tester.ensureVisible(
        find.byKey(const ValueKey('provider-orders-offers')),
      );
      await tester.tap(find.byKey(const ValueKey('provider-orders-offers')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('provider-nav-dashboard')));
      await tester.pumpAndSettle();
      expect(general.hitTestable(), findsOneWidget);
      await tester.tap(general);
      await tester.pumpAndSettle();
      expect(tester.widget<TabBar>(find.byType(TabBar)).controller!.index, 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'order history replaces repeating recent cards and retains store scope',
    (tester) async {
      final dashboard = FakeDashboard();
      await pump(tester, dashboard);
      await tester.tap(find.byKey(const ValueKey('dashboard-store-null')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Second Store').last);
      await tester.pumpAndSettle();
      final history = find.byKey(const Key('dashboard-order-history'));
      await reveal(tester, history);
      expect(find.byKey(const ValueKey('dashboard-recent-31')), findsNothing);
      expect(find.byKey(const ValueKey('dashboard-view-recent')), findsNothing);
      await tester.tap(history);
      await tester.pumpAndSettle();
      expect(find.byType(ProviderDashboardActivityScreen), findsOneWidget);
      expect(dashboard.activityQueries.last.query, (
        storeId: 2,
        section: ProviderDashboardSection.recent,
      ));
      expect(find.byType(UnknownRouteScreen), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'paid and customer-accepted cards use distinct statuses and open the correct provider chat without sending',
    (tester) async {
      final dashboard = FakeDashboard();
      final chats = _DashboardChats();
      final container = await pump(tester, dashboard, chats: chats);
      expect(find.byType(ProviderDashboardScreen), findsOneWidget);
      expect(find.text(tr('paid_count')), findsOneWidget);
      await _preview(tester, 'dashboard-en');
      for (final (section, id, status) in [
        ('paid', 31, 'paid'),
        ('awaiting_payment', 32, 'awaiting_payment'),
      ]) {
        final card = find.byKey(ValueKey('dashboard-$section-$id'));
        await reveal(tester, card);
        expect(
          tester
              .widget<DashboardOrderStatus>(
                find.descendant(
                  of: card,
                  matching: find.byType(DashboardOrderStatus),
                ),
              )
              .status,
          status,
        );
        expect(
          find.descendant(of: card, matching: find.text('Customer One')),
          findsOneWidget,
        );
        final button = find.descendant(
          of: card,
          matching: find.byKey(ValueKey('dashboard-chat-$id')),
        );
        await _preview(
          tester,
          section == 'paid' ? 'dashboard-paid-card' : 'dashboard-accepted-card',
        );
        await reveal(tester, button);
        await _preview(
          tester,
          section == 'paid' ? 'dashboard-paid-chat' : 'dashboard-accepted-chat',
        );
        await tester.tap(button);
        await tester.pumpAndSettle();
        expect(find.byType(ChatConversationScreen), findsOneWidget);
        expect(
          tester
              .widget<ChatConversationScreen>(
                find.byType(ChatConversationScreen),
              )
              .provider,
          isTrue,
        );
        expect(chats.targets.last, ChatTarget.providerOrder(id));
        expect(find.text('Customer One'), findsOneWidget);
        expect(chats.sends, 0);
        container.read(appRouterProvider).pop();
        await tester.pumpAndSettle();
      }
      final pending = find.byKey(const ValueKey('dashboard-pending_direct-30'));
      await reveal(tester, pending);
      expect(
        find.descendant(
          of: pending,
          matching: find.byKey(const ValueKey('dashboard-chat-30')),
        ),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );

  for (final arabic in [false, true]) {
    testWidgets(
      'sales displays the API timezone and Saturday week hint (Arabic: $arabic)',
      (tester) async {
        final dashboard = FakeDashboard()
          ..response = (_) async => ProviderDashboardDto.fromJson({
            ...dashboardJson(period: 'week'),
            'sales': {
              ...dashboardJson(period: 'week')['sales'] as Map<String, dynamic>,
              'timezone': 'Asia/Dubai',
            },
          }).toEntity();
        await pump(tester, dashboard, arabic: arabic, scale: arabic ? 2 : 1);
        final hint = find.text(
          tr(
            'sales_hint',
            arabic: arabic,
          ).replaceAll('{timezone}', 'Asia/Dubai'),
        );
        await reveal(tester, hint);
        expect(hint, findsOneWidget);
        expect(find.textContaining('{timezone}'), findsNothing);
        expect(
          find.textContaining(arabic ? 'السبت' : 'Saturday'),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'store and sales-period controls send scoped queries; manual refresh preserves both',
    (tester) async {
      final dashboard = FakeDashboard();
      await pump(tester, dashboard);
      await tester.tap(find.byKey(const ValueKey('dashboard-store-null')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Second Store').last);
      await tester.pumpAndSettle();
      expect(dashboard.queries.last.storeId, 2);
      final period = find.byKey(const ValueKey('dashboard-period-month'));
      await reveal(tester, period);
      await tester.tap(period);
      await tester.pumpAndSettle();
      await tester.tap(find.text(tr('period_week')).last);
      await tester.pumpAndSettle();
      expect(dashboard.queries.last, (
        storeId: 2,
        period: ProviderDashboardPeriod.week,
      ));
      final before = dashboard.queries.length;
      await reveal(
        tester,
        find.byKey(const Key('dashboard-refresh')),
        delta: -350,
      );
      await tester.tap(find.byKey(const Key('dashboard-refresh')));
      await tester.pumpAndSettle();
      expect(dashboard.queries.length, before + 1);
      expect(dashboard.queries.last, (
        storeId: 2,
        period: ProviderDashboardPeriod.week,
      ));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'loading, recoverable error and empty-account views remain actionable',
    (tester) async {
      final result = Completer<ProviderDashboard>();
      final dashboard = FakeDashboard()..response = (_) => result.future;
      final container = await pump(tester, dashboard, settle: false);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      result.completeError(const ApiFailure(type: ApiFailureType.noConnection));
      await tester.pumpAndSettle();
      expect(find.byType(DashboardError), findsOneWidget);
      expect(find.byType(DashboardOrderCard), findsNothing);
      dashboard.response = (_) async => _emptyDashboard();
      await tester.tap(
        find.descendant(
          of: find.byType(DashboardError),
          matching: find.byType(OutlinedButton),
        ),
      );
      await tester.pumpAndSettle();
      expect(dashboard.queries.length, 2);
      expect(
        container.read(providerDashboardProvider).hasError,
        isFalse,
        reason: container.read(providerDashboardProvider).error.toString(),
      );
      expect(find.text(tr('no_stores')), findsOneWidget);
      expect(find.byType(DashboardOrderCard), findsNothing);
      await reveal(tester, find.byKey(const Key('provider-shortcut-stores')));
      expect(find.byKey(const Key('provider-shortcut-stores')), findsOneWidget);
      await _preview(tester, 'dashboard-empty');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'view-all carries store scope and pagination retry retains already loaded orders',
    (tester) async {
      final dashboard = FakeDashboard();
      var failNext = true;
      dashboard.activityResponse = (query, page) async {
        if (page == 2 && failNext) {
          throw const ApiFailure(type: ApiFailureType.noConnection);
        }
        return ProviderDashboardActivityPage(
          items: [testDashboardOrder(id: page == 1 ? 31 : 33, storeId: 2)],
          page: page,
          lastPage: 2,
          total: 2,
        );
      };
      await pump(tester, dashboard);
      await tester.tap(find.byKey(const ValueKey('dashboard-store-null')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Second Store').last);
      await tester.pumpAndSettle();
      final viewAll = find.byKey(const ValueKey('dashboard-view-paid'));
      await reveal(tester, viewAll);
      await tester.tap(viewAll);
      await tester.pumpAndSettle();
      expect(find.byType(ProviderDashboardActivityScreen), findsOneWidget);
      expect(dashboard.activityQueries.single.query, (
        storeId: 2,
        section: ProviderDashboardSection.paid,
      ));
      expect(
        tester
            .widget<ProviderDashboardActivityScreen>(
              find.byType(ProviderDashboardActivityScreen),
            )
            .storeId,
        2,
      );
      await reveal(tester, find.text(tr('load_more')), activity: true);
      await tester.tap(find.text(tr('load_more')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('activity-order-31')), findsOneWidget);
      final retry = find.descendant(
        of: find.byType(DashboardError),
        matching: find.byType(OutlinedButton),
      );
      await reveal(tester, retry, activity: true);
      failNext = false;
      await tester.tap(retry);
      await tester.pumpAndSettle();
      await reveal(
        tester,
        find.byKey(const ValueKey('activity-order-33')),
        activity: true,
      );
      expect(find.byKey(const ValueKey('activity-order-33')), findsOneWidget);
      expect(dashboard.activityQueries.map((request) => request.page), [
        1,
        2,
        2,
      ]);
      expect(find.text(tr('load_more')), findsNothing);
      await _preview(tester, 'dashboard-paid-activity');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'returning from order details reloads activity and removes newly completed payments',
    (tester) async {
      final dashboard = FakeDashboard();
      final managed = FakeManagedOrders()
        ..items = [testManagedOrder(status: 'paid')];
      final container = await pump(tester, dashboard, managedOrders: managed);
      final viewAll = find.byKey(const ValueKey('dashboard-view-paid'));
      await reveal(tester, viewAll);
      await tester.tap(viewAll);
      await tester.pumpAndSettle();
      final details = find.byKey(const ValueKey('dashboard-details-31'));
      await reveal(tester, details, activity: true);
      await tester.tap(details);
      await tester.pumpAndSettle();
      expect(find.byType(ProviderManagedOrderScreen), findsOneWidget);
      final dashboardReads = dashboard.queries.length;
      final activityReads = dashboard.activityQueries.length;
      // The customer's receipt confirmation can happen while the provider reads
      // these details; returning must not keep that order in outstanding payments.
      dashboard.activityResponse = (_, page) async =>
          ProviderDashboardActivityPage(
            items: const [],
            page: page,
            lastPage: 1,
            total: 0,
          );
      container.read(appRouterProvider).pop();
      await tester.pumpAndSettle();
      expect(find.byType(ProviderDashboardActivityScreen), findsOneWidget);
      expect(dashboard.activityQueries.length, activityReads + 1);
      expect(dashboard.queries.length, greaterThan(dashboardReads));
      expect(find.byType(DashboardOrderCard), findsNothing);
      expect(find.text(tr('paid_empty')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'dashboard shortcuts select the requested orders tab and stores workspace',
    (tester) async {
      final container = await pump(tester, FakeDashboard());
      for (final (key, index) in [
        ('provider-shortcut-offers', 2),
        ('provider-shortcut-orders', 0),
      ]) {
        await reveal(tester, find.byKey(Key(key)));
        await tester.tap(find.byKey(Key(key)));
        await tester.pumpAndSettle();
        expect(find.byType(ProviderOrdersScreen), findsOneWidget);
        expect(
          tester.widget<TabBar>(find.byType(TabBar)).controller!.index,
          index,
        );
        await tester.tap(find.byKey(const Key('provider-nav-dashboard')));
        await tester.pumpAndSettle();
      }
      await reveal(tester, find.byKey(const Key('provider-shortcut-stores')));
      await tester.tap(find.byKey(const Key('provider-shortcut-stores')));
      await tester.pumpAndSettle();
      expect(find.byType(ProviderStoresScreen), findsOneWidget);
      expect(
        container
            .read(appRouterProvider)
            .routeInformationProvider
            .value
            .uri
            .path,
        '/provider/more/stores',
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Arabic dashboard and activity remain usable at 320 pixels and twice text scale',
    (tester) async {
      final dashboard = FakeDashboard();
      final container = await pump(tester, dashboard, arabic: true, scale: 2);
      expect(
        Directionality.of(tester.element(find.byType(ProviderDashboardScreen))),
        ui.TextDirection.rtl,
      );
      await _preview(tester, 'dashboard-ar');
      await tester.tap(find.byKey(const ValueKey('dashboard-store-null')));
      await tester.pumpAndSettle();
      expect(find.text('Al Faris Parts').last, findsOneWidget);
      expect(find.text('Second Store').last, findsOneWidget);
      expect(tester.takeException(), isNull);
      await _preview(tester, 'dashboard-store-menu-ar');
      await tester.tap(find.text(tr('all_stores', arabic: true)).last);
      await tester.pumpAndSettle();
      for (final key in [
        'dashboard-chat-31',
        'dashboard-chat-32',
        'dashboard-details-30',
        'dashboard-period-month',
        'provider-shortcut-stores',
      ]) {
        await reveal(
          tester,
          key == 'dashboard-chat-31'
              ? find.descendant(
                  of: find.byKey(const ValueKey('dashboard-paid-31')),
                  matching: find.byKey(ValueKey(key)),
                )
              : find.byKey(ValueKey(key)),
        );
        expect(tester.takeException(), isNull);
        if (key == 'dashboard-chat-31') {
          await _preview(tester, 'dashboard-paid-ar-large');
        }
      }
      final viewAll = find.byKey(const ValueKey('dashboard-view-paid'));
      await reveal(tester, viewAll, delta: -350);
      await tester.tap(viewAll);
      await tester.pumpAndSettle();
      await reveal(
        tester,
        find.byKey(const ValueKey('dashboard-chat-31')),
        activity: true,
      );
      expect(tester.takeException(), isNull);
      await tester.tap(find.byKey(const ValueKey('dashboard-chat-31')));
      await tester.pumpAndSettle();
      expect(find.byType(ChatConversationScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
      await _preview(tester, 'dashboard-customer-chat-ar');
      expect(container.read(appRouterProvider).canPop(), isTrue);
    },
  );
}

ProviderDashboard _emptyDashboard() {
  const emptyGroup = {'total': 0, 'items': <Object>[]};
  return ProviderDashboardDto.fromJson({
    ...dashboardJson(),
    'stores': <Object>[],
    'counts': {
      'pending_direct_requests': 0,
      'pending_offers': 0,
      'accepted_offers': 0,
      'paid_orders': 0,
    },
    'sales': {
      ...dashboardJson()['sales'] as Map<String, dynamic>,
      'amount': 0,
      'count': 0,
    },
    'attention': {
      'pending_direct': emptyGroup,
      'awaiting_payment': emptyGroup,
      'paid': emptyGroup,
    },
    'recent_orders': emptyGroup,
  }).toEntity();
}

Future<void> _preview(WidgetTester tester, String name) async {
  if (!const bool.fromEnvironment('CAPTURE_PROVIDER_NAV_PREVIEWS')) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const Key('dashboard-preview')),
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
