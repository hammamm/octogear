import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui show TextDirection;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:octogear/core/api/api_failure.dart';
import 'package:octogear/core/design_system/octogear_theme.dart';
import 'package:octogear/core/localization/app_locale.dart';
import 'package:octogear/core/localization/app_locale_controller.dart';
import 'package:octogear/features/customer_garage/domain/entities/create_customer_car_command.dart';
import 'package:octogear/features/customer_garage/domain/entities/update_customer_car_command.dart';
import 'package:octogear/features/customer_garage/domain/entities/customer_car.dart';
import 'package:octogear/features/customer_garage/domain/entities/customer_car_form_references.dart';
import 'package:octogear/features/customer_garage/domain/repositories/customer_garage_repository.dart';
import 'package:octogear/features/customer_garage/domain/use_cases/create_customer_car_use_case.dart';
import 'package:octogear/features/customer_garage/domain/use_cases/get_customer_car_form_references_use_case.dart';
import 'package:octogear/features/customer_garage/domain/use_cases/get_customer_car_names_use_case.dart';
import 'package:octogear/features/customer_garage/presentation/controllers/customer_cars_providers.dart';
import 'package:octogear/features/customer_garage/presentation/screens/create_customer_car_screen.dart';
import 'package:octogear/features/customer_garage/presentation/services/customer_car_gallery_picker.dart';
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

  testWidgets('shows an accessible loading state while references load', (
    tester,
  ) async {
    final referencesUseCase = _PendingReferencesUseCase();
    await _pumpScreen(
      tester,
      translations: englishTranslations,
      referencesUseCase: referencesUseCase,
      settle: false,
    );

    expect(find.bySemanticsLabel('Loading vehicle options'), findsOneWidget);

    referencesUseCase.completer.complete(_references);
    await tester.pumpAndSettle();
  });

  testWidgets('keeps a reference failure visible until explicit Retry', (
    tester,
  ) async {
    final referencesUseCase = _RetryingReferencesUseCase();
    await _pumpScreen(
      tester,
      translations: englishTranslations,
      referencesUseCase: referencesUseCase,
    );

    expect(find.text("We couldn't load vehicle options"), findsOneWidget);
    expect(
      find.text('Check your internet connection and try again.'),
      findsOneWidget,
    );
    expect(find.text('Retry'), findsOneWidget);
    expect(referencesUseCase.callCount, 1);

    referencesUseCase.shouldSucceed = true;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('customer_car_company_field')), findsOneWidget);
    expect(referencesUseCase.callCount, 2);
  });

  testWidgets('shows field validation without submitting an incomplete car', (
    tester,
  ) async {
    final namesUseCase = _RecordingNamesUseCase();
    final createUseCase = _PendingCreateUseCase();
    await _pumpScreen(
      tester,
      translations: englishTranslations,
      namesUseCase: namesUseCase,
      createUseCase: createUseCase,
    );

    await _selectDropdown(
      tester,
      const Key('customer_car_company_field'),
      'Toyota',
    );
    expect(namesUseCase.companyIds, [1]);

    final submit = find.byKey(const Key('customer_car_submit_button'));
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();

    expect(find.text('Choose a car name.'), findsOneWidget);
    expect(find.text('Enter the manufacturing year.'), findsOneWidget);
    expect(
      find.byKey(const Key('customer_car_transmission_field')),
      findsOneWidget,
    );
    expect(find.text('Choose a color.'), findsOneWidget);
    expect(find.text('Choose a fuel type.'), findsOneWidget);
    expect(createUseCase.commands, isEmpty);
  });

  testWidgets(
    'loads names for the selected company and submits the exact car command',
    (tester) async {
      final namesUseCase = _RecordingNamesUseCase();
      final createUseCase = _PendingCreateUseCase();
      final picker = _FakeGalleryPicker(
        pickSelection: CustomerCarPhotoSelection(photos: [_firstPhoto]),
      );
      await _pumpScreen(
        tester,
        translations: englishTranslations,
        namesUseCase: namesUseCase,
        createUseCase: createUseCase,
        galleryPicker: picker,
      );

      await _selectDropdown(
        tester,
        const Key('customer_car_company_field'),
        'Toyota',
      );
      expect(namesUseCase.companyIds, [1]);

      await _selectDropdown(
        tester,
        const Key('customer_car_name_field'),
        'Camry',
      );
      await tester.enterText(
        find.byKey(const Key('customer_car_year_field')),
        '2022',
      );
      await _selectDropdown(
        tester,
        const Key('customer_car_transmission_field'),
        'Automatic',
      );
      await _selectDropdown(
        tester,
        const Key('customer_car_color_field'),
        'White',
      );
      await _selectDropdown(
        tester,
        const Key('customer_car_fuel_type_field'),
        'Petrol',
      );
      final addPhotos = find.byKey(const Key('customer_car_add_photos_button'));
      await tester.ensureVisible(addPhotos);
      await tester.tap(addPhotos);
      await tester.pumpAndSettle();

      final submit = find.byKey(const Key('customer_car_submit_button'));
      await tester.ensureVisible(submit);
      await tester.tap(submit);
      await tester.pump();

      expect(picker.requestedLimits, [5]);
      expect(createUseCase.commands, hasLength(1));
      final command = createUseCase.commands.single;
      expect(command.carNameId, 11);
      expect(command.manufacturingYear, 2022);
      expect(command.transmissionType, 'automatic');
      expect(command.colorId, 21);
      expect(command.fuelTypeId, 31);
      expect(command.pictures, [_firstPhoto]);
      expect(
        command.idempotencyKey,
        matches(
          RegExp(
            r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
          ),
        ),
      );
    },
  );

  testWidgets(
    'retrying a connection failure reuses the original submission command',
    (tester) async {
      final namesUseCase = _RecordingNamesUseCase();
      final createUseCase = _ConnectionThenPendingCreateUseCase();
      await _pumpScreen(
        tester,
        translations: englishTranslations,
        namesUseCase: namesUseCase,
        createUseCase: createUseCase,
      );

      await _fillValidCarForm(tester);
      final submit = find.byKey(const Key('customer_car_submit_button'));
      await tester.ensureVisible(submit);
      await tester.tap(submit);
      await tester.pumpAndSettle();

      expect(
        find.text('Check your internet connection and try again.'),
        findsOneWidget,
      );
      final retry = find.byKey(
        const Key('customer_car_retry_submission_button'),
      );
      await tester.ensureVisible(retry);
      await tester.tap(retry);
      await tester.pump();

      expect(createUseCase.commands, hasLength(2));
      expect(
        identical(createUseCase.commands.first, createUseCase.commands.last),
        isTrue,
      );
      expect(
        createUseCase.commands.first.idempotencyKey,
        createUseCase.commands.last.idempotencyKey,
      );
    },
  );

  testWidgets(
    'adds gallery photos in memory and lets the customer remove one',
    (tester) async {
      final picker = _FakeGalleryPicker(
        pickSelection: CustomerCarPhotoSelection(
          photos: [_firstPhoto, _secondPhoto],
        ),
      );
      await _pumpScreen(
        tester,
        translations: englishTranslations,
        galleryPicker: picker,
      );

      final addPhotos = find.byKey(const Key('customer_car_add_photos_button'));
      await tester.ensureVisible(addPhotos);
      await tester.tap(addPhotos);
      await tester.pumpAndSettle();

      expect(picker.requestedLimits, [5]);
      expect(
        find.byKey(const Key('customer_car_remove_photo_0')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('customer_car_remove_photo_1')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('customer_car_remove_photo_0')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('customer_car_remove_photo_0')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('customer_car_remove_photo_1')),
        findsNothing,
      );
    },
  );

  testWidgets('uses Arabic RTL layout with a localized transmission selector', (
    tester,
  ) async {
    await _pumpScreen(
      tester,
      translations: arabicTranslations,
      locale: AppLocale.arabic,
    );

    final title = find.text('إضافة سيارة').first;
    expect(Directionality.of(tester.element(title)), ui.TextDirection.rtl);
    await _selectDropdown(
      tester,
      const Key('customer_car_transmission_field'),
      'أوتوماتيك',
    );
    expect(find.text('أوتوماتيك'), findsOneWidget);
  });
}

