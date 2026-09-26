import 'dart:async';
import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:octogear/app/octogear_app.dart';
import 'package:octogear/app/routing/app_routes.dart';
import 'package:octogear/core/api/api_failure.dart';
import 'package:octogear/core/design_system/octogear_theme.dart';
import 'package:octogear/core/localization/app_locale.dart';
import 'package:octogear/core/localization/app_locale_controller.dart';
import 'package:octogear/core/routing/app_route_paths.dart';
import 'package:octogear/features/authentication/domain/entities/app_user.dart';
import 'package:octogear/features/authentication/domain/entities/session_outcome.dart';
import 'package:octogear/features/authentication/presentation/controllers/session_controller.dart';
import 'package:octogear/features/customer_garage/domain/entities/customer_car.dart';
import 'package:octogear/features/customer_garage/domain/repositories/customer_garage_repository.dart';
import 'package:octogear/features/customer_garage/domain/use_cases/get_customer_cars_use_case.dart';
import 'package:octogear/features/customer_garage/presentation/controllers/customer_cars_controller.dart';
import 'package:octogear/features/customer_garage/presentation/controllers/customer_cars_providers.dart';
import 'package:octogear/features/customer_garage/presentation/screens/customer_cars_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  testWidgets('shows accessible loading skeletons while saved cars load', (
    tester,
  ) async {
    final useCase = _PendingCustomerCarsUseCase();
    await _pumpCarsScreen(
      tester,
      translations: englishTranslations,
      locale: AppLocale.english,
      useCase: useCase,
    );

    expect(find.bySemanticsLabel('Loading your saved cars'), findsOneWidget);

    useCase.completer.complete(const []);
    await tester.pumpAndSettle();
  });

  testWidgets('shows a truthful empty state when the customer has no cars', (
    tester,
  ) async {
    await _pumpCarsScreen(
      tester,
      translations: englishTranslations,
      locale: AppLocale.english,
      useCase: _EmptyCustomerCarsUseCase(),
    );

    expect(find.text('No cars saved yet'), findsOneWidget);
    expect(
      find.text(
        'Cars you save will appear here and help make future part searches more accurate.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('shows an error and Retry replaces it with the retried result', (
    tester,
  ) async {
    final useCase = _RetryingCustomerCarsUseCase();
    await _pumpCarsScreen(
      tester,
      translations: englishTranslations,
      locale: AppLocale.english,
      useCase: useCase,
    );

    final container = ProviderScope.containerOf(
      tester.element(find.byType(CustomerCarsScreen)),
    );
    expect(
      container.read(customerCarsControllerProvider),
      isA<AsyncError<List<CustomerCar>>>(),
    );
    expect(find.bySemanticsLabel("We couldn't load your cars"), findsOneWidget);
    expect(
      find.text('Check your internet connection and try again.'),
      findsOneWidget,
    );
    expect(find.text('Retry'), findsOneWidget);

    final retry = find.text('Retry');
    await tester.scrollUntilVisible(retry, 200);
    useCase.shouldSucceed = true;
    await tester.tap(retry);
    await tester.pumpAndSettle();

    expect(find.text("We couldn't load your cars"), findsNothing);
    expect(find.text('Camry'), findsOneWidget);
    expect(useCase.callCount, greaterThan(1));
  });

  testWidgets('renders saved-car details without guessing a picture URL', (
    tester,
  ) async {
    await _pumpCarsScreen(
      tester,
      translations: englishTranslations,
      locale: AppLocale.english,
      useCase: _PopulatedCustomerCarsUseCase(),
    );

    expect(find.bySemanticsLabel('Camry'), findsOneWidget);
    expect(find.text('Camry'), findsOneWidget);
    expect(find.text('2022', findRichText: true), findsOneWidget);
    expect(find.text('White'), findsOneWidget);
    expect(find.text('Petrol'), findsOneWidget);
    expect(find.text('ABC 1234'), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('uses Arabic RTL UI while keeping a plate value left-to-right', (
    tester,
  ) async {
    await _pumpCarsScreen(
      tester,
      translations: arabicTranslations,
      locale: AppLocale.arabic,
      useCase: _PopulatedCustomerCarsUseCase(),
    );

    expect(find.text('سياراتي'), findsOneWidget);
    final title = find.text('سياراتي');
    final plate = find.text('ABC 1234');
    expect(Directionality.of(tester.element(title)).name, 'rtl');
    expect(Directionality.of(tester.element(plate)).name, 'ltr');
  });

  testWidgets('Account opens the typed My Cars child route', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await _pumpCustomerApp(
      tester,
      translations: englishTranslations,
      useCase: _PopulatedCustomerCarsUseCase(),
    );

    await tester.tap(find.text('Account'));
    await tester.pumpAndSettle();
    final garageEntry = find.bySemanticsLabel('My cars');
    expect(garageEntry, findsOneWidget);

    await tester.scrollUntilVisible(garageEntry, 200);
    await tester.tap(garageEntry);
    await tester.pumpAndSettle();

    final screen = find.byType(CustomerCarsScreen);
    expect(screen, findsOneWidget);
    expect(const CustomerCarsRoute().location, AppRoutePath.customerCars);
  });
}

Future<void> _pumpCarsScreen(
  WidgetTester tester, {
  required Map<String, dynamic> translations,
  required AppLocale locale,
  required GetCustomerCarsUseCase useCase,
}) async {
  await tester.pumpWidget(
    EasyLocalization(
      supportedLocales: const [Locale('ar'), Locale('en')],
      startLocale: locale.locale,
      path: 'assets/translations',
      assetLoader: _PreloadedTranslations(translations),
      saveLocale: false,
      child: ProviderScope(
        overrides: [
          getCustomerCarsUseCaseProvider.overrideWithValue(useCase),
          appLocaleProvider.overrideWith(
            locale == AppLocale.arabic
                ? _ArabicLocaleController.new
                : _EnglishLocaleController.new,
          ),
        ],
        child: Builder(
          builder: (context) => MaterialApp(
            theme: OctoGearTheme.lightTheme,
            locale: context.locale,
            supportedLocales: context.supportedLocales,
            localizationsDelegates: context.localizationDelegates,
            home: const CustomerCarsScreen(),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpCustomerApp(
  WidgetTester tester, {
  required Map<String, dynamic> translations,
  required GetCustomerCarsUseCase useCase,
}) async {
  await tester.pumpWidget(
    EasyLocalization(
      supportedLocales: const [Locale('ar'), Locale('en')],
      startLocale: const Locale('en'),
      path: 'assets/translations',
      assetLoader: _PreloadedTranslations(translations),
      saveLocale: false,
      child: ProviderScope(
        overrides: [
          appLocaleProvider.overrideWith(_EnglishLocaleController.new),
          getCustomerCarsUseCaseProvider.overrideWithValue(useCase),
          sessionControllerProvider.overrideWith(
            _CustomerSessionController.new,
          ),
        ],
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

class _EnglishLocaleController extends AppLocaleController {
  @override
  AppLocale build() => AppLocale.english;
}

class _ArabicLocaleController extends AppLocaleController {
  @override
  AppLocale build() => AppLocale.arabic;
}

class _CustomerSessionController extends SessionController {
  @override
  Future<SessionOutcome> build() async => const AuthenticatedSession(_customer);
}

class _PendingCustomerCarsUseCase extends GetCustomerCarsUseCase {
  _PendingCustomerCarsUseCase() : super(_UnusedCustomerGarageRepository());

  final completer = Completer<List<CustomerCar>>();

  @override
  Future<List<CustomerCar>> call() => completer.future;
}

class _EmptyCustomerCarsUseCase extends GetCustomerCarsUseCase {
  _EmptyCustomerCarsUseCase() : super(_UnusedCustomerGarageRepository());

  @override
  Future<List<CustomerCar>> call() async => const [];
}

class _PopulatedCustomerCarsUseCase extends GetCustomerCarsUseCase {
  _PopulatedCustomerCarsUseCase() : super(_UnusedCustomerGarageRepository());

  @override
  Future<List<CustomerCar>> call() async => [_sampleCar()];
}

class _RetryingCustomerCarsUseCase extends GetCustomerCarsUseCase {
  _RetryingCustomerCarsUseCase() : super(_UnusedCustomerGarageRepository());

  bool shouldSucceed = false;
  int callCount = 0;

  @override
  Future<List<CustomerCar>> call() async {
    callCount++;
    if (!shouldSucceed) {
      throw const ApiFailure(type: ApiFailureType.noConnection);
    }
    return [_sampleCar()];
  }
}

class _UnusedCustomerGarageRepository implements CustomerGarageRepository {
  @override
  Future<List<CustomerCar>> getCustomerCars() => throw UnimplementedError();
}

CustomerCar _sampleCar() {
  return CustomerCar(
    id: 9,
    manufacturingYear: 2022,
    licensePlateNumber: 'ABC 1234',
    carName: const CustomerCarReference(id: 4, name: 'Camry'),
    color: const CustomerCarReference(id: 2, name: 'White'),
    fuelType: const CustomerCarReference(id: 1, name: 'Petrol'),
    picturePaths: const ['cars/9.jpg'],
    createdAt: DateTime.utc(2026, 9, 26, 10, 15),
  );
}

const _customer = AppUser(
  id: 1,
  fullName: 'Aisha Alharbi',
  mobile: '500000000',
  role: AppUserRole.customer,
  city: AppCity(id: 1, name: 'Riyadh'),
);
