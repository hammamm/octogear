import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_failure.dart';
import '../../../../core/api/api_providers.dart';
import '../../../authentication/domain/entities/app_user.dart';
import '../../../authentication/domain/entities/session_outcome.dart';
import '../../../authentication/presentation/controllers/session_controller.dart';
import '../../data/data_sources/provider_profile_remote_data_source.dart';
import '../../data/repositories/provider_profile_repository_impl.dart';
import '../../domain/entities/update_provider_profile_command.dart';
import '../../domain/repositories/provider_profile_repository.dart';
import '../../domain/use_cases/update_provider_profile_use_case.dart';

final providerProfileRemoteDataSourceProvider =
    Provider<ProviderProfileRemoteDataSource>(
      (ref) =>
          ProviderProfileRemoteDataSourceImpl(ref.watch(apiClientProvider)),
    );
final providerProfileRepositoryProvider = Provider<ProviderProfileRepository>(
  (ref) => ProviderProfileRepositoryImpl(
    ref.watch(providerProfileRemoteDataSourceProvider),
  ),
);
final updateProviderProfileProvider = Provider(
  (ref) => UpdateProviderProfileUseCase(
    ref.watch(providerProfileRepositoryProvider),
  ),
);

class ProviderProfileState {
  const ProviderProfileState({this.saving = false, this.error});
  final bool saving;
  final ApiFailure? error;
}

final providerProfileControllerProvider = NotifierProvider.autoDispose
    .family<ProviderProfileController, ProviderProfileState, int>(
      ProviderProfileController.new,
    );

class ProviderProfileController extends Notifier<ProviderProfileState> {
  ProviderProfileController(this.userId);
  final int userId;

  @override
  ProviderProfileState build() => const ProviderProfileState();

  void clearError() {
    if (!state.saving) state = const ProviderProfileState();
  }

  Future<AppUser?> save(UpdateProviderProfileCommand command) async {
    if (state.saving) return null;
    final session = ref.read(sessionControllerProvider).asData?.value;
    if (session is! AuthenticatedSession || session.user.id != userId) {
      return null;
    }
    final link = ref.keepAlive();
    state = const ProviderProfileState(saving: true);
    try {
      final saved = await ref.read(updateProviderProfileProvider)(
        session.user,
        command,
      );
      if (!ref.mounted) return null;
      final applied = ref
          .read(sessionControllerProvider.notifier)
          .applyProfileUpdate(expected: session, user: saved);
      state = const ProviderProfileState();
      return applied ? saved : null;
    } catch (error) {
      if (ref.mounted) {
        state =
            identical(
              ref.read(sessionControllerProvider).asData?.value,
              session,
            )
            ? ProviderProfileState(
                error: error is ApiFailure
                    ? error
                    : const ApiFailure.unexpected(),
              )
            : const ProviderProfileState();
      }
      return null;
    } finally {
      link.close();
    }
  }
}
