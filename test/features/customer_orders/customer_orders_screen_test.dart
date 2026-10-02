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
import 'package:octogear/features/customer_orders/data/models/customer_order_dto.dart';
import 'package:octogear/features/customer_orders/domain/entities/customer_order.dart';
import 'package:octogear/features/customer_orders/presentation/controllers/customer_orders_providers.dart';
import 'package:octogear/features/customer_orders/presentation/screens/customer_order_details_screen.dart';
import 'package:octogear/features/customer_orders/presentation/screens/customer_orders_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'order_fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final translations = <String, Map<String, dynamic>>{};
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    for (final code in ['ar', 'en']) {
      translations[code] =
          jsonDecode(
                await rootBundle.loadString('assets/translations/$code.json'),
              )
              as Map<String, dynamic>;
    }
  });
  Future<void> pump(
    WidgetTester tester,
    FakeOrdersRepository repo, {
    int? detailId,
    bool arabic = false,
    double scale = 1,
    bool settle = true,
  }) async {
    await tester.binding.setSurfaceSize(const Size(360, 760));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          customerOrdersRepositoryProvider.overrideWithValue(repo),
          appLocaleProvider.overrideWith(arabic ? _Arabic.new : _English.new),
        ],
        child: EasyLocalization(
          supportedLocales: const [Locale('ar'), Locale('en')],
          startLocale: Locale(arabic ? 'ar' : 'en'),
          path: 'assets/translations',
          saveLocale: false,
          assetLoader: _Translations(translations),
          child: _App(
            scale: scale,
            child: detailId == null
                ? const CustomerOrdersScreen()
                : CustomerOrderDetailsScreen(orderId: detailId),
          ),
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

  testWidgets('list distinguishes both types and filters using the server', (
    tester,
  ) async {
    final repo = FakeOrdersRepository();
    await pump(tester, repo);
    expect(find.text('Your orders'), findsOneWidget);
    expect(find.text('Left wheel'), findsOneWidget);
    expect(find.text('Order total'), findsOneWidget);
    expect(find.textContaining('300.00'), findsOneWidget);
    await tester.tap(find.text('General requests'));
    await tester.pumpAndSettle();
    expect(find.text('General part request'), findsOneWidget);
    expect(find.text('Awaiting offers'), findsOneWidget);
    expect(find.text('No store selected yet'), findsOneWidget);
    expect(find.text('Left wheel'), findsNothing);
    expect(repo.calls.last.filter, CustomerOrderFilter.general);
  });
  testWidgets('general detail shows whole-request totals without quantity', (
    tester,
  ) async {
    final json = orderJson(id: 2, general: true)
      ..['status'] = 'awaiting_payment'
      ..['accepted_offer_id'] = 1
      ..['accepted_store'] = {'id': 14, 'name': 'Chosen store'}
      ..['offered_price'] = 15000
      ..['offers_count'] = 2
      ..['offers'] = [
        {
          'id': 1,
          'price': 15000,
          'images': [],
          'status': 'pending',
          'store': {'id': 14, 'name': 'Chosen store'},
          'notes': 'Original part',
        },
        {
          'id': 2,
          'price': 18000,
          'images': [],
          'status': 'rejected',
          'store': null,
          'rejection_reason': 'Not suitable',
        },
      ];
    final repo = FakeOrdersRepository()
      ..onGet = (_) async => CustomerOrderDto.fromJson(json).value;
    await pump(tester, repo, detailId: 2);
    expect(find.text('General part request'), findsOneWidget);
    expect(find.text('Awaiting payment'), findsOneWidget);
    expect(find.text('Quantity'), findsNothing);
    await reveal(tester, find.text('Selected offer total'));
    expect(find.textContaining('150.00'), findsWidgets);
    await reveal(tester, find.text('Store offers (2)'));
    await reveal(tester, find.text('Original part'));
    expect(find.text('Selected store'), findsWidgets);
    await reveal(tester, find.text('Reason: Not suitable'));
    expect(find.text('Store details unavailable'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'specific paid detail shows actual payment and never general offer controls',
    (tester) async {
      final json = orderJson()
        ..['paid_amount'] = 24000
        ..['status'] = 'paid';
      final repo = FakeOrdersRepository()
        ..onGet = (_) async => CustomerOrderDto.fromJson(json).value;
      await pump(tester, repo, detailId: 1);
      await reveal(tester, find.text('Amount paid'));
      expect(find.textContaining('240.00'), findsOneWidget);
      expect(find.textContaining('500.00'), findsNothing);
      expect(find.textContaining('Store offers'), findsNothing);
      await reveal(tester, find.text('Check connector'));
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'paid general order retains accepted and unselected offers without unit prices',
    (tester) async {
      final json = orderJson(id: 2, general: true)
        ..['status'] = 'paid'
        ..['paid_amount'] = 30000
        ..['accepted_offer_id'] = 10
        ..['offers_count'] = 2
        ..['offers'] = [
          {
            'id': 10,
            'price': 30000,
            'status': 'accepted',
            'notes': 'Purchased mirror set',
            'images': [],
          },
          {
            'id': 11,
            'price': 40000,
            'status': 'not_selected',
            'notes': 'Alternative mirror set',
            'images': [],
          },
        ];
      final repo = FakeOrdersRepository()
        ..onGet = (_) async => CustomerOrderDto.fromJson(json).value;
      await pump(tester, repo, detailId: 2);
      expect(find.text('Quantity'), findsNothing);
      await reveal(tester, find.text('Purchased mirror set'));
      await reveal(tester, find.text('Alternative mirror set'));
      expect(find.text('Not selected'), findsOneWidget);
      expect(find.textContaining('Unit price'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'Arabic large text general detail supports missing data and zero offers',
    (tester) async {
      final json = orderJson(id: 2, general: true)
        ..['notes'] = null
        ..['vehicle_details'] = null
        ..['car_name'] = null;
      final repo = FakeOrdersRepository()
        ..onGet = (_) async => CustomerOrderDto.fromJson(json).value;
      await pump(tester, repo, detailId: 2, arabic: true, scale: 1.8);
      expect(
        Directionality.of(
          tester.element(find.byType(CustomerOrderDetailsScreen)),
        ).name,
        'rtl',
      );
      await reveal(tester, find.text('لم يُختر متجر بعد'));
      await reveal(tester, find.text('لا توجد عروض لعرضها'));
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('Arabic large text list filters remain reachable and cards fit', (
    tester,
  ) async {
    await pump(tester, FakeOrdersRepository(), arabic: true, scale: 1.8);
    await tester.tap(find.text('الطلبات العامة'));
    await tester.pumpAndSettle();
    await reveal(tester, find.text('عرض التفاصيل'), list: true);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'list has visible loading, retry and truthful empty state without automatic retries',
    (tester) async {
      final pending = Completer<CustomerOrdersPage>();
      final repo = FakeOrdersRepository()..onList = (_, _) => pending.future;
      await pump(tester, repo, settle: false);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      pending.completeError(
        const ApiFailure(type: ApiFailureType.noConnection),
      );
      await tester.pumpAndSettle();
      expect(find.text("Couldn't load orders"), findsOneWidget);
      expect(repo.calls.length, 1);
      repo.onList = (_, _) async => ordersPage([]);
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(find.text('No orders yet'), findsOneWidget);
      expect(find.text('Explore stores'), findsNothing);
      expect(find.text('Home'), findsOneWidget);
      expect(
        find.text('Your requests and their updates will appear here.'),
        findsOneWidget,
      );
    },
  );
  testWidgets(
    'detail not found never displays another order or write actions',
    (tester) async {
      final repo = FakeOrdersRepository()
        ..onGet = (_) async =>
            throw const ApiFailure(type: ApiFailureType.notFound);
      await pump(tester, repo, detailId: 99);
      expect(
        find.textContaining('This order is no longer available'),
        findsOneWidget,
      );
      expect(find.text('Left wheel'), findsNothing);
      expect(find.text('Pay'), findsNothing);
    },
  );
}

Future<void> reveal(
  WidgetTester tester,
  Finder finder, {
  bool list = false,
}) async {
  for (var i = 0; i < 50; i++) {
    if (finder.hitTestable().evaluate().isNotEmpty) return;
    await tester.drag(
      find.byType(list ? CustomScrollView : ListView),
      const Offset(0, -200),
    );
    await tester.pump(const Duration(milliseconds: 200));
  }
  expect(finder.hitTestable(), findsWidgets);
}

class _App extends StatelessWidget {
  const _App({required this.child, required this.scale});
  final Widget child;
  final double scale;
  @override
  Widget build(BuildContext context) => MaterialApp(
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
    home: Scaffold(body: SafeArea(child: child)),
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
  const _Translations(this.translations);
  final Map<String, Map<String, dynamic>> translations;
  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async =>
      translations[locale.languageCode]!;
}
