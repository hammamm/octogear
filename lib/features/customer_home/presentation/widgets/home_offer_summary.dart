import '../../../customer_orders/domain/entities/customer_order.dart';

typedef HomeOffer = ({CustomerOrder order, CustomerOrderOffer offer});

/// Available choices from the loaded order pages; never imply all history was fetched.
List<HomeOffer> homeOffers(List<CustomerOrder> orders) {
  final offers = <HomeOffer>[
    for (final order in orders)
      if (order.isGeneral &&
          order.status == CustomerOrderStatus.pending &&
          !order.hasSelectedOffer)
        for (final offer in order.offers)
          if (offer.status == CustomerOfferStatus.pending)
            (order: order, offer: offer),
  ]..sort((a, b) => b.offer.id.compareTo(a.offer.id));
  return offers.take(8).toList(growable: false);
}
