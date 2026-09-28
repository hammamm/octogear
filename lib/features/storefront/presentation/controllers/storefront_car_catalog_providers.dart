import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_providers.dart';
import '../../../../core/localization/app_locale_controller.dart';
import '../../data/data_sources/storefront_car_catalog_remote_data_source.dart';
import '../../data/repositories/storefront_car_catalog_repository_impl.dart';
import '../../domain/entities/storefront_car_catalog.dart';
import '../../domain/repositories/storefront_car_catalog_repository.dart';
import '../../domain/use_cases/get_store_car_components_use_case.dart';
import '../../domain/use_cases/get_store_car_details_use_case.dart';

final storefrontCarCatalogRepositoryProvider =
    Provider<StorefrontCarCatalogRepository>(
      (ref) => StorefrontCarCatalogRepositoryImpl(
        StorefrontCarCatalogRemoteDataSource(ref.watch(apiClientProvider)),
      ),
    );

final getStoreCarDetailsUseCaseProvider = Provider(
  (ref) => GetStoreCarDetailsUseCase(
    ref.watch(storefrontCarCatalogRepositoryProvider),
  ),
);
final getStoreCarComponentsUseCaseProvider = Provider(
  (ref) => GetStoreCarComponentsUseCase(
    ref.watch(storefrontCarCatalogRepositoryProvider),
  ),
);

final storefrontCarDetailsProvider = FutureProvider.autoDispose
    .family<StorefrontCarDetails, StorefrontCarKey>((ref, key) {
      ref.watch(appLocaleProvider);
      return ref.watch(getStoreCarDetailsUseCaseProvider).call(key);
    }, retry: (_, _) => null);

final storefrontCarComponentsProvider = AsyncNotifierProvider.autoDispose
    .family<
      StorefrontCarComponentsController,
      StorefrontComponentsState,
      StorefrontCarKey
    >(StorefrontCarComponentsController.new, retry: (_, _) => null);

class StorefrontComponentsState {
  const StorefrontComponentsState({
    required this.page,
    this.isLoadingMore = false,
    this.nextPageError,
  });
  final StorefrontComponentsPage page;
  final bool isLoadingMore;
  final Object? nextPageError;
}

class StorefrontCarComponentsController
    extends AsyncNotifier<StorefrontComponentsState> {
  StorefrontCarComponentsController(this.key);
  final StorefrontCarKey key;
  var _generation = 0;

  @override
  Future<StorefrontComponentsState> build() async {
    ref.watch(appLocaleProvider);
    ++_generation;
    ref.onDispose(() => ++_generation);
    final page = await ref
        .watch(getStoreCarComponentsUseCaseProvider)
        .call(key, page: 1);
    return StorefrontComponentsState(page: page);
  }

  Future<void> loadNextPage() async {
    final current = state.asData?.value;
    if (current == null || current.isLoadingMore || !current.page.hasNextPage) {
      return;
    }
    final generation = _generation;
    final useCase = ref.read(getStoreCarComponentsUseCaseProvider);
    state = AsyncData(
      StorefrontComponentsState(page: current.page, isLoadingMore: true),
    );
    try {
      final next = await useCase.call(key, page: current.page.currentPage + 1);
      if (!ref.mounted || generation != _generation) return;
      // A new/removed record can move page boundaries while browsing.
      final parts = {
        for (final part in current.page.components) part.id: part,
        for (final part in next.components) part.id: part,
      };
      state = AsyncData(
        StorefrontComponentsState(
          page: StorefrontComponentsPage(
            components: List.unmodifiable(parts.values),
            currentPage: next.currentPage,
            lastPage: next.lastPage,
            total: next.total,
          ),
        ),
      );
    } catch (error) {
      if (!ref.mounted || generation != _generation) return;
      state = AsyncData(
        StorefrontComponentsState(page: current.page, nextPageError: error),
      );
    }
  }
}
