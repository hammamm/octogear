import 'dart:ui' as ui show TextDirection;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/routing/app_routes.dart';
import '../../../../core/api/api_failure.dart';
import '../../../../core/design_system/octogear_theme.dart';
import '../../../../core/widgets/app_language_toggle_button.dart';
import '../../../../core/widgets/octogear_surface_card.dart';
import '../../domain/entities/customer_car.dart';
import '../controllers/customer_cars_controller.dart';

/// The customer's read-only saved-vehicle list.
///
/// Creation, editing, deletion, photo rendering, and vehicle selection are
/// intentionally separate slices. This screen is limited to a reliable view
/// of the vehicles that the authenticated customer already saved.
class CustomerCarsScreen extends ConsumerWidget {
  const CustomerCarsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cars = ref.watch(customerCarsControllerProvider);

    return RefreshIndicator(
      semanticsLabel: context.tr('customer_garage.cars.refresh_label'),
      onRefresh: () => _refresh(ref),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        slivers: [
          SliverPadding(
            padding: const EdgeInsetsDirectional.fromSTEB(20, 16, 20, 32),
            sliver: SliverMainAxisGroup(
              slivers: [
                SliverToBoxAdapter(child: _CustomerCarsHeader()),
                const SliverToBoxAdapter(
                  child: SizedBox(height: OctoGearSpacing.xLarge),
                ),
                cars.when(
                  loading: () =>
                      const SliverToBoxAdapter(child: _CustomerCarsLoading()),
                  error: (error, _) => SliverToBoxAdapter(
                    child: _CustomerCarsError(
                      message: _failureMessage(context, error),
                      onRetry: () => ref
                          .read(customerCarsControllerProvider.notifier)
                          .retry(),
                    ),
                  ),
                  data: (values) => values.isEmpty
                      ? const SliverToBoxAdapter(child: _CustomerCarsEmpty())
                      : SliverList.separated(
                          itemCount: values.length,
                          itemBuilder: (context, index) =>
                              _CustomerCarCard(car: values[index]),
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: OctoGearSpacing.medium),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _refresh(WidgetRef ref) async {
    try {
      await ref.read(customerCarsControllerProvider.notifier).retry();
    } catch (_) {
      // The provider exposes the failure state in the screen. RefreshIndicator
      // should finish cleanly rather than surface a second unhandled error.
    }
  }
}

class _CustomerCarsHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              onPressed: () => const CustomerAccountRoute().go(context),
              icon: const BackButtonIcon(),
            ),
            const Spacer(),
            const AppLanguageToggleButton(compact: true),
          ],
        ),
        const SizedBox(height: OctoGearSpacing.large),
        Semantics(
          header: true,
          child: Text(
            context.tr('customer_garage.cars.title'),
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
        const SizedBox(height: OctoGearSpacing.xSmall),
        Text(
          context.tr('customer_garage.cars.description'),
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: OctoGearColors.structuralGray),
        ),
      ],
    );
  }
}

class _CustomerCarsLoading extends StatelessWidget {
  const _CustomerCarsLoading();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: context.tr('customer_garage.cars.loading'),
      child: const ExcludeSemantics(
        child: Column(
          children: [
            _CustomerCarSkeleton(),
            SizedBox(height: OctoGearSpacing.medium),
            _CustomerCarSkeleton(),
            SizedBox(height: OctoGearSpacing.medium),
            _CustomerCarSkeleton(),
          ],
        ),
      ),
    );
  }
}

class _CustomerCarSkeleton extends StatelessWidget {
  const _CustomerCarSkeleton();

