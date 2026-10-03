import 'package:octogear/features/customer_orders/presentation/screens/customer_offer_details_screen.dart';
import 'package:octogear/features/customer_orders/presentation/screens/refuse_customer_offer_screen.dart';
import 'package:octogear/features/customer_chats/presentation/screens/customer_chats_screen.dart';
import 'dart:async';
import 'package:octogear/core/api/api_failure.dart';
import 'package:octogear/features/customer_orders/domain/entities/customer_order.dart';
import 'package:octogear/features/customer_orders/data/models/customer_order_dto.dart';
import 'package:octogear/features/customer_garage/presentation/controllers/customer_cars_providers.dart';
import '../../features/general_requests/general_request_fixtures.dart';
import 'dart:convert';

import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:octogear/app/octogear_app.dart';
import 'package:octogear/app/routing/app_router.dart';
import 'package:octogear/core/config/customer_features.dart';
import 'package:octogear/features/customer_orders/presentation/controllers/customer_orders_providers.dart';
import 'package:octogear/features/customer_orders/presentation/screens/customer_order_details_screen.dart';
import '../../features/customer_orders/order_fixtures.dart';
import 'package:octogear/core/localization/app_locale.dart';
import 'package:octogear/core/localization/app_locale_controller.dart';
import 'package:octogear/features/authentication/domain/entities/app_user.dart';
import 'package:octogear/features/authentication/domain/entities/session_outcome.dart';
import 'package:octogear/features/authentication/presentation/controllers/session_controller.dart';
import 'package:octogear/features/storefront/domain/entities/marketplace_store.dart';
import 'package:octogear/features/storefront/domain/entities/storefront_filter_options.dart';
import 'package:octogear/features/storefront/domain/entities/storefront_filters.dart';
import 'package:octogear/features/storefront/domain/entities/storefront_page.dart';
import 'package:octogear/features/storefront/domain/entities/storefront_store_car.dart';
import 'package:octogear/features/storefront/domain/entities/storefront_store_cars_page.dart';
import 'package:octogear/features/storefront/domain/entities/storefront_store_details.dart';
import 'package:octogear/features/storefront/domain/repositories/storefront_repository.dart';
import 'package:octogear/features/storefront/domain/use_cases/get_store_cars_use_case.dart';
import 'package:octogear/features/storefront/domain/use_cases/get_store_details_use_case.dart';
import 'package:octogear/features/storefront/domain/use_cases/search_stores_use_case.dart';
import 'package:octogear/features/storefront/presentation/controllers/storefront_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:octogear/features/storefront/presentation/controllers/storefront_car_catalog_providers.dart';
import '../../features/storefront/support/car_catalog_fixtures.dart';
import 'package:octogear/features/part_requests/presentation/controllers/part_request_providers.dart';
import 'package:octogear/features/part_requests/presentation/services/part_request_photo_picker.dart';
import 'package:octogear/features/part_requests/presentation/screens/request_part_screen.dart';
import '../../features/part_requests/part_request_test.dart'
    show FakeRequestRepository;
