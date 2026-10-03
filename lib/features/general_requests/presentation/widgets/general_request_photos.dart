import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../part_requests/domain/entities/part_request.dart';

class GeneralRequestPhotos extends StatelessWidget {
  const GeneralRequestPhotos({required this.photos, this.onRemove, super.key});
  final List<PartRequestPhoto> photos;
  final ValueChanged<int>? onRemove;
  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 12,
    runSpacing: 12,
    children: [
      for (var i = 0; i < photos.length; i++)
        SizedBox(
          width: 104,
          child: Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(
                  photos[i].bytes,
                  width: 104,
                  height: 84,
                  fit: BoxFit.cover,
                  semanticLabel: context.tr(
                    'general_request.photo_number',
                    args: ['${i + 1}'],
                  ),
                  errorBuilder: (_, _, _) => const SizedBox(
                    width: 104,
                    height: 84,
                    child: Icon(Icons.broken_image_outlined),
                  ),
                ),
              ),
              if (onRemove != null)
                IconButton(
                  onPressed: () => onRemove!(i),
                  tooltip: context.tr(
                    'general_request.remove_photo',
                    args: ['${i + 1}'],
                  ),
                  icon: const Icon(Icons.delete_outline),
                ),
            ],
          ),
        ),
    ],
  );
}
