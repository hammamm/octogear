import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_failure.dart';
import '../../../../core/api/api_providers.dart';
import '../../../../core/localization/app_locale_controller.dart';
import '../../data/data_sources/general_request_remote_data_source.dart';
import '../../data/repositories/general_request_repository_impl.dart';
import '../../domain/entities/general_request.dart';
import '../../domain/repositories/general_request_repository.dart';
import '../../domain/use_cases/get_request_components_use_case.dart';
import '../../domain/use_cases/send_general_request.dart';

final generalRequestRepositoryProvider = Provider<GeneralRequestRepository>(
  (ref) => GeneralRequestRepositoryImpl(
    GeneralRequestRemoteDataSource(ref.watch(apiClientProvider)),
  ),
);
final sendGeneralRequestProvider = Provider(
  (ref) => SendGeneralRequest(ref.watch(generalRequestRepositoryProvider)),
);
final getRequestComponentsProvider = Provider(
  (ref) =>
      GetRequestComponentsUseCase(ref.watch(generalRequestRepositoryProvider)),
);

final localizedRequestComponentProvider = FutureProvider.autoDispose
    .family<RequestComponent?, RequestComponent>((ref, selected) async {
      ref.watch(appLocaleProvider);
      final result = await ref
          .read(getRequestComponentsProvider)
          .call(
            search: String.fromCharCodes(selected.name.runes.take(100)),
            page: 1,
          );
      return result.items.where((item) => item.id == selected.id).firstOrNull;
    }, retry: (_, _) => null);

class GeneralRequestState {
  const GeneralRequestState({
    this.submitting = false,
    this.orderId,
    this.error,
    this.retryCommand,
  });
  final bool submitting;
  final int? orderId;
  final ApiFailure? error;
  final GeneralRequestCommand? retryCommand;
  bool get locked => submitting || retryCommand != null || orderId != null;
}

final generalRequestControllerProvider = NotifierProvider.autoDispose
    .family<GeneralRequestController, GeneralRequestState, String>(
      GeneralRequestController.new,
    );

class GeneralRequestController extends Notifier<GeneralRequestState> {
  GeneralRequestController(this.draftId);
  final String draftId;
  @override
  GeneralRequestState build() => const GeneralRequestState();
  void clearError() {
    if (!state.locked) state = const GeneralRequestState();
  }

  Future<void> submit(GeneralRequestCommand command) async {
    if (state.submitting ||
        state.orderId != null ||
        state.error?.statusCode == 409) {
      return;
    }
    final snapshot = state.retryCommand ?? command;
    final send = ref.read(sendGeneralRequestProvider);
    state = GeneralRequestState(submitting: true, retryCommand: snapshot);
    try {
      final id = await send(snapshot);
      if (ref.mounted) state = GeneralRequestState(orderId: id);
    } catch (error) {
      if (!ref.mounted) return;
      final failure = error is ApiFailure
          ? error
          : const ApiFailure.unexpected();
      final rejected = switch (failure.type) {
        ApiFailureType.validation ||
        ApiFailureType.badRequest ||
        ApiFailureType.unauthorized ||
        ApiFailureType.forbidden ||
        ApiFailureType.notFound ||
        ApiFailureType.rateLimited => true,
        _ => false,
      };
      state = GeneralRequestState(
        error: failure,
        retryCommand: rejected ? null : snapshot,
      );
    }
  }
}
