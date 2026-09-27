import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'customer_cars_providers.dart';

/// Network state for a confirmed saved-car removal.
///
/// A deletion is not blindly retried after a timeout because its outcome can
/// be uncertain. The detail screen instead offers Refresh, then lets the
/// customer make a fresh, deliberate decision if the car still exists.
class DeleteCustomerCarState {
  const DeleteCustomerCarState({
    this.isDeleting = false,
    this.error,
    this.successfulDeletionCount = 0,
  });

  final bool isDeleting;
  final Object? error;
  final int successfulDeletionCount;
}

final deleteCustomerCarControllerProvider =
    NotifierProvider.autoDispose<
      DeleteCustomerCarController,
      DeleteCustomerCarState
    >(DeleteCustomerCarController.new);

class DeleteCustomerCarController extends Notifier<DeleteCustomerCarState> {
  @override
  DeleteCustomerCarState build() => const DeleteCustomerCarState();

  Future<void> delete(int carId) async {
    if (state.isDeleting) return;

    state = DeleteCustomerCarState(
      isDeleting: true,
      successfulDeletionCount: state.successfulDeletionCount,
    );

    try {
      await ref.read(deleteCustomerCarUseCaseProvider).call(carId);
      state = DeleteCustomerCarState(
        successfulDeletionCount: state.successfulDeletionCount + 1,
      );
    } catch (error) {
      state = DeleteCustomerCarState(
        error: error,
        successfulDeletionCount: state.successfulDeletionCount,
      );
    }
  }

  void clearError() {
    if (state.error == null || state.isDeleting) return;
    state = DeleteCustomerCarState(
      successfulDeletionCount: state.successfulDeletionCount,
    );
  }
}
