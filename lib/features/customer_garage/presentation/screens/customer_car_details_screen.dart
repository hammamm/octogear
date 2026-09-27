import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routing/app_routes.dart';
import '../../../../core/api/api_failure.dart';
import '../../../../core/design_system/octogear_theme.dart';
import '../../../../core/widgets/app_language_toggle_button.dart';
import '../../../../core/widgets/octogear_surface_card.dart';
import '../../domain/entities/customer_car.dart';
import '../controllers/customer_car_detail_controller.dart';
import '../controllers/delete_customer_car_controller.dart';
import '../customer_garage_failure_message.dart';
import '../widgets/customer_car_information_card.dart';
import '../widgets/customer_car_photo_gallery.dart';

/// Shows the authoritative details, private gallery, and safe management
/// actions for one saved customer car.
class CustomerCarDetailsScreen extends ConsumerStatefulWidget {
  const CustomerCarDetailsScreen({required this.carId, super.key});

  final int carId;

  @override
  ConsumerState<CustomerCarDetailsScreen> createState() =>
      _CustomerCarDetailsScreenState();
}

class _CustomerCarDetailsScreenState
    extends ConsumerState<CustomerCarDetailsScreen> {
  var _awaitingDeleteReconciliation = false;

  @override
  Widget build(BuildContext context) {
    ref.listen<DeleteCustomerCarState>(deleteCustomerCarControllerProvider, (
      previous,
      next,
    ) {
      if (next.successfulDeletionCount >
              (previous?.successfulDeletionCount ?? 0) &&
          mounted) {
        context.pop(true);
      }
    });

    final details = ref.watch(customerCarDetailProvider(widget.carId));
    final deletion = ref.watch(deleteCustomerCarControllerProvider);

    return CustomScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      slivers: [
        SliverPadding(
          padding: const EdgeInsetsDirectional.fromSTEB(20, 16, 20, 32),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _CustomerCarDetailsHeader(onBack: () => context.pop(false)),
                const SizedBox(height: OctoGearSpacing.xLarge),
                details.when(
                  loading: () => const _CustomerCarDetailsLoading(),
                  error: (error, _) =>
                      _CustomerCarDetailsError(error: error, onRetry: _refresh),
                  data: (car) => _CustomerCarDetailsBody(
                    car: car,
                    deletion: deletion,
                    onEdit: deletion.isDeleting || deletion.error != null
                        ? null
                        : () => _openEdit(car),
                    onDelete: deletion.isDeleting || deletion.error != null
                        ? null
                        : () => _confirmDelete(car),
                    onRefreshAfterDeleteFailure: deletion.error == null
                        ? null
                        : _refresh,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _refresh() async {
    try {
      final _ = await ref.refresh(
        customerCarDetailProvider(widget.carId).future,
      );
      if (!mounted || !_awaitingDeleteReconciliation) {
        return;
      }

      setState(() => _awaitingDeleteReconciliation = false);
      ref.read(deleteCustomerCarControllerProvider.notifier).clearError();
    } on ApiFailure catch (error) {
      // A 404 after an uncertain DELETE confirms that Laravel completed the
      // removal. Return a changed result so the list refetches its source of
      // truth instead of continuing to show a stale card.
      if (_awaitingDeleteReconciliation &&
          error.type == ApiFailureType.notFound &&
          mounted) {
        context.pop(true);
      }
    } catch (_) {
      // The provider renders the safe retryable error state. The destructive
      // action remains blocked until a successful reconciliation.
    }
  }

  Future<void> _openEdit(CustomerCar car) async {
    final changed = await CustomerCarEditRoute(
      carId: car.id,
    ).push<bool>(context);
    if (changed != true || !mounted) {
      return;
    }

    ref.invalidate(customerCarDetailProvider(widget.carId));
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(context.tr('customer_garage.edit.saved'))),
      );
  }

  Future<void> _confirmDelete(CustomerCar car) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(dialogContext.tr('customer_garage.details.remove_title')),
        content: Text(
          dialogContext.tr(
            'customer_garage.details.remove_description',
            args: [car.carName.name],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(dialogContext.tr('common.cancel')),
          ),
          FilledButton(
            key: const Key('customer_car_confirm_delete_button'),
            style: FilledButton.styleFrom(
              backgroundColor: OctoGearColors.error,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              dialogContext.tr('customer_garage.details.remove_confirm'),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) {
      return;
    }
    await ref.read(deleteCustomerCarControllerProvider.notifier).delete(car.id);
    if (!mounted) {
      return;
    }

    if (ref.read(deleteCustomerCarControllerProvider).error != null) {
      setState(() => _awaitingDeleteReconciliation = true);
    }
  }
}

class _CustomerCarDetailsHeader extends StatelessWidget {
  const _CustomerCarDetailsHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              onPressed: onBack,
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
            context.tr('customer_garage.details.title'),
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
      ],
    );
  }
}

class _CustomerCarDetailsLoading extends StatelessWidget {
  const _CustomerCarDetailsLoading();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: context.tr('customer_garage.details.loading'),
      child: const ExcludeSemantics(
        child: Column(
          children: [
            _CustomerCarDetailsSkeleton(height: 250),
            SizedBox(height: OctoGearSpacing.large),
            _CustomerCarDetailsSkeleton(height: 290),
          ],
        ),
      ),
    );
  }
}

