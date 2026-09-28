import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/design_system/octogear_theme.dart';
import '../../../../core/widgets/authenticated_network_image.dart';
import '../../domain/entities/storefront_store_car.dart';

class StorefrontCarGallery extends StatefulWidget {
  const StorefrontCarGallery({required this.car, super.key});
  final StorefrontStoreCar car;
  @override
  State<StorefrontCarGallery> createState() => _StorefrontCarGalleryState();
}

class _StorefrontCarGalleryState extends State<StorefrontCarGallery> {
  final _controller = PageController();
  var _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant StorefrontCarGallery oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.car.id != widget.car.id ||
        _index >= widget.car.pictures.length) {
      _index = 0;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _controller.hasClients) _controller.jumpToPage(0);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final pictures = widget.car.pictures;
    final format = NumberFormat.decimalPattern(context.locale.toLanguageTag());
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(OctoGearRadii.medium),
          child: AspectRatio(
            aspectRatio: 16 / 10,
            child: pictures.isEmpty
                ? const _PhotoFallback()
                : PageView.builder(
                    key: PageStorageKey('car-gallery-${widget.car.id}'),
                    controller: _controller,
                    itemCount: pictures.length,
                    onPageChanged: (index) => setState(() => _index = index),
                    itemBuilder: (context, index) => AuthenticatedNetworkImage(
                      apiPath: pictures[index].url,
                      cacheWidth:
                          (MediaQuery.sizeOf(context).width *
                                  MediaQuery.devicePixelRatioOf(context))
                              .round(),
                      semanticLabel: context.tr(
                        'storefront.car.photo',
                        args: [
                          widget.car.carName.name,
                          format.format(index + 1),
                          format.format(pictures.length),
                        ],
                      ),
                      errorBuilder: (_, _, _) => const _PhotoFallback(),
                      loadingBuilder: (_, child, progress) => progress == null
                          ? child
                          : const ColoredBox(
                              color: OctoGearColors.surfaceMuted,
                              child: Center(child: CircularProgressIndicator()),
                            ),
                    ),
                  ),
          ),
        ),
        if (pictures.length > 1)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                tooltip: context.tr('storefront.car.previous_photo'),
                onPressed: _index == 0
                    ? null
                    : () => _controller.previousPage(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOut,
                      ),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              Flexible(
                child: Text(
                  context.tr(
                    'storefront.car.photo_count',
                    args: [
                      format.format(_index + 1),
                      format.format(pictures.length),
                    ],
                  ),
                ),
              ),
              IconButton(
                tooltip: context.tr('storefront.car.next_photo'),
                onPressed: _index == pictures.length - 1
                    ? null
                    : () => _controller.nextPage(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOut,
                      ),
                icon: const Icon(Icons.arrow_forward_rounded),
              ),
            ],
          ),
      ],
    );
  }
}

class _PhotoFallback extends StatelessWidget {
  const _PhotoFallback();
  @override
  Widget build(BuildContext context) => ColoredBox(
    color: OctoGearColors.yellowSoft,
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.directions_car_outlined,
            size: 54,
            color: OctoGearColors.navy,
          ),
          const SizedBox(height: 12),
          Text(
            context.tr('storefront.car.no_photos'),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}
