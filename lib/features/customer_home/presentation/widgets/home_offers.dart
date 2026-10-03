import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../app/routing/app_routes.dart';
import '../../../customer_orders/domain/entities/customer_order.dart';
import 'home_offer_card.dart';
import 'home_offer_summary.dart';

/// A naturally sized horizontal row keeps prices readable at larger text sizes.
class HomeOffers extends StatefulWidget {
  const HomeOffers({required this.page, super.key});
  final CustomerOrdersPage page;

  @override
  State<HomeOffers> createState() => _HomeOffersState();
}

class _HomeOffersState extends State<HomeOffers> {
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _move(double distance) {
    if (!_scroll.hasClients) return;
    final target = (_scroll.offset + distance).clamp(
      0.0,
      _scroll.position.maxScrollExtent,
    );
    if (MediaQuery.disableAnimationsOf(context)) {
      _scroll.jumpTo(target);
    } else {
      _scroll.animateTo(
        target,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final offers = homeOffers(widget.page.orders);
    // Recent requests already show waiting status and the no-request message.
    if (offers.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    context.tr('home.review_offers'),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                key: const ValueKey('home-view-all-offers'),
                onPressed: () => const CustomerOrdersRoute().go(context),
                child: Text(context.tr('home.view_all')),
              ),
            ],
          ),
          Text(
            context.tr('home.recent_offers_hint'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = offers.length == 1
                  ? constraints.maxWidth
                  : (constraints.maxWidth * .88).clamp(0.0, 320.0);
              return Column(
                children: [
                  SingleChildScrollView(
                    key: const ValueKey('home-offers-scroll'),
                    controller: _scroll,
                    scrollDirection: Axis.horizontal,
                    child: IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (var index = 0; index < offers.length; index++)
                            Padding(
                              padding: EdgeInsetsDirectional.only(
                                end: index == offers.length - 1 ? 0 : 12,
                              ),
                              child: SizedBox(
                                width: width,
                                child: HomeOfferCard(
                                  key: ValueKey(
                                    'home-offer-${offers[index].offer.id}',
                                  ),
                                  item: offers[index],
                                  onTap: () => CustomerOrderDetailsRoute(
                                    orderId: offers[index].order.id,
                                  ).push<void>(context),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  if (offers.length > 1)
                    AnimatedBuilder(
                      animation: _scroll,
                      builder: (context, _) => Row(
                        children: [
                          Expanded(
                            child: Text(
                              context.tr('home.swipe_offers'),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                          IconButton(
                            key: const ValueKey('home-previous-offer'),
                            tooltip: context.tr('home.previous_offer'),
                            onPressed:
                                !_scroll.hasClients || _scroll.offset <= 0
                                ? null
                                : () => _move(-width - 12),
                            icon: const Icon(
                              Icons.arrow_back_rounded,
                              size: 20,
                            ),
                          ),
                          IconButton(
                            key: const ValueKey('home-next-offer'),
                            tooltip: context.tr('home.next_offer'),
                            onPressed:
                                _scroll.hasClients &&
                                    _scroll.position.hasContentDimensions &&
                                    _scroll.offset >=
                                        _scroll.position.maxScrollExtent
                                ? null
                                : () => _move(width + 12),
                            icon: const Icon(
                              Icons.arrow_forward_rounded,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
