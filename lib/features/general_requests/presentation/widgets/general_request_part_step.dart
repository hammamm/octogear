import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../part_requests/domain/entities/part_request.dart';
import 'general_request_feedback.dart';
import 'general_request_photos.dart';

class GeneralRequestPartStep extends StatelessWidget {
  const GeneralRequestPartStep({
    required this.formKey,
    required this.partName,
    required this.customPart,
    required this.disabled,
    required this.partError,
    required this.picking,
    required this.photoError,
    required this.nameController,
    required this.descriptionController,
    required this.photos,
    required this.onPartModeChanged,
    required this.onChoosePart,
    required this.onChanged,
    required this.onAddPhoto,
    required this.onRemovePhoto,
    super.key,
  });
  final GlobalKey<FormState> formKey;
  final String partName;
  final bool customPart, disabled, partError, picking, photoError;
  final TextEditingController nameController, descriptionController;
  final List<PartRequestPhoto> photos;
  final ValueChanged<bool> onPartModeChanged;
  final VoidCallback onChoosePart, onChanged, onAddPhoto;
  final ValueChanged<int> onRemovePhoto;
  @override
  Widget build(BuildContext context) {
    String tr(String key) => context.tr('general_request.$key');
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(tr('part_hint'), style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: Text(tr('catalog_part')),
                selected: !customPart,
                onSelected: disabled
                    ? null
                    : (_) {
                        onPartModeChanged(false);
                      },
              ),
              ChoiceChip(
                key: const Key('general-custom-part'),
                label: Text(tr('custom_part')),
                selected: customPart,
                onSelected: disabled
                    ? null
                    : (_) {
                        onPartModeChanged(true);
                      },
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (customPart)
            TextFormField(
              key: const Key('general-part-name'),
              controller: nameController,
              enabled: !disabled,
              maxLength: 255,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: tr('part_name'),
                hintText: tr('part_name_hint'),
              ),
              onChanged: (_) => onChanged(),
              validator: (value) => value == null || value.trim().isEmpty
                  ? tr('part_required')
                  : value.trim().runes.length > 255
                  ? tr('part_too_long')
                  : null,
            )
          else
            OutlinedButton.icon(
              key: const Key('general-choose-part'),
              onPressed: disabled ? null : onChoosePart,
              icon: const Icon(Icons.search),
              label: Text(partName.isEmpty ? tr('choose_part') : partName),
            ),
          if (partError) GeneralRequestFeedback(message: tr('part_required')),
          const SizedBox(height: 20),
          TextFormField(
            key: const Key('general-description'),
            controller: descriptionController,
            enabled: !disabled,
            minLines: 3,
            maxLines: 5,
            maxLength: 1000,
            validator: (value) => (value?.trim().runes.length ?? 0) > 1000
                ? context.tr('part_request.notes_error')
                : null,
            onChanged: (_) => onChanged(),
            decoration: InputDecoration(
              labelText: tr('description'),
              hintText: tr('description_hint'),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 16),
          Text(tr('photos'), style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 4),
          Text(tr('photos_hint'), style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 12),
          GeneralRequestPhotos(
            photos: photos,
            onRemove: disabled ? null : onRemovePhoto,
          ),
          if (photos.length < 5)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: OutlinedButton.icon(
                key: const Key('general-add-photo'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(48, 48),
                ),
                onPressed: disabled ? null : onAddPhoto,
                icon: const Icon(Icons.add_photo_alternate_outlined),
                label: Text(
                  context.tr(
                    picking
                        ? 'part_request.photo_loading'
                        : 'part_request.add_photo',
                  ),
                ),
              ),
            ),
          if (photoError)
            GeneralRequestFeedback(
              message: context.tr('part_request.photo_error'),
            ),
        ],
      ),
    );
  }
}
