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
  final provider = registrationCitiesProvider;
  setUp(() {
    useCase = _UseCase();
    container = ProviderContainer(
      overrides: [
        getRegistrationCitiesUseCaseProvider.overrideWithValue(useCase),
        appLocaleProvider.overrideWith(_Locale.new),
      ],
    );
  });
  tearDown(() => container.dispose());

  test(
    'loads every page once, merges IDs and retains the complete catalog',
    () async {
      final subscription = container.listen(provider, (_, _) {});
      final loaded = container.read(provider.future);
      useCase.pending.single.complete(_page([1], 1, 2));
      await Future<void>.delayed(Duration.zero);
      expect(useCase.calls, [('', 1), ('', 2)]);
      expect(container.read(provider).isLoading, isTrue);
      useCase.pending.last.complete(_page([1, 2], 2, 2));
      final cities = await loaded;
      expect(cities.map((city) => city.id), [1, 2]);
      subscription.close();
      await container.pump();
      final reopened = container.listen(provider, (_, _) {});
      expect(await container.read(provider.future), same(cities));
      expect(useCase.calls, hasLength(2));
      reopened.close();
    },
  );

  for (final failedPage in [1, 2]) {
    test(
      'page $failedPage failure waits for explicit retry of the catalog',
      () async {
        final failure = expectLater(
          container.read(provider.future),
          throwsException,
        );
        if (failedPage == 2) {
          useCase.pending.single.complete(_page([1], 1, 2));
          await Future<void>.delayed(Duration.zero);
        }
        useCase.pending.last.completeError(Exception('offline'));
        await failure;
        await Future<void>.delayed(const Duration(milliseconds: 250));
        expect(useCase.calls, hasLength(failedPage));
        expect(container.read(provider).hasError, isTrue);
        container.read(provider.notifier).retry();
        final retried = container.read(provider.future);
        expect(useCase.calls.last, ('', 1));
        useCase.pending.last.complete(_page([3], 1, 1));
        expect((await retried).single.id, 3);
      },
    );
  }

  test(
    'language change ignores a late page and stops the obsolete load',
    () async {
      container.listen(provider, (_, _) {});
      useCase.pending.single.complete(_page([1], 1, 3));
      await Future<void>.delayed(Duration.zero);
      final oldRequest = useCase.pending.last;
      (container.read(appLocaleProvider.notifier) as _Locale).change();
      final localized = container.read(provider.future);
      useCase.pending.last.complete(_page([3], 1, 1));
      expect((await localized).single.id, 3);
      oldRequest.complete(_page([2], 2, 3));
      await container.pump();
      expect(container.read(provider).requireValue.single.id, 3);
      expect(useCase.calls, [('', 1), ('', 2), ('', 1)]);
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
