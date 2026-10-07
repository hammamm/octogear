import 'package:octogear/features/customer_orders/domain/entities/order_lifecycle_action.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:octogear/core/api/api_failure.dart';
import 'package:octogear/features/customer_orders/data/models/customer_order_dto.dart';
import 'package:octogear/features/customer_orders/data/models/order_changes_dto.dart';
import 'package:octogear/features/customer_orders/domain/entities/order_changes.dart';
import 'package:octogear/features/customer_orders/domain/use_cases/verify_customer_offer_use_case.dart';
import 'package:octogear/features/customer_orders/domain/use_cases/verify_order_lifecycle_use_case.dart';

import 'offer_actions_test.dart' show actionOrder;
import 'order_fixtures.dart';

void main() {
  final conflict = throwsA(
    isA<ApiFailure>().having((failure) => failure.statusCode, 'status', 409),
  );

  test(
    'offer preflight rejects stale prices, membership and eligibility without UI',
    () async {
      final displayed = actionOrder().offers.single;
      final repo = FakeOrdersRepository()..onGet = (_) async => actionOrder();
      final verify = VerifyCustomerOfferUseCase(repo);
      await verify(17, displayed);
      for (final fresh in [
        actionOrder(price: 20000),
        actionOrder(offerStatus: 'rejected'),
        actionOrder(status: 'completed'),
        fixtureOrder(id: 17, general: true),
      ]) {
        repo.onGet = (_) async => fresh;
        await expectLater(verify(17, displayed), conflict);
      }
      expect(repo.detailCalls, everyElement(17));
    },
  );

  test(
    'lifecycle preflight requires unchanged status, selected offer and permission',
    () async {
      final json = orderJson(id: 17, general: true)..['can_cancel'] = true;
      final displayed = CustomerOrderDto.fromJson(json).toEntity();
      final repo = FakeOrdersRepository()..onGet = (_) async => displayed;
      final verify = VerifyOrderLifecycleUseCase(repo);
      await verify(displayed, OrderLifecycleAction.cancel);
      await expectLater(
        verify(displayed, OrderLifecycleAction.received),
        conflict,
      );
      for (final change in [
        {'can_cancel': false},
        {'status': 'awaiting_payment'},
        {'accepted_offer_id': 42},
      ]) {
        repo.onGet = (_) async =>
            CustomerOrderDto.fromJson({...json, ...change}).toEntity();
        await expectLater(
          verify(displayed, OrderLifecycleAction.cancel),
          conflict,
        );
      }
    },
  );

  test(
    'partial edits omit unchanged fields but preserve an explicit empty note',
    () {
      expect(const OrderChangesDto(OrderChanges()).toJson(), isEmpty);
      expect(
        const OrderChangesDto(OrderChanges(notes: '', quantity: 3)).toJson(),
        {'notes': '', 'quantity': 3},
      );
      expect(const OrderChangesDto(OrderChanges(componentId: 7)).toJson(), {
        'component_id': 7,
      });
      expect(
        const OrderChangesDto(
          OrderChanges(componentName: 'Headlight'),
        ).toJson(),
        {'component_name': 'Headlight'},
      );
    },
  );

  test(
    'vehicle replacement serializes a complete snapshot without garage mutations',
    () {
      const dto = OrderChangesDto(
        OrderChanges(
          vehicle: OrderVehicleChanges(
            carNameId: 2,
            year: 2020,
            transmission: 'automatic',
            colorId: 3,
            fuelTypeId: 4,
          ),
        ),
      );
      expect(dto.toJson(), {
        'vehicle': {
          'car_name_id': 2,
          'manufacturing_year': 2020,
          'transmission_type': 'automatic',
          'color_id': 3,
          'fuel_type': 4,
        },
      });
    },
  );
}
