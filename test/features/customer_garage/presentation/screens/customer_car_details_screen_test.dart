import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui show TextDirection;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:octogear/core/design_system/octogear_theme.dart';
import 'package:octogear/core/localization/app_locale.dart';
import 'package:octogear/core/localization/app_locale_controller.dart';
import 'package:octogear/features/customer_garage/domain/entities/create_customer_car_command.dart';
import 'package:octogear/features/customer_garage/domain/entities/customer_car.dart';
import 'package:octogear/features/customer_garage/domain/entities/customer_car_form_references.dart';
import 'package:octogear/features/customer_garage/domain/entities/update_customer_car_command.dart';
import 'package:octogear/features/customer_garage/domain/repositories/customer_garage_repository.dart';
import 'package:octogear/features/customer_garage/domain/use_cases/delete_customer_car_use_case.dart';
import 'package:octogear/features/customer_garage/domain/use_cases/get_customer_car_use_case.dart';
import 'package:octogear/features/customer_garage/presentation/controllers/customer_cars_providers.dart';
import 'package:octogear/features/customer_garage/presentation/screens/customer_car_details_screen.dart';
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

  testWidgets('shows an accessible loading state while car details load', (
    tester,
  ) async {
    final useCase = _PendingGetCustomerCarUseCase();
    await _pumpDetailsScreen(
      tester,
      translations: englishTranslations,
      getCustomerCarUseCase: useCase,
      settle: false,
    );

    expect(find.bySemanticsLabel('Loading car details'), findsOneWidget);

    useCase.completer.complete(_sampleCar());
    await tester.pumpAndSettle();
  });

  testWidgets(
    'shows manufacturer, all vehicle facts, and an honest no-photo gallery',
    (tester) async {
      await _pumpDetailsScreen(tester, translations: englishTranslations);

      expect(find.text('Car details'), findsOneWidget);
      expect(find.text('Toyota'), findsWidgets);
      expect(find.text('Camry'), findsWidgets);
      expect(find.text('2022'), findsOneWidget);
      expect(find.text('ABC 1234'), findsOneWidget);
      expect(find.text('White'), findsOneWidget);
      expect(find.text('Petrol'), findsOneWidget);
      expect(find.text('No vehicle photos yet'), findsOneWidget);
      expect(find.byIcon(Icons.directions_car_outlined), findsWidgets);
    },
  );

  testWidgets('keeps a plate number left-to-right in Arabic details', (
    tester,
  ) async {
    await _pumpDetailsScreen(
      tester,
      translations: arabicTranslations,
      locale: AppLocale.arabic,
    );

    final title = find.text('تفاصيل السيارة');
    final plate = find.text('ABC 1234');

    expect(Directionality.of(tester.element(title)), ui.TextDirection.rtl);
    expect(Directionality.of(tester.element(plate)), ui.TextDirection.ltr);
  });

  testWidgets('cancelling removal never calls the delete use case', (
    tester,
  ) async {
    final deleteUseCase = _RecordingDeleteCustomerCarUseCase();
    await _pumpDetailsScreen(
      tester,
      translations: englishTranslations,
      deleteCustomerCarUseCase: deleteUseCase,
    );

    final deleteButton = find.byKey(const Key('customer_car_delete_button'));
    await tester.ensureVisible(deleteButton);
    await tester.tap(deleteButton);
    await tester.pumpAndSettle();

    expect(find.text('Remove this saved car?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(deleteUseCase.carIds, isEmpty);
    expect(find.text('Car details'), findsOneWidget);
  });

  testWidgets('confirming removal calls delete once and returns true', (
    tester,
  ) async {
    final deleteUseCase = _RecordingDeleteCustomerCarUseCase();
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const _LandingScreen(),
          routes: [
            GoRoute(
              path: 'details',
              builder: (_, _) => const CustomerCarDetailsScreen(carId: 9),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);

    await _pumpRouter(
      tester,
      translations: englishTranslations,
      router: router,
      deleteCustomerCarUseCase: deleteUseCase,
    );

    final result = router.push<bool>('/details');
    await tester.pumpAndSettle();

    final deleteButton = find.byKey(const Key('customer_car_delete_button'));
    await tester.ensureVisible(deleteButton);
    await tester.tap(deleteButton);
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('customer_car_confirm_delete_button')),
    );
    await tester.pumpAndSettle();

    expect(deleteUseCase.carIds, [9]);
    expect(await result, isTrue);
    expect(find.byType(_LandingScreen), findsOneWidget);
  });
}

