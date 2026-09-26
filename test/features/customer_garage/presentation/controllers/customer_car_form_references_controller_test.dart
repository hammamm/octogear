import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:octogear/core/api/api_failure.dart';
import 'package:octogear/core/localization/app_locale.dart';
import 'package:octogear/core/localization/app_locale_controller.dart';
import 'package:octogear/features/customer_garage/domain/entities/customer_car.dart';
import 'package:octogear/features/customer_garage/domain/entities/customer_car_form_references.dart';
import 'package:octogear/features/customer_garage/domain/entities/create_customer_car_command.dart';
import 'package:octogear/features/customer_garage/domain/repositories/customer_garage_repository.dart';
import 'package:octogear/features/customer_garage/domain/use_cases/get_customer_car_form_references_use_case.dart';
import 'package:octogear/features/customer_garage/presentation/controllers/customer_car_form_references_controller.dart';
import 'package:octogear/features/customer_garage/presentation/controllers/customer_cars_providers.dart';

void main() {
  test(
    'reloads localized form references after an app-locale change',
    () async {
      final useCase = _CountingReferencesUseCase();
      final container = ProviderContainer(
        overrides: [
          appLocaleProvider.overrideWith(_MutableLocaleController.new),
          getCustomerCarFormReferencesUseCaseProvider.overrideWithValue(
            useCase,
          ),
        ],
      );
      addTearDown(container.dispose);

      final subscription = container.listen(
        customerCarFormReferencesControllerProvider,
        (_, _) {},
      );
      addTearDown(subscription.close);

      await container.read(customerCarFormReferencesControllerProvider.future);
      await container.read(appLocaleProvider.notifier).select(AppLocale.arabic);
      await container.read(customerCarFormReferencesControllerProvider.future);

      expect(useCase.callCount, 2);
    },
  );

  test('keeps a failed reference load visible until explicit Retry', () async {
    final useCase = _RetryingReferencesUseCase();
    final container = ProviderContainer(
      overrides: [
        appLocaleProvider.overrideWith(_MutableLocaleController.new),
        getCustomerCarFormReferencesUseCaseProvider.overrideWithValue(useCase),
      ],
    );
    addTearDown(container.dispose);

    final subscription = container.listen(
      customerCarFormReferencesControllerProvider,
      (_, _) {},
    );
    addTearDown(subscription.close);

    await expectLater(
      container.read(customerCarFormReferencesControllerProvider.future),
      throwsA(isA<ApiFailure>()),
    );
    expect(
      container.read(customerCarFormReferencesControllerProvider),
      isA<AsyncError<CustomerCarFormReferences>>(),
    );
    expect(useCase.callCount, 1);

    useCase.shouldSucceed = true;
    await container
        .read(customerCarFormReferencesControllerProvider.notifier)
        .retry();

    expect(
      container.read(customerCarFormReferencesControllerProvider).value,
      _references,
    );
    expect(useCase.callCount, 2);
  });
}

class _MutableLocaleController extends AppLocaleController {
  @override
  AppLocale build() => AppLocale.english;

  @override
  Future<void> select(AppLocale locale) async {
    state = locale;
  }
}

class _CountingReferencesUseCase extends GetCustomerCarFormReferencesUseCase {
  _CountingReferencesUseCase() : super(_UnusedCustomerGarageRepository());

  int callCount = 0;

  @override
  Future<CustomerCarFormReferences> call() async {
    callCount++;
    return _references;
  }
}

class _RetryingReferencesUseCase extends GetCustomerCarFormReferencesUseCase {
  _RetryingReferencesUseCase() : super(_UnusedCustomerGarageRepository());

  bool shouldSucceed = false;
  int callCount = 0;

  @override
  Future<CustomerCarFormReferences> call() async {
    callCount++;
    if (!shouldSucceed) {
      throw const ApiFailure(type: ApiFailureType.noConnection);
    }
    return _references;
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
}

const _references = CustomerCarFormReferences(
  companies: [CustomerCarReference(id: 1, name: 'Toyota')],
  colors: [CustomerCarReference(id: 2, name: 'White')],
  fuelTypes: [CustomerCarReference(id: 3, name: 'Petrol')],
);
