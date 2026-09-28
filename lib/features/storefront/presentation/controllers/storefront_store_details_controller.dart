import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/app_locale_controller.dart';
import '../../domain/entities/storefront_store_details.dart';
import 'storefront_providers.dart';

/// Authoritative, locale-aware public store information for one detail route.
final storefrontStoreDetailsProvider = FutureProvider.autoDispose
    .family<StorefrontStoreDetails, int>((ref, storeId) async {
      ref.watch(appLocaleProvider);
      return ref.read(getStoreDetailsUseCaseProvider).call(storeId);
    }, retry: (_, _) => null);
