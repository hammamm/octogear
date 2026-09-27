import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/design_system/octogear_theme.dart';
import '../../../../core/widgets/authenticated_network_image.dart';
import '../../domain/entities/customer_car.dart';

/// Full, bearer-authenticated gallery for the private pictures of one car.
class CustomerCarPhotoGallery extends StatefulWidget {
  const CustomerCarPhotoGallery({required this.car, super.key});

  final CustomerCar car;

  @override
  State<CustomerCarPhotoGallery> createState() =>
      _CustomerCarPhotoGalleryState();
}

class _CustomerCarPhotoGalleryState extends State<CustomerCarPhotoGallery> {
  late final PageController _pageController;
  var _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant CustomerCarPhotoGallery oldWidget) {
    super.didUpdateWidget(oldWidget);

    final lastValidIndex = widget.car.pictures.length - 1;
    if (lastValidIndex < 0 || _currentPage <= lastValidIndex) {
      return;
    }

    _currentPage = lastValidIndex;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _pageController.hasClients) {
        _pageController.jumpToPage(_currentPage);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final pictures = widget.car.pictures;
    if (pictures.isEmpty) return const _CustomerCarGalleryEmpty();

    final cacheWidth = (720 * MediaQuery.devicePixelRatioOf(context)).round();
    return Semantics(
      label: context.tr(
        'customer_garage.details.photo_semantics',
        args: ['${_currentPage + 1}', '${pictures.length}'],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(OctoGearRadii.medium),
        child: AspectRatio(
          aspectRatio: 4 / 3,
          child: Stack(
            fit: StackFit.expand,
            children: [
              PageView.builder(
                controller: _pageController,
                itemCount: pictures.length,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemBuilder: (context, index) {
                  final picture = pictures[index];
                  return AuthenticatedNetworkImage(
                    apiPath: picture.url,
                    cacheWidth: cacheWidth,
                    semanticLabel: context.tr(
                      'customer_garage.details.photo_semantics',
                      args: ['${index + 1}', '${pictures.length}'],
                    ),
                    errorBuilder: (_, _, _) => const _CustomerCarGalleryEmpty(),
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const _CustomerCarGalleryLoading();
                    },
                  );
                },
              ),
              PositionedDirectional(
                top: OctoGearSpacing.small,
                end: OctoGearSpacing.small,
                child: _CustomerCarPhotoCounter(
                  current: _currentPage + 1,
                  total: pictures.length,
                ),
              ),
              if (pictures.length > 1)
                Positioned(
                  bottom: OctoGearSpacing.small,
                  left: 0,
                  right: 0,
                  child: _CustomerCarPhotoDots(
                    currentIndex: _currentPage,
                    count: pictures.length,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CustomerCarGalleryEmpty extends StatelessWidget {
  const _CustomerCarGalleryEmpty();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: OctoGearColors.yellowSoft,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.directions_car_outlined,
              color: OctoGearColors.navy,
              size: 52,
            ),
            const SizedBox(height: OctoGearSpacing.small),
            Text(
              context.tr('customer_garage.details.no_photo'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomerCarGalleryLoading extends StatelessWidget {
  const _CustomerCarGalleryLoading();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: OctoGearColors.surfaceMuted,
      child: Center(
        child: SizedBox(
          height: 34,
          width: 34,
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
      ),
    );
  }
}

class _CustomerCarPhotoCounter extends StatelessWidget {
  const _CustomerCarPhotoCounter({required this.current, required this.total});

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: OctoGearColors.navy.withValues(alpha: .86),
          borderRadius: BorderRadius.circular(OctoGearRadii.pill),
        ),
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: OctoGearSpacing.small,
            vertical: 6,
          ),
          child: Text(
            context.tr(
              'customer_garage.details.photo_counter',
              args: ['$current', '$total'],
            ),
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: Colors.white),
          ),
        ),
      ),
    );
  }
}

class _CustomerCarPhotoDots extends StatelessWidget {
  const _CustomerCarPhotoDots({
    required this.currentIndex,
    required this.count,
  });

  final int currentIndex;
  final int count;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var index = 0; index < count; index++)
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsetsDirectional.symmetric(horizontal: 3),
              height: 7,
              width: index == currentIndex ? 20 : 7,
              decoration: BoxDecoration(
                color: index == currentIndex
                    ? OctoGearColors.yellow
                    : Colors.white.withValues(alpha: .72),
                borderRadius: BorderRadius.circular(OctoGearRadii.pill),
              ),
            ),
        ],
      ),
    );
  }
}
