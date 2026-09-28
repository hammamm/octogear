import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/design_system/octogear_theme.dart';
import '../../../../core/widgets/authenticated_network_image.dart';
import '../../domain/entities/storefront_store_details.dart';

/// Authenticated, same-origin gallery for public marketplace store pictures.
class StorefrontStoreGallery extends StatefulWidget {
  const StorefrontStoreGallery({required this.store, super.key});

  final StorefrontStoreDetails store;

  @override
  State<StorefrontStoreGallery> createState() => _StorefrontStoreGalleryState();
}

class _StorefrontStoreGalleryState extends State<StorefrontStoreGallery> {
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
  void didUpdateWidget(covariant StorefrontStoreGallery oldWidget) {
    super.didUpdateWidget(oldWidget);
    final lastValidIndex = widget.store.pictures.length - 1;
    if (lastValidIndex < 0 || _currentPage <= lastValidIndex) return;

    _currentPage = lastValidIndex;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _pageController.hasClients) {
        _pageController.jumpToPage(_currentPage);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final pictures = widget.store.pictures;
    if (pictures.isEmpty) return const _StoreGalleryFallback();

    final cacheWidth = (720 * MediaQuery.devicePixelRatioOf(context)).round();
    return Semantics(
      label: context.tr(
        'storefront.details.gallery_semantics',
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
                      'storefront.details.gallery_semantics',
                      args: ['${index + 1}', '${pictures.length}'],
                    ),
                    errorBuilder: (_, _, _) => const _StoreGalleryFallback(),
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return const _StoreGalleryLoading();
                    },
                  );
                },
              ),
              PositionedDirectional(
                top: OctoGearSpacing.small,
                end: OctoGearSpacing.small,
                child: _StoreGalleryCounter(
                  current: _currentPage + 1,
                  total: pictures.length,
                ),
              ),
              if (pictures.length > 1)
                Positioned(
                  bottom: OctoGearSpacing.small,
                  left: 0,
                  right: 0,
                  child: _StoreGalleryDots(
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

class _StoreGalleryFallback extends StatelessWidget {
  const _StoreGalleryFallback();

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: ColoredBox(
        color: OctoGearColors.yellowSoft,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.storefront_outlined,
                color: OctoGearColors.navy,
                size: 52,
              ),
              const SizedBox(height: OctoGearSpacing.small),
              Text(
                context.tr('storefront.details.no_gallery'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StoreGalleryLoading extends StatelessWidget {
  const _StoreGalleryLoading();

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

class _StoreGalleryCounter extends StatelessWidget {
  const _StoreGalleryCounter({required this.current, required this.total});

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
            '$current/$total',
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: Colors.white),
          ),
        ),
      ),
    );
  }
}

class _StoreGalleryDots extends StatelessWidget {
  const _StoreGalleryDots({required this.currentIndex, required this.count});

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
