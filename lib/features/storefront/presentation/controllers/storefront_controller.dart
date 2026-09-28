import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/app_locale_controller.dart';
import '../../domain/entities/storefront_filters.dart';
import '../../domain/entities/storefront_page.dart';
import 'storefront_providers.dart';

final storefrontControllerProvider =
    AsyncNotifierProvider.autoDispose<
      StorefrontController,
      StorefrontViewState
    >(
      StorefrontController.new,
      // Discovery is an explicit, customer-controlled query. Do not silently
      // retry a failed initial query and make network activity look random.
      retry: (_, _) => null,
    );

class StorefrontViewState {
  const StorefrontViewState({
    required this.page,
    required this.filters,
    this.isLoadingMore = false,
    this.nextPageError,
  });

  final StorefrontPage page;
  final StorefrontFilters filters;
  final bool isLoadingMore;
  final Object? nextPageError;

  StorefrontViewState copyWith({
    StorefrontPage? page,
    StorefrontFilters? filters,
    bool? isLoadingMore,
    Object? nextPageError,
    bool clearNextPageError = false,
  }) {
    return StorefrontViewState(
      page: page ?? this.page,
      filters: filters ?? this.filters,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      nextPageError: clearNextPageError
          ? null
          : nextPageError ?? this.nextPageError,
    );
  }
}

/// Holds one search/filter result set and protects it from stale responses.
class StorefrontController extends AsyncNotifier<StorefrontViewState> {
  StorefrontFilters _filters = const StorefrontFilters.empty();
  int _requestGeneration = 0;

  @override
  Future<StorefrontViewState> build() async {
    // Store names and reference data are localized by the Laravel API.
    ref.watch(appLocaleProvider);
    return _loadCurrentFilters();
  }

  Future<void> applyFilters(StorefrontFilters filters) async {
    final normalized = StorefrontFilters(
      query: filters.query.trim(),
      cityId: filters.cityId,
      companyId: filters.companyId,
    );
    if (normalized == _filters) return;
    _filters = normalized;
    await _reload();
  }

  Future<void> refresh() => _reload();

  Future<void> loadNextPage() async {
    final current = state.asData?.value;
    if (current == null || current.isLoadingMore || !current.page.hasNextPage) {
      return;
    }

    final generation = _requestGeneration;
    final filters = current.filters;
    final currentPage = current.page;
    state = AsyncData(
      current.copyWith(isLoadingMore: true, clearNextPageError: true),
    );

    try {
      final next = await _search(filters, page: currentPage.currentPage + 1);
      if (generation != _requestGeneration || filters != _filters) return;

      final visible = state.asData?.value;
      if (visible == null ||
          visible.page.currentPage != currentPage.currentPage) {
        return;
      }
      state = AsyncData(
        StorefrontViewState(
          filters: filters,
          page: StorefrontPage(
            stores: List.unmodifiable([...currentPage.stores, ...next.stores]),
            currentPage: next.currentPage,
            lastPage: next.lastPage,
            perPage: next.perPage,
            total: next.total,
          ),
        ),
      );
    } catch (error) {
      if (generation != _requestGeneration || filters != _filters) return;
      state = AsyncData(
        current.copyWith(isLoadingMore: false, nextPageError: error),
      );
    }
  }

  Future<void> _reload() async {
    final generation = ++_requestGeneration;
    final filters = _filters;
    state = const AsyncLoading();
    try {
      final page = await _search(filters, page: 1);
      if (generation != _requestGeneration || filters != _filters) return;
      state = AsyncData(StorefrontViewState(page: page, filters: filters));
    } catch (error, stackTrace) {
      if (generation != _requestGeneration || filters != _filters) return;
      state = AsyncError(error, stackTrace);
    }
  }

  Future<StorefrontViewState> _loadCurrentFilters() async {
    while (true) {
      final filters = _filters;
      final page = await _search(filters, page: 1);
      if (filters == _filters) {
        return StorefrontViewState(page: page, filters: filters);
      }
    }
  }

  Future<StorefrontPage> _search(
    StorefrontFilters filters, {
    required int page,
  }) {
    return ref.read(searchStoresUseCaseProvider).call(filters, page: page);
  }
}
