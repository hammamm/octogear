import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/app_locale_controller.dart';
import '../../domain/entities/customer_car.dart';
import 'customer_cars_providers.dart';

/// Localized car names for one selected manufacturer.
///
/// The form explicitly invalidates this family to retry a failed company/name
/// request. Auto-retry is disabled so an offline state remains truthful.
final customerCarNamesProvider =
    FutureProvider.family<List<CustomerCarReference>, int>((
      ref,
      companyId,
    ) async {
      ref.watch(appLocaleProvider);
      return ref.read(getCustomerCarNamesUseCaseProvider).call(companyId);
    }, retry: (_, _) => null);
