import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/routing/app_routes.dart';
import '../../../../core/design_system/octogear_theme.dart';
import '../../../../core/widgets/app_language_toggle_button.dart';
import '../../../customer_orders/domain/entities/customer_order.dart';
import '../../../customer_orders/presentation/controllers/customer_orders_providers.dart';
import '../../../authentication/domain/entities/session_outcome.dart';
import '../../../authentication/presentation/controllers/session_controller.dart';
import '../widgets/home_promotions.dart';
import '../widgets/home_offers.dart';
import '../widgets/home_recent_requests.dart';
import '../../../customer_notifications/presentation/widgets/notification_entry.dart';

/// Entry point for requests and a compact summary of their latest status.
class CustomerHomeScreen extends ConsumerWidget {
  const CustomerHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(customerOrdersProvider(CustomerOrderFilter.all));
    final session = ref.watch(sessionControllerProvider).asData?.value;
    final name = session is AuthenticatedSession
        ? session.user.fullName.trim().split(RegExp(r'\s+')).first
        : '';
    final text = Theme.of(context).textTheme;
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: RefreshIndicator(
          onRefresh: () async {
            final provider = customerOrdersProvider(CustomerOrderFilter.all);
            try {
              ref.invalidate(provider);
              await ref.read(provider.future);
            } catch (_) {
              // The section displays the provider error and a retry action.
            }
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            key: const PageStorageKey('customer-tab-home'),
            padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 24),
            children: [
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      'assets/icons/app_icon.png',
                      width: 42,
                      height: 42,
                      semanticLabel: context.tr('app.name'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      context.tr(
                        name.isEmpty ? 'home.welcome' : 'home.greeting',
                        args: name.isEmpty ? [] : [name],
                      ),
                      style: text.titleMedium,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const NotificationBell(),
                  const AppLanguageToggleButton(compact: true),
                ],
              ),
              const SizedBox(height: 16),
              const HomePromotions(),
              const SizedBox(height: 8),
              const _RequestPanel(),
              const SizedBox(height: 24),
              if (orders.asData case final data?)
                HomeOffers(
                  key: ValueKey(context.locale.languageCode),
                  page: data.value.page,
                ),
              HomeRecentRequests(
                orders: orders,
                onRetry: () => ref.invalidate(
                  customerOrdersProvider(CustomerOrderFilter.all),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RequestPanel extends StatelessWidget {
  const _RequestPanel();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return DecoratedBox(
      key: const ValueKey('home-request-panel'),
      decoration: BoxDecoration(
        color: OctoGearColors.navy,
        borderRadius: BorderRadius.circular(OctoGearRadii.medium),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.all(OctoGearSpacing.medium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(
                context.tr('home.request_title'),
                style: text.titleMedium?.copyWith(
                  color: OctoGearColors.surface,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              context.tr('home.request_availability'),
              style: text.bodyMedium?.copyWith(color: OctoGearColors.surface),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: FilledButton.icon(
                key: const ValueKey('home-request-part'),
                onPressed: () =>
                    const GeneralPartRequestRoute().push<void>(context),
                style: FilledButton.styleFrom(
                  backgroundColor: OctoGearColors.yellow,
                  foregroundColor: OctoGearColors.navy,
                  minimumSize: const Size(48, 48),
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  textStyle: text.labelLarge?.copyWith(
                    fontSize: 14,
                    height: 1.4,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(OctoGearRadii.small),
                  ),
                ),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(
                  context.tr('home.request_action'),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
