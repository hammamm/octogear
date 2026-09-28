import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/app_locale_controller.dart';
import '../../domain/entities/storefront_store_cars_page.dart';
import 'storefront_providers.dart';

final storefrontStoreCarsControllerProvider = AsyncNotifierProvider.autoDispose
    .family<StorefrontStoreCarsController, StorefrontStoreCarsViewState, int>(
      StorefrontStoreCarsController.new,
      // Inventory reads are explicit customer actions; avoid surprising
      // background traffic or a stale retry after this detail route closes.
      retry: (_, _) => null,
    );

class StorefrontStoreCarsViewState {
  const StorefrontStoreCarsViewState({
    required this.page,
    this.isLoadingMore = false,
    this.nextPageError,
  });

  final StorefrontStoreCarsPage page;
  final bool isLoadingMore;
  final Object? nextPageError;

  StorefrontStoreCarsViewState copyWith({
    StorefrontStoreCarsPage? page,
    bool? isLoadingMore,
    Object? nextPageError,
    bool clearNextPageError = false,
  }) {
    return StorefrontStoreCarsViewState(
      page: page ?? this.page,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      nextPageError: clearNextPageError
          ? null
          : nextPageError ?? this.nextPageError,
    );
  }
}

/// Owns a single store's paginated inventory and rejects stale page results.
class StorefrontStoreCarsController
    extends AsyncNotifier<StorefrontStoreCarsViewState> {
  StorefrontStoreCarsController(this._storeId);

  final int _storeId;
  var _requestGeneration = 0;

  @override
  Future<StorefrontStoreCarsViewState> build() async {
    ref.watch(appLocaleProvider);
    final generation = ++_requestGeneration;
    while (true) {
      final page = await _fetch(page: 1);
      if (generation == _requestGeneration) {
        return StorefrontStoreCarsViewState(page: page);
      }
    }
  }

  Future<void> refresh() async {
    final generation = ++_requestGeneration;
    state = const AsyncLoading();
    try {
      final page = await _fetch(page: 1);
      if (generation != _requestGeneration) return;
      state = AsyncData(StorefrontStoreCarsViewState(page: page));
    } catch (error, stackTrace) {
      if (generation != _requestGeneration) return;
      state = AsyncError(error, stackTrace);
    }
  }

  Future<void> loadNextPage() async {
    final current = state.asData?.value;
    if (current == null || current.isLoadingMore || !current.page.hasNextPage) {
      return;
    }

    final generation = _requestGeneration;
    final currentPage = current.page;
    state = AsyncData(
      current.copyWith(isLoadingMore: true, clearNextPageError: true),
    );

    try {
      final next = await _fetch(page: currentPage.currentPage + 1);
      if (generation != _requestGeneration) return;

      final visible = state.asData?.value;
      if (visible == null ||
          visible.page.currentPage != currentPage.currentPage) {
        return;
      }
      state = AsyncData(
        StorefrontStoreCarsViewState(
          page: StorefrontStoreCarsPage(
            cars: List.unmodifiable([...currentPage.cars, ...next.cars]),
            currentPage: next.currentPage,
            lastPage: next.lastPage,
            perPage: next.perPage,
            total: next.total,
          ),
        ),
      );
    } catch (error) {
      if (generation != _requestGeneration) return;
      state = AsyncData(
        current.copyWith(isLoadingMore: false, nextPageError: error),
      );
    }
  }

  Future<StorefrontStoreCarsPage> _fetch({required int page}) {
    return ref.read(getStoreCarsUseCaseProvider).call(_storeId, page: page);
  }
}
