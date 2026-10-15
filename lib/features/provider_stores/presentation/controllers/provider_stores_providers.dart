import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_providers.dart';
import '../../../../core/localization/app_locale_controller.dart';
import '../../../authentication/domain/entities/app_user.dart';
import '../../../authentication/domain/entities/session_outcome.dart';
import '../../../authentication/presentation/controllers/session_controller.dart';
import '../../data/data_sources/provider_stores_remote_data_source.dart';
import '../../data/repositories/provider_stores_repository_impl.dart';
import '../../domain/entities/provider_store.dart';
import '../../domain/repositories/provider_stores_repository.dart';

final providerStoresRepositoryProvider = Provider<ProviderStoresRepository>(
  (ref) => ProviderStoresRepositoryImpl(
    ProviderStoresRemoteDataSourceImpl(ref.watch(apiClientProvider)),
  ),
);

/// Refetch on locale/session changes; never poll or retry without user action.
final providerStoresProvider = FutureProvider.autoDispose<List<ProviderStore>>((
  ref,
) async {
  final session = ref.watch(sessionControllerProvider).asData?.value;
  ref.watch(appLocaleProvider);
  if (session is! AuthenticatedSession ||
      session.user.role != AppUserRole.provider) {
    return const [];
  }
  return ref.watch(providerStoresRepositoryProvider).fetchStores();
}, retry: (_, _) => null);
