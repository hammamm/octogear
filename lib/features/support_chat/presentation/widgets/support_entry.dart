import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/routing/app_routes.dart';
import '../../../../core/design_system/octogear_theme.dart';
import '../../../../core/widgets/octogear_menu_entry.dart';
import '../../../authentication/domain/entities/session_outcome.dart';
import '../../../authentication/domain/entities/app_user.dart';
import '../../../authentication/presentation/controllers/session_controller.dart';
import '../controllers/support_providers.dart';

void openSupport(BuildContext context, WidgetRef ref) {
  final session = ref.read(sessionControllerProvider).asData?.value;
  if (session is! AuthenticatedSession) return;
  if (session.user.role == AppUserRole.provider) {
    const ProviderSupportRoute().push<void>(context);
  } else {
    const CustomerSupportRoute().push<void>(context);
  }
}

class SupportButton extends ConsumerWidget {
  const SupportButton({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionControllerProvider).asData?.value;
    if (session is! AuthenticatedSession) return const SizedBox.shrink();
    final count = ref.watch(
      supportChatProvider.select((s) => s.conversation?.unread ?? 0),
    );
    return IconButton(
      key: const Key('support-button'),
      tooltip: count > 0
          ? context.tr(
              'support.unread',
              args: [
                NumberFormat.decimalPattern(
                  context.locale.languageCode,
                ).format(count),
              ],
            )
          : context.tr('support.title'),
      onPressed: () => openSupport(context, ref),
      icon: SupportBadge(count: count),
    );
  }
}

class SupportBadge extends StatelessWidget {
  const SupportBadge({required this.count, super.key});
  final int count;
  @override
  Widget build(BuildContext context) => Badge(
    isLabelVisible: count > 0,
    backgroundColor: OctoGearColors.navy,
    textColor: OctoGearColors.surface,
    label: Text(
      count > 99
          ? '99+'
          : NumberFormat.decimalPattern(
              context.locale.languageCode,
            ).format(count),
    ),
    child: const Icon(Icons.support_agent_rounded),
  );
}

class SupportMenuEntry extends ConsumerWidget {
  const SupportMenuEntry({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(
      supportChatProvider.select((s) => s.conversation?.unread ?? 0),
    );
    return OctoGearMenuEntry(
      leading: SupportBadge(count: count),
      title: context.tr('support.title'),
      subtitle: context.tr('support.menu_hint'),
      onTap: () => openSupport(context, ref),
    );
  }
}

class SupportSessionScope extends ConsumerWidget {
  const SupportSessionScope({required this.child, super.key});
  final Widget child;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(supportChatProvider);
    return child;
  }
}
