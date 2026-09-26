import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:octogear/core/localization/app_locale.dart';
import 'package:octogear/core/localization/app_locale_controller.dart';
import 'package:octogear/features/customer_garage/domain/entities/customer_car.dart';
import 'package:octogear/features/customer_garage/domain/repositories/customer_garage_repository.dart';
import 'package:octogear/features/customer_garage/domain/use_cases/get_customer_cars_use_case.dart';
import 'package:octogear/features/customer_garage/presentation/controllers/customer_cars_controller.dart';
import 'package:octogear/features/customer_garage/presentation/controllers/customer_cars_providers.dart';

void main() {
  test('reloads saved cars when the app locale changes', () async {
    final useCase = _CountingCustomerCarsUseCase();
    final container = ProviderContainer(
      overrides: [
        appLocaleProvider.overrideWith(_MutableLocaleController.new),
        getCustomerCarsUseCaseProvider.overrideWithValue(useCase),
      ],
    );
    addTearDown(container.dispose);

    final subscription = container.listen(
      customerCarsControllerProvider,
      (_, _) {},
    );
    addTearDown(subscription.close);

    await container.read(customerCarsControllerProvider.future);
    await container.read(appLocaleProvider.notifier).select(AppLocale.arabic);
    await container.read(customerCarsControllerProvider.future);

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

class _CountingCustomerCarsUseCase extends GetCustomerCarsUseCase {
  _CountingCustomerCarsUseCase() : super(_UnusedCustomerGarageRepository());

  int callCount = 0;

  @override
  Future<List<CustomerCar>> call() async {
    callCount++;
    return const [];
  }
}

class _UnusedCustomerGarageRepository implements CustomerGarageRepository {
  @override
  Future<List<CustomerCar>> getCustomerCars() => throw UnimplementedError();
}
