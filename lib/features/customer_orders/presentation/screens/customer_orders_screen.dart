import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/routing/app_routes.dart';
import '../../../../core/config/customer_features.dart';
import '../../../../core/widgets/app_language_toggle_button.dart';
import '../../domain/entities/customer_order.dart';
import '../controllers/customer_orders_providers.dart';
import '../widgets/order_widgets.dart';

class CustomerOrdersScreen extends ConsumerStatefulWidget {
  const CustomerOrdersScreen({super.key});
  @override
  ConsumerState<CustomerOrdersScreen> createState() =>
      _CustomerOrdersScreenState();
}

class _CustomerOrdersScreenState extends ConsumerState<CustomerOrdersScreen> {
  CustomerOrderFilter _filter = CustomerOrderFilter.all;
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(customerOrdersProvider(_filter));
    final storesEnabled = ref.watch(customerStoresEnabledProvider);
    return RefreshIndicator(
      onRefresh: () async {
        try {
          ref.invalidate(customerOrdersProvider(_filter));
          await ref.read(customerOrdersProvider(_filter).future);
        } catch (_) {
          /* Visible provider error. */
        }
      },
      child: CustomScrollView(
        key: const PageStorageKey('customer-tab-orders'),
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsetsDirectional.fromSTEB(20, 16, 20, 32),
            sliver: SliverMainAxisGroup(
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              context.tr('orders.title'),
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const AppLanguageToggleButton(compact: true),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(context.tr('orders.subtitle')),
                      const SizedBox(height: 20),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final filter in CustomerOrderFilter.values)
                            ChoiceChip(
                              label: Text(
                                context.tr('orders.filter_${filter.name}'),
                              ),
                              selected: filter == _filter,
                              onSelected: (_) =>
                                  setState(() => _filter = filter),
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
                ...state.when(
                  skipLoadingOnRefresh: false,
                  loading: () => [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Center(
                          child: CircularProgressIndicator(
                            semanticsLabel: context.tr('orders.loading'),
                          ),
                        ),
                      ),
                    ),
                  ],
                  error: (error, _) => [
                    SliverToBoxAdapter(
                      child: OrdersFeedback(
                        title: context.tr('orders.error_title'),
                        message: ordersErrorMessage(context, error),
                        icon: Icons.cloud_off_outlined,
                        action: context.tr('common.retry'),
                        onAction: () =>
                            ref.invalidate(customerOrdersProvider(_filter)),
                      ),
                    ),
                  ],
                  data: (value) {
                    if (value.page.orders.isEmpty) {
                      return [
                        SliverToBoxAdapter(
                          child: OrdersFeedback(
                            title: context.tr('orders.empty_title'),
                            message: context.tr(
                              _filter == CustomerOrderFilter.all
                                  ? storesEnabled
                                        ? 'orders.empty_all'
                                        : 'orders.empty_all_stores_hidden'
                                  : 'orders.empty_filter',
                            ),
                            icon: Icons.receipt_long_outlined,
                            action: context.tr(
                              _filter == CustomerOrderFilter.all
                                  ? storesEnabled
                                        ? 'orders.browse'
                                        : 'customer_shell.home.tab'
                                  : 'orders.filter_all',
                            ),
                            onAction: () => _filter == CustomerOrderFilter.all
                                ? storesEnabled
                                      ? const CustomerStoresRoute().go(context)
                                      : const CustomerHomeRoute().go(context)
                                : setState(
                                    () => _filter = CustomerOrderFilter.all,
                                  ),
                          ),
                        ),
                      ];
                    }
                    return [
                      SliverList.separated(
                        itemCount: value.page.orders.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (_, index) {
                          final order = value.page.orders[index];
                          return CustomerOrderCard(
                            key: ValueKey(order.id),
                            order: order,
                            onTap: () => CustomerOrderDetailsRoute(
                              orderId: order.id,
                            ).push<void>(context),
                          );
                        },
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsetsDirectional.only(top: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                context.tr(
                                  'orders.showing',
                                  args: [
                                    orderNumber(
                                      context,
                                      value.page.orders.length,
                                    ),
                                    orderNumber(context, value.page.total),
                                  ],
                                ),
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              if (value.nextPageError != null)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  child: Text(
                                    ordersErrorMessage(
                                      context,
                                      value.nextPageError!,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              if (value.page.hasMore) ...[
                                const SizedBox(height: 12),
                                OutlinedButton(
                                  onPressed: value.loadingMore
                                      ? null
                                      : () => ref
                                            .read(
                                              customerOrdersProvider(
                                                _filter,
                                              ).notifier,
                                            )
                                            .loadMore(),
                                  child: Text(
                                    context.tr(
                                      value.loadingMore
                                          ? 'orders.loading'
                                          : value.nextPageError != null
                                          ? 'common.retry'
                                          : 'orders.load_more',
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ];
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
