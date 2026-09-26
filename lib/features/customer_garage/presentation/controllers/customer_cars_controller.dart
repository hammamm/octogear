import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/app_locale_controller.dart';
import '../../domain/entities/customer_car.dart';
import 'customer_cars_providers.dart';

final customerCarsControllerProvider =
    AsyncNotifierProvider.autoDispose<
      CustomerCarsController,
      List<CustomerCar>
    >(
      CustomerCarsController.new,
      // Riverpod otherwise retries an initial async failure automatically.
      // This screen deliberately waits for an explicit customer Retry or
      // pull-to-refresh so its offline/error state remains truthful.
      retry: (_, _) => null,
    );

/// Owns the read-only customer-garage query for the current API locale.
class CustomerCarsController extends AsyncNotifier<List<CustomerCar>> {
  @override
  Future<List<CustomerCar>> build() {
    // The server localizes reference names. Watching the locale intentionally
    // reruns this query whenever the user switches Arabic/English.
    ref.watch(appLocaleProvider);
    return ref.read(getCustomerCarsUseCaseProvider).call();
  }

  Future<void> retry() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(getCustomerCarsUseCaseProvider).call(),
    );
  }
}
