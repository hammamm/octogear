import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_failure.dart';
import '../../../../core/api/api_providers.dart';
import '../../../authentication/domain/entities/app_user.dart';
import '../../../authentication/domain/entities/session_outcome.dart';
import '../../../authentication/presentation/controllers/session_controller.dart';
import '../../data/data_sources/customer_profile_remote_data_source.dart';
import '../../data/repositories/customer_profile_repository_impl.dart';
import '../../domain/entities/update_customer_profile_command.dart';
import '../../domain/repositories/customer_profile_repository.dart';
import '../../domain/use_cases/update_customer_profile_use_case.dart';

final customerProfileRemoteDataSourceProvider =
    Provider<CustomerProfileRemoteDataSource>(
      (ref) =>
          CustomerProfileRemoteDataSourceImpl(ref.watch(apiClientProvider)),
    );
final customerProfileRepositoryProvider = Provider<CustomerProfileRepository>(
  (ref) => CustomerProfileRepositoryImpl(
    ref.watch(customerProfileRemoteDataSourceProvider),
  ),
);
final updateCustomerProfileProvider = Provider(
  (ref) => UpdateCustomerProfileUseCase(
    ref.watch(customerProfileRepositoryProvider),
  ),
);

class CustomerProfileState {
  const CustomerProfileState({this.saving = false, this.error});
  final bool saving;
  final ApiFailure? error;
}

final customerProfileControllerProvider = NotifierProvider.autoDispose
    .family<CustomerProfileController, CustomerProfileState, int>(
      CustomerProfileController.new,
    );

class CustomerProfileController extends Notifier<CustomerProfileState> {
  CustomerProfileController(this.userId);
  final int userId;

  @override
  CustomerProfileState build() => const CustomerProfileState();

  void clearError() {
    if (!state.saving) state = const CustomerProfileState();
  }

  Future<AppUser?> save(UpdateCustomerProfileCommand command) async {
    if (state.saving) return null;
    final session = ref.read(sessionControllerProvider).asData?.value;
    if (session is! AuthenticatedSession || session.user.id != userId) {
      return null;
    }
    final link = ref.keepAlive();
    state = const CustomerProfileState(saving: true);
    try {
      final saved = await ref.read(updateCustomerProfileProvider)(
        session.user,
        command,
      );
      if (!ref.mounted) return null;
      final applied = ref
          .read(sessionControllerProvider.notifier)
          .applyProfileUpdate(expected: session, user: saved);
      state = const CustomerProfileState();
      return applied ? saved : null;
    } catch (error) {
      if (ref.mounted) {
        state =
            identical(
              ref.read(sessionControllerProvider).asData?.value,
              session,
            )
            ? CustomerProfileState(
                error: error is ApiFailure
                    ? error
                    : const ApiFailure.unexpected(),
              )
            : const CustomerProfileState();
      }
      return null;
    } finally {
      link.close();
    }
  }
}
