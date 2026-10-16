import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/routing/app_routes.dart';
import '../../../account_profile/presentation/widgets/account_profile_editor.dart';
import '../../../authentication/domain/entities/app_user.dart';
import '../../../authentication/domain/entities/session_outcome.dart';
import '../../../authentication/presentation/controllers/session_controller.dart';
import '../../domain/entities/update_customer_profile_command.dart';
import '../controllers/customer_profile_controller.dart';

class CustomerProfileScreen extends ConsumerWidget {
  const CustomerProfileScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionControllerProvider).asData?.value;
    if (session is! AuthenticatedSession ||
        session.user.role != AppUserRole.customer) {
      return const SizedBox.shrink();
    }
    final state = ref.watch(customerProfileControllerProvider(session.user.id));
    final controller = ref.read(
      customerProfileControllerProvider(session.user.id).notifier,
    );
    return AccountProfileEditor(
      key: ValueKey(session.user.id),
      user: session.user,
      pageKey: 'customer-profile',
      titleKey: 'customer_more.profile',
      saving: state.saving,
      error: state.error,
      onClearError: controller.clearError,
      onSave: (name, city) => controller.save(
        UpdateCustomerProfileCommand(fullName: name, cityId: city),
      ),
      onExit: () {
        if (context.canPop()) {
          context.pop();
        } else {
          const CustomerMoreRoute().go(context);
        }
      },
    );
  }
}
