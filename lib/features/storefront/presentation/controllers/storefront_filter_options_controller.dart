import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/app_locale_controller.dart';
import '../../domain/entities/storefront_filter_options.dart';
import 'storefront_providers.dart';

/// Localized reference lists for the optional city/manufacturer filters.
///
/// Loading starts only when the filter sheet is opened. The provider renews on
/// a language change because Laravel returns reference names in that language.
final storefrontFilterOptionsProvider =
    FutureProvider<StorefrontFilterOptions>((ref) async {
      ref.watch(appLocaleProvider);
      return ref.read(getStorefrontFilterOptionsUseCaseProvider).call();
    }, retry: (_, _) => null);
