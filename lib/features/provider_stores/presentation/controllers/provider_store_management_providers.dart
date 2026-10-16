import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_failure.dart';
import '../../../../core/api/api_providers.dart';
import '../../../../core/localization/app_locale_controller.dart';
import '../../../authentication/domain/entities/app_user.dart';
import '../../../authentication/domain/entities/session_outcome.dart';
import '../../../authentication/presentation/controllers/session_controller.dart';
import '../../../provider_dashboard/presentation/controllers/provider_dashboard_providers.dart';
import '../../../seller_registration/domain/entities/seller_application.dart';
import '../../data/data_sources/provider_store_management_remote_data_source.dart';
import '../../data/repositories/provider_store_management_repository_impl.dart';
import '../../domain/entities/provider_store_management.dart';
import '../../domain/repositories/provider_store_management_repository.dart';
import '../../domain/use_cases/manage_provider_stores.dart';
import 'provider_stores_providers.dart';

final providerStoreManagementRepositoryProvider =
    Provider<ProviderStoreManagementRepository>(
      (ref) => ProviderStoreManagementRepositoryImpl(
        ProviderStoreManagementRemoteDataSource(ref.watch(apiClientProvider)),
      ),
    );
final manageProviderStoresProvider = Provider(
  (ref) => ManageProviderStores(
    ref.watch(providerStoreManagementRepositoryProvider),
  ),
);

void _watchOwner(Ref ref) {
  final session = ref.watch(sessionControllerProvider).asData?.value;
  ref.watch(appLocaleProvider);
  if (session is! AuthenticatedSession ||
      session.user.role != AppUserRole.provider) {
    throw const ApiFailure(type: ApiFailureType.unauthorized);
  }
}

final providerStoreDetailsProvider = FutureProvider.autoDispose
    .family<ProviderStoreDetails, int>((ref, id) {
      _watchOwner(ref);
      return ref.watch(manageProviderStoresProvider).store(id);
    }, retry: (_, _) => null);
final providerStoreApplicationsProvider =
    FutureProvider.autoDispose<List<SellerApplication>>((ref) {
      _watchOwner(ref);
      return ref.watch(manageProviderStoresProvider).applications();
    }, retry: (_, _) => null);
final providerStoreApplicationProvider = FutureProvider.autoDispose
    .family<SellerApplication, int>((ref, id) {
      _watchOwner(ref);
      return ref.watch(manageProviderStoresProvider).application(id);
    }, retry: (_, _) => null);

class StoreWriteState {
  const StoreWriteState({
    this.busy = false,
    this.uncertain = false,
    this.error,
  });
  final bool busy, uncertain;
  final ApiFailure? error;
}

final providerStoreWriteProvider = NotifierProvider.autoDispose
    .family<ProviderStoreWriteController, StoreWriteState, String>(
      ProviderStoreWriteController.new,
    );

class ProviderStoreWriteController extends Notifier<StoreWriteState> {
  ProviderStoreWriteController(this.formId);
  final String formId;
  @override
  StoreWriteState build() {
    ref.watch(sessionControllerProvider);
    return const StoreWriteState();
  }

  void clearError() {
    if (!state.busy && !state.uncertain) state = const StoreWriteState();
  }

  Future<int?> save(
    ProviderStoreDraft draft, {
    int? storeId,
    SellerApplication? application,
    required String requestKey,
  }) async {
    if (state.busy || state.uncertain) return null;
    final expected = ref.read(sessionControllerProvider).asData?.value;
    if (expected is! AuthenticatedSession ||
        expected.user.role != AppUserRole.provider) {
      return null;
    }
    final link = ref.keepAlive();
    state = const StoreWriteState(busy: true);
    try {
      final useCase = ref.read(manageProviderStoresProvider);
      final int id;
      if (storeId != null) {
        id = (await useCase.requestChange(storeId, draft, requestKey)).id;
      } else if (application != null) {
        id = (await useCase.resubmit(application, draft)).id;
      } else {
        id = (await useCase.submit(draft, requestKey, expected.user.mobile)).id;
      }
      if (!_same(expected)) return null;
      _invalidate(storeId: storeId, applicationId: id);
      state = const StoreWriteState();
      return id;
    } catch (error) {
      if (_same(expected)) {
        final failure = error is ApiFailure
            ? error
            : const ApiFailure.unexpected();
        state = StoreWriteState(
          error: failure,
          uncertain:
              failure.statusCode != 409 &&
              switch (failure.type) {
                ApiFailureType.timeout ||
                ApiFailureType.noConnection ||
                ApiFailureType.server ||
                ApiFailureType.unexpected => true,
                _ => false,
              },
        );
      }
      return null;
    } finally {
      link.close();
    }
  }

  /// Always read server truth before allowing another submission after an
  /// ambiguous response. This action never replays a write automatically.
  Future<int?> reconcile({
    int? storeId,
    int? applicationId,
    required String mobile,
    required String requestKey,
  }) async {
    if (state.busy || !state.uncertain) return null;
    final expected = ref.read(sessionControllerProvider).asData?.value;
    if (expected is! AuthenticatedSession ||
        expected.user.role != AppUserRole.provider) {
      return null;
    }
    final link = ref.keepAlive();
    state = const StoreWriteState(busy: true, uncertain: true);
    try {
      final useCase = ref.read(manageProviderStoresProvider);
      final int? id;
      if (storeId != null) {
        final items = await useCase.applications();
        id = items
            .where(
              (a) => a.storeId == storeId && a.idempotencyKey == requestKey,
            )
            .firstOrNull
            ?.id;
      } else if (applicationId != null) {
        id = (await useCase.application(applicationId)).id;
      } else {
        final items = await useCase.applications();
        id = items
            .where((a) => a.mobile == mobile && a.idempotencyKey == requestKey)
            .firstOrNull
            ?.id;
      }
      if (!_same(expected)) return null;
      _invalidate(storeId: storeId, applicationId: id);
      state = const StoreWriteState();
      return id;
    } catch (error) {
      if (_same(expected)) {
        state = StoreWriteState(
          uncertain: true,
          error: error is ApiFailure ? error : const ApiFailure.unexpected(),
        );
      }
      return null;
    } finally {
      link.close();
    }
  }

  bool _same(AuthenticatedSession expected) =>
      ref.mounted &&
      identical(ref.read(sessionControllerProvider).asData?.value, expected);
  void _invalidate({int? storeId, int? applicationId}) {
    ref.invalidate(providerStoresProvider);
    ref.invalidate(providerDashboardProvider);
    ref.invalidate(providerStoreApplicationsProvider);
    if (storeId != null) ref.invalidate(providerStoreDetailsProvider(storeId));
    if (applicationId != null) {
      ref.invalidate(providerStoreApplicationProvider(applicationId));
    }
  }
}
