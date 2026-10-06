import '../../../customer_orders/domain/entities/customer_order.dart';

typedef HomeOffer = ({CustomerOrder order, CustomerOrderOffer offer});

extension HomeOfferStatus on HomeOffer {
  bool get awaitingPayment =>
      order.status == CustomerOrderStatus.awaitingPayment &&
      order.acceptedOfferId == offer.id &&
      offer.status == CustomerOfferStatus.accepted;
}

/// Unpaid selected offers come first, followed by available choices from the
/// loaded order pages. Apply the preview limit only after prioritizing payment.
List<HomeOffer> homeOffers(List<CustomerOrder> orders) {
  final offers =
      <HomeOffer>[
        for (final order in orders)
          if (order.isGeneral &&
              (order.status == CustomerOrderStatus.awaitingPayment ||
                  (order.status == CustomerOrderStatus.pending &&
                      !order.hasSelectedOffer)))
            for (final offer in order.offers)
              if ((order.status == CustomerOrderStatus.awaitingPayment &&
                      order.acceptedOfferId == offer.id &&
                      offer.status == CustomerOfferStatus.accepted) ||
                  (order.status == CustomerOrderStatus.pending &&
                      offer.status == CustomerOfferStatus.pending))
                (order: order, offer: offer),
      ]..sort((a, b) {
        if (a.awaitingPayment != b.awaitingPayment) {
          return a.awaitingPayment ? -1 : 1;
        }
        return b.offer.id.compareTo(a.offer.id);
      });
  return offers.take(8).toList(growable: false);
}
