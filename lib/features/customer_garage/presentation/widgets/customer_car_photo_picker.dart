import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/design_system/octogear_theme.dart';
import '../../domain/entities/create_customer_car_command.dart';

/// Feature-specific local-photo selector for the first Add Car submission.
///
/// It displays only in-memory previews. Uploading, storage, and authorization
/// are intentionally outside this widget.
class CustomerCarPhotoPicker extends StatelessWidget {
  const CustomerCarPhotoPicker({
    required this.photos,
    required this.onAddPhotos,
    required this.onRemovePhoto,
    this.enabled = true,
    this.errorText,
    super.key,
  });

  final List<CustomerCarPhotoUpload> photos;
  final VoidCallback? onAddPhotos;
  final ValueChanged<int>? onRemovePhoto;
  final bool enabled;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr('customer_garage.add.photos_label'),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 4),
        Text(
          context.tr('customer_garage.add.photos_hint'),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: OctoGearSpacing.medium),
        Wrap(
          spacing: OctoGearSpacing.small,
          runSpacing: OctoGearSpacing.small,
          children: [
            for (var index = 0; index < photos.length; index++)
              _SelectedPhotoTile(
                index: index,
                photo: photos[index],
                enabled: enabled,
                onRemove: onRemovePhoto == null
                    ? null
                    : () => onRemovePhoto!(index),
              ),
            _AddPhotoTile(enabled: enabled, onPressed: onAddPhotos),
          ],
        ),
        if (errorText != null) ...[
          const SizedBox(height: OctoGearSpacing.xSmall),
          Text(
            errorText!,
            style: Theme.of(context).inputDecorationTheme.errorStyle,
          ),
        ],
      ],
    );
  }
}

class _SelectedPhotoTile extends StatelessWidget {
  const _SelectedPhotoTile({
    required this.index,
    required this.photo,
    required this.enabled,
    required this.onRemove,
  });

  final int index;
  final CustomerCarPhotoUpload photo;
  final bool enabled;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final photoNumber = index + 1;
    final cacheSize = (96 * MediaQuery.devicePixelRatioOf(context)).round();

    return Semantics(
      label: context.tr(
        'customer_garage.add.photo_preview_semantics',
        args: ['$photoNumber'],
      ),
      child: SizedBox(
        height: 96,
        width: 96,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(OctoGearRadii.small),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.memory(
                photo.bytes,
                fit: BoxFit.cover,
                cacheWidth: cacheSize,
                cacheHeight: cacheSize,
                filterQuality: FilterQuality.medium,
                errorBuilder: (_, _, _) => const _PhotoPreviewFallback(),
              ),
              PositionedDirectional(
                top: 2,
                end: 2,
                child: Semantics(
                  button: true,
                  label: context.tr(
                    'customer_garage.add.remove_photo_semantics',
                    args: ['$photoNumber'],
                  ),
                  child: IconButton.filled(
                    key: Key('customer_car_remove_photo_$index'),
                    tooltip: context.tr('customer_garage.add.remove_photo'),
                    onPressed: enabled ? onRemove : null,
                    style: IconButton.styleFrom(
                      backgroundColor: OctoGearColors.navy,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(48, 48),
                    ),
                    icon: const Icon(Icons.close_rounded, size: 18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddPhotoTile extends StatelessWidget {
  const _AddPhotoTile({required this.enabled, required this.onPressed});

  final bool enabled;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: context.tr('customer_garage.add.add_photos_semantics'),
      child: SizedBox(
        height: 96,
        width: 112,
        child: OutlinedButton.icon(
          key: const Key('customer_car_add_photos_button'),
          onPressed: enabled ? onPressed : null,
          icon: const Icon(Icons.add_photo_alternate_outlined),
          label: Text(
            context.tr('customer_garage.add.add_photos'),
            textAlign: TextAlign.center,
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: OctoGearColors.navy,
            side: const BorderSide(color: OctoGearColors.border),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(OctoGearRadii.small),
            ),
          ),
        ),
      ),
    );
  }
}

class _PhotoPreviewFallback extends StatelessWidget {
  const _PhotoPreviewFallback();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: OctoGearColors.surfaceMuted,
      child: Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          color: OctoGearColors.structuralGray,
        ),
      ),
    );
  }
}
