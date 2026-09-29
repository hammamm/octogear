import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:octogear/app/octogear_app.dart';
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

  testWidgets('renders and switches all customer destinations', (tester) async {
    await _pumpCustomerApp(
      tester,
      translations: englishTranslations,
      locale: AppLocale.english,
    );

    expect(find.byType(NavigationDestination), findsNWidgets(4));
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Stores'), findsOneWidget);
    expect(find.text('Orders'), findsOneWidget);
    expect(find.text('Account'), findsOneWidget);
    expect(
      find.byKey(const PageStorageKey<String>('customer-tab-home')),
      findsOneWidget,
    );

    await tester.tap(find.text('Stores'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const PageStorageKey<String>('customer-storefront')),
      findsOneWidget,
    );
    expect(find.text('Explore stores'), findsOneWidget);

    await tester.tap(find.text('Orders'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const PageStorageKey<String>('customer-tab-orders')),
      findsOneWidget,
    );
    expect(find.text('Your orders'), findsOneWidget);

    await tester.tap(find.text('Account'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const PageStorageKey<String>('customer-tab-account')),
      findsOneWidget,
    );
    expect(find.text('Account details'), findsOneWidget);
  });

  testWidgets('uses Arabic labels and right-to-left layout', (tester) async {
    await _pumpCustomerApp(
      tester,
      translations: arabicTranslations,
      locale: AppLocale.arabic,
    );

    expect(find.text('الرئيسية'), findsOneWidget);
    expect(find.text('المتاجر'), findsOneWidget);
    expect(find.text('الطلبات'), findsOneWidget);
    expect(find.text('الحساب'), findsOneWidget);
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
    expect(find.byType(NavigationDestination), findsNWidgets(4));
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
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
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
        assetLoader: _PreloadedTranslations(translations),
        saveLocale: false,
        child: const OctoGearApp(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _PreloadedTranslations extends AssetLoader {
  const _PreloadedTranslations(this.translations);

  final Map<String, dynamic> translations;

  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) {
    return Future.value(translations);
  }
}

class _CustomerSessionController extends SessionController {
  @override
  Future<SessionOutcome> build() async => const AuthenticatedSession(_customer);
}

class _EnglishLocaleController extends AppLocaleController {
  @override
  AppLocale build() => AppLocale.english;
}

class _ArabicLocaleController extends AppLocaleController {
  @override
  AppLocale build() => AppLocale.arabic;
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
