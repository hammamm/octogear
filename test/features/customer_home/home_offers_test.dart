import 'dart:convert';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:octogear/core/design_system/octogear_theme.dart';
import 'package:octogear/features/customer_home/presentation/widgets/home_offer_summary.dart';
import 'package:octogear/features/customer_home/presentation/widgets/home_offers.dart';
import 'package:octogear/features/customer_orders/data/models/customer_order_dto.dart';
import '../customer_orders/order_fixtures.dart';

Map<String, Object?> offer(int id, {String status = 'pending'}) => {
  'id': id,
  'price': 12550,
  'status': status,
  'store': {'id': id, 'name': 'Store $id'},
  'images': [],
};

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

  test(
    'summary includes only available general offers, caps and orders previews',
    () {
      final pending = CustomerOrderDto.fromJson(
        orderJson(id: 2, general: true)
          ..['offers'] = [
            for (var i = 1; i <= 10; i++) offer(i),
            offer(11, status: 'rejected'),
            offer(12, status: 'not_selected'),
          ],
      ).value;
      final completed = CustomerOrderDto.fromJson(
        orderJson(id: 3, general: true)
          ..['status'] = 'completed'
          ..['offers'] = [offer(20)],
      ).value;
      final selected = CustomerOrderDto.fromJson(
        orderJson(id: 4, general: true)
          ..['accepted_offer_id'] = 21
          ..['offers'] = [offer(21), offer(22)],
      ).value;
      final specific = CustomerOrderDto.fromJson(
        orderJson(id: 5)..['offers'] = [offer(30)],
      ).value;
      final result = homeOffers([pending, completed, selected, specific]);
      expect(result.map((item) => item.offer.id), [10, 9, 8, 7, 6, 5, 4, 3]);
      expect(result.every((item) => item.order.id == 2), isTrue);
      expect(pending.offers.first.id, 1);
      expect(homeOffers([completed, selected, specific]), isEmpty);
    },
  );

  for (final code in ['en', 'ar']) {
    testWidgets('offers fit and scroll at 200 percent text in $code', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(320, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final order = CustomerOrderDto.fromJson(
        orderJson(id: 7, general: true)
          ..['part_name'] = code == 'ar'
              ? 'مصباح أمامي للسيارة مع جميع التوصيلات'
              : 'Front headlight with all connectors included'
          ..['offers'] = [offer(1), offer(2)],
      ).value;
      await tester.pumpWidget(
        EasyLocalization(
          supportedLocales: const [Locale('en'), Locale('ar')],
          startLocale: Locale(code),
          path: 'assets/translations',
          saveLocale: false,
          assetLoader: _Translations(translations),
          child: _App(child: HomeOffers(page: ordersPage([order]))),
        ),
      );
      await tester.pumpAndSettle();
      final scroll = find.byKey(const ValueKey('home-offers-scroll'));
      final position = tester
          .state<ScrollableState>(
            find.descendant(of: scroll, matching: find.byType(Scrollable)),
          )
          .position;
      expect(position.pixels, 0);
      expect(
        tester
            .widget<IconButton>(
              find.byKey(const ValueKey('home-previous-offer')),
            )
            .onPressed,
        isNull,
      );
      await tester.ensureVisible(scroll);
      await tester.dragFrom(
        tester.getTopLeft(scroll) + const Offset(120, 30),
        Offset(code == 'ar' ? 260 : -260, 0),
      );
      await tester.pumpAndSettle();
      expect(position.pixels, greaterThan(0));
      expect(find.textContaining('125.50'), findsNWidgets(2));
      expect(find.textContaining('251.00'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(
        find.byKey(const ValueKey('home-previous-offer')),
      );
      await tester.tap(find.byKey(const ValueKey('home-previous-offer')));
      await tester.pumpAndSettle();
      expect(position.pixels, 0);
      expect(
        tester
            .widget<IconButton>(
              find.byKey(const ValueKey('home-previous-offer')),
            )
            .onPressed,
        isNull,
      );
      expect(tester.takeException(), isNull);
    });
  }
}

class _Translations extends AssetLoader {
  const _Translations(this.translations);
  final Map<String, Map<String, dynamic>> translations;
  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async =>
      translations[locale.languageCode]!;
}

class _App extends StatelessWidget {
  const _App({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => MaterialApp(
    theme: OctoGearTheme.lightTheme,
    locale: context.locale,
    supportedLocales: context.supportedLocales,
    localizationsDelegates: context.localizationDelegates,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: const TextScaler.linear(2)),
      child: child!,
    ),
    home: Scaffold(
      body: SingleChildScrollView(
        child: Padding(padding: const EdgeInsets.all(16), child: child),
      ),
    ),
  );
}
