import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/create_customer_car_command.dart';
import '../../domain/entities/customer_car.dart';
import 'customer_cars_providers.dart';

final createCustomerCarControllerProvider =
    NotifierProvider<CreateCustomerCarController, CreateCustomerCarState>(
      CreateCustomerCarController.new,
    );

/// Submission state only. Form fields and photo-selection UI stay with the
/// screen so validation failures never erase a customer's draft.
class CreateCustomerCarState {
  const CreateCustomerCarState({
    this.isSubmitting = false,
    this.error,
    this.createdCar,
    this.lastSubmittedCommand,
    this.successfulSubmissionCount = 0,
  });

  final bool isSubmitting;
  final Object? error;
  final CustomerCar? createdCar;
  final CreateCustomerCarCommand? lastSubmittedCommand;
  final int successfulSubmissionCount;
}

class CreateCustomerCarController extends Notifier<CreateCustomerCarState> {
  @override
  CreateCustomerCarState build() => const CreateCustomerCarState();

  Future<void> submit(CreateCustomerCarCommand command) {
    return _submit(command);
  }

  /// Reuses the exact command and idempotency key after an uncertain result.
  /// The screen decides when Retry is appropriate; this method never retries
  /// automatically.
  Future<void> retry() async {
    final command = state.lastSubmittedCommand;
    if (command == null) return;
    await _submit(command);
  }

  Future<void> _submit(CreateCustomerCarCommand command) async {
    if (state.isSubmitting) return;

    state = CreateCustomerCarState(
      isSubmitting: true,
      lastSubmittedCommand: command,
      successfulSubmissionCount: state.successfulSubmissionCount,
    );

    try {
      final car = await ref
          .read(createCustomerCarUseCaseProvider)
          .call(command);
      state = CreateCustomerCarState(
        createdCar: car,
        lastSubmittedCommand: command,
        successfulSubmissionCount: state.successfulSubmissionCount + 1,
      );
    } catch (error) {
      state = CreateCustomerCarState(
        error: error,
        lastSubmittedCommand: command,
        successfulSubmissionCount: state.successfulSubmissionCount,
      );
    }
  }
}
