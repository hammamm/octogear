import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/routing/app_routes.dart';
import '../../../../core/widgets/octogear_surface_card.dart';
import '../../../provider_portal/presentation/widgets/provider_page.dart';
import '../controllers/provider_store_management_providers.dart';
import '../widgets/store_management_widgets.dart';

class ProviderStoreDetailsScreen extends ConsumerWidget {
  const ProviderStoreDetailsScreen({required this.storeId, super.key});
  final int storeId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(providerStoreDetailsProvider(storeId));
    return ProviderPage(
      titleKey: 'provider_portal.store_details',
      showBack: true,
      children: [
        OutlinedButton.icon(
          onPressed: state.isLoading
              ? null
              : () => ref.invalidate(providerStoreDetailsProvider(storeId)),
          icon: const Icon(Icons.refresh),
          label: Text(context.tr('provider_stores.refresh')),
        ),
        const SizedBox(height: 16),
        state.when(
          skipLoadingOnRefresh: false,
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => StoreLoadFailure(
            error: e,
            onRetry: () =>
                ref.invalidate(providerStoreDetailsProvider(storeId)),
          ),
          data: (details) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              OctoGearSurfaceCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Icon(Icons.storefront_outlined, size: 36),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      details.store.name,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      context.tr(
                        'provider_stores.status_${details.store.status.name}',
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (details.pendingChangeRequestId != null)
                      StorePendingChangeNotice(
                        requestId: details.pendingChangeRequestId!,
                      )
                    else
                      FilledButton.icon(
                        key: const Key('store-edit'),
                        onPressed: () => ProviderStoreEditRoute(
                          storeId: storeId,
                        ).push<void>(context),
                        icon: const Icon(Icons.edit_outlined),
                        label: Text(context.tr('store_management.edit')),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              OctoGearSurfaceCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    StoreInformation(
                      label: 'store_management.nickname',
                      value: details.nickname,
                    ),
                    StoreInformation(
                      label: 'store_management.employee',
                      value: details.employeeName,
                    ),
                    StoreInformation(
                      label: 'provider_stores.phone',
                      value: details.store.mobile!,
                    ),
                    StoreInformation(
                      label: 'provider_stores.city',
                      value: details.city.name,
                    ),
                    StoreInformation(
                      label: 'provider_stores.location',
                      value: details.store.location ?? '',
                    ),
                    StoreInformation(
                      label: 'store_management.registration',
                      value: details.registrationNumber,
                    ),
                    StoreInformation(
                      label: 'provider_stores.brands',
                      value: details.store.brands.isEmpty
                          ? context.tr('provider_stores.no_brands')
                          : details.store.brands.join(' • '),
                    ),
                    if (details.documentPath != null) ...[
                      const Divider(),
                      Text(context.tr('store_management.document')),
                      const SizedBox(height: 12),
                      StorePrivateImage(
                        path: details.documentPath!,
                        label: 'store_management.document',
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                context.tr('store_management.photos'),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              if (details.pictures.isEmpty)
                Text(context.tr('store_management.no_photos')),
              for (final picture in details.pictures)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: StorePrivateImage(
                    path: picture.path,
                    label: 'store_management.photos',
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
