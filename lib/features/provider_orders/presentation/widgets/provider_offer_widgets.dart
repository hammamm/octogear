import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../core/api/api_failure.dart';
import '../../../../core/design_system/octogear_theme.dart';
import '../../../../core/widgets/octogear_surface_card.dart';
import '../../domain/entities/provider_offer.dart';

String offerMoney(BuildContext context, int minor) => NumberFormat.currency(
  locale: context.locale.toLanguageTag(),
  symbol: '${context.tr('storefront.car.sar')}\u00a0',
  decimalDigits: 2,
).format(minor / 100);
String offerStatus(BuildContext context, String status) => context.tr(
  'provider_offers.${switch (status) {
    'pending' => 'pending',
    'accepted' => 'accepted',
    'rejected' => 'rejected',
    'not_selected' => 'not_selected',
    _ => 'unknown',
  }}',
);
String offerFailure(BuildContext context, Object error) {
  if (error is ApiFailure) {
    return context.tr(switch (error.type) {
      ApiFailureType.unauthorized => 'provider_requests.unauthorized',
      ApiFailureType.forbidden ||
      ApiFailureType.notFound => 'provider_offers.unavailable',
      ApiFailureType.badRequest => 'provider_offers.changed',
      ApiFailureType.validation => 'provider_offers.invalid',
      ApiFailureType.noConnection => 'errors.no_connection',
      ApiFailureType.timeout => 'errors.timeout',
      ApiFailureType.rateLimited => 'errors.rate_limited',
      _ => 'provider_offers.failed',
    });
  }
  return context.tr('provider_offers.failed');
}

class ProviderOfferError extends StatelessWidget {
  const ProviderOfferError({
    required this.error,
    required this.retry,
    super.key,
  });
  final Object error;
  final VoidCallback retry;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(offerFailure(context, error), textAlign: TextAlign.center),
      const SizedBox(height: 8),
      OutlinedButton(onPressed: retry, child: Text(context.tr('common.retry'))),
    ],
  );
}

class ProviderOfferStatusBadge extends StatelessWidget {
  const ProviderOfferStatusBadge({required this.status, super.key});

  final String status;

  @override
  Widget build(BuildContext context) {
    final (accent, icon) = switch (status) {
      'accepted' => (OctoGearColors.success, Icons.check_circle_rounded),
      'pending' => (OctoGearColors.warning, Icons.schedule_rounded),
      'rejected' => (OctoGearColors.error, Icons.cancel_rounded),
      'not_selected' => (
        OctoGearColors.structuralGray,
        Icons.remove_circle_outline_rounded,
      ),
      _ => (OctoGearColors.structuralGray, Icons.help_outline_rounded),
    };
    // Darken the foreground so amber and green remain readable on pale fills.
    final foreground = Color.alphaBlend(
      Colors.black.withValues(alpha: 0.4),
      accent,
    );

    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.1),
          border: Border.all(color: accent.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(OctoGearRadii.small),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: foreground),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                offerStatus(context, status),
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProviderOfferCard extends StatelessWidget {
  const ProviderOfferCard({required this.offer, required this.open, super.key});
  final ProviderOffer offer;
  final VoidCallback open;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: OctoGearSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            offer.partName ?? context.tr('provider_requests.unnamed'),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Text(
            context.tr(
              'provider_requests.request_number',
              args: ['${offer.orderId}'],
            ),
          ),
          const SizedBox(height: 8),
          Text(offer.storeName),
          Text(
            offerMoney(context, offer.price),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          ProviderOfferStatusBadge(status: offer.status),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: open,
            child: Text(context.tr('provider_offers.view')),
          ),
        ],
      ),
    ),
  );
}
