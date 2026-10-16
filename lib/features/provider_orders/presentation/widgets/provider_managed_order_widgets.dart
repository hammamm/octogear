import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../core/api/api_failure.dart';
import '../../../../core/widgets/octogear_surface_card.dart';
import '../../domain/entities/provider_managed_order.dart';
import 'provider_offer_widgets.dart';

String managedOrderStatus(BuildContext context, String status) => context.tr(
  'provider_orders.${switch (status) {
    'pending' || 'awaiting_payment' || 'paid' || 'completed' || 'rejected' || 'cancelled' => status,
    _ => 'unknown',
  }}',
);
String managedOrderVehicle(ProviderManagedOrder order) => [
  order.companyName,
  order.carName,
  order.year?.toString(),
].whereType<String>().where((s) => s.isNotEmpty).join(' · ');

class ProviderManagedOrderError extends StatelessWidget {
  const ProviderManagedOrderError({
    required this.error,
    required this.retry,
    super.key,
  });
  final Object error;
  final VoidCallback retry;
  @override
  Widget build(BuildContext context) {
    final key = error is ApiFailure
        ? switch ((error as ApiFailure).type) {
            ApiFailureType.noConnection => 'errors.no_connection',
            ApiFailureType.timeout => 'errors.timeout',
            ApiFailureType.unauthorized => 'provider_requests.unauthorized',
            ApiFailureType.forbidden ||
            ApiFailureType.notFound => 'provider_orders.unavailable',
            ApiFailureType.badRequest ||
            ApiFailureType.validation => 'provider_orders.changed',
            ApiFailureType.rateLimited => 'errors.rate_limited',
            _ => 'provider_orders.failed',
          }
        : 'provider_orders.failed';
    return Column(
      children: [
        Text(context.tr(key), textAlign: TextAlign.center),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: retry,
          child: Text(context.tr('common.retry')),
        ),
      ],
    );
  }
}

class ProviderManagedOrderCard extends StatelessWidget {
  const ProviderManagedOrderCard({
    required this.order,
    required this.open,
    super.key,
  });
  final ProviderManagedOrder order;
  final VoidCallback open;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: OctoGearSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.tr(
              'provider_requests.request_number',
              args: ['${order.id}'],
            ),
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          Text(
            order.partName ?? context.tr('provider_requests.unnamed'),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const Divider(height: 24),
          Text(
            order.storeName.isEmpty
                ? context.tr('provider_requests.not_provided')
                : order.storeName,
          ),
          if (managedOrderVehicle(order).isNotEmpty)
            Text(managedOrderVehicle(order)),
          if (order.city != null) Text(order.city!),
          const SizedBox(height: 8),
          Text(
            managedOrderStatus(context, order.status),
            style: Theme.of(context).textTheme.labelLarge,
          ),
          if (order.total != null)
            Text(
              offerMoney(context, order.total!),
              style: Theme.of(context).textTheme.titleLarge,
            ),
          Text(
            DateFormat.yMMMd(
              context.locale.toLanguageTag(),
            ).format(order.createdAt.toLocal()),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: open,
            child: Text(context.tr('provider_requests.view_details')),
          ),
        ],
      ),
    ),
  );
}

class ProviderOrderField extends StatelessWidget {
  const ProviderOrderField(this.label, this.value, {super.key});
  final String label;
  final String? value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(context.tr(label), style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 4),
        SelectableText(
          value == null || value!.isEmpty
              ? context.tr('provider_requests.not_provided')
              : value!,
        ),
      ],
    ),
  );
}
