import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_providers.dart';
import '../../data/data_sources/customer_cars_remote_data_source.dart';
import '../../data/repositories/customer_garage_repository_impl.dart';
import '../../domain/repositories/customer_garage_repository.dart';
import '../../domain/use_cases/get_customer_cars_use_case.dart';

final customerCarsRemoteDataSourceProvider =
    Provider<CustomerCarsRemoteDataSource>((ref) {
      return CustomerCarsRemoteDataSourceImpl(
        apiClient: ref.watch(apiClientProvider),
      );
    });

final customerGarageRepositoryProvider = Provider<CustomerGarageRepository>((
  ref,
) {
  return CustomerGarageRepositoryImpl(
    remoteDataSource: ref.watch(customerCarsRemoteDataSourceProvider),
  );
});

final getCustomerCarsUseCaseProvider = Provider<GetCustomerCarsUseCase>((ref) {
  return GetCustomerCarsUseCase(ref.watch(customerGarageRepositoryProvider));
});