Future<void> _pumpDetailsScreen(
  WidgetTester tester, {
  required Map<String, dynamic> translations,
  AppLocale locale = AppLocale.english,
  GetCustomerCarUseCase? getCustomerCarUseCase,
  DeleteCustomerCarUseCase? deleteCustomerCarUseCase,
  bool settle = true,
}) async {
  await tester.binding.setSurfaceSize(const Size(800, 1400));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    _localizedProviderScope(
      translations: translations,
      locale: locale,
      getCustomerCarUseCase: getCustomerCarUseCase,
      deleteCustomerCarUseCase: deleteCustomerCarUseCase,
      child: Builder(
        builder: (context) => MaterialApp(
          theme: OctoGearTheme.lightTheme,
          locale: context.locale,
          supportedLocales: context.supportedLocales,
          localizationsDelegates: context.localizationDelegates,
          home: const Scaffold(body: CustomerCarDetailsScreen(carId: 9)),
        ),
      ),
    ),
  );
  await tester.pump();
  if (settle) await tester.pumpAndSettle();
}

Future<void> _pumpRouter(
  WidgetTester tester, {
  required Map<String, dynamic> translations,
  required GoRouter router,
  DeleteCustomerCarUseCase? deleteCustomerCarUseCase,
}) async {
  await tester.binding.setSurfaceSize(const Size(800, 1400));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    _localizedProviderScope(
      translations: translations,
      deleteCustomerCarUseCase: deleteCustomerCarUseCase,
      child: Builder(
        builder: (context) => MaterialApp.router(
          theme: OctoGearTheme.lightTheme,
          locale: context.locale,
          supportedLocales: context.supportedLocales,
          localizationsDelegates: context.localizationDelegates,
          routerConfig: router,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Widget _localizedProviderScope({
  required Map<String, dynamic> translations,
  required Widget child,
  AppLocale locale = AppLocale.english,
  GetCustomerCarUseCase? getCustomerCarUseCase,
  DeleteCustomerCarUseCase? deleteCustomerCarUseCase,
}) {
  return EasyLocalization(
    supportedLocales: const [Locale('ar'), Locale('en')],
    startLocale: locale.locale,
    path: 'assets/translations',
    assetLoader: _PreloadedTranslations(translations),
    saveLocale: false,
    child: ProviderScope(
      overrides: [
        appLocaleProvider.overrideWith(
          locale == AppLocale.arabic
              ? _ArabicLocaleController.new
              : _EnglishLocaleController.new,
        ),
        getCustomerCarUseCaseProvider.overrideWithValue(
          getCustomerCarUseCase ?? _SuccessfulGetCustomerCarUseCase(),
        ),
        deleteCustomerCarUseCaseProvider.overrideWithValue(
          deleteCustomerCarUseCase ?? _RecordingDeleteCustomerCarUseCase(),
        ),
      ],
      child: child,
    ),
  );
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

class _SuccessfulGetCustomerCarUseCase extends GetCustomerCarUseCase {
  _SuccessfulGetCustomerCarUseCase() : super(_UnusedCustomerGarageRepository());

  @override
  Future<CustomerCar> call(int carId) async => _sampleCar();
}

class _PendingGetCustomerCarUseCase extends GetCustomerCarUseCase {
  _PendingGetCustomerCarUseCase() : super(_UnusedCustomerGarageRepository());

  final completer = Completer<CustomerCar>();

  @override
  Future<CustomerCar> call(int carId) => completer.future;
}

class _RecordingDeleteCustomerCarUseCase extends DeleteCustomerCarUseCase {
  _RecordingDeleteCustomerCarUseCase()
    : super(_UnusedCustomerGarageRepository());

  final carIds = <int>[];

  @override
  Future<void> call(int carId) async {
    carIds.add(carId);
  }
}

class _UnusedCustomerGarageRepository implements CustomerGarageRepository {
  @override
  Future<CustomerCar> createCustomerCar(CreateCustomerCarCommand command) =>
      throw UnimplementedError();

  @override
  Future<void> deleteCustomerCar(int carId) => throw UnimplementedError();

  @override
  Future<List<CustomerCarReference>> getCarNames(int companyId) =>
      throw UnimplementedError();

  @override
  Future<CustomerCar> getCustomerCar(int carId) => throw UnimplementedError();

  @override
  Future<CustomerCarFormReferences> getCustomerCarFormReferences() =>
      throw UnimplementedError();

  @override
  Future<List<CustomerCar>> getCustomerCars() => throw UnimplementedError();

  @override
  Future<CustomerCar> updateCustomerCar(
    int carId,
    UpdateCustomerCarCommand command,
  ) => throw UnimplementedError();
}

class _LandingScreen extends StatelessWidget {
  const _LandingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('Landing')));
  }
}

CustomerCar _sampleCar() {
  return CustomerCar(
    id: 9,
    manufacturingYear: 2022,
    licensePlateNumber: 'ABC 1234',
    company: const CustomerCarReference(id: 1, name: 'Toyota'),
    carName: const CustomerCarReference(id: 4, name: 'Camry'),
    color: const CustomerCarReference(id: 2, name: 'White'),
    fuelType: const CustomerCarReference(id: 1, name: 'Petrol'),
    pictures: const [],
    createdAt: DateTime.utc(2026, 9, 26, 10, 15),
  );
}
