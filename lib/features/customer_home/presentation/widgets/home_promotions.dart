import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/design_system/octogear_theme.dart';

/// Finished, owner-supplied artwork. Never mirror images containing text.
/// Both languages use their own complete set of three banners.
class HomePromotions extends StatelessWidget {
  const HomePromotions({super.key});

  @override
  Widget build(BuildContext context) {
    final language = context.locale.languageCode;
    return _PromotionCarousel(
      key: ValueKey(language),
      language: language,
      slides: const ['parts', 'details', 'offers'],
    );
  }
}

class _PromotionCarousel extends StatefulWidget {
  const _PromotionCarousel({
    required this.language,
    required this.slides,
    super.key,
  });
  final String language;
  final List<String> slides;

  @override
  State<_PromotionCarousel> createState() => _PromotionCarouselState();
}

class _PromotionCarouselState extends State<_PromotionCarousel> {
  // Start with the first banner when changing language.
  final _controller = PageController(keepPage: false);
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _select(int page) async {
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.jumpToPage(page);
    } else {
      await _controller.animateToPage(
        page,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    }
  }

  String _asset(String slide) =>
      'assets/images/home/$slide-${widget.language}.png';

  String _description(BuildContext context, String slide) =>
      '${context.tr('home.slides.$slide.title')} ${context.tr('home.slides.$slide.description')}';

  @override
  Widget build(BuildContext context) => Column(
    children: [
      AspectRatio(
        aspectRatio: 2,
        child: PageView.builder(
          key: const ValueKey('home-promotions'),
          controller: _controller,
          itemCount: widget.slides.length,
          onPageChanged: (page) => setState(() => _page = page),
          itemBuilder: (context, index) {
            final slide = widget.slides[index];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Semantics(
                image: true,
                label:
                    '${context.tr('home.slide_position', args: ['${index + 1}', '${widget.slides.length}'])}. ${_description(context, slide)}',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(OctoGearRadii.small),
                  child: Image.asset(
                    _asset(slide),
                    key: ValueKey('home-banner-${widget.language}-$slide'),
                    fit: BoxFit.contain,
                    excludeFromSemantics: true,
                    // Artwork contains text: never flip it for RTL.
                    matchTextDirection: false,
                  ),
                ),
              ),
            );
          },
        ),
      ),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            tooltip: context.tr('home.previous_slide'),
            onPressed: _page > 0 ? () => _select(_page - 1) : null,
            style: IconButton.styleFrom(shape: const CircleBorder()),
            icon: const Icon(Icons.arrow_back_rounded, size: 20),
          ),
          for (var index = 0; index < widget.slides.length; index++)
            Semantics(
              selected: _page == index,
              child: IconButton(
                tooltip: context.tr(
                  'home.slide_position',
                  args: ['${index + 1}', '${widget.slides.length}'],
                ),
                onPressed: () => _select(index),
                style: IconButton.styleFrom(shape: const CircleBorder()),
                icon: Container(
                  width: _page == index ? 22 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: _page == index
                        ? OctoGearColors.navy
                        : OctoGearColors.structuralGray,
                    borderRadius: BorderRadius.circular(OctoGearRadii.pill),
                  ),
                ),
              ),
            ),
          IconButton(
            tooltip: context.tr('home.next_slide'),
            onPressed: _page < widget.slides.length - 1
                ? () => _select(_page + 1)
                : null,
            style: IconButton.styleFrom(shape: const CircleBorder()),
            icon: const Icon(Icons.arrow_forward_rounded, size: 20),
          ),
        ],
      ),
    ],
  );
}
