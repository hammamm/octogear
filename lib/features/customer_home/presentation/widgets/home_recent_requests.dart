import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/routing/app_routes.dart';
import '../../../../core/design_system/octogear_theme.dart';
import '../../../../core/widgets/octogear_surface_card.dart';

import '../../../customer_orders/presentation/controllers/customer_orders_providers.dart';
import '../../../customer_orders/presentation/widgets/order_widgets.dart';
import 'home_request_card.dart';

/// Shares the Orders cache, including invalidation after a successful request.
class HomeRecentRequests extends StatelessWidget {
  const HomeRecentRequests({
    required this.orders,
    required this.onRetry,
    super.key,
  });

  final AsyncValue<CustomerOrdersState> orders;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Semantics(
                header: true,
                child: Text(
                  context.tr('home.recent_requests'),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              key: const ValueKey('home-view-requests'),
              onPressed: () => const CustomerOrdersRoute().go(context),
              child: Text(context.tr('home.view_all')),
            ),
          ],
        ),
        const SizedBox(height: 8),
        orders.when(
          skipLoadingOnRefresh: false,
          loading: () => Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: CircularProgressIndicator(
                semanticsLabel: context.tr('orders.loading'),
              ),
            ),
          ),
          error: (error, _) => OctoGearSurfaceCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('home.requests_error'),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(ordersErrorMessage(context, error)),
                TextButton.icon(
                  key: const ValueKey('home-retry-requests'),
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: Text(context.tr('common.retry')),
                ),
              ],
            ),
          ),
          data: (value) {
            if (value.page.orders.isEmpty) {
              return OctoGearSurfaceCard(
                key: const ValueKey('home-empty-requests'),
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.receipt_long_outlined,
                      color: OctoGearColors.navy,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr('home.no_requests'),
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            context.tr('home.no_requests_hint'),
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }
            // The API returns newest first. Sorting a copy also keeps the
            // summary stable when the shared paginated list has been merged.
            final recent = [...value.page.orders]
              ..sort((a, b) {
                final date = b.createdAt.compareTo(a.createdAt);
                return date == 0 ? b.id.compareTo(a.id) : date;
              });
            return Column(
              children: [
                for (final order in recent.take(3))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: HomeRequestCard(
                      key: ValueKey('home-request-${order.id}'),
                      order: order,
                      onTap: () => CustomerOrderDetailsRoute(
                        orderId: order.id,
                      ).push<void>(context),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}
