import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_failure.dart';
import '../../../../core/api/api_providers.dart';
import '../../data/repositories/api_offer_actions_repository.dart';
import '../../domain/entities/customer_order.dart';
import '../../domain/repositories/offer_actions_repository.dart';
import 'customer_orders_providers.dart';

final offerActionsRepositoryProvider = Provider<OfferActionsRepository>(
  (ref) => ApiOfferActionsRepository(ref.watch(apiClientProvider)),
);

bool canRespondToOffer(CustomerOrder order, CustomerOrderOffer offer) =>
    order.isGeneral &&
    order.status == CustomerOrderStatus.pending &&
    !order.hasSelectedOffer &&
    offer.status == CustomerOfferStatus.pending;

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
      // Check membership, current eligibility and the price the customer saw.
      final order = await ref
          .read(customerOrdersRepositoryProvider)
          .get(orderId);
      if (!ref.mounted) return false;
      final current = order.offers
          .where((item) => item.id == offer.id)
          .firstOrNull;
      if (current == null ||
          !canRespondToOffer(order, current) ||
          current.totalPrice != offer.totalPrice) {
        throw const ApiFailure(
          type: ApiFailureType.badRequest,
          statusCode: 409,
        );
      }
      final repository = ref.read(offerActionsRepositoryProvider);
      writeStarted = true;
      if (accept) {
        await repository.accept(orderId: orderId, offerId: offer.id);
      } else {
        await repository.reject(
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