  @override
  Widget build(BuildContext context) {
    return const OctoGearSurfaceCard(
      child: Row(
        children: [
          _SkeletonBlock(height: 56, width: 56, circular: true),
          SizedBox(width: OctoGearSpacing.medium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SkeletonBlock(height: 18, width: 156),
                SizedBox(height: OctoGearSpacing.small),
                _SkeletonBlock(height: 14, width: 112),
                SizedBox(height: OctoGearSpacing.medium),
                _SkeletonBlock(height: 14, width: double.infinity),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SkeletonBlock extends StatelessWidget {
  const _SkeletonBlock({
    required this.height,
    required this.width,
    this.circular = false,
  });

  final double height;
  final double width;
  final bool circular;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: OctoGearColors.surfaceMuted,
        borderRadius: BorderRadius.circular(
          circular ? height / 2 : OctoGearRadii.small,
        ),
      ),
    );
  }
}

class _CustomerCarsEmpty extends StatelessWidget {
  const _CustomerCarsEmpty();

  @override
  Widget build(BuildContext context) {
    return OctoGearSurfaceCard(
      semanticLabel: context.tr('customer_garage.cars.empty_title'),
      child: Column(
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              color: OctoGearColors.yellowSoft,
              shape: BoxShape.circle,
            ),
            child: SizedBox(
              height: 72,
              width: 72,
              child: Icon(
                Icons.directions_car_outlined,
                size: 36,
                color: OctoGearColors.navy,
              ),
            ),
          ),
          const SizedBox(height: OctoGearSpacing.large),
          Text(
            context.tr('customer_garage.cars.empty_title'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: OctoGearSpacing.xSmall),
          Text(
            context.tr('customer_garage.cars.empty_description'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _CustomerCarsError extends StatelessWidget {
  const _CustomerCarsError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return OctoGearSurfaceCard(
      semanticLabel: context.tr('customer_garage.cars.error_title'),
      child: Column(
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              color: Color(0xFFFFF0EF),
              shape: BoxShape.circle,
            ),
            child: SizedBox(
              height: 56,
              width: 56,
              child: Icon(
                Icons.cloud_off_outlined,
                color: OctoGearColors.error,
                size: 28,
              ),
            ),
          ),
          const SizedBox(height: OctoGearSpacing.medium),
          Text(
            context.tr('customer_garage.cars.error_title'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: OctoGearSpacing.xSmall),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: OctoGearSpacing.large),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(context.tr('common.retry')),
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomerCarCard extends StatelessWidget {
  const _CustomerCarCard({required this.car});

  final CustomerCar car;

  @override
  Widget build(BuildContext context) {
    // A manufacturing year is a four-digit identifier, not a quantity. Format
    // it for the active locale without introducing a thousands separator.
    final year = NumberFormat(
      '0000',
      context.locale.languageCode,
    ).format(car.manufacturingYear);

    return OctoGearSurfaceCard(
      semanticLabel: car.carName.name,
      padding: const EdgeInsetsDirectional.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _CarIdentityIcon(),
              const SizedBox(width: OctoGearSpacing.medium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        car.carName.name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _CarDetailLine(
                      icon: Icons.calendar_today_outlined,
                      label: context.tr('customer_garage.cars.year_label'),
                      value: year,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: OctoGearSpacing.medium),
          const Divider(),
          const SizedBox(height: OctoGearSpacing.medium),
          _CarDetailLine(
            icon: Icons.palette_outlined,
            label: context.tr('customer_garage.cars.color_label'),
            value: car.color.name,
          ),
          const SizedBox(height: OctoGearSpacing.small),
          _CarDetailLine(
            icon: Icons.local_gas_station_outlined,
            label: context.tr('customer_garage.cars.fuel_type_label'),
            value: car.fuelType.name,
          ),
          const SizedBox(height: OctoGearSpacing.small),
          _CarDetailLine(
            icon: Icons.pin_outlined,
            label: context.tr('customer_garage.cars.plate_label'),
            value: car.licensePlateNumber,
            valueDirection: ui.TextDirection.ltr,
          ),
        ],
      ),
    );
  }
}

class _CarIdentityIcon extends StatelessWidget {
  const _CarIdentityIcon();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        color: OctoGearColors.yellowSoft,
        shape: BoxShape.circle,
      ),
      child: SizedBox(
        height: 56,
        width: 56,
        child: Icon(
          Icons.directions_car_outlined,
          size: 28,
          color: OctoGearColors.navy,
        ),
      ),
    );
  }
}

class _CarDetailLine extends StatelessWidget {
  const _CarDetailLine({
    required this.icon,
    required this.label,
    required this.value,
    this.valueDirection,
  });

  final IconData icon;
  final String label;
  final String value;
  final ui.TextDirection? valueDirection;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 19, color: OctoGearColors.structuralGray),
        const SizedBox(width: OctoGearSpacing.small),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: Theme.of(context).textTheme.bodyMedium,
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                WidgetSpan(
                  alignment: PlaceholderAlignment.baseline,
                  baseline: TextBaseline.alphabetic,
                  child: Directionality(
                    textDirection: valueDirection ?? Directionality.of(context),
                    child: Text(
                      value,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

String _failureMessage(BuildContext context, Object error) {
  if (error is! ApiFailure) return context.tr('errors.unexpected');

  final serverMessage = error.serverMessage?.trim();
  if (serverMessage != null && serverMessage.isNotEmpty) {
    return serverMessage;
  }

  return switch (error.type) {
    ApiFailureType.validation => context.tr('errors.validation'),
    ApiFailureType.rateLimited => context.tr('errors.rate_limited'),
    ApiFailureType.timeout => context.tr('errors.timeout'),
    ApiFailureType.noConnection => context.tr('errors.no_connection'),
    ApiFailureType.server => context.tr('errors.server'),
    ApiFailureType.forbidden => context.tr('customer_garage.cars.forbidden'),
    ApiFailureType.notFound => context.tr('customer_garage.cars.not_found'),
    _ => context.tr('errors.unexpected'),
  };
}
