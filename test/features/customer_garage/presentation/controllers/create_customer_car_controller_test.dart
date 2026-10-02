import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:octogear/core/api/api_failure.dart';
import 'package:octogear/features/customer_garage/domain/entities/create_customer_car_command.dart';
import 'package:octogear/features/customer_garage/domain/entities/update_customer_car_command.dart';
import 'package:octogear/features/customer_garage/domain/entities/customer_car.dart';
import 'package:octogear/features/customer_garage/domain/entities/customer_car_form_references.dart';
import 'package:octogear/features/customer_garage/domain/repositories/customer_garage_repository.dart';
import 'package:octogear/features/customer_garage/domain/use_cases/create_customer_car_use_case.dart';
import 'package:octogear/features/customer_garage/presentation/controllers/create_customer_car_controller.dart';
import 'package:octogear/features/customer_garage/presentation/controllers/customer_cars_providers.dart';

void main() {
  test(
    'manual retry reuses the original idempotency command after failure',
    () async {
      final useCase = _RetryingCreateUseCase();
      final container = ProviderContainer(
        overrides: [
          createCustomerCarUseCaseProvider.overrideWithValue(useCase),
        ],
      );
      addTearDown(container.dispose);

      final command = _command();
      final notifier = container.read(
        createCustomerCarControllerProvider.notifier,
      );

      await notifier.submit(command);

      final failed = container.read(createCustomerCarControllerProvider);
      expect(failed.isSubmitting, isFalse);
      expect(failed.error, isA<ApiFailure>());
      expect(identical(failed.lastSubmittedCommand, command), isTrue);
      expect(useCase.commands, [command]);

      useCase.shouldSucceed = true;
      await notifier.retry();

      final succeeded = container.read(createCustomerCarControllerProvider);
      expect(succeeded.error, isNull);
      expect(succeeded.createdCar, _createdCar);
      expect(succeeded.successfulSubmissionCount, 1);
      expect(useCase.commands, [command, command]);
    },
  );
}

class _RetryingCreateUseCase extends CreateCustomerCarUseCase {
  _RetryingCreateUseCase() : super(_UnusedCustomerGarageRepository());

  bool shouldSucceed = false;
  final commands = <CreateCustomerCarCommand>[];

  @override
  Future<CustomerCar> call(CreateCustomerCarCommand command) async {
    commands.add(command);
    if (!shouldSucceed) {
      throw const ApiFailure(type: ApiFailureType.timeout);
    }
    return _createdCar;
  }
}

class _UnusedCustomerGarageRepository implements CustomerGarageRepository {
  @override
  Future<CustomerCar> createCustomerCar(CreateCustomerCarCommand command) {
    throw UnimplementedError();
  }

  @override
  Future<List<CustomerCarReference>> getCarNames(int companyId) {
    throw UnimplementedError();
  }

  @override
  Future<CustomerCarFormReferences> getCustomerCarFormReferences() {
    throw UnimplementedError();
  }

  @override
  Future<List<CustomerCar>> getCustomerCars() => throw UnimplementedError();

  @override
  Future<CustomerCar> getCustomerCar(int carId) => throw UnimplementedError();

  @override
  Future<CustomerCar> updateCustomerCar(
    int carId,
    UpdateCustomerCarCommand command,
  ) => throw UnimplementedError();

  @override
  Future<void> deleteCustomerCar(int carId) => throw UnimplementedError();
}

CreateCustomerCarCommand _command() {
  return const CreateCustomerCarCommand(
    carNameId: 4,
    manufacturingYear: 2022,
    transmissionType: 'automatic',
    colorId: 2,
    fuelTypeId: 1,
    pictures: [],
    idempotencyKey: 'request-uuid',
  );
}

final _createdCar = CustomerCar(
  id: 9,
  manufacturingYear: 2022,
  transmissionType: 'automatic',
  company: const CustomerCarReference(id: 1, name: 'Toyota'),
  carName: const CustomerCarReference(id: 4, name: 'Camry'),
  color: const CustomerCarReference(id: 2, name: 'White'),
  fuelType: const CustomerCarReference(id: 1, name: 'Petrol'),
  pictures: [],
  createdAt: DateTime.utc(2026, 9, 26),
);
