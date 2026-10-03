import 'dart:convert';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:octogear/core/design_system/octogear_theme.dart';
import 'package:octogear/core/widgets/octogear_searchable_select_field.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final translations = <String, Map<String, dynamic>>{};
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    for (final language in ['en', 'ar']) {
      translations[language] =
          jsonDecode(
                await rootBundle.loadString(
                  'assets/translations/$language.json',
                ),
              )
              as Map<String, dynamic>;
    }
  });
  final form = GlobalKey<FormState>();
  late ValueNotifier<int?> selected;
  late List<int?> changes;
  setUp(() {
    selected = ValueNotifier<int?>(null);
    changes = [];
  });
  tearDown(() => selected.dispose());
  Future<void> pump(
    WidgetTester tester, {
    bool arabic = false,
    bool enabled = true,
    double scale = 1,
    double keyboard = 0,
  }) async {
    await tester.binding.setSurfaceSize(const Size(360, 740));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('ar'), Locale('en')],
        startLocale: Locale(arabic ? 'ar' : 'en'),
        path: 'assets/translations',
        saveLocale: false,
        assetLoader: _Translations(translations),
        child: Builder(
          builder: (context) => MaterialApp(
            theme: OctoGearTheme.forLocale(context.locale),
            locale: context.locale,
            supportedLocales: context.supportedLocales,
            localizationsDelegates: context.localizationDelegates,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(scale),
                viewInsets: EdgeInsets.only(bottom: keyboard),
              ),
              child: child!,
            ),
            home: Scaffold(
              body: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: form,
                    child: ValueListenableBuilder<int?>(
                      valueListenable: selected,
                      builder: (_, value, _) =>
                          OctoGearSearchableSelectField<int>(
                            key: const Key('field'),
                            value: value,
                            options: arabic
                                ? const [
                                    OctoGearSelectOption(
                                      value: 1,
                                      label: 'أُوبل',
                                    ),
                                    OctoGearSelectOption(
                                      value: 2,
                                      label: 'تويوتا',
                                    ),
                                  ]
                                : const [
                                    OctoGearSelectOption(
                                      value: 1,
                                      label: 'Toyota',
                                    ),
                                    OctoGearSelectOption(
                                      value: 2,
                                      label: 'Honda',
                                    ),
                                  ],
                            label: arabic ? 'الشركة المصنعة' : 'Manufacturer',
                            hint: arabic
                                ? 'اختر الشركة'
                                : 'Choose manufacturer',
                            searchHint: arabic
                                ? 'ابحث عن الشركة'
                                : 'Search manufacturers',
                            noResultsText: arabic
                                ? 'لا توجد نتائج'
                                : 'No matches',
                            icon: Icons.factory_outlined,
                            onChanged: enabled
                                ? (value) {
                                    selected.value = value;
                                    changes.add(value);
                                  }
                                : null,
                            validator: (value) =>
                                value == null ? 'Required' : null,
                          ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> open(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('field')));
    await tester.pumpAndSettle();
  }

  final query = find.byKey(const Key('searchable-select-query'));
  testWidgets(
    'filters case-insensitively, clears no matches, and preserves selection on cancel/reselect',
    (tester) async {
      await pump(tester);
      expect(form.currentState!.validate(), isFalse);
      await tester.pump();
      await open(tester);
      await tester.enterText(query, '  tOyO  ');
      await tester.pumpAndSettle();
      expect(find.widgetWithText(ListTile, 'Toyota'), findsOneWidget);
      expect(find.widgetWithText(ListTile, 'Honda'), findsNothing);
      await tester.tap(find.text('Toyota'));
      await tester.pumpAndSettle();
      expect(selected.value, 1);
      expect(form.currentState!.validate(), isTrue);
      await open(tester);
      await tester.enterText(query, 'not a manufacturer');
      await tester.pumpAndSettle();
      expect(find.text('No matches'), findsOneWidget);
      await tester.tap(find.byTooltip('Clear search'));
      await tester.pumpAndSettle();
      expect(find.byType(ListTile), findsNWidgets(2));
      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();
      expect(selected.value, 1);
      await open(tester);
      await tester.tap(find.widgetWithText(ListTile, 'Toyota'));
      await tester.pumpAndSettle();
      expect(changes, [1]);
      selected.value = null;
      await tester.pumpAndSettle();
      expect(form.currentState!.validate(), isFalse);
    },
  );
  testWidgets(
    'Arabic search matches alef variants and vowel marks with large text and keyboard',
    (tester) async {
      await pump(tester, arabic: true, scale: 2, keyboard: 280);
      await open(tester);
      await tester.enterText(query, 'اوبل');
      await tester.pumpAndSettle();
      expect(find.widgetWithText(ListTile, 'أُوبل'), findsOneWidget);
      expect(find.widgetWithText(ListTile, 'تويوتا'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.tap(find.widgetWithText(ListTile, 'أُوبل'));
      await tester.pumpAndSettle();
      expect(selected.value, 1);
    },
  );
  testWidgets('locked form cannot open a selector', (tester) async {
    await pump(tester, enabled: false);
    await open(tester);
    expect(query, findsNothing);
    expect(changes, isEmpty);
  });
}

class _Translations extends AssetLoader {
  const _Translations(this.translations);
  final Map<String, Map<String, dynamic>> translations;
  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async =>
      translations[locale.languageCode]!;
}
