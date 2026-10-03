import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../core/widgets/authenticated_network_image.dart';

class OrderPhoto extends StatelessWidget {
  const OrderPhoto({required this.path, super.key});
  final String path;
  Widget _image(BuildContext context) => AuthenticatedNetworkImage(
    apiPath: path,
    fit: BoxFit.contain,
    semanticLabel: context.tr('orders.photo'),
    loadingBuilder: (_, child, progress) => progress == null
        ? child
        : const Center(child: CircularProgressIndicator()),
    errorBuilder: (_, _, _) => Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          context.tr('orders.photo_error'),
          textAlign: TextAlign.center,
        ),
      ),
    ),
  );
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(height: 220, child: _image(context)),
      ),
      TextButton.icon(
        icon: const Icon(Icons.zoom_in_rounded),
        label: Text(context.tr('orders.enlarge_photo')),
        onPressed: () => showDialog<void>(
          context: context,
          builder: (dialogContext) => Dialog.fullscreen(
            child: SafeArea(
              child: Column(
                children: [
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: IconButton(
                      tooltip: MaterialLocalizations.of(
                        dialogContext,
                      ).closeButtonTooltip,
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ),
                  Expanded(
                    child: InteractiveViewer(
                      minScale: 1,
                      maxScale: 4,
                      child: Center(child: _image(dialogContext)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ],
  );
}
