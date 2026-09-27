import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/customer_car.dart';
import '../../domain/entities/update_customer_car_command.dart';
import 'customer_cars_providers.dart';

/// Network state for the scalar saved-car PATCH operation.
///
/// The screen owns the editable fields, so a validation or network failure
/// never erases the customer’s in-progress form. PATCH is a replacement of
/// scalar values and can safely reuse this exact command after an uncertain
/// network result.
class UpdateCustomerCarState {
  const UpdateCustomerCarState({
    this.isSubmitting = false,
    this.error,
    this.updatedCar,
    this.lastSubmittedCommand,
    this.successfulSubmissionCount = 0,
  });

  final bool isSubmitting;
  final Object? error;
  final CustomerCar? updatedCar;
  final UpdateCustomerCarCommand? lastSubmittedCommand;
  final int successfulSubmissionCount;
}

final updateCustomerCarControllerProvider =
    NotifierProvider.autoDispose<
      UpdateCustomerCarController,
      UpdateCustomerCarState
    >(UpdateCustomerCarController.new);

class UpdateCustomerCarController extends Notifier<UpdateCustomerCarState> {
  @override
  UpdateCustomerCarState build() => const UpdateCustomerCarState();

  Future<void> submit(int carId, UpdateCustomerCarCommand command) {
    return _submit(carId, command);
  }

  Future<void> retry(int carId) async {
    final command = state.lastSubmittedCommand;
    if (command == null) return;
    await _submit(carId, command);
  }

  /// A changed draft must not offer Retry for an older set of values.
  void clearError() {
    if (state.isSubmitting || state.error == null) return;
    state = UpdateCustomerCarState(
      successfulSubmissionCount: state.successfulSubmissionCount,
    );
  }

  Future<void> _submit(int carId, UpdateCustomerCarCommand command) async {
    if (state.isSubmitting) return;

    state = UpdateCustomerCarState(
      isSubmitting: true,
      lastSubmittedCommand: command,
      successfulSubmissionCount: state.successfulSubmissionCount,
    );

    try {
      final car = await ref
          .read(updateCustomerCarUseCaseProvider)
          .call(carId, command);
      state = UpdateCustomerCarState(
        updatedCar: car,
        lastSubmittedCommand: command,
        successfulSubmissionCount: state.successfulSubmissionCount + 1,
      );
    } catch (error) {
      state = UpdateCustomerCarState(
        error: error,
        lastSubmittedCommand: command,
        successfulSubmissionCount: state.successfulSubmissionCount,
      );
    }
  }
}
