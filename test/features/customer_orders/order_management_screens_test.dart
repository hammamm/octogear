import 'package:octogear/features/customer_garage/domain/entities/customer_car.dart';
import 'package:octogear/features/customer_garage/domain/entities/customer_car_form_references.dart';
import 'package:octogear/features/customer_garage/presentation/controllers/customer_car_form_references_controller.dart';
import 'package:octogear/features/customer_garage/presentation/controllers/customer_car_names_controller.dart';
import 'dart:convert';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:octogear/core/localization/app_locale.dart';
import 'package:octogear/core/localization/app_locale_controller.dart';
import 'package:octogear/core/design_system/octogear_theme.dart';
import 'package:octogear/features/customer_orders/data/models/customer_order_dto.dart';
import 'package:octogear/features/customer_orders/presentation/controllers/customer_orders_providers.dart';
import 'package:octogear/features/customer_orders/presentation/controllers/order_management_controller.dart';
import 'package:octogear/features/customer_orders/presentation/screens/customer_order_details_screen.dart';
import 'package:octogear/features/customer_orders/presentation/screens/edit_customer_order_screen.dart';
import 'order_fixtures.dart';
import 'order_management_test.dart' show FakeOrderManagement, managementJson;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final translations = <String, Map<String, dynamic>>{};
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    for (final code in ['en', 'ar']) {
      translations[code] =
          jsonDecode(
                await rootBundle.loadString('assets/translations/$code.json'),
              )
              as Map<String, dynamic>;
    }
  });
  Future<void> pump(
    WidgetTester tester,
    FakeOrderManagement actions, {
    bool edit = false,
    bool arabic = false,
    bool general = true,
    bool editable = true,
    double scale = 1,
  }) async {
    await tester.binding.setSurfaceSize(Size(scale == 1 ? 390 : 320, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final json = managementJson(general: general, editable: editable);
    if (general) {
      (json['vehicle_details'] as Map).addAll(<String, Object>{
        'car_company_id': 1,
        'car_name_id': 2,
        'color_id': 3,
        'fuel_type': 4,
      });
    }
    final repo = FakeOrdersRepository()
      ..onGet = (_) async => CustomerOrderDto.fromJson(json).value;
    actions.onWrite = () async {
      if (actions.changes != null) {
        json['notes'] =
            actions.changes!['description'] ?? actions.changes!['notes'];
        if (actions.changes!.containsKey('component_name')) {
          json['part_name'] = actions.changes!['component_name'];
        }
        if (actions.changes!.containsKey('quantity')) {
          json['quantity'] = actions.changes!['quantity'];
        }
        json['edit_token'] = 'b' * 64;
      }
    };
    final router = GoRouter(
      initialLocation: '/customer/orders/17${edit ? '/edit' : ''}',
      routes: [
        GoRoute(
          path: '/customer/orders',
          builder: (_, _) => const Scaffold(body: Text('Request list')),
          routes: [
            GoRoute(
              path: ':orderId',
              builder: (_, _) =>
                  const Scaffold(body: CustomerOrderDetailsScreen(orderId: 17)),
              routes: [
                GoRoute(
                  path: 'edit',
                  builder: (_, _) => const Scaffold(
                    body: EditCustomerOrderScreen(orderId: 17),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          customerOrdersRepositoryProvider.overrideWithValue(repo),
          customerCarFormReferencesControllerProvider.overrideWith(
            _References.new,
          ),
          customerCarNamesProvider(1).overrideWith(
            (ref) async => [const CustomerCarReference(id: 2, name: 'Camry')],
          ),
          orderManagementRepositoryProvider.overrideWithValue(actions),
          appLocaleProvider.overrideWith(arabic ? _Arabic.new : _English.new),
        ],
        child: EasyLocalization(
          supportedLocales: const [Locale('ar'), Locale('en')],
          startLocale: Locale(arabic ? 'ar' : 'en'),
          path: 'assets/translations',
          saveLocale: false,
          assetLoader: _Translations(translations),
          child: _App(router: router, scale: scale),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'delete can be cancelled and only confirmation removes the request',
    (tester) async {
      final actions = FakeOrderManagement();
      await pump(tester, actions);
      await tester.tap(find.byKey(const Key('order-delete')));
      await tester.pumpAndSettle();
      expect(actions.deletes, 0);
      await tester.tap(find.text('Keep request'));
      await tester.pumpAndSettle();
      expect(actions.deletes, 0);
      await tester.tap(find.byKey(const Key('order-delete')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('order-confirm-delete')));
      await tester.pumpAndSettle();
      expect(actions.deletes, 1);
      expect(find.text('Request list'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  for (final general in [true, false]) {
    testWidgets(
      'edit saves supported fields and returns to updated details general=$general',
      (tester) async {
        final actions = FakeOrderManagement();
        await pump(tester, actions, general: general);
        await tester.tap(find.byKey(const Key('order-edit')));
        await tester.pumpAndSettle();
        final target = find.byKey(
          Key(general ? 'order-edit-part' : 'order-edit-quantity'),
        );
        await tester.enterText(target, general ? 'Left mirror' : '3');
        await tester.enterText(
          find.byKey(const Key('order-edit-notes')),
          'Updated details',
        );
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.ensureVisible(find.byKey(const Key('order-save')));
        await tester.tap(find.byKey(const Key('order-save')));
        await tester.pumpAndSettle();
        expect(actions.updates, 1);
        expect(
          actions.changes,
          general
              ? {
                  'component_name': 'Left mirror',
                  'description': 'Updated details',
                }
              : {'quantity': 3, 'notes': 'Updated details'},
        );
        expect(find.byType(CustomerOrderDetailsScreen), findsOneWidget);
        expect(find.byType(EditCustomerOrderScreen), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'vehicle step keeps a draft until save and includes it in the update',
    (tester) async {
      final actions = FakeOrderManagement();
      await pump(tester, actions, edit: true);
      await tester.tap(find.text('Change vehicle'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('customer_car_year_field')),
        '2023',
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.scrollUntilVisible(
        find.text('Use these details'),
        180,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(find.text('Use these details'));
      await tester.pumpAndSettle();
      expect(actions.updates, 0);
      expect(find.text('Camry · 2023'), findsOneWidget);
      await tester.ensureVisible(find.byKey(const Key('order-save')));
      await tester.tap(find.byKey(const Key('order-save')));
      await tester.pumpAndSettle();
      expect(actions.updates, 1);
      expect(actions.changes!['vehicle'], {
        'car_name_id': 2,
        'manufacturing_year': 2023,
        'color_id': 3,
        'fuel_type': 4,
        'transmission_type': 'automatic',
      });
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('leaving an edited draft requires confirmation', (tester) async {
    final actions = FakeOrderManagement();
    await pump(tester, actions, edit: true);
    await tester.enterText(
      find.byKey(const Key('order-edit-part')),
      'Another part',
    );
    await tester.tap(find.byType(BackButtonIcon).last);
    await tester.pumpAndSettle();
    expect(find.text('Discard your changes?'), findsOneWidget);
    await tester.tap(find.text('Keep editing'));
    await tester.pumpAndSettle();
    expect(find.byType(EditCustomerOrderScreen), findsOneWidget);
    expect(actions.updates, 0);
  });

  testWidgets('server eligibility hides edit and protects direct edit links', (
    tester,
  ) async {
    await pump(tester, FakeOrderManagement(), editable: false);
    expect(find.byKey(const Key('order-edit')), findsNothing);
    expect(find.byKey(const Key('order-delete')), findsOneWidget);
    await pump(tester, FakeOrderManagement(), editable: false, edit: true);
    expect(find.byKey(const Key('order-save')), findsNothing);
  });

  for (final arabic in [false, true]) {
    for (final general in [false, true]) {
      testWidgets(
        'edit is scrollable at 200% text arabic=$arabic general=$general',
        (tester) async {
          await pump(
            tester,
            FakeOrderManagement(),
            edit: true,
            arabic: arabic,
            general: general,
            scale: 2,
          );
          await tester.scrollUntilVisible(
            find.byKey(const Key('order-save')),
            180,
            scrollable: find.byType(Scrollable).first,
          );
          await tester.pumpAndSettle();
          expect(
            find.byKey(const Key('order-save')).hitTestable(),
            findsOneWidget,
          );
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}

class _App extends StatelessWidget {
  const _App({required this.router, required this.scale});
  final GoRouter router;
  final double scale;
  @override
  Widget build(BuildContext context) => MaterialApp.router(
    routerConfig: router,
    theme: OctoGearTheme.lightTheme,
    locale: context.locale,
    localizationsDelegates: context.localizationDelegates,
    supportedLocales: context.supportedLocales,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(scale)),
      child: child!,
    ),
  );
}

class _Translations extends AssetLoader {
  const _Translations(this.values);
  final Map<String, Map<String, dynamic>> values;
  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async =>
      values[locale.languageCode]!;
}

class _English extends AppLocaleController {
  @override
  AppLocale build() => AppLocale.english;
}

class _Arabic extends AppLocaleController {
  @override
  AppLocale build() => AppLocale.arabic;
}

class _References extends CustomerCarFormReferencesController {
  @override
  Future<CustomerCarFormReferences> build() async =>
      const CustomerCarFormReferences(
        companies: [CustomerCarReference(id: 1, name: 'Toyota')],
        colors: [CustomerCarReference(id: 3, name: 'White')],
        fuelTypes: [CustomerCarReference(id: 4, name: 'Petrol')],
      );
}
