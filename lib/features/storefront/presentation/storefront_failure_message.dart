import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

import '../../../core/api/api_failure.dart';

/// Maps the shared transport failure type to safe discovery-screen language.
String storefrontFailureMessage(BuildContext context, Object error) {
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
    ApiFailureType.forbidden => context.tr('storefront.forbidden'),
    ApiFailureType.notFound => context.tr('storefront.not_found'),
    _ => context.tr('errors.unexpected'),
  };
}
