import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/app_locale_controller.dart';
import '../../domain/entities/customer_car_form_references.dart';
import 'customer_cars_providers.dart';

/// Loads the three independent localized selector lists in parallel.
final customerCarFormReferencesControllerProvider =
    AsyncNotifierProvider<
      CustomerCarFormReferencesController,
      CustomerCarFormReferences
    >(
      CustomerCarFormReferencesController.new,
      // Selector failures should be shown to the customer with an explicit
      // Retry, not be hidden by Riverpod's automatic retry behavior.
      retry: (_, _) => null,
    );

class CustomerCarFormReferencesController
    extends AsyncNotifier<CustomerCarFormReferences> {
  @override
  Future<CustomerCarFormReferences> build() {
    // The server returns localized names. Rebuild when the selected app locale
    // changes so labels refresh without retaining a language-neutral cache.
    ref.watch(appLocaleProvider);
    return ref.read(getCustomerCarFormReferencesUseCaseProvider).call();
  }

  Future<void> retry() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(getCustomerCarFormReferencesUseCaseProvider).call(),
    );
  }
}
