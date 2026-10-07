import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/app_locale_controller.dart';
import '../../domain/entities/general_request.dart';
import 'general_request_providers.dart';

class RequestComponentsState {
  const RequestComponentsState({
    required this.page,
    this.loadingMore = false,
    this.error,
  });

  final RequestComponentsPage page;
  final bool loadingMore;
  final Object? error;
}

final requestComponentsProvider = AsyncNotifierProvider.autoDispose
    .family<RequestComponentsController, RequestComponentsState, String>(
      RequestComponentsController.new,
      retry: (_, _) => null,
    );

class RequestComponentsController
    extends AsyncNotifier<RequestComponentsState> {
  RequestComponentsController(this.search);

  final String search;
  int _generation = 0;

  @override
  Future<RequestComponentsState> build() async {
    ++_generation;
    ref.onDispose(() => ++_generation);
    ref.watch(appLocaleProvider);
    return RequestComponentsState(
      page: await ref.watch(getRequestComponentsProvider)(
        search: search,
        page: 1,
      ),
    );
  }

  Future<void> loadMore() async {
    final current = state.asData?.value;
    if (current == null ||
        current.loadingMore ||
        current.page.page >= current.page.lastPage) {
      return;
    }
    final generation = _generation;
    state = AsyncData(
      RequestComponentsState(page: current.page, loadingMore: true),
    );
    try {
      final next = await ref.read(getRequestComponentsProvider)(
        search: search,
        page: current.page.page + 1,
      );
      if (!ref.mounted || generation != _generation) return;
      state = AsyncData(
        RequestComponentsState(
          page: RequestComponentsPage(
            items: List.unmodifiable(
              {
                for (final item in current.page.items) item.id: item,
                for (final item in next.items) item.id: item,
              }.values,
            ),
            page: next.page,
            lastPage: next.lastPage,
          ),
        ),
      );
    } catch (error) {
      if (ref.mounted && generation == _generation) {
        state = AsyncData(
          RequestComponentsState(page: current.page, error: error),
        );
      }
    }
  }
}
