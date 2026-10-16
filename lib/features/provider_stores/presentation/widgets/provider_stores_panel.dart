import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/routing/app_routes.dart';
import '../../../../core/api/api_failure.dart';
import '../../../../core/design_system/octogear_theme.dart';
import '../../../../core/widgets/octogear_surface_card.dart';
import '../../domain/entities/provider_store.dart';
import '../controllers/provider_stores_providers.dart';

class ProviderStoresPanel extends ConsumerWidget {
  const ProviderStoresPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stores = ref.watch(providerStoresProvider);
    void reload() => ref.invalidate(providerStoresProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                context.tr('provider_stores.title'),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            IconButton(
              tooltip: context.tr('provider_stores.refresh'),
              onPressed: stores.isLoading ? null : reload,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        const SizedBox(height: OctoGearSpacing.medium),
        stores.when(
          skipLoadingOnRefresh: false,
          skipLoadingOnReload: false,
          loading: () => Padding(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: CircularProgressIndicator(
                semanticsLabel: context.tr('provider_stores.loading'),
              ),
            ),
          ),
          error: (error, _) => OctoGearSurfaceCard(
            child: Column(
              children: [
                const Icon(Icons.cloud_off_outlined, size: 36),
                const SizedBox(height: 12),
                Text(_failure(context, error), textAlign: TextAlign.center),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: reload,
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(context.tr('provider_stores.retry')),
                ),
              ],
            ),
          ),
          data: (items) => items.isEmpty
              ? OctoGearSurfaceCard(
                  child: Column(
                    children: [
                      const Icon(Icons.storefront_outlined, size: 40),
                      const SizedBox(height: 12),
                      Text(
                        context.tr('provider_stores.empty_title'),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        context.tr('provider_stores.empty_body'),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    if (items.length > 1)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(context.tr('provider_stores.choose_store')),
                      ),
                    for (final store in items)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _StoreCard(
                          key: ValueKey(store.id),
                          store: store,
                          expandable: items.length > 1,
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }

  String _failure(BuildContext context, Object error) {
    final key = switch (error) {
      ApiFailure(type: ApiFailureType.noConnection) => 'errors.no_connection',
      ApiFailure(type: ApiFailureType.timeout) => 'errors.timeout',
      ApiFailure(type: ApiFailureType.unauthorized) =>
        'provider_stores.unauthorized',
      ApiFailure(type: ApiFailureType.forbidden) => 'provider_stores.forbidden',
      ApiFailure(type: ApiFailureType.rateLimited) => 'errors.rate_limited',
      _ => 'provider_stores.load_error',
    };
    return context.tr(key);
  }
}

class _StoreCard extends StatelessWidget {
  const _StoreCard({required this.store, required this.expandable, super.key});
  final ProviderStore store;
  final bool expandable;

  @override
  Widget build(BuildContext context) {
    final status = Text(
      context.tr('provider_stores.status_${store.status.name}'),
    );
    if (expandable) {
      return OctoGearSurfaceCard(
        padding: EdgeInsets.zero,
        child: ExpansionTile(
          key: PageStorageKey('provider-store-${store.id}'),
          title: Text(store.name),
          subtitle: status,
          leading: const Icon(Icons.storefront_outlined),
          childrenPadding: const EdgeInsetsDirectional.fromSTEB(20, 0, 20, 20),
          children: [_StoreDetails(store: store)],
        ),
      );
    }
    return OctoGearSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Align(
            alignment: AlignmentDirectional.centerStart,
            child: Icon(Icons.storefront_outlined, size: 36),
          ),
          const SizedBox(height: 12),
          Text(store.name, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          status,
          const Divider(height: 32),
          _StoreDetails(store: store),
        ],
      ),
    );
  }
}

class _StoreDetails extends StatelessWidget {
  const _StoreDetails({required this.store});
  final ProviderStore store;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          key: Key('manage-store-${store.id}'),
          onPressed: () =>
              ProviderStoreDetailsRoute(storeId: store.id).push<void>(context),
          icon: const Icon(Icons.settings_outlined),
          label: Text(context.tr('store_management.manage')),
        ),
        const SizedBox(height: 20),
        _Field(label: 'phone', value: store.mobile, leftToRight: true),
        _Field(label: 'city', value: store.city),
        _Field(label: 'location', value: store.location, leftToRight: true),
        Text(
          context.tr('provider_stores.brands'),
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 8),
        if (store.brands.isEmpty)
          Text(context.tr('provider_stores.no_brands'))
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final brand in store.brands) Chip(label: Text(brand)),
            ],
          ),
      ],
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.value,
    this.leftToRight = false,
  });
  final String label;
  final String? value;
  final bool leftToRight;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.tr('provider_stores.$label'),
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 6),
          if (value == null)
            Text(context.tr('provider_stores.not_provided'))
          else
            SelectableText(
              value!,
              textDirection: leftToRight ? TextDirection.ltr : null,
            ),
        ],
      ),
    );
  }
}
