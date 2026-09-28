import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:octogear/core/localization/app_locale.dart';
import 'package:octogear/core/localization/app_locale_controller.dart';
import 'package:octogear/features/storefront/domain/entities/marketplace_store.dart';
import 'package:octogear/features/storefront/domain/entities/storefront_filter_options.dart';
import 'package:octogear/features/storefront/domain/entities/storefront_filters.dart';
import 'package:octogear/features/storefront/domain/entities/storefront_page.dart';
import 'package:octogear/features/storefront/domain/entities/storefront_store_car.dart';
import 'package:octogear/features/storefront/domain/entities/storefront_store_cars_page.dart';
import 'package:octogear/features/storefront/domain/entities/storefront_store_details.dart';
import 'package:octogear/features/storefront/domain/repositories/storefront_repository.dart';
import 'package:octogear/features/storefront/domain/use_cases/get_store_cars_use_case.dart';
import 'package:octogear/features/storefront/presentation/controllers/storefront_providers.dart';
import 'package:octogear/features/storefront/presentation/controllers/storefront_store_cars_controller.dart';

void main() {
  test('starts at page one and appends a later inventory page once', () async {
    final useCase = _RecordingGetStoreCarsUseCase();
    final container = ProviderContainer(
      overrides: [
        appLocaleProvider.overrideWith(_MutableLocaleController.new),
        getStoreCarsUseCaseProvider.overrideWithValue(useCase),
      ],
    );
    addTearDown(container.dispose);

    final subscription = container.listen(
      storefrontStoreCarsControllerProvider(14),
      (_, _) {},
    );
    addTearDown(subscription.close);

    await container.read(storefrontStoreCarsControllerProvider(14).future);
    await container
        .read(storefrontStoreCarsControllerProvider(14).notifier)
        .loadNextPage();
    await container
        .read(storefrontStoreCarsControllerProvider(14).notifier)
        .loadNextPage();

    final state = container
        .read(storefrontStoreCarsControllerProvider(14))
        .asData!
        .value;
    expect(useCase.calls, [(storeId: 14, page: 1), (storeId: 14, page: 2)]);
    expect(state.page.cars.map((car) => car.id), [1, 2]);
    expect(state.page.hasNextPage, isFalse);
  });
}

class _MutableLocaleController extends AppLocaleController {
  @override
  AppLocale build() => AppLocale.english;

  @override
  Future<void> select(AppLocale locale) async {
    state = locale;
  }
}

class _RecordingGetStoreCarsUseCase extends GetStoreCarsUseCase {
  _RecordingGetStoreCarsUseCase() : super(_UnusedStorefrontRepository());

  final List<({int storeId, int page})> calls = [];

  @override
  Future<StorefrontStoreCarsPage> call(int storeId, {required int page}) async {
    calls.add((storeId: storeId, page: page));
    return StorefrontStoreCarsPage(
      cars: [_car(page)],
      currentPage: page,
      lastPage: 2,
      perPage: 15,
      total: 2,
    );
  }
}

StorefrontStoreCar _car(int id) {
  const reference = StorefrontReference(id: 1, name: 'Camry');
  return StorefrontStoreCar(
    id: id,
    manufacturingYear: 2020,
    carName: reference,
    color: const StorefrontReference(id: 2, name: 'White'),
    fuelType: const StorefrontReference(id: 3, name: 'Petrol'),
    componentsCount: 1,
    pictures: const [],
  );
}

class _UnusedStorefrontRepository implements StorefrontRepository {
  @override
  Future<StorefrontStoreCarsPage> getStoreCars(
    int storeId, {
    required int page,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<StorefrontStoreDetails> getStoreDetails(int storeId) {
    throw UnimplementedError();
  }

  @override
  Future<StorefrontFilterOptions> getFilterOptions() {
    throw UnimplementedError();
  }

  @override
  Future<StorefrontPage> searchStores(
    StorefrontFilters filters, {
    required int page,
  }) {
    throw UnimplementedError();
  }
}
