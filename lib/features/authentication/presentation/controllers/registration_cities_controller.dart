import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/app_locale_controller.dart';
import '../../domain/entities/app_user.dart';
import 'session_providers.dart';

/// Disposable result sets keep late responses for old searches out of the UI.
final registrationCitiesProvider = AsyncNotifierProvider.autoDispose
    .family<RegistrationCitiesController, RegistrationCitiesState, String>(
      RegistrationCitiesController.new,
      retry: (_, _) => null,
    );

class RegistrationCitiesState {
  const RegistrationCitiesState({
    required this.page,
    this.isLoadingMore = false,
    this.nextPageError,
  });

  final AppCityPage page;
  final bool isLoadingMore;
  final Object? nextPageError;
}

class RegistrationCitiesController
    extends AsyncNotifier<RegistrationCitiesState> {
  RegistrationCitiesController(this.search);
  final String search;
  int _generation = 0;

  @override
  Future<RegistrationCitiesState> build() async {
    ref.watch(appLocaleProvider);
    ++_generation;
    ref.onDispose(() => ++_generation);
    return RegistrationCitiesState(
      page: await ref
          .watch(getRegistrationCitiesUseCaseProvider)
          .call(search: search),
    );
  }

  void retry() => ref.invalidateSelf();

  Future<void> loadMore() async {
    final current = state.value;
    if (state.isLoading ||
        current == null ||
        current.isLoadingMore ||
        !current.page.hasMore) {
      return;
    }
    final generation = _generation;
    state = AsyncData(
      RegistrationCitiesState(page: current.page, isLoadingMore: true),
    );
    try {
      final next = await ref
          .read(getRegistrationCitiesUseCaseProvider)
          .call(search: search, page: current.page.page + 1);
      if (!ref.mounted || generation != _generation) return;
      final ids = current.page.items.map((city) => city.id).toSet();
      state = AsyncData(
        RegistrationCitiesState(
          page: AppCityPage(
            items: List.unmodifiable([
              ...current.page.items,
              ...next.items.where((city) => ids.add(city.id)),
            ]),
            page: next.page,
            lastPage: next.lastPage,
          ),
        ),
      );
    } catch (error) {
      if (!ref.mounted || generation != _generation) return;
      state = AsyncData(
        RegistrationCitiesState(page: current.page, nextPageError: error),
      );
    }
  }
}
