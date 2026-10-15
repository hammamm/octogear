import '../../../../app/routing/app_routes.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/authenticated_network_image.dart';
import '../../../../core/widgets/octogear_surface_card.dart';
import '../controllers/provider_general_requests_providers.dart';
import '../widgets/provider_request_widgets.dart';

class ProviderGeneralRequestScreen extends ConsumerWidget {
  const ProviderGeneralRequestScreen({required this.orderId, super.key});
  final int orderId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = providerGeneralRequestProvider(orderId);
    final request = ref.watch(provider);
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(provider);
        try {
          await ref.read(provider.future);
        } catch (_) {
          /* Rendered below. */
        }
      },
      child: ListView(
        key: PageStorageKey('provider-request-detail-$orderId'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              const BackButton(),
              Expanded(
                child: Text(
                  context.tr(
                    'provider_requests.request_number',
                    args: ['$orderId'],
                  ),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              IconButton(
                tooltip: context.tr('provider_requests.refresh'),
                onPressed: request.isLoading
                    ? null
                    : () => ref.invalidate(provider),
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...request.when<List<Widget>>(
            skipLoadingOnRefresh: false,
            skipLoadingOnReload: false,
            loading: () => [const Center(child: CircularProgressIndicator())],
            error: (error, _) => [
              ProviderRequestError(
                error: error,
                onRetry: () => ref.invalidate(provider),
              ),
            ],
            data: (item) => [
              for (final offer in item.ownOffers)
                OutlinedButton(
                  onPressed: () =>
                      ProviderOfferRoute(offerId: offer.id).push<void>(context),
                  child: Text(
                    '${context.tr('provider_offers.view')} — ${offer.storeName ?? '#${offer.storeId}'}',
                  ),
                ),
              if (item.status == 'pending')
                FilledButton.icon(
                  key: const Key('provider-create-offer'),
                  onPressed: () => ProviderOfferFormRoute(
                    orderId: item.id,
                  ).push<void>(context),
                  icon: const Icon(Icons.local_offer_outlined),
                  label: Text(context.tr('provider_offers.create')),
                ),
              const SizedBox(height: 16),
              if (item.status != 'pending') ...[
                Text(context.tr('provider_requests.no_longer_open')),
                const SizedBox(height: 16),
              ],
              OctoGearSurfaceCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      item.partName ?? context.tr('provider_requests.unnamed'),
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const Divider(height: 32),
                    _Field(
                      label: 'city_filter',
                      value:
                          item.cityName ??
                          context.tr('provider_requests.city_unknown'),
                    ),
                    _Field(
                      label: 'vehicle',
                      value: requestVehicle(item).isEmpty
                          ? null
                          : requestVehicle(item),
                    ),
                    _Field(
                      label: 'date',
                      value: DateFormat.yMMMd(
                        context.locale.toLanguageTag(),
                      ).add_jm().format(item.createdAt.toLocal()),
                    ),
                    _Field(
                      label: 'transmission',
                      value: switch (item.transmission) {
                        'automatic' => context.tr(
                          'provider_requests.automatic',
                        ),
                        'manual' => context.tr('provider_requests.manual'),
                        _ => item.transmission,
                      },
                    ),
                    _Field(label: 'color', value: item.color),
                    _Field(label: 'fuel', value: item.fuel),
                    _Field(label: 'description', value: item.notes),
                    Text(
                      context.tr('provider_requests.pickup_notice'),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (item.imagePaths.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text(
                  context.tr('provider_requests.photos'),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                for (final path in item.imagePaths)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: AspectRatio(
                      aspectRatio: 4 / 3,
                      child: InteractiveViewer(
                        child: AuthenticatedNetworkImage(
                          apiPath: path,
                          fit: BoxFit.contain,
                          semanticLabel: context.tr('provider_requests.photo'),
                          errorBuilder: (_, _, _) => Center(
                            child: Text(
                              context.tr('provider_requests.photo_error'),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.label, required this.value});
  final String label;
  final String? value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          context.tr('provider_requests.$label'),
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 4),
        SelectableText(value ?? context.tr('provider_requests.not_provided')),
      ],
    ),
  );
}
