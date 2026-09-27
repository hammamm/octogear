import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_providers.dart';
import '../../data/data_sources/customer_cars_remote_data_source.dart';
import '../../data/repositories/customer_garage_repository_impl.dart';
import '../../domain/repositories/customer_garage_repository.dart';
import '../../domain/use_cases/create_customer_car_use_case.dart';
import '../../domain/use_cases/get_customer_car_form_references_use_case.dart';
import '../../domain/use_cases/get_customer_car_names_use_case.dart';
import '../../domain/use_cases/get_customer_cars_use_case.dart';
import '../../domain/use_cases/delete_customer_car_use_case.dart';
import '../../domain/use_cases/get_customer_car_use_case.dart';
import '../../domain/use_cases/update_customer_car_use_case.dart';

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

final getCustomerCarUseCaseProvider = Provider<GetCustomerCarUseCase>((ref) {
  return GetCustomerCarUseCase(ref.watch(customerGarageRepositoryProvider));
});

final getCustomerCarFormReferencesUseCaseProvider =
    Provider<GetCustomerCarFormReferencesUseCase>((ref) {
      return GetCustomerCarFormReferencesUseCase(
        ref.watch(customerGarageRepositoryProvider),
      );
    });

final getCustomerCarNamesUseCaseProvider = Provider<GetCustomerCarNamesUseCase>(
  (ref) {
    return GetCustomerCarNamesUseCase(
      ref.watch(customerGarageRepositoryProvider),
    );
  },
);

final createCustomerCarUseCaseProvider = Provider<CreateCustomerCarUseCase>((
  ref,
) {
  return CreateCustomerCarUseCase(ref.watch(customerGarageRepositoryProvider));
});

final updateCustomerCarUseCaseProvider = Provider<UpdateCustomerCarUseCase>((
  ref,
) {
  return UpdateCustomerCarUseCase(ref.watch(customerGarageRepositoryProvider));
});

final deleteCustomerCarUseCaseProvider = Provider<DeleteCustomerCarUseCase>((
  ref,
) {
  return DeleteCustomerCarUseCase(ref.watch(customerGarageRepositoryProvider));
});
