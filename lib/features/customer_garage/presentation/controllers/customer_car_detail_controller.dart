import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/app_locale_controller.dart';
import '../../domain/entities/customer_car.dart';
import 'customer_cars_providers.dart';

/// The authoritative, localized representation of one saved car.
///
/// A list summary is deliberately not reused here: details may include every
/// private picture and must reflect an edit made in another route.
final customerCarDetailProvider = FutureProvider.autoDispose
    .family<CustomerCar, int>((ref, carId) async {
      ref.watch(appLocaleProvider);
      return ref.read(getCustomerCarUseCaseProvider).call(carId);
    }, retry: (_, _) => null);
