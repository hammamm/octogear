import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:octogear/features/customer_garage/domain/entities/create_customer_car_command.dart';
import 'package:octogear/features/customer_garage/domain/entities/customer_car.dart';
import 'package:octogear/features/customer_garage/domain/entities/customer_car_form_references.dart';
import 'package:octogear/features/customer_garage/domain/entities/update_customer_car_command.dart';
import 'package:octogear/features/customer_garage/domain/repositories/customer_garage_repository.dart';
import 'package:octogear/features/customer_garage/domain/use_cases/delete_customer_car_use_case.dart';
import 'package:octogear/features/customer_garage/presentation/controllers/customer_cars_providers.dart';
import 'package:octogear/features/customer_garage/presentation/controllers/delete_customer_car_controller.dart';

void main() {
  test(
    'ignores a duplicate removal while the original request is in flight',
    () async {
      final useCase = _PendingDeleteCustomerCarUseCase();
      final container = ProviderContainer(
        overrides: [
          deleteCustomerCarUseCaseProvider.overrideWithValue(useCase),
        ],
      );
      addTearDown(container.dispose);

      final subscription = container.listen(
        deleteCustomerCarControllerProvider,
        (_, _) {},
      );
      addTearDown(subscription.close);

      final notifier = container.read(
        deleteCustomerCarControllerProvider.notifier,
      );
      final firstRemoval = notifier.delete(9);
      final duplicateRemoval = notifier.delete(9);

      expect(useCase.carIds, [9]);
      expect(
        container.read(deleteCustomerCarControllerProvider).isDeleting,
        isTrue,
      );

      useCase.completer.complete();
      await firstRemoval;
      await duplicateRemoval;

      final state = container.read(deleteCustomerCarControllerProvider);
      expect(state.isDeleting, isFalse);
      expect(state.error, isNull);
      expect(state.successfulDeletionCount, 1);
      expect(useCase.carIds, [9]);
    },
  );
}

class _PendingDeleteCustomerCarUseCase extends DeleteCustomerCarUseCase {
  _PendingDeleteCustomerCarUseCase() : super(_UnusedCustomerGarageRepository());

  final carIds = <int>[];
  final completer = Completer<void>();

  @override
  Future<void> call(int carId) {
    carIds.add(carId);
    return completer.future;
  }
}

class _UnusedCustomerGarageRepository implements CustomerGarageRepository {
  @override
  Future<CustomerCar> createCustomerCar(CreateCustomerCarCommand command) =>
      throw UnimplementedError();

  @override
  Future<void> deleteCustomerCar(int carId) => throw UnimplementedError();

  @override
  Future<List<CustomerCarReference>> getCarNames(int companyId) =>
      throw UnimplementedError();

  @override
  Future<CustomerCar> getCustomerCar(int carId) => throw UnimplementedError();

  @override
  Future<CustomerCarFormReferences> getCustomerCarFormReferences() =>
      throw UnimplementedError();

  @override
  Future<List<CustomerCar>> getCustomerCars() => throw UnimplementedError();

  @override
  Future<CustomerCar> updateCustomerCar(
    int carId,
    UpdateCustomerCarCommand command,
  ) => throw UnimplementedError();
}
