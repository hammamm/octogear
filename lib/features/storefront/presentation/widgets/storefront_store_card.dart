import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/design_system/octogear_theme.dart';
import '../../../../core/widgets/authenticated_network_image.dart';
import '../../../../core/widgets/octogear_surface_card.dart';
import '../../domain/entities/marketplace_store.dart';

/// A customer-safe visual summary of one active store.
///
class StorefrontStoreCard extends StatelessWidget {
  const StorefrontStoreCard({required this.store, this.onTap, super.key});

  final MarketplaceStore store;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return OctoGearSurfaceCard(
      semanticLabel: store.displayName,
      padding: const EdgeInsetsDirectional.all(16),
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StorefrontImage(store: store),
          const SizedBox(width: OctoGearSpacing.medium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    store.displayName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (store.name.isNotEmpty && store.name != store.displayName)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(top: 2),
                    child: Text(
                      store.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                const SizedBox(height: OctoGearSpacing.small),
                _StorefrontMetadata(
                  icon: Icons.location_on_outlined,
                  label:
                      store.city?.name ??
                      context.tr('storefront.city_unavailable'),
                ),
                if (store.averageRating != null) ...[
                  const SizedBox(height: 6),
                  Semantics(
                    label: context.tr(
                      'storefront.rating_semantics',
                      args: [store.averageRating!.toStringAsFixed(1)],
                    ),
                    child: ExcludeSemantics(
                      child: _StorefrontMetadata(
                        icon: Icons.star_rounded,
                        iconColor: OctoGearColors.yellow,
                        label: store.averageRating!.toStringAsFixed(1),
                      ),
                    ),
                  ),
                ],
                if (onTap != null) ...[
                  const SizedBox(height: OctoGearSpacing.small),
                  const Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: ExcludeSemantics(
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        color: OctoGearColors.navy,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StorefrontImage extends StatelessWidget {
  const _StorefrontImage({required this.store});

  final MarketplaceStore store;

  @override
  Widget build(BuildContext context) {
    final pixelSize = (88 * MediaQuery.devicePixelRatioOf(context)).round();
    final picturePath = store.primaryPictureUrl;

    return SizedBox(
      height: 88,
      width: 88,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(OctoGearRadii.medium),
        child: picturePath == null
            ? const _StorefrontImageFallback()
            : AuthenticatedNetworkImage(
                apiPath: picturePath,
                semanticLabel: context.tr(
                  'storefront.store_photo_semantics',
                  args: [store.displayName],
                ),
                cacheWidth: pixelSize,
                cacheHeight: pixelSize,
                errorBuilder: (_, _, _) => const _StorefrontImageFallback(),
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return const _StorefrontImageFallback(isLoading: true);
                },
              ),
      ),
    );
  }
}

class _StorefrontImageFallback extends StatelessWidget {
  const _StorefrontImageFallback({this.isLoading = false});

  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: ColoredBox(
        color: OctoGearColors.yellowSoft,
        child: Center(
          child: isLoading
              ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                )
              : const Icon(
                  Icons.storefront_outlined,
                  color: OctoGearColors.navy,
                  size: 37,
                ),
        ),
      ),
    );
  }
}

class _StorefrontMetadata extends StatelessWidget {
  const _StorefrontMetadata({
    required this.icon,
    required this.label,
    this.iconColor = OctoGearColors.structuralGray,
  });

  final IconData icon;
  final String label;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}
