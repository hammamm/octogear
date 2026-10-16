import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../app/routing/app_routes.dart';
import '../../../../core/widgets/authenticated_network_image.dart';
import '../../../../core/widgets/octogear_surface_card.dart';
import '../../../authentication/presentation/widgets/authentication_failure_text.dart';
import '../../../seller_registration/domain/entities/seller_application.dart';

class StoreLoadFailure extends StatelessWidget {
  const StoreLoadFailure({
    required this.error,
    required this.onRetry,
    super.key,
  });
  final Object error;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => OctoGearSurfaceCard(
    child: Column(
      children: [
        const Icon(Icons.cloud_off_outlined, size: 36),
        const SizedBox(height: 12),
        Text(
          authenticationFailureText(context, error),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
          label: Text(context.tr('common.retry')),
        ),
      ],
    ),
  );
}

class StoreApplicationBadge extends StatelessWidget {
  const StoreApplicationBadge({required this.status, super.key});
  final SellerApplicationStatus status;
  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (status) {
      SellerApplicationStatus.accepted => (
        const Color(0xFF17613C),
        Icons.check_circle_outline,
      ),
      SellerApplicationStatus.pending => (
        const Color(0xFF785300),
        Icons.schedule,
      ),
      SellerApplicationStatus.rejected => (
        Theme.of(context).colorScheme.error,
        Icons.error_outline,
      ),
    };
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .09),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                context.tr('store_management.${status.name}'),
                style: TextStyle(color: color, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StoreInformation extends StatelessWidget {
  const StoreInformation({required this.label, required this.value, super.key});
  final String label, value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(context.tr(label), style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 6),
        SelectableText(value),
      ],
    ),
  );
}

class StorePrivateImage extends StatelessWidget {
  const StorePrivateImage({
    required this.path,
    required this.label,
    this.height = 180,
    super.key,
  });
  final String path, label;
  final double height;
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(16),
    child: AuthenticatedNetworkImage(
      apiPath: path,
      height: height,
      width: double.infinity,
      fit: BoxFit.contain,
      semanticLabel: context.tr(label),
      errorBuilder: (_, _, _) => SizedBox(
        height: height,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.broken_image_outlined),
              Text(
                context.tr('store_management.image_unavailable'),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class StorePendingChangeNotice extends StatelessWidget {
  const StorePendingChangeNotice({required this.requestId, super.key});
  final int requestId;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const StoreApplicationBadge(status: SellerApplicationStatus.pending),
      const SizedBox(height: 12),
      Text(context.tr('store_management.pending_change')),
      const SizedBox(height: 12),
      OutlinedButton.icon(
        key: const Key('store-pending-change'),
        onPressed: () => ProviderStoreApplicationRoute(
          requestId: requestId,
        ).push<void>(context),
        icon: const Icon(Icons.visibility_outlined),
        label: Text(context.tr('store_management.view_change')),
      ),
    ],
  );
}
