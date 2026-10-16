import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/routing/app_routes.dart';
import '../../../../core/widgets/octogear_surface_card.dart';
import '../../../provider_portal/presentation/widgets/provider_page.dart';
import '../../../seller_registration/domain/entities/seller_application.dart';
import '../controllers/provider_store_management_providers.dart';
import '../controllers/provider_stores_providers.dart';
import '../../../provider_dashboard/presentation/controllers/provider_dashboard_providers.dart';
import '../widgets/store_management_widgets.dart';

class ProviderStoreApplicationsScreen extends ConsumerWidget {
  const ProviderStoreApplicationsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(providerStoreApplicationsProvider);
    return ProviderPage(
      titleKey: 'store_management.applications',
      showBack: true,
      children: [
        OutlinedButton.icon(
          onPressed: state.isLoading
              ? null
              : () => ref.invalidate(providerStoreApplicationsProvider),
          icon: const Icon(Icons.refresh),
          label: Text(context.tr('provider_stores.refresh')),
        ),
        const SizedBox(height: 16),
        state.when(
          skipLoadingOnRefresh: false,
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => StoreLoadFailure(
            error: e,
            onRetry: () => ref.invalidate(providerStoreApplicationsProvider),
          ),
          data: (items) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (items.isEmpty)
                Text(context.tr('store_management.no_applications')),
              for (final application in items)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: OctoGearSurfaceCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          context.tr(
                            application.isStoreChange
                                ? 'store_management.change_type'
                                : 'store_management.new_type',
                          ),
                        ),
                        const SizedBox(height: 8),
                        StoreApplicationBadge(status: application.status),
                        const SizedBox(height: 12),
                        Text(
                          application.name,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(application.city.name),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          key: Key('store-application-${application.id}'),
                          onPressed: () => ProviderStoreApplicationRoute(
                            requestId: application.id,
                          ).push<void>(context),
                          icon: const Icon(Icons.arrow_forward),
                          label: Text(
                            context.tr('store_management.view_application'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class ProviderStoreApplicationScreen extends ConsumerWidget {
  const ProviderStoreApplicationScreen({required this.requestId, super.key});
  final int requestId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(providerStoreApplicationProvider(requestId));
    return ProviderPage(
      titleKey: 'store_management.application',
      showBack: true,
      children: [
        OutlinedButton.icon(
          onPressed: state.isLoading
              ? null
              : () =>
                    ref.invalidate(providerStoreApplicationProvider(requestId)),
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
                ref.invalidate(providerStoreApplicationProvider(requestId)),
          ),
          data: (a) => OctoGearSurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  context.tr(
                    a.isStoreChange
                        ? 'store_management.change_type'
                        : 'store_management.new_type',
                  ),
                ),
                const SizedBox(height: 8),
                StoreApplicationBadge(status: a.status),
                const SizedBox(height: 16),
                Text(a.name, style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 16),
                Text(
                  context.tr(
                    'store_management.${a.isStoreChange ? 'change_' : ''}${a.status.name}_hint',
                  ),
                ),
                if (a.changeReason != null) ...[
                  const SizedBox(height: 16),
                  StoreInformation(
                    label: 'store_management.change_reason',
                    value: a.changeReason!,
                  ),
                ],
                if (a.status == SellerApplicationStatus.rejected &&
                    a.rejectionReason != null) ...[
                  const SizedBox(height: 16),
                  StoreInformation(
                    label: 'store_management.reason',
                    value: a.rejectionReason!,
                  ),
                ],
                const Divider(height: 32),
                StoreInformation(
                  label: 'store_management.nickname',
                  value: a.nickname,
                ),
                StoreInformation(
                  label: 'store_management.employee',
                  value: a.employeeName,
                ),
                StoreInformation(
                  label: 'provider_stores.phone',
                  value: a.mobile,
                ),
                StoreInformation(
                  label: 'provider_stores.city',
                  value: a.city.name,
                ),
                StoreInformation(
                  label: 'provider_stores.location',
                  value: a.location,
                ),
                StoreInformation(
                  label: 'store_management.registration',
                  value: a.registrationNumber,
                ),
                if (a.hasDocument)
                  StorePrivateImage(
                    path: '/api/media/store-requests/${a.id}/registration',
                    label: 'store_management.document',
                  ),
                for (final path in a.picturePaths) ...[
                  const SizedBox(height: 12),
                  StorePrivateImage(
                    path: path,
                    label: 'store_management.photos',
                  ),
                ],
                const SizedBox(height: 20),
                if (a.status == SellerApplicationStatus.rejected)
                  FilledButton.icon(
                    key: const Key('store-resubmit'),
                    onPressed: () {
                      if (a.isStoreChange) {
                        ref.invalidate(
                          providerStoreDetailsProvider(a.storeId!),
                        );
                        ProviderStoreEditRoute(
                          storeId: a.storeId!,
                        ).push<void>(context);
                      } else {
                        ProviderStoreApplicationEditRoute(
                          requestId: a.id,
                        ).push<void>(context);
                      }
                    },
                    icon: const Icon(Icons.edit_outlined),
                    label: Text(
                      context.tr(
                        a.isStoreChange
                            ? 'store_management.new_change'
                            : 'store_management.correct',
                      ),
                    ),
                  ),
                if (a.isStoreChange)
                  OutlinedButton.icon(
                    onPressed: () {
                      ref.invalidate(providerStoreDetailsProvider(a.storeId!));
                      ref.invalidate(providerStoresProvider);
                      ref.invalidate(providerDashboardProvider);
                      ProviderStoreDetailsRoute(
                        storeId: a.storeId!,
                      ).go(context);
                    },
                    icon: const Icon(Icons.storefront_outlined),
                    label: Text(context.tr('store_management.view_store')),
                  ),
                if (!a.isStoreChange &&
                    a.status == SellerApplicationStatus.accepted)
                  FilledButton.icon(
                    key: const Key('approved-store-list'),
                    onPressed: () {
                      ref.invalidate(providerStoresProvider);
                      ref.invalidate(providerDashboardProvider);
                      const ProviderStoresRoute().go(context);
                    },
                    icon: const Icon(Icons.storefront_outlined),
                    label: Text(context.tr('provider_stores.title')),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