Future<void> _pumpScreen(
  WidgetTester tester, {
  required Map<String, dynamic> translations,
  AppLocale locale = AppLocale.english,
  GetCustomerCarFormReferencesUseCase? referencesUseCase,
  GetCustomerCarNamesUseCase? namesUseCase,
  CreateCustomerCarUseCase? createUseCase,
  CustomerCarGalleryPicker? galleryPicker,
  bool settle = true,
}) async {
  await tester.binding.setSurfaceSize(const Size(800, 1400));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    EasyLocalization(
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
          getCustomerCarFormReferencesUseCaseProvider.overrideWithValue(
            referencesUseCase ?? _SuccessfulReferencesUseCase(),
          ),
          getCustomerCarNamesUseCaseProvider.overrideWithValue(
            namesUseCase ?? _RecordingNamesUseCase(),
          ),
          createCustomerCarUseCaseProvider.overrideWithValue(
            createUseCase ?? _PendingCreateUseCase(),
          ),
          customerCarGalleryPickerProvider.overrideWithValue(
            galleryPicker ?? _FakeGalleryPicker(),
          ),
        ],
        child: Builder(
          builder: (context) => MaterialApp(
            theme: OctoGearTheme.lightTheme,
            locale: context.locale,
            supportedLocales: context.supportedLocales,
            localizationsDelegates: context.localizationDelegates,
            home: const Scaffold(body: CreateCustomerCarScreen()),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  if (settle) await tester.pumpAndSettle();
}

Future<void> _fillValidCarForm(WidgetTester tester) async {
  await _selectDropdown(
    tester,
    const Key('customer_car_company_field'),
    'Toyota',
  );
  await _selectDropdown(tester, const Key('customer_car_name_field'), 'Camry');
  await tester.enterText(
    find.byKey(const Key('customer_car_year_field')),
    '2022',
  );
  await _selectDropdown(
    tester,
    const Key('customer_car_transmission_field'),
    'Automatic',
  );
  await _selectDropdown(tester, const Key('customer_car_color_field'), 'White');
  await _selectDropdown(
    tester,
    const Key('customer_car_fuel_type_field'),
    'Petrol',
  );
}

Future<void> _selectDropdown(
  WidgetTester tester,
  Key fieldKey,
  String option,
) async {
  final field = find.byKey(fieldKey);
  await tester.ensureVisible(field);
  await tester.tap(field);
  await tester.pumpAndSettle();
  if (fieldKey == const Key('customer_car_company_field') ||
      fieldKey == const Key('customer_car_name_field')) {
    await tester.enterText(
      find.byKey(const Key('searchable-select-query')),
      option.substring(0, 3).toLowerCase(),
    );
    await tester.pumpAndSettle();
    expect(find.widgetWithText(ListTile, option), findsOneWidget);
  }
  await tester.tap(find.text(option).last);
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

class _PendingReferencesUseCase extends GetCustomerCarFormReferencesUseCase {
  _PendingReferencesUseCase() : super(_UnusedCustomerGarageRepository());

  final completer = Completer<CustomerCarFormReferences>();

  @override
  Future<CustomerCarFormReferences> call() => completer.future;
}

class _SuccessfulReferencesUseCase extends GetCustomerCarFormReferencesUseCase {
  _SuccessfulReferencesUseCase() : super(_UnusedCustomerGarageRepository());

  @override
  Future<CustomerCarFormReferences> call() async => _references;
}

class _RetryingReferencesUseCase extends GetCustomerCarFormReferencesUseCase {
  _RetryingReferencesUseCase() : super(_UnusedCustomerGarageRepository());

  bool shouldSucceed = false;
  int callCount = 0;

  @override
  Future<CustomerCarFormReferences> call() async {
    callCount++;
    if (!shouldSucceed) {
      throw const ApiFailure(type: ApiFailureType.noConnection);
    }
    return _references;
  }
}

class _RecordingNamesUseCase extends GetCustomerCarNamesUseCase {
  _RecordingNamesUseCase() : super(_UnusedCustomerGarageRepository());

  final companyIds = <int>[];

  @override
  Future<List<CustomerCarReference>> call(int companyId) async {
    companyIds.add(companyId);
    return switch (companyId) {
      1 => _toyotaNames,
      _ => const [],
    };
  }
}

class _PendingCreateUseCase extends CreateCustomerCarUseCase {
  _PendingCreateUseCase() : super(_UnusedCustomerGarageRepository());

  final commands = <CreateCustomerCarCommand>[];
  final completer = Completer<CustomerCar>();

  @override
  Future<CustomerCar> call(CreateCustomerCarCommand command) {
    commands.add(command);
    return completer.future;
  }
}

class _ConnectionThenPendingCreateUseCase extends CreateCustomerCarUseCase {
  _ConnectionThenPendingCreateUseCase()
    : super(_UnusedCustomerGarageRepository());

  final commands = <CreateCustomerCarCommand>[];
  final completer = Completer<CustomerCar>();

  @override
  Future<CustomerCar> call(CreateCustomerCarCommand command) async {
    commands.add(command);
    if (commands.length == 1) {
      throw const ApiFailure(type: ApiFailureType.noConnection);
    }
    return completer.future;
  }
}

class _FakeGalleryPicker implements CustomerCarGalleryPicker {
  _FakeGalleryPicker({
    this.pickSelection = const CustomerCarPhotoSelection(photos: []),
  });

  final CustomerCarPhotoSelection pickSelection;
  final requestedLimits = <int>[];

  @override
  Future<CustomerCarPhotoSelection> pickPhotos({required int limit}) async {
    requestedLimits.add(limit);
    return pickSelection;
  }

  @override
  Future<CustomerCarPhotoSelection> recoverLostPhotos() async {
    return const CustomerCarPhotoSelection(photos: []);
  }
}

class _UnusedCustomerGarageRepository implements CustomerGarageRepository {
  @override
  Future<CustomerCar> createCustomerCar(CreateCustomerCarCommand command) {
    throw UnimplementedError();
  }

  @override
  Future<List<CustomerCarReference>> getCarNames(int companyId) {
    throw UnimplementedError();
  }

  @override
  Future<CustomerCarFormReferences> getCustomerCarFormReferences() {
    throw UnimplementedError();
  }

  @override
  Future<List<CustomerCar>> getCustomerCars() => throw UnimplementedError();

  @override
  Future<CustomerCar> getCustomerCar(int carId) => throw UnimplementedError();

  @override
  Future<CustomerCar> updateCustomerCar(
    int carId,
    UpdateCustomerCarCommand command,
  ) => throw UnimplementedError();

  @override
  Future<void> deleteCustomerCar(int carId) => throw UnimplementedError();
}

const _references = CustomerCarFormReferences(
  companies: [CustomerCarReference(id: 1, name: 'Toyota')],
  colors: [CustomerCarReference(id: 21, name: 'White')],
  fuelTypes: [CustomerCarReference(id: 31, name: 'Petrol')],
);

const _toyotaNames = [CustomerCarReference(id: 11, name: 'Camry')];

final _firstPhoto = CustomerCarPhotoUpload(
  bytes: Uint8List.fromList(_transparentPng),
  mimeType: 'image/png',
);

final _secondPhoto = CustomerCarPhotoUpload(
  bytes: Uint8List.fromList(_transparentPng),
  mimeType: 'image/png',
);

const _transparentPng = <int>[
  137,
  80,
  78,
  71,
  13,
  10,
  26,
  10,
  0,
  0,
  0,
  13,
  73,
  72,
  68,
  82,
  0,
  0,
  0,
  1,
  0,
  0,
  0,
  1,
  8,
  6,
  0,
  0,
  0,
  31,
  21,
  196,
  137,
  0,
  0,
  0,
  13,
  73,
  68,
  65,
  84,
  8,
  215,
  99,
  248,
  207,
  192,
  240,
  31,
  0,
  5,
  0,
  1,
  255,
  137,
  153,
  61,
  29,
  0,
  0,
  0,
  0,
  73,
  69,
  78,
  68,
  174,
  66,
  96,
  130,
];