class _CustomerCarDetailsSkeleton extends StatelessWidget {
  const _CustomerCarDetailsSkeleton({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: OctoGearColors.surfaceMuted,
        borderRadius: BorderRadius.circular(OctoGearRadii.medium),
      ),
    );
  }
}

class _CustomerCarDetailsError extends StatelessWidget {
  const _CustomerCarDetailsError({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return OctoGearSurfaceCard(
      semanticLabel: context.tr('customer_garage.details.error_title'),
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
            context.tr('customer_garage.details.error_title'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: OctoGearSpacing.xSmall),
          Text(
            customerGarageFailureMessage(context, error),
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
          const SizedBox(height: OctoGearSpacing.small),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => const CustomerCarsRoute().go(context),
              child: Text(context.tr('customer_garage.details.back_to_cars')),
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomerCarDetailsBody extends StatelessWidget {
  const _CustomerCarDetailsBody({
    required this.car,
    required this.deletion,
    required this.onEdit,
    required this.onDelete,
    required this.onRefreshAfterDeleteFailure,
  });

  final CustomerCar car;
  final DeleteCustomerCarState deletion;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onRefreshAfterDeleteFailure;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          car.carName.name,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 2),
        Text(
          car.company.name,
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: OctoGearColors.structuralGray),
        ),
        const SizedBox(height: OctoGearSpacing.large),
        CustomerCarPhotoGallery(car: car),
        const SizedBox(height: OctoGearSpacing.large),
        CustomerCarInformationCard(car: car),
        if (deletion.error != null) ...[
          const SizedBox(height: OctoGearSpacing.large),
          OctoGearFeedbackBanner(
            message: customerGarageFailureMessage(context, deletion.error!),
            tone: OctoGearFeedbackTone.error,
          ),
          const SizedBox(height: OctoGearSpacing.small),
          Text(
            context.tr('customer_garage.details.remove_error_description'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (onRefreshAfterDeleteFailure != null) ...[
            const SizedBox(height: OctoGearSpacing.small),
            TextButton.icon(
              onPressed: onRefreshAfterDeleteFailure,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(context.tr('common.refresh')),
            ),
          ],
        ],
        const SizedBox(height: OctoGearSpacing.xLarge),
        FilledButton.icon(
          key: const Key('customer_car_edit_button'),
          onPressed: onEdit,
          icon: const Icon(Icons.edit_outlined),
          label: Text(context.tr('customer_garage.details.edit')),
        ),
        const SizedBox(height: OctoGearSpacing.small),
        OutlinedButton.icon(
          key: const Key('customer_car_delete_button'),
          onPressed: onDelete,
          style: OutlinedButton.styleFrom(
            foregroundColor: OctoGearColors.error,
            side: const BorderSide(color: OctoGearColors.error),
          ),
          icon: deletion.isDeleting
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.delete_outline_rounded),
          label: Text(context.tr('customer_garage.details.remove')),
        ),
      ],
    );
  }
}
