import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/routing/app_routes.dart';
import '../../../../core/design_system/octogear_theme.dart';
import '../../../../core/widgets/app_language_toggle_button.dart';
import '../../../../core/widgets/octogear_surface_card.dart';
import '../customer_garage_failure_message.dart';
import '../controllers/customer_cars_controller.dart';
import '../widgets/customer_car_card.dart';

/// The customer’s saved-vehicle list and entry point to the Add Car child flow.
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
                SliverToBoxAdapter(
                  child: _CustomerCarsHeader(
                    onAddCar: () => _openAddCar(context, ref),
                  ),
                ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: OctoGearSpacing.xLarge),
                ),
                cars.when(
                  loading: () =>
                      const SliverToBoxAdapter(child: _CustomerCarsLoading()),
                  error: (error, _) => SliverToBoxAdapter(
                    child: _CustomerCarsError(
                      message: customerGarageFailureMessage(context, error),
                      onRetry: () => ref
                          .read(customerCarsControllerProvider.notifier)
                          .retry(),
                    ),
                  ),
                  data: (values) => values.isEmpty
                      ? SliverToBoxAdapter(
                          child: _CustomerCarsEmpty(
                            onAddCar: () => _openAddCar(context, ref),
                          ),
                        )
                      : SliverList.separated(
                          itemCount: values.length,
                          itemBuilder: (context, index) =>
                              CustomerCarCard(car: values[index]),
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

  Future<void> _openAddCar(BuildContext context, WidgetRef ref) async {
    final created = await const CreateCustomerCarRoute().push<bool>(context);
    if (created != true || !context.mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(context.tr('customer_garage.add.created'))),
      );

    try {
      await ref.read(customerCarsControllerProvider.notifier).retry();
    } catch (_) {
      // The already-visible list owns its retryable error state. Do not show a
      // second modal or erase the car the customer just saved.
    }
  }
}

class _CustomerCarsHeader extends StatelessWidget {
  const _CustomerCarsHeader({required this.onAddCar});

  final VoidCallback onAddCar;

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
        const SizedBox(height: OctoGearSpacing.large),
        FilledButton.icon(
          key: const Key('customer_cars_add_button'),
          onPressed: onAddCar,
          icon: const Icon(Icons.add_rounded),
          label: Text(context.tr('customer_garage.cars.add_car')),
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
  const _CustomerCarsEmpty({required this.onAddCar});

  final VoidCallback onAddCar;

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
          const SizedBox(height: OctoGearSpacing.large),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              key: const Key('customer_cars_empty_add_button'),
              onPressed: onAddCar,
              icon: const Icon(Icons.add_rounded),
              label: Text(context.tr('customer_garage.cars.add_car')),
            ),
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
