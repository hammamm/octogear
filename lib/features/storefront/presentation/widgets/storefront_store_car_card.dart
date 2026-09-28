import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/design_system/octogear_theme.dart';
import '../../../../core/widgets/authenticated_network_image.dart';
import '../../../../core/widgets/octogear_surface_card.dart';
import '../../domain/entities/storefront_store_car.dart';

/// Read-only customer summary of one vehicle in a store's inventory.
///
class StorefrontStoreCarCard extends StatelessWidget {
  const StorefrontStoreCarCard({required this.car, this.onTap, super.key});

  final StorefrontStoreCar car;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final numberFormat = NumberFormat.decimalPattern(
      context.locale.toLanguageTag(),
    );
    return OctoGearSurfaceCard(
      onTap: onTap,
      semanticLabel: context.tr(
        'storefront.details.car_semantics',
        args: [car.carName.name, numberFormat.format(car.manufacturingYear)],
      ),
      padding: const EdgeInsetsDirectional.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StoreCarImage(car: car),
          const SizedBox(width: OctoGearSpacing.medium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  car.carName.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 2),
                Directionality(
                  textDirection: ui.TextDirection.ltr,
                  child: Text(
                    NumberFormat(
                      '0',
                      context.locale.toLanguageTag(),
                    ).format(car.manufacturingYear),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: OctoGearColors.structuralGray,
                    ),
                  ),
                ),
                const SizedBox(height: OctoGearSpacing.small),
                _StoreCarMetadata(
                  icon: Icons.palette_outlined,
                  label: car.color.name,
                ),
                const SizedBox(height: 6),
                _StoreCarMetadata(
                  icon: Icons.local_gas_station_outlined,
                  label: car.fuelType.name,
                ),
                const SizedBox(height: 6),
                _StoreCarMetadata(
                  icon: Icons.inventory_2_outlined,
                  label: context.tr(
                    'storefront.details.components_count',
                    args: [numberFormat.format(car.componentsCount)],
                  ),
                ),
                if (onTap != null)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(top: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            context.tr('storefront.car.view_parts'),
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                        ),
                        const Icon(Icons.arrow_forward_rounded, size: 18),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StoreCarImage extends StatelessWidget {
  const _StoreCarImage({required this.car});

  final StorefrontStoreCar car;

  @override
  Widget build(BuildContext context) {
    final picture = car.pictures.isEmpty ? null : car.pictures.first;
    final pixelSize = (104 * MediaQuery.devicePixelRatioOf(context)).round();

    return SizedBox(
      height: 104,
      width: 104,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(OctoGearRadii.medium),
        child: picture == null
            ? const _StoreCarImageFallback()
            : AuthenticatedNetworkImage(
                apiPath: picture.url,
                semanticLabel: context.tr(
                  'storefront.details.car_photo_semantics',
                  args: [car.carName.name],
                ),
                cacheWidth: pixelSize,
                cacheHeight: pixelSize,
                errorBuilder: (_, _, _) => const _StoreCarImageFallback(),
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return const _StoreCarImageFallback(isLoading: true);
                },
              ),
      ),
    );
  }
}

class _StoreCarImageFallback extends StatelessWidget {
  const _StoreCarImageFallback({this.isLoading = false});

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
                  Icons.directions_car_outlined,
                  color: OctoGearColors.navy,
                  size: 40,
                ),
        ),
      ),
    );
  }
}

class _StoreCarMetadata extends StatelessWidget {
  const _StoreCarMetadata({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: OctoGearColors.structuralGray),
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
