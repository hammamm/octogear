import 'package:flutter/widgets.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../../core/api/api_failure.dart';

String authenticationFailureText(BuildContext context, Object? error) {
  if (error is! ApiFailure) return context.tr('errors.unexpected');

  final serverMessage = error.serverMessage?.trim();
  if (serverMessage != null && serverMessage.isNotEmpty) {
    return serverMessage;
  }

  return switch (error.type) {
    ApiFailureType.validation => context.tr('errors.validation'),
    ApiFailureType.rateLimited => context.tr('errors.rate_limited'),
    ApiFailureType.timeout => context.tr('errors.timeout'),
    ApiFailureType.noConnection => context.tr('errors.no_connection'),
    ApiFailureType.server => context.tr('errors.server'),
    _ => context.tr('errors.unexpected'),
  };
}
