import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:octogear/core/localization/app_locale.dart';
import 'package:octogear/core/localization/app_locale_controller.dart';
import 'package:octogear/features/storefront/domain/entities/marketplace_store.dart';
import 'package:octogear/features/storefront/domain/entities/storefront_filter_options.dart';
import 'package:octogear/features/storefront/domain/entities/storefront_filters.dart';
import 'package:octogear/features/storefront/domain/entities/storefront_page.dart';
import 'package:octogear/features/storefront/domain/entities/storefront_store_cars_page.dart';
import 'package:octogear/features/storefront/domain/entities/storefront_store_details.dart';
import 'package:octogear/features/storefront/domain/repositories/storefront_repository.dart';
import 'package:octogear/features/storefront/domain/use_cases/search_stores_use_case.dart';
import 'package:octogear/features/storefront/presentation/controllers/storefront_controller.dart';
import 'package:octogear/features/storefront/presentation/controllers/storefront_providers.dart';

void main() {
  test('starts at page one and appends a later page once', () async {
    final useCase = _RecordingSearchStoresUseCase();
    final container = ProviderContainer(
      overrides: [
        appLocaleProvider.overrideWith(_MutableLocaleController.new),
        searchStoresUseCaseProvider.overrideWithValue(useCase),
      ],
    );
    addTearDown(container.dispose);

    final subscription = container.listen(
      storefrontControllerProvider,
      (_, _) {},
    );
    addTearDown(subscription.close);

    await container.read(storefrontControllerProvider.future);
    await container.read(storefrontControllerProvider.notifier).loadNextPage();
    await container.read(storefrontControllerProvider.notifier).loadNextPage();

    final state = container.read(storefrontControllerProvider).asData!.value;
    expect(useCase.pages, [1, 2]);
    expect(state.page.stores.map((store) => store.id), [1, 2]);
    expect(state.page.hasNextPage, isFalse);
  });

  test(
    'restarts pagination at page one when customer changes a filter',
    () async {
      final useCase = _RecordingSearchStoresUseCase();
      final container = ProviderContainer(
        overrides: [
          appLocaleProvider.overrideWith(_MutableLocaleController.new),
          searchStoresUseCaseProvider.overrideWithValue(useCase),
        ],
      );
      addTearDown(container.dispose);

      final subscription = container.listen(
        storefrontControllerProvider,
        (_, _) {},
      );
      addTearDown(subscription.close);

      await container.read(storefrontControllerProvider.future);
      await container
          .read(storefrontControllerProvider.notifier)
          .applyFilters(const StorefrontFilters(query: 'Faris', cityId: 2));

      final state = container.read(storefrontControllerProvider).asData!.value;
      expect(useCase.calls.last, const (page: 1, query: 'Faris', cityId: 2));
      expect(state.page.currentPage, 1);
      expect(state.filters, const StorefrontFilters(query: 'Faris', cityId: 2));
    },
  );
}

class _MutableLocaleController extends AppLocaleController {
  @override
  AppLocale build() => AppLocale.english;

  @override
  Future<void> select(AppLocale locale) async {
    state = locale;
  }
}

class _RecordingSearchStoresUseCase extends SearchStoresUseCase {
  _RecordingSearchStoresUseCase() : super(_UnusedStorefrontRepository());

  final List<int> pages = [];
  final List<({int page, String query, int? cityId})> calls = [];

  @override
  Future<StorefrontPage> call(
    StorefrontFilters filters, {
    required int page,
  }) async {
    pages.add(page);
    calls.add((page: page, query: filters.query, cityId: filters.cityId));
    return StorefrontPage(
      stores: [
        MarketplaceStore(
          id: page,
          name: 'Store $page',
          nickname: '',
          city: null,
          primaryPictureUrl: null,
          averageRating: null,
        ),
      ],
      currentPage: page,
      lastPage: 2,
      perPage: 15,
      total: 2,
    );
  }
}

class _UnusedStorefrontRepository implements StorefrontRepository {
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

  @override
  Future<StorefrontStoreDetails> getStoreDetails(int storeId) {
    throw UnimplementedError();
  }

  @override
  Future<StorefrontStoreCarsPage> getStoreCars(
    int storeId, {
    required int page,
  }) {
    throw UnimplementedError();
  }
}