import '../../features/part_requests/request_part_screen_test.dart'
    show FakePhotoPicker;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late final Map<String, dynamic> englishTranslations;
  late final Map<String, dynamic> arabicTranslations;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    englishTranslations =
        jsonDecode(await rootBundle.loadString('assets/translations/en.json'))
            as Map<String, dynamic>;
    arabicTranslations =
        jsonDecode(await rootBundle.loadString('assets/translations/ar.json'))
            as Map<String, dynamic>;
  });

  testWidgets(
    'Home offer opens the specific offer, refusal page and Chats tab',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final repo = FakeOrdersRepository()
        ..onList = (_, _) async => ordersPage([
          CustomerOrderDto.fromJson(
            orderJson(id: 17, general: true)
              ..['part_name'] = 'Front headlight'
              ..['offers_count'] = 1
              ..['offers'] = [
                {
                  'id': 42,
                  'price': 12550,
                  'status': 'pending',
                  'images': [],
                  'store': {'id': 6, 'name': 'Parts store'},
                },
              ],
          ).value,
        ]);
      repo.onGet = (_) async =>
          (await repo.onList!(CustomerOrderFilter.all, 1)).orders.single;
      await _pumpCustomerApp(
        tester,
        translations: englishTranslations,
        locale: AppLocale.english,
        ordersRepository: repo,
      );
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('home-offer-42')),
        180,
        scrollable: find
            .descendant(
              of: find.byKey(const PageStorageKey('customer-tab-home')),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(find.text('Parts store'), findsOneWidget);
      expect(find.textContaining('125.50'), findsOneWidget);
      expect(repo.detailCalls, isEmpty);
      expect(repo.calls, hasLength(1));
      await tester.tap(find.byKey(const ValueKey('home-offer-42')));
      await tester.pumpAndSettle();
      expect(repo.detailCalls, [17]);
      expect(find.byType(CustomerOfferDetailsScreen), findsOneWidget);
      await tester.ensureVisible(find.byKey(const ValueKey('offer-refuse')));
      await tester.tap(find.byKey(const ValueKey('offer-refuse')));
      await tester.pumpAndSettle();
      expect(find.byType(RefuseCustomerOfferScreen), findsOneWidget);
      await tester.tap(find.byType(BackButtonIcon).last);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const ValueKey('offer-chat')));
      await tester.tap(find.byKey(const ValueKey('offer-chat')));
      await tester.pumpAndSettle();
      expect(find.byType(CustomerChatsScreen), findsOneWidget);
    },
  );
  testWidgets(
    'Home shows three latest requests and opens the selected details',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final repo = FakeOrdersRepository()
        ..onList = (_, _) async => ordersPage([
          for (final id in [1, 4, 2, 3])
            CustomerOrderDto.fromJson(
              orderJson(id: id, general: true)
                ..['part_name'] = 'Headlight $id'
                ..['offers_count'] = id == 4 ? 2 : 0,
            ).value,
        ]);
      await _pumpCustomerApp(
        tester,
        translations: englishTranslations,
        locale: AppLocale.english,
        ordersRepository: repo,
      );
      await tester.ensureVisible(find.byKey(const ValueKey('home-request-4')));
      expect(find.byKey(const ValueKey('home-request-1')), findsNothing);
      expect(find.byKey(const ValueKey('home-request-2')), findsOneWidget);
      expect(
        tester.getTopLeft(find.byKey(const ValueKey('home-request-4'))).dy,
        lessThan(
          tester.getTopLeft(find.byKey(const ValueKey('home-request-3'))).dy,
        ),
      );
      expect(find.text('Offers received'), findsOneWidget);
      expect(find.text('Offers: 2'), findsOneWidget);
      expect(repo.calls, hasLength(1));
      expect(repo.detailCalls, isEmpty);
      await tester.tap(find.byKey(const ValueKey('home-request-4')));
      await tester.pumpAndSettle();
      expect(find.byType(CustomerOrderDetailsScreen), findsOneWidget);
      expect(repo.detailCalls, [4]);
    },
  );

  testWidgets('Home loads, retries a failure and shows an honest empty state', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final pending = Completer<CustomerOrdersPage>();
    final repo = FakeOrdersRepository()..onList = (_, _) => pending.future;
    await _pumpCustomerApp(
      tester,
      translations: englishTranslations,
      locale: AppLocale.english,
      ordersRepository: repo,
      settle: false,
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    pending.completeError(const ApiFailure(type: ApiFailureType.noConnection));
    await tester.pumpAndSettle();
    expect(find.text('Couldn’t load your requests'), findsOneWidget);
    expect(repo.calls, hasLength(1));
    expect(find.byKey(const ValueKey('home-empty-requests')), findsNothing);
    repo.onList = (_, _) async => ordersPage([]);
    await tester.ensureVisible(
      find.byKey(const ValueKey('home-retry-requests')),
    );
    await tester.tap(find.byKey(const ValueKey('home-retry-requests')));
    await tester.pumpAndSettle();
    expect(find.text('No requests yet'), findsOneWidget);
    expect(repo.calls, hasLength(2));
    expect(find.byKey(const ValueKey('home-request-part')), findsOneWidget);
  });

  testWidgets(
    'Home refreshes orders and reacts to submission cache invalidation',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final repo = FakeOrdersRepository()
        ..onList = (_, _) async => ordersPage([]);
      await _pumpCustomerApp(
        tester,
        translations: englishTranslations,
        locale: AppLocale.english,
        ordersRepository: repo,
      );
      repo.onList = (_, _) async =>
          ordersPage([fixtureOrder(id: 8, general: true)]);
      await tester.drag(
        find.byKey(const PageStorageKey('customer-tab-home')),
        const Offset(0, 500),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('home-request-8')), findsOneWidget);
      expect(repo.calls, hasLength(2));
      repo.onList = (_, _) async =>
          ordersPage([fixtureOrder(id: 9, general: true)]);
      final container = ProviderScope.containerOf(
        tester.element(find.byType(OctoGearApp)),
      );
      container.invalidate(customerOrdersProvider);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('home-request-9')), findsOneWidget);
      expect(find.byKey(const ValueKey('home-request-8')), findsNothing);
    },
  );

  testWidgets('Home opens the guided request flow and existing requests', (
    tester,
  ) async {
    await _pumpCustomerApp(
      tester,
      translations: englishTranslations,
      locale: AppLocale.english,
    );
    final homeScroll = find
        .descendant(
          of: find.byKey(const PageStorageKey('customer-tab-home')),
          matching: find.byType(Scrollable),
        )
        .first;
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('home-request-part')),
      180,
      scrollable: homeScroll,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('home-request-part')));
    await tester.pumpAndSettle();
    expect(find.text('Step 1 of 3 · Vehicle'), findsOneWidget);
    await tester.tap(find.byKey(const Key('general-back')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('home-view-requests')),
      180,
      scrollable: homeScroll,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('home-view-requests')));
    await tester.pumpAndSettle();
    expect(find.text('Your orders'), findsOneWidget);
  });

  testWidgets('Home banners swipe and change language without opening on tap', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _pumpCustomerApp(
      tester,
      translations: englishTranslations,
      alternateTranslations: arabicTranslations,
      locale: AppLocale.english,
    );
    final carousel = find.byKey(const ValueKey('home-promotions'));
    final panel = find.byKey(const ValueKey('home-request-panel'));
    expect(
      tester.getBottomLeft(carousel).dy,
      lessThan(tester.getTopLeft(panel).dy),
    );
    expect(tester.getSize(panel).height, lessThan(844 / 3));
    final requestButton = tester.getSize(
      find.byKey(const ValueKey('home-request-part')),
    );
    expect(requestButton.width, lessThan(tester.getSize(panel).width * .75));
    expect(requestButton.height, greaterThanOrEqualTo(48));
    expect(
      find.byKey(const ValueKey('home-banner-en-parts')).hitTestable(),
      findsOneWidget,
    );
    final banner = tester.widget<Image>(
      find.byKey(const ValueKey('home-banner-en-parts')),
    );
    expect(banner.fit, BoxFit.contain);
    expect(banner.matchTextDirection, isFalse);
    await tester.drag(carousel, const Offset(-340, 0));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('home-banner-en-details')).hitTestable(),
      findsOneWidget,
    );
    await tester.tap(find.byTooltip('Previous tip'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('home-banner-en-parts')).hitTestable(),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('home-banner-en-parts')));
    await tester.pumpAndSettle();
    expect(find.byType(InteractiveViewer), findsNothing);
    expect(find.byType(Dialog), findsNothing);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(OctoGearApp)),
    );
    await container.read(appLocaleProvider.notifier).select(AppLocale.arabic);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('home-banner-ar-parts')).hitTestable(),
      findsOneWidget,
    );
    expect(Directionality.of(tester.element(carousel)), TextDirection.rtl);
    await tester.drag(carousel, const Offset(340, 0));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('home-banner-ar-details')).hitTestable(),
      findsOneWidget,
    );
    await tester.tap(find.byTooltip('النصيحة التالية'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('home-banner-ar-offers')).hitTestable(),
      findsOneWidget,
    );
    await container.read(appLocaleProvider.notifier).select(AppLocale.english);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('home-banner-en-parts')).hitTestable(),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  for (final locale in AppLocale.values) {
    testWidgets('Home fits narrow ${locale.name} with large text', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(320, 800));
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(() {
        tester.platformDispatcher.clearTextScaleFactorTestValue();
        return tester.binding.setSurfaceSize(null);
      });
      await _pumpCustomerApp(
        tester,
        translations: locale == AppLocale.arabic
            ? arabicTranslations
            : englishTranslations,
        locale: locale,
      );
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('home-request-1')),
        180,
        scrollable: find
            .descendant(
              of: find.byKey(const PageStorageKey('customer-tab-home')),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('home-promotions')),
        -180,
        scrollable: find
            .descendant(
              of: find.byKey(const PageStorageKey('customer-tab-home')),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      final carousel = find.byKey(const ValueKey('home-promotions'));
      await tester.drag(
        carousel,
        Offset(locale == AppLocale.arabic ? 300 : -300, 0),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('home-request-part')),
        180,
        scrollable: find
            .descendant(
              of: find.byKey(const PageStorageKey('customer-tab-home')),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('home-request-part')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('renders and switches all customer destinations', (tester) async {
    await _pumpCustomerApp(
      tester,
      translations: englishTranslations,
      locale: AppLocale.english,
    );

    expect(find.byType(NavigationDestination), findsNWidgets(4));
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Stores'), findsNothing);
    expect(find.text('Orders'), findsOneWidget);
    expect(find.text('Chats'), findsOneWidget);
    expect(find.text('More'), findsOneWidget);
    expect(
      find.byKey(const PageStorageKey<String>('customer-tab-home')),
      findsOneWidget,
    );

    await tester.tap(find.text('Chats'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const PageStorageKey<String>('customer-tab-chats')),
      findsOneWidget,
    );
    expect(find.text('Chats are coming soon'), findsOneWidget);

    await tester.tap(find.text('Orders'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const PageStorageKey<String>('customer-tab-orders')),
      findsOneWidget,
    );
    expect(find.text('Your orders'), findsOneWidget);
    await tester.ensureVisible(find.text('Left wheel'));
    await tester.tap(find.text('Left wheel'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<CustomerOrderDetailsScreen>(
            find.byType(CustomerOrderDetailsScreen),
          )
          .orderId,
      1,
    );
    await tester.tap(find.byType(BackButtonIcon).last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const PageStorageKey<String>('customer-tab-more')),
      findsOneWidget,
    );
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(find.text('Account details'), findsOneWidget);
    expect(find.text('500000000'), findsOneWidget);
    await tester.tap(find.byType(BackButtonIcon).last);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const PageStorageKey('customer-tab-more')),
      findsOneWidget,
    );
  });

  testWidgets('hidden Stores deep links redirect before building the feature', (
    tester,
  ) async {
    await _pumpCustomerApp(
      tester,
      translations: englishTranslations,
      locale: AppLocale.english,
    );
    final container = ProviderScope.containerOf(
      tester.element(find.byType(OctoGearApp)),
    );
    final router = container.read(appRouterProvider);
    for (final path in [
      '/customer/stores',
      '/customer/stores/1/cars/7',
      '/customer/stores/1/cars/7/components/1/request',
    ]) {
      router.go(path);
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, '/customer');
      expect(
        find.byKey(const PageStorageKey('customer-tab-home')),
        findsOneWidget,
      );
      expect(find.byType(RequestPartScreen), findsNothing);
    }
  });

  testWidgets(
    'old account links reach More and tab switching preserves its child stack',
    (tester) async {
      await _pumpCustomerApp(
        tester,
        translations: englishTranslations,
        locale: AppLocale.english,
      );
      final container = ProviderScope.containerOf(
        tester.element(find.byType(OctoGearApp)),
      );
      final router = container.read(appRouterProvider);
      router.go('/customer/account');
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, '/customer/more');
      await tester.ensureVisible(find.text('Settings'));
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();
      expect(find.text('App language'), findsOneWidget);
      await tester.tap(find.text('Chats').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('More').last);
      await tester.pumpAndSettle();
      expect(find.text('App language'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(
        find.byKey(const PageStorageKey('customer-tab-more')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'language settings change app direction without leaving the page',
    (tester) async {
      await _pumpCustomerApp(
        tester,
        translations: englishTranslations,
        locale: AppLocale.english,
        alternateTranslations: arabicTranslations,
      );
      await tester.tap(find.text('More'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Settings'));
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('العربية'));
      await tester.pumpAndSettle();
      expect(find.text('لغة التطبيق'), findsOneWidget);
      expect(
        Directionality.of(tester.element(find.text('لغة التطبيق'))),
        TextDirection.rtl,
      );
      expect(
        find.byKey(const PageStorageKey('customer-settings')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'More sign out delegates to the session and leaves protected routes',
    (tester) async {
      await _pumpCustomerApp(
        tester,
        translations: englishTranslations,
        locale: AppLocale.english,
      );
      await tester.tap(find.text('More'));
      await tester.pumpAndSettle();
      final container = ProviderScope.containerOf(
        tester.element(find.byType(OctoGearApp)),
      );
      await tester.scrollUntilVisible(find.text('Sign out'), 200);
      await tester.tap(find.text('Sign out'));
      await tester.pumpAndSettle();
      expect(
        container.read(sessionControllerProvider).requireValue,
        isA<SignedOutSession>(),
      );
      expect(
        container
            .read(appRouterProvider)
            .routeInformationProvider
            .value
            .uri
            .path,
        '/auth/phone',
      );
      expect(find.byType(NavigationBar), findsNothing);
    },
  );

  testWidgets('More and Chats fit a narrow Arabic screen with large text', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    tester.platformDispatcher.textScaleFactorTestValue = 1.8;
    addTearDown(() {
      tester.platformDispatcher.clearTextScaleFactorTestValue();
      return tester.binding.setSurfaceSize(null);
    });
    await _pumpCustomerApp(
      tester,
      translations: arabicTranslations,
      locale: AppLocale.arabic,
    );
    await tester.tap(find.text('المزيد').last);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('الإعدادات'), 180);
    await tester.tap(find.text('الإعدادات'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('المحادثات').last);
    await tester.pumpAndSettle();
    expect(find.text('المحادثات قريباً'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('uses Arabic labels and right-to-left layout', (tester) async {
    await _pumpCustomerApp(
      tester,
      translations: arabicTranslations,
      locale: AppLocale.arabic,
    );

    expect(find.text('الرئيسية'), findsOneWidget);
    expect(find.text('المتاجر'), findsNothing);
    expect(find.text('الطلبات'), findsOneWidget);
    expect(find.text('المحادثات'), findsOneWidget);
    expect(find.text('المزيد'), findsOneWidget);
    expect(
      Directionality.of(
        tester.element(
          find.byKey(const PageStorageKey<String>('customer-tab-home')),
        ),
      ).name,
      'rtl',
    );
  });

  testWidgets('opens the real typed store detail and inventory journey', (
    tester,
  ) async {
    await _pumpCustomerApp(
      tester,
      translations: englishTranslations,
      locale: AppLocale.english,
      storesEnabled: true,
    );

    await tester.tap(find.text('Stores'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Test Store').first);
    await tester.pumpAndSettle();

    expect(find.text('Store details'), findsOneWidget);
    expect(find.text('Supported manufacturers'), findsOneWidget);
    expect(find.text('Toyota'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Cars available in this store'),
      300,
      scrollable: find.descendant(
        of: find.byKey(
          const PageStorageKey<String>('customer-store-details-1'),
        ),
        matching: find.byType(Scrollable),
      ),
    );
    expect(find.text('Cars available in this store'), findsOneWidget);
    expect(find.text('Camry'), findsOneWidget);
    await tester.ensureVisible(find.text('Camry'));
    await tester.tap(find.text('Camry'));
    await tester.pumpAndSettle();
    expect(find.byKey(const PageStorageKey('store-car-1-7')), findsOneWidget);
    expect(find.text('Car & parts'), findsOneWidget);
    expect(find.byType(NavigationDestination), findsNWidgets(5));
    for (
      var i = 0;
      i < 20 && find.text('Request a part').hitTestable().evaluate().isEmpty;
      i++
    ) {
      await tester.drag(
        find.byKey(const PageStorageKey('store-car-1-7')),
        const Offset(0, -180),
      );
      await tester.pump(const Duration(milliseconds: 300));
    }
    await tester.tap(find.text('Request a part').first);
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<RequestPartScreen>(find.byType(RequestPartScreen))
          .requestKey,
      (storeId: 1, carId: 7, componentId: 1),
    );
    await tester.tap(find.text('Stores').last);
    await tester.pumpAndSettle();
    expect(find.byType(RequestPartScreen), findsOneWidget);
    await tester.tap(find.text('Home').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Stores').last);
    await tester.pumpAndSettle();
    expect(find.byType(RequestPartScreen), findsOneWidget);
    await tester.tap(find.byType(BackButtonIcon).last);
    await tester.pumpAndSettle();
    expect(find.byKey(const PageStorageKey('store-car-1-7')), findsOneWidget);
    await tester.drag(
      find.byKey(const PageStorageKey('store-car-1-7')),
      const Offset(0, 1800),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(BackButtonIcon).last);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const PageStorageKey<String>('customer-store-details-1')),
      findsOneWidget,
    );
  });
}

Future<void> _pumpCustomerApp(
  WidgetTester tester, {
  required Map<String, dynamic> translations,
  required AppLocale locale,
  bool storesEnabled = false,
  FakeOrdersRepository? ordersRepository,
  bool settle = true,
  Map<String, dynamic>? alternateTranslations,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        customerGarageRepositoryProvider.overrideWithValue(
          RequestGarageRepository(),
        ),
        customerStoresEnabledProvider.overrideWithValue(storesEnabled),
        customerOrdersRepositoryProvider.overrideWithValue(
          ordersRepository ?? FakeOrdersRepository(),
        ),
        partRequestRepositoryProvider.overrideWithValue(
          FakeRequestRepository(),
        ),
        partRequestPhotoPickerProvider.overrideWithValue(FakePhotoPicker()),
        storefrontCarCatalogRepositoryProvider.overrideWithValue(
          FakeCarCatalogRepository(),
        ),
        sessionControllerProvider.overrideWith(_CustomerSessionController.new),
        appLocaleProvider.overrideWith(
          locale == AppLocale.arabic
              ? _ArabicLocaleController.new
              : _EnglishLocaleController.new,
        ),
        searchStoresUseCaseProvider.overrideWithValue(
          _CustomerStorefrontUseCase(),
        ),
        getStoreDetailsUseCaseProvider.overrideWithValue(
          _CustomerStoreDetailsUseCase(),
        ),
        getStoreCarsUseCaseProvider.overrideWithValue(
          _CustomerStoreCarsUseCase(),
        ),
      ],
      child: EasyLocalization(
        supportedLocales: const [Locale('ar'), Locale('en')],
        startLocale: locale.locale,
        path: 'assets/translations',
        assetLoader: _PreloadedTranslations(
          translations,
          alternateTranslations,
        ),
        saveLocale: false,
        child: const OctoGearApp(),
      ),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }
}

class _PreloadedTranslations extends AssetLoader {
  const _PreloadedTranslations(this.translations, this.arabicTranslations);

  final Map<String, dynamic> translations;
  final Map<String, dynamic>? arabicTranslations;

  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) {
    return Future.value(
      locale.languageCode == 'ar'
          ? arabicTranslations ?? translations
          : translations,
    );
  }
}

class _CustomerSessionController extends SessionController {
  @override
  Future<SessionOutcome> build() async => const AuthenticatedSession(_customer);
  @override
  Future<void> signOut() async => state = const AsyncData(SignedOutSession());
}

class _EnglishLocaleController extends AppLocaleController {
  @override
  AppLocale build() => AppLocale.english;
  @override
  Future<void> select(AppLocale locale) async => state = locale;
}

class _ArabicLocaleController extends AppLocaleController {
  @override
  AppLocale build() => AppLocale.arabic;
  @override
  Future<void> select(AppLocale locale) async => state = locale;
}

class _CustomerStorefrontUseCase extends SearchStoresUseCase {
  _CustomerStorefrontUseCase() : super(_UnusedStorefrontRepository());

  @override
  Future<StorefrontPage> call(
    StorefrontFilters filters, {
    required int page,
  }) async {
    return const StorefrontPage(
      stores: [
        MarketplaceStore(
          id: 1,
          name: 'Test Store',
          nickname: 'Test Store',
          city: null,
          primaryPictureUrl: null,
          averageRating: null,
        ),
      ],
      currentPage: 1,
      lastPage: 1,
      perPage: 15,
      total: 1,
    );
  }
}

class _CustomerStoreDetailsUseCase extends GetStoreDetailsUseCase {
  _CustomerStoreDetailsUseCase() : super(_UnusedStorefrontRepository());

  @override
  Future<StorefrontStoreDetails> call(int storeId) async {
    return const StorefrontStoreDetails(
      id: 1,
      name: 'Test Store',
      nickname: 'Test Store',
      city: StorefrontReference(id: 1, name: 'Aden'),
      companies: [StorefrontReference(id: 9, name: 'Toyota')],
      pictures: [],
      averageRating: 4.5,
      soldQuantity: 3,
    );
  }
}

class _CustomerStoreCarsUseCase extends GetStoreCarsUseCase {
  _CustomerStoreCarsUseCase() : super(_UnusedStorefrontRepository());

  @override
  Future<StorefrontStoreCarsPage> call(int storeId, {required int page}) async {
    return const StorefrontStoreCarsPage(
      cars: [
        StorefrontStoreCar(
          id: 7,
          manufacturingYear: 2020,
          carName: StorefrontReference(id: 1, name: 'Camry'),
          color: StorefrontReference(id: 2, name: 'White'),
          fuelType: StorefrontReference(id: 3, name: 'Petrol'),
          componentsCount: 5,
          pictures: [],
        ),
      ],
      currentPage: 1,
      lastPage: 1,
      perPage: 15,
      total: 1,
    );
  }
}

class _UnusedStorefrontRepository implements StorefrontRepository {
  @override
  Future<StorefrontFilterOptions> getFilterOptions() {
    throw UnimplementedError();
  }

  @override
  Future<StorefrontPage> searchStores(
    StorefrontFilters filters, {
    required int page,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<StorefrontStoreDetails> getStoreDetails(int storeId) {
    throw UnimplementedError();
  }

  @override
  Future<StorefrontStoreCarsPage> getStoreCars(
    int storeId, {
    required int page,
  }) {
    throw UnimplementedError();
  }
}

const _customer = AppUser(
  id: 1,
  fullName: 'Aisha Alharbi',
  mobile: '500000000',
  role: AppUserRole.customer,
  city: AppCity(id: 1, name: 'Riyadh'),
);
