import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_failure.dart';
import '../../../../core/api/api_providers.dart';
import '../../../../core/localization/app_locale_controller.dart';
import '../../../storefront/domain/entities/storefront_car_catalog.dart';
import '../../data/data_sources/part_request_remote_data_source.dart';
import '../../data/repositories/part_request_repository_impl.dart';
import '../../domain/entities/part_request.dart';
import '../../domain/repositories/part_request_repository.dart';
import '../../domain/use_cases/send_part_request.dart';

final partRequestRepositoryProvider = Provider<PartRequestRepository>(
  (ref) => PartRequestRepositoryImpl(
    PartRequestRemoteDataSource(ref.watch(apiClientProvider)),
  ),
);
final sendPartRequestProvider = Provider(
  (ref) => SendPartRequest(ref.watch(partRequestRepositoryProvider)),
);
final requestComponentProvider = FutureProvider.autoDispose
    .family<StorefrontCarComponent, PartRequestKey>((ref, key) {
      ref.watch(appLocaleProvider);
      return ref.watch(partRequestRepositoryProvider).getComponent(key);
    }, retry: (_, _) => null);

class PartRequestState {
  const PartRequestState({
    this.submitting = false,
    this.receipt,
    this.error,
    this.retryCommand,
  });
  final bool submitting;
  final PartRequestReceipt? receipt;
  final ApiFailure? error;
  final PartRequestCommand? retryCommand;
  bool get locked => submitting || retryCommand != null || receipt != null;
}

final partRequestControllerProvider = NotifierProvider.autoDispose
    .family<PartRequestController, PartRequestState, PartRequestKey>(
      PartRequestController.new,
    );

class PartRequestController extends Notifier<PartRequestState> {
  PartRequestController(this.key);
  final PartRequestKey key;
  @override
  PartRequestState build() => const PartRequestState();

  void clearError() {
    if (!state.locked && state.error != null) state = const PartRequestState();
  }

  Future<void> submit(PartRequestCommand command) async {
    if (state.submitting || state.receipt != null) return;
    final request = state.retryCommand ?? command;
    if (request.componentId != key.componentId) return;
    final send = ref.read(sendPartRequestProvider);
    state = PartRequestState(submitting: true, retryCommand: request);
    try {
      final receipt = await send(request);
      if (!ref.mounted) return;
      state = PartRequestState(receipt: receipt);
    } catch (error) {
      if (!ref.mounted) return;
      final failure = error is ApiFailure
          ? error
          : const ApiFailure.unexpected();
      final definitelyRejected = switch (failure.type) {
        ApiFailureType.validation ||
        ApiFailureType.badRequest ||
        ApiFailureType.unauthorized ||
        ApiFailureType.forbidden ||
        ApiFailureType.notFound ||
        ApiFailureType.rateLimited => true,
        _ => false,
      };
      state = PartRequestState(
        error: failure,
        retryCommand: definitelyRejected ? null : request,
      );
    }
  }
}
