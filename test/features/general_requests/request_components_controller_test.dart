import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:octogear/core/localization/app_locale.dart';
import 'package:octogear/core/localization/app_locale_controller.dart';
import 'package:octogear/features/general_requests/domain/entities/general_request.dart';
import 'package:octogear/features/general_requests/presentation/controllers/general_request_providers.dart';
import 'package:octogear/features/general_requests/presentation/controllers/request_components_controller.dart';

import 'general_request_fixtures.dart';

class _Locale extends AppLocaleController {
  @override
  AppLocale build() => AppLocale.arabic;
  void change() => state = AppLocale.english;
}

RequestComponentsPage page(int number, List<int> ids) => RequestComponentsPage(
  items: [for (final id in ids) RequestComponent(id: id, name: 'Part $id')],
  page: number,
  lastPage: 2,
);

void main() {
  ProviderContainer setup(FakeGeneralRequestRepository repo) {
    final c = ProviderContainer(
      overrides: [
        appLocaleProvider.overrideWith(_Locale.new),
        generalRequestRepositoryProvider.overrideWithValue(repo),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  test(
    'next-page failure retains rows and retries the same page without duplicates',
    () async {
      var fail = true;
      final requests = <int>[];
      final repo = FakeGeneralRequestRepository()
        ..onSearch = (search, number) async {
          expect(search, 'light');
          requests.add(number);
          if (number == 2 && fail) throw Exception('offline');
          return number == 1 ? page(1, [1]) : page(2, [1, 2]);
        };
      final c = setup(repo);
      final provider = requestComponentsProvider('light');
      c.listen(provider, (_, _) {});
      await c.read(provider.future);
      await c.read(provider.notifier).loadMore();
      expect(c.read(provider).requireValue.page.items.single.id, 1);
      expect(c.read(provider).requireValue.error, isNotNull);
      fail = false;
      await c.read(provider.notifier).loadMore();
      await c.read(provider.notifier).loadMore();
      expect(requests, [1, 2, 2]);
      expect(c.read(provider).requireValue.page.items.map((item) => item.id), [
        1,
        2,
      ]);
    },
  );

  test(
    'locale reload discards late pagination and serializes load-more taps',
    () async {
      final pending = Completer<RequestComponentsPage>();
      var pages = 0;
      final repo = FakeGeneralRequestRepository()
        ..onSearch = (_, number) async {
          if (number == 2) {
            pages++;
            return pending.future;
          }
          return page(1, [1]);
        };
      final c = setup(repo);
      final provider = requestComponentsProvider('');
      c.listen(provider, (_, _) {});
      await c.read(provider.future);
      final next = c.read(provider.notifier).loadMore();
      await c.read(provider.notifier).loadMore();
      expect(pages, 1);
      (c.read(appLocaleProvider.notifier) as _Locale).change();
      await c.read(provider.future);
      pending.complete(page(2, [2]));
      await next;
      expect(c.read(provider).requireValue.page.page, 1);
      expect(c.read(provider).requireValue.page.items.single.id, 1);
    },
  );
}
