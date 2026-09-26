import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

import '../../../core/api/api_failure.dart';

/// Maps transport failures to safe, localized customer-garage feedback.
///
/// Field errors stay attached to their form controls. This helper is for the
/// one readable summary shown for all other outcomes.
String customerGarageFailureMessage(BuildContext context, Object error) {
  if (error is! ApiFailure) return context.tr('errors.unexpected');

  final serverMessage = error.serverMessage?.trim();
  if (serverMessage != null &&
      serverMessage.isNotEmpty &&
      error.type != ApiFailureType.server &&
      error.type != ApiFailureType.unexpected) {
    return serverMessage;
  }

  return switch (error.type) {
    ApiFailureType.validation => context.tr('errors.validation'),
    ApiFailureType.rateLimited => context.tr('errors.rate_limited'),
    ApiFailureType.timeout => context.tr('errors.timeout'),
    ApiFailureType.noConnection => context.tr('errors.no_connection'),
    ApiFailureType.server => context.tr('errors.server'),
    ApiFailureType.forbidden => context.tr('customer_garage.cars.forbidden'),
    ApiFailureType.notFound => context.tr('customer_garage.cars.not_found'),
    _ => context.tr('errors.unexpected'),
  };
}

bool isCustomerGarageRetryable(Object error) {
  if (error is! ApiFailure) return false;

  return switch (error.type) {
    ApiFailureType.timeout ||
    ApiFailureType.noConnection ||
    ApiFailureType.server => true,
    _ => false,
  };
}
