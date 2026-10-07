import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_failure.dart';
import '../../../../core/api/api_providers.dart';
import '../../data/data_sources/offer_actions_remote_data_source.dart';
import '../../data/repositories/api_offer_actions_repository.dart';
import '../../domain/entities/customer_order.dart';
import '../../domain/repositories/offer_actions_repository.dart';
import '../../domain/use_cases/accept_customer_offer_use_case.dart';
import '../../domain/use_cases/reject_customer_offer_use_case.dart';
import '../../domain/use_cases/verify_customer_offer_use_case.dart';
import 'customer_orders_providers.dart';

final offerActionsRemoteDataSourceProvider = Provider(
  (ref) => OfferActionsRemoteDataSource(ref.watch(apiClientProvider)),
);

final offerActionsRepositoryProvider = Provider<OfferActionsRepository>(
  (ref) => ApiOfferActionsRepository(
    ref.watch(offerActionsRemoteDataSourceProvider),
  ),
);

final acceptCustomerOfferProvider = Provider(
  (ref) =>
      AcceptCustomerOfferUseCase(ref.watch(offerActionsRepositoryProvider)),
);

final rejectCustomerOfferProvider = Provider(
  (ref) =>
      RejectCustomerOfferUseCase(ref.watch(offerActionsRepositoryProvider)),
);

final verifyCustomerOfferProvider = Provider(
  (ref) =>
      VerifyCustomerOfferUseCase(ref.watch(customerOrdersRepositoryProvider)),
);

enum OfferActionResult { accepted, rejected }

class OfferActionState {
  const OfferActionState({
    this.busy = false,
    this.error,
    this.needsRefresh = false,
    this.result,
  });
  final bool busy, needsRefresh;
  final ApiFailure? error;
  final OfferActionResult? result;
}

final offerActionProvider = NotifierProvider.autoDispose
    .family<OfferActionController, OfferActionState, int>(
      OfferActionController.new,
    );

/// A write is never automatically retried. Uncertain results require a read
/// before another explicit action; the order remains the source of truth.
class OfferActionController extends Notifier<OfferActionState> {
  OfferActionController(this.orderId);
  final int orderId;
  @override
  OfferActionState build() => const OfferActionState();

  Future<bool> submit({
    required CustomerOrderOffer offer,
    required bool accept,
    String? reason,
  }) async {
    if (state.busy || state.needsRefresh || state.result != null) return false;
    final keepAlive = ref.keepAlive();
    state = const OfferActionState(busy: true);
    var writeStarted = false;
    try {
      await ref.read(verifyCustomerOfferProvider)(orderId, offer);
      if (!ref.mounted) return false;
      writeStarted = true;
      if (accept) {
        await ref.read(acceptCustomerOfferProvider)(
          orderId: orderId,
          offerId: offer.id,
        );
      } else {
        await ref.read(rejectCustomerOfferProvider)(
          orderId: orderId,
          offerId: offer.id,
          reason: reason,
        );
      }
      if (!ref.mounted) return false;
      state = OfferActionState(
        result: accept
            ? OfferActionResult.accepted
            : OfferActionResult.rejected,
      );
      _invalidate();
      return true;
    } catch (error) {
      if (!ref.mounted) return false;
      final failure = error is ApiFailure
          ? error
          : const ApiFailure.unexpected();
      state = OfferActionState(
        error: failure,
        needsRefresh: writeStarted || failure.statusCode == 409,
      );
      _invalidate();
      return false;
    } finally {
      keepAlive.close();
    }
  }

  Future<void> refresh() async {
    if (state.busy) return;
    state = const OfferActionState(busy: true);
    try {
      ref.invalidate(customerOrderProvider(orderId));
      await ref.read(customerOrderProvider(orderId).future);
      if (!ref.mounted) return;
      ref.invalidate(customerOrdersProvider);
      state = const OfferActionState();
    } catch (error) {
      if (ref.mounted) {
        state = OfferActionState(
          needsRefresh: true,
          error: error is ApiFailure ? error : const ApiFailure.unexpected(),
        );
      }
    }
  }

  void _invalidate() {
    ref.invalidate(customerOrderProvider(orderId));
    ref.invalidate(customerOrdersProvider);
  }
}
