import 'package:octogear/features/part_requests/domain/entities/part_request.dart';
import 'dart:async';
import 'dart:convert';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:octogear/core/api/api_failure.dart';
import 'package:octogear/core/design_system/octogear_theme.dart';
import 'package:octogear/core/localization/app_locale.dart';
import 'package:octogear/core/localization/app_locale_controller.dart';
import 'package:octogear/features/customer_garage/presentation/controllers/customer_cars_providers.dart';
import 'package:octogear/features/general_requests/domain/entities/general_request.dart';
import 'package:octogear/features/general_requests/presentation/controllers/general_request_providers.dart';
import 'package:octogear/features/general_requests/presentation/screens/general_part_request_screen.dart';
import 'package:octogear/features/general_requests/presentation/widgets/request_component_picker.dart';
import 'package:octogear/features/part_requests/presentation/services/part_request_photo_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../part_requests/request_part_screen_test.dart' show FakePhotoPicker;
import 'general_request_fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final translations = <String, Map<String, dynamic>>{};
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    for (final locale in ['en', 'ar']) {
      translations[locale] =
          jsonDecode(
                await rootBundle.loadString('assets/translations/$locale.json'),
              )
              as Map<String, dynamic>;
    }
  });
  Future<void> pump(
    WidgetTester tester,
    FakeGeneralRequestRepository repository, {
    RequestGarageRepository? garage,
    bool arabic = false,
    double scale = 1,
    FakePhotoPicker? picker,
  }) async {
    await tester.binding.setSurfaceSize(const Size(360, 740));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          generalRequestRepositoryProvider.overrideWithValue(repository),
          customerGarageRepositoryProvider.overrideWithValue(
            garage ?? RequestGarageRepository(),
          ),
          partRequestPhotoPickerProvider.overrideWithValue(
            picker ?? FakePhotoPicker(),
          ),
          appLocaleProvider.overrideWith(arabic ? _Arabic.new : _English.new),
        ],
        child: EasyLocalization(
          supportedLocales: const [Locale('ar'), Locale('en')],
          startLocale: Locale(arabic ? 'ar' : 'en'),
          path: 'assets/translations',
          saveLocale: false,
          assetLoader: _Translations(translations),
          child: _App(scale: scale),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tap(WidgetTester tester, String key) async {
    final finder = find.byKey(Key(key));
    if (finder.evaluate().isEmpty) {
      await tester.scrollUntilVisible(
        finder,
        180,
        scrollable: find
            .descendant(
              of: find.byType(ListView).last,
              matching: find.byType(Scrollable),
            )
            .first,
      );
    }
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> toReview(WidgetTester tester) async {
    await tap(tester, 'request-car-7');
    await tap(tester, 'general-next');
    await tap(tester, 'general-custom-part');
    await tester.enterText(
      find.byKey(const Key('general-part-name')),
      'Left headlight',
    );
    await tester.enterText(
      find.byKey(const Key('general-description')),
      'Check the connector',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tap(tester, 'general-next');
  }

  testWidgets(
    'three separate steps validate selection, preserve edits and confirm only on submit',
    (tester) async {
      final repository = FakeGeneralRequestRepository();
      await pump(tester, repository);
      expect(find.text('Step 1 of 3 · Vehicle'), findsOneWidget);
      expect(find.byKey(const Key('general-part-name')), findsNothing);
      await tap(tester, 'general-next');
      expect(
        find.text('Select a car or enter another vehicle.'),
        findsOneWidget,
      );
      await toReview(tester);
      expect(find.text('Step 3 of 3 · Review'), findsOneWidget);
      expect(find.text('Left headlight'), findsOneWidget);
      expect(repository.commands, isEmpty);
      await tap(tester, 'general-edit-1');
      expect(
        find.widgetWithText(TextFormField, 'Left headlight'),
        findsOneWidget,
      );
      await tap(tester, 'general-next');
      await tap(tester, 'general-next');
      expect(repository.commands, hasLength(1));
      final command = repository.commands.single;
      expect((command.vehicle as SavedRequestVehicle).id, 7);
      expect(command.componentName, 'Left headlight');
      expect(command.componentId, isNull);
      expect(command.description, 'Check the connector');
      expect(find.text('View request'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'inline vehicle uses shared selectors and requires transmission; optional save is explicit',
    (tester) async {
      final repository = FakeGeneralRequestRepository();
      await pump(
        tester,
        repository,
        garage: RequestGarageRepository()..cars = [],
      );
      await tap(tester, 'general-new-vehicle');
      Future<void> choose(String key, String value) async {
        await tap(tester, key);
        if (key == 'customer_car_company_field' ||
            key == 'customer_car_name_field') {
          await tester.enterText(
            find.byKey(const Key('searchable-select-query')),
            value.substring(0, 3).toLowerCase(),
          );
          await tester.pumpAndSettle();
          expect(find.widgetWithText(ListTile, value), findsOneWidget);
        }
        await tester.tap(find.text(value).last);
        await tester.pumpAndSettle();
      }

      await choose('customer_car_company_field', 'Toyota');
      await choose('customer_car_name_field', 'Camry');
      await tester.ensureVisible(
        find.byKey(const Key('customer_car_year_field')),
      );
      await tester.enterText(
        find.byKey(const Key('customer_car_year_field')),
        '2020',
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await choose('customer_car_color_field', 'White');
      await choose('customer_car_fuel_type_field', 'Petrol');
      await tap(tester, 'general-next');
      expect(
        find.text('Choose a transmission, or select Not sure.'),
        findsOneWidget,
      );
      await choose('customer_car_transmission_field', 'Automatic');
      await tap(tester, 'general-save-vehicle');
      await tap(tester, 'general-next');
      await tap(tester, 'general-choose-part');
      await tap(tester, 'catalog-part-5');
      await tap(tester, 'general-next');
      expect(
        find.text('This vehicle will also be saved to My cars.'),
        findsOneWidget,
      );
      await tap(tester, 'general-edit-0');
      expect(find.text('Toyota'), findsOneWidget);
      expect(find.text('Camry'), findsOneWidget);
      expect(
        tester
            .widget<TextFormField>(
              find.byKey(const Key('customer_car_year_field')),
            )
            .controller!
            .text,
        '2020',
      );
      await tester.ensureVisible(find.byKey(const Key('general-save-vehicle')));
      expect(
        tester
            .widget<CheckboxListTile>(
              find.byKey(const Key('general-save-vehicle')),
            )
            .value,
        isTrue,
      );
      await tap(tester, 'general-next');
      expect(find.text('Headlight'), findsOneWidget);
      await tap(tester, 'general-next');
      await tap(tester, 'general-next');
      final command = repository.commands.single;
      final vehicle = command.vehicle as NewRequestVehicle;
      expect(
        [
          vehicle.carNameId,
          vehicle.year,
          vehicle.transmission,
          vehicle.colorId,
          vehicle.fuelTypeId,
          vehicle.saveToGarage,
        ],
        [2, 2020, 'automatic', 3, 4, true],
      );
      expect(command.componentId, 5);
      expect(command.componentName, isNull);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'uncertain submission disables edits and retries the original payload',
    (tester) async {
      final repository = FakeGeneralRequestRepository()
        ..onSubmit = (_) async =>
            throw const ApiFailure(type: ApiFailureType.timeout);
      await pump(tester, repository);
      await toReview(tester);
      await tap(tester, 'general-next');
      expect(
        tester
            .widget<TextButton>(find.byKey(const Key('general-edit-0')))
            .onPressed,
        isNull,
      );
      expect(
        tester
            .widget<TextButton>(find.byKey(const Key('general-edit-1')))
            .onPressed,
        isNull,
      );
      expect(repository.commands, hasLength(1));
      repository.onSubmit = null;
      await tap(tester, 'general-next');
      expect(repository.commands, hasLength(2));
      expect(
        identical(repository.commands.first, repository.commands.last),
        isTrue,
      );
    },
  );
  testWidgets(
    'failed garage still allows another vehicle; cancel protects the draft',
    (tester) async {
      await pump(
        tester,
        FakeGeneralRequestRepository(),
        garage: RequestGarageRepository()..failCars = true,
      );
      expect(
        find.text('We couldn’t load the vehicle details. Please try again.'),
        findsOneWidget,
      );
      await tap(tester, 'general-new-vehicle');
      expect(
        find.byKey(const Key('customer_car_company_field')),
        findsOneWidget,
      );
      await tap(tester, 'general-back');
      expect(find.byType(AlertDialog), findsOneWidget);
      await tester.tap(find.text('Keep request open'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(
        find.byKey(const Key('customer_car_company_field')),
        findsOneWidget,
      );
    },
  );
  testWidgets(
    'five photos stay in the draft after validation rejection and can be removed',
    (tester) async {
      final repository = FakeGeneralRequestRepository()
        ..onSubmit = (_) async => throw const ApiFailure(
          type: ApiFailureType.validation,
          statusCode: 422,
          fieldErrors: {
            'description': ['Please clarify the part'],
          },
        );
      final picker = FakePhotoPicker()
        ..photo = PartRequestPhoto(
          bytes: base64Decode(
            'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVQIHWP4z8DwHwAF/gL+9/3K8QAAAABJRU5ErkJggg==',
          ),
          mimeType: 'image/png',
        );
      await pump(tester, repository, picker: picker);
      await toReview(tester);
      await tap(tester, 'general-edit-1');
      for (var i = 0; i < 5; i++) {
        await tap(tester, 'general-add-photo');
      }
      expect(find.byKey(const Key('general-add-photo')), findsNothing);
      await tap(tester, 'general-next');
      await tap(tester, 'general-next');
      expect(repository.commands.single.photos, hasLength(5));
      expect(find.text('Please clarify the part'), findsOneWidget);
      await tap(tester, 'general-edit-1');
      final remove = find.byTooltip('Remove photo 1');
      await tester.ensureVisible(remove);
      await tester.pumpAndSettle();
      await tester.tap(remove);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('general-add-photo')), findsOneWidget);
      await tap(tester, 'general-next');
      repository.onSubmit = null;
      await tap(tester, 'general-next');
      expect(repository.commands.last.photos, hasLength(4));
      expect(
        repository.commands.last.idempotencyKey,
        isNot(repository.commands.first.idempotencyKey),
      );
    },
  );
  for (final arabic in [false, true]) {
    testWidgets(
      'all steps fit ${arabic ? 'Arabic' : 'English'} at large text size',
      (tester) async {
        await pump(
          tester,
          FakeGeneralRequestRepository(),
          arabic: arabic,
          scale: 2,
        );
        await toReview(tester);
        expect(tester.takeException(), isNull);
        await tap(tester, 'general-edit-0');
        await tap(tester, 'general-new-vehicle');
        await tap(tester, 'general-next');
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets('catalog search discards stale results and loads another page', (
    tester,
  ) async {
    final oldSearch = Completer<RequestComponentsPage>();
    final repository = FakeGeneralRequestRepository()
      ..onSearch = (query, page) async {
        if (query == 'old') return oldSearch.future;
        return RequestComponentsPage(
          items: [RequestComponent(id: page, name: '$query part $page')],
          page: page,
          lastPage: 2,
        );
      };
    await pump(tester, repository);
    await tap(tester, 'request-car-7');
    await tap(tester, 'general-next');
    await tap(tester, 'general-choose-part');
    final search = find.byKey(const Key('general-part-search'));
    await tester.enterText(search, 'old');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.enterText(search, 'new');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    oldSearch.complete(
      const RequestComponentsPage(
        items: [RequestComponent(id: 99, name: 'stale')],
        page: 1,
        lastPage: 1,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('stale'), findsNothing);
    await tester.tap(find.text('Show more parts'));
    await tester.pumpAndSettle();
    expect(find.text('new part 2'), findsOneWidget);
    await tap(tester, 'catalog-part-2');
    expect(find.byType(RequestComponentPicker), findsNothing);
  });
}

class _App extends StatelessWidget {
  const _App({required this.scale});
  final double scale;
  @override
  Widget build(BuildContext context) => MaterialApp(
    theme: OctoGearTheme.forLocale(context.locale),
    locale: context.locale,
    supportedLocales: context.supportedLocales,
    localizationsDelegates: context.localizationDelegates,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(scale)),
      child: child!,
    ),
    home: const Scaffold(body: SafeArea(child: GeneralPartRequestScreen())),
  );
}

class _English extends AppLocaleController {
  @override
  AppLocale build() => AppLocale.english;
}

class _Arabic extends AppLocaleController {
  @override
  AppLocale build() => AppLocale.arabic;
}

class _Translations extends AssetLoader {
  const _Translations(this.values);
  final Map<String, Map<String, dynamic>> values;
  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async =>
      values[locale.languageCode]!;
}
