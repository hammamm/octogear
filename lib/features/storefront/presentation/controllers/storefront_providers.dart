import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_providers.dart';
import '../../data/data_sources/storefront_remote_data_source.dart';
import '../../data/repositories/storefront_repository_impl.dart';
import '../../domain/repositories/storefront_repository.dart';
import '../../domain/use_cases/get_storefront_filter_options_use_case.dart';
import '../../domain/use_cases/get_store_cars_use_case.dart';
import '../../domain/use_cases/get_store_details_use_case.dart';
import '../../domain/use_cases/search_stores_use_case.dart';

final storefrontRemoteDataSourceProvider = Provider<StorefrontRemoteDataSource>(
  (ref) {
    return StorefrontRemoteDataSourceImpl(
      apiClient: ref.watch(apiClientProvider),
    );
  },
);

final storefrontRepositoryProvider = Provider<StorefrontRepository>((ref) {
  return StorefrontRepositoryImpl(
    remoteDataSource: ref.watch(storefrontRemoteDataSourceProvider),
  );
});

final searchStoresUseCaseProvider = Provider<SearchStoresUseCase>((ref) {
  return SearchStoresUseCase(ref.watch(storefrontRepositoryProvider));
});

final getStorefrontFilterOptionsUseCaseProvider =
    Provider<GetStorefrontFilterOptionsUseCase>((ref) {
      return GetStorefrontFilterOptionsUseCase(
        ref.watch(storefrontRepositoryProvider),
      );
    });

final getStoreDetailsUseCaseProvider = Provider<GetStoreDetailsUseCase>((ref) {
  return GetStoreDetailsUseCase(ref.watch(storefrontRepositoryProvider));
});

final getStoreCarsUseCaseProvider = Provider<GetStoreCarsUseCase>((ref) {
  return GetStoreCarsUseCase(ref.watch(storefrontRepositoryProvider));
});
