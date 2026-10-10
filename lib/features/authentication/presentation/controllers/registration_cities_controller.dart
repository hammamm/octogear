import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/app_locale_controller.dart';
import '../../domain/entities/app_user.dart';
import 'session_providers.dart';

/// Keeps the complete localized catalog alive between picker visits.
final registrationCitiesProvider =
    AsyncNotifierProvider<RegistrationCitiesController, List<AppCity>>(
      RegistrationCitiesController.new,
      retry: (_, _) => null,
    );

class RegistrationCitiesController extends AsyncNotifier<List<AppCity>> {
  int _generation = 0;

  @override
  Future<List<AppCity>> build() async {
    ref.watch(appLocaleProvider);
    final useCase = ref.watch(getRegistrationCitiesUseCaseProvider);
    final generation = ++_generation;
    ref.onDispose(() => ++_generation);
    final cities = <AppCity>[];
    final ids = <int>{};
    var page = 1;
    while (true) {
      final result = await useCase.call(page: page);
      // Stop an obsolete load when the locale or provider scope changes.
      // Riverpod ignores this build's result after its invalidation.
      if (!ref.mounted || generation != _generation) return const [];
      cities.addAll(result.items.where((city) => ids.add(city.id)));
      if (!result.hasMore) return List.unmodifiable(cities);
      page = result.page + 1;
    }
  }

  void retry() => ref.invalidateSelf();
}
