import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../authentication/domain/entities/app_user.dart';
import '../../../authentication/presentation/controllers/registration_cities_controller.dart';
import '../../../authentication/presentation/widgets/registration_city_field.dart';
import '../../../provider_stores/presentation/controllers/provider_stores_providers.dart';
import '../controllers/provider_general_requests_providers.dart';
import 'provider_request_widgets.dart';

class ProviderCityFilter extends ConsumerWidget {
  const ProviderCityFilter({super.key});

  Future<void> _select(BuildContext context, WidgetRef ref, int? cityId) async {
    final saved = await ref
        .read(providerOrderCityProvider.notifier)
        .select(cityId);
    if (!saved && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('provider_requests.preference_failed')),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cityId = ref.watch(providerOrderCityProvider);
    final catalog = cityId == null
        ? null
        : ref.watch(registrationCitiesProvider);
    final selected = catalog?.asData?.value
        .where((city) => city.id == cityId)
        .firstOrNull;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          context.tr('provider_requests.city_filter'),
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              key: const Key('provider-city-all'),
              label: Text(context.tr('provider_requests.all_cities')),
              selected: cityId == null,
              onSelected: (_) => _select(context, ref, null),
            ),
            OutlinedButton.icon(
              key: const Key('provider-city-select'),
              icon: const Icon(Icons.location_on_outlined),
              label: Text(
                selected?.name ??
                    (cityId == null
                        ? context.tr('provider_requests.choose_city')
                        : context.tr(
                            'provider_requests.city_number',
                            args: ['$cityId'],
                          )),
              ),
              onPressed: () async {
                final city = await showModalBottomSheet<AppCity>(
                  context: context,
                  isScrollControlled: true,
                  useSafeArea: true,
                  builder: (_) => RegistrationCityPicker(selectedId: cityId),
                );
                if (city != null && context.mounted) {
                  await _select(context, ref, city.id);
                }
              },
            ),
            TextButton.icon(
              key: const Key('provider-city-store'),
              icon: const Icon(Icons.storefront_outlined),
              label: Text(context.tr('provider_requests.store_city')),
              onPressed: () async {
                final city = await showModalBottomSheet<AppCity>(
                  context: context,
                  isScrollControlled: true,
                  useSafeArea: true,
                  builder: (_) => const _StoreCities(),
                );
                if (city != null && context.mounted) {
                  await _select(context, ref, city.id);
                }
              },
            ),
          ],
        ),
      ],
    );
  }
}

class _StoreCities extends ConsumerWidget {
  const _StoreCities();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stores = ref.watch(providerStoresProvider);
    return FractionallySizedBox(
      heightFactor: .65,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    context.tr('provider_requests.store_city'),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: stores.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => SingleChildScrollView(
                  child: ProviderRequestError(
                    error: error,
                    onRetry: () => ref.invalidate(providerStoresProvider),
                  ),
                ),
                data: (items) {
                  final cities = {
                    for (final store in items)
                      if (store.cityId != null && store.city != null)
                        store.cityId!: AppCity(
                          id: store.cityId!,
                          name: store.city!,
                        ),
                  }.values.toList();
                  if (cities.isEmpty) {
                    return Text(context.tr('provider_requests.no_store_city'));
                  }
                  return ListView(
                    children: [
                      for (final city in cities)
                        ListTile(
                          title: Text(city.name),
                          onTap: () => Navigator.pop(context, city),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
