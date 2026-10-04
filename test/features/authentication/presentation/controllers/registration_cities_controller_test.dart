import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:octogear/core/localization/app_locale.dart';
import 'package:octogear/core/localization/app_locale_controller.dart';
import 'package:octogear/features/authentication/domain/entities/app_user.dart';
import 'package:octogear/features/authentication/domain/use_cases/get_registration_cities_use_case.dart';
import 'package:octogear/features/authentication/presentation/controllers/registration_cities_controller.dart';
import 'package:octogear/features/authentication/presentation/controllers/session_providers.dart';

void main() {
  late ProviderContainer container;
  late _UseCase useCase;
  final provider = registrationCitiesProvider('');
  setUp(() {
    useCase = _UseCase();
    container = ProviderContainer(
      overrides: [
        getRegistrationCitiesUseCaseProvider.overrideWithValue(useCase),
        appLocaleProvider.overrideWith(_Locale.new),
      ],
    );
    container.listen(provider, (_, _) {});
  });
  tearDown(() => container.dispose());

  test(
    'loads one page, requests more explicitly, merges IDs and stops at last page',
    () async {
      useCase.pending.single.complete(_page([1], 1, 2));
      await container.read(provider.future);
      expect(useCase.calls, [('', 1)]);
      final controller = container.read(provider.notifier);
      final more = controller.loadMore();
      await controller
          .loadMore(); // Duplicate taps cannot start another request.
      expect(useCase.calls, [('', 1), ('', 2)]);
      expect(container.read(provider).requireValue.page.items.single.id, 1);
      useCase.pending.last.complete(_page([1, 2], 2, 2));
      await more;
      expect(
        container.read(provider).requireValue.page.items.map((c) => c.id),
        [1, 2],
      );
      await controller.loadMore();
      expect(useCase.calls, hasLength(2));
    },
  );

  test(
    'page failure preserves cities and retry requests only the failed page',
    () async {
      useCase.pending.single.complete(_page([1], 1, 92));
      await container.read(provider.future);
      final controller = container.read(provider.notifier);
      final more = controller.loadMore();
      useCase.pending.last.completeError(Exception('offline'));
      await more;
      expect(container.read(provider).requireValue.page.items.single.id, 1);
      expect(container.read(provider).requireValue.nextPageError, isNotNull);
      final retry = controller.loadMore();
      expect(useCase.calls, [('', 1), ('', 2), ('', 2)]);
      useCase.pending.last.complete(_page([2], 2, 92));
      await retry;
      expect(container.read(provider).requireValue.nextPageError, isNull);
    },
  );

  test('first page failure waits for explicit retry', () async {
    final failure = expectLater(
      container.read(provider.future),
      throwsException,
    );
    useCase.pending.single.completeError(Exception('offline'));
    await failure;
    await Future<void>.delayed(const Duration(milliseconds: 250));
    expect(useCase.calls, hasLength(1));
    container.read(provider.notifier).retry();
    final retried = container.read(provider.future);
    useCase.pending.last.complete(_page([1], 1, 1));
    expect((await retried).page.items.single.id, 1);
  });

  test(
    'a late next page cannot overwrite cities after a language change',
    () async {
      useCase.pending.single.complete(_page([1], 1, 2));
      await container.read(provider.future);
      final more = container.read(provider.notifier).loadMore();
      final oldRequest = useCase.pending.last;
      (container.read(appLocaleProvider.notifier) as _Locale).change();
      final localized = container.read(provider.future);
      useCase.pending.last.complete(_page([3], 1, 1));
      await localized;
      oldRequest.complete(_page([2], 2, 2));
      await more;
      expect(container.read(provider).requireValue.page.items.single.id, 3);
    },
  );

  test(
    'different searches cannot replace each other with late responses',
    () async {
      final searchProvider = registrationCitiesProvider('Aden');
      container.listen(searchProvider, (_, _) {});
      useCase.pending.last.complete(_page([7], 1, 1));
      await container.read(searchProvider.future);
      useCase.pending.first.complete(_page([1], 1, 92));
      await container.read(provider.future);
      expect(
        container.read(searchProvider).requireValue.page.items.single.id,
        7,
      );
      expect(useCase.calls, [('', 1), ('Aden', 1)]);
    },
  );
}

AppCityPage _page(List<int> ids, int page, int lastPage) => AppCityPage(
  items: ids.map((id) => AppCity(id: id, name: 'City $id')).toList(),
  page: page,
  lastPage: lastPage,
);

class _Locale extends AppLocaleController {
  @override
  AppLocale build() => AppLocale.english;
  void change() => state = AppLocale.arabic;
}

class _UseCase implements GetRegistrationCitiesUseCase {
  final calls = <(String, int)>[];
  final pending = <Completer<AppCityPage>>[];
  @override
  Future<AppCityPage> call({String search = '', int page = 1}) {
    calls.add((search, page));
    final result = Completer<AppCityPage>();
    pending.add(result);
    return result.future;
  }
}
