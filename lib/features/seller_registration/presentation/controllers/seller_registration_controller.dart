import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_failure.dart';
import '../../../../core/api/api_providers.dart';
import '../../../authentication/domain/entities/saudi_mobile_number.dart';
import '../../../authentication/domain/entities/session_outcome.dart';
import '../../../authentication/presentation/controllers/session_controller.dart';
import '../../data/data_sources/seller_registration_remote_data_source.dart';
import '../../data/repositories/seller_registration_repository_impl.dart';
import '../../domain/entities/seller_application.dart';
import '../../domain/repositories/seller_registration_repository.dart';
import '../../domain/use_cases/seller_registration_actions.dart';

final sellerRegistrationRepositoryProvider =
    Provider<SellerRegistrationRepository>(
      (ref) => SellerRegistrationRepositoryImpl(
        SellerRegistrationRemoteDataSource(ref.watch(apiClientProvider)),
      ),
    );

final sellerRegistrationActionsProvider = Provider(
  (ref) => SellerRegistrationActions(
    ref.watch(sellerRegistrationRepositoryProvider),
  ),
);

final sellerRegistrationControllerProvider = NotifierProvider.autoDispose
    .family<SellerRegistrationController, SellerRegistrationState, int>(
      SellerRegistrationController.new,
    );

class SellerRegistrationState {
  const SellerRegistrationState({
    this.application,
    this.loading = true,
    this.busy = false,
    this.error,
    this.uncertain = false,
    this.codeSent = false,
    this.verified = false,
    this.testCode,
    this.retryAt,
    this.loadFailed = false,
  });
  final SellerApplication? application;
  final bool loading, busy, uncertain, codeSent, verified, loadFailed;
  final ApiFailure? error;
  final String? testCode;
  final DateTime? retryAt;
  SellerRegistrationState copy({
    SellerApplication? application,
    bool? loading,
    bool? busy,
    ApiFailure? error,
    bool? uncertain,
    bool? codeSent,
    bool? verified,
    String? testCode,
    bool clearCode = false,
    DateTime? retryAt,
    bool? loadFailed,
  }) => SellerRegistrationState(
    application: application ?? this.application,
    loading: loading ?? this.loading,
    busy: busy ?? this.busy,
    error: error,
    uncertain: uncertain ?? this.uncertain,
    codeSent: codeSent ?? this.codeSent,
    verified: verified ?? this.verified,
    testCode: clearCode ? null : testCode ?? this.testCode,
    retryAt: retryAt ?? this.retryAt,
    loadFailed: loadFailed ?? this.loadFailed,
  );
}

class SellerRegistrationController extends Notifier<SellerRegistrationState> {
  SellerRegistrationController(this.userId);
  final int userId;
  String? _mobile, _token;
  DateTime? _verifiedAt;
  @override
  SellerRegistrationState build() => const SellerRegistrationState();
  AuthenticatedSession? get _session {
    final value = ref.read(sessionControllerProvider).asData?.value;
    return value is AuthenticatedSession && value.user.id == userId
        ? value
        : null;
  }

  bool _current(AuthenticatedSession? session) =>
      ref.mounted && session != null && identical(_session, session);
  ApiFailure _failure(Object error) =>
      error is ApiFailure ? error : const ApiFailure.unexpected();

  Future<void> load() async {
    if (state.busy) return;
    final session = _session;
    if (session == null) return;
    state = state.copy(loading: true, busy: true);
    try {
      final application = await ref
          .read(sellerRegistrationActionsProvider)
          .application();
      if (!_current(session)) return;
      _token = null;
      state = SellerRegistrationState(application: application, loading: false);
      if (application?.status == SellerApplicationStatus.accepted) {
        await ref.read(sessionControllerProvider.notifier).refreshProfile();
      }
    } catch (error) {
      if (_current(session)) {
        state = state.copy(
          loading: false,
          busy: false,
          loadFailed: true,
          error: _failure(error),
        );
      }
    }
  }

  void changeMobile() {
    if (state.busy) return;
    _mobile = null;
    _token = null;
    _verifiedAt = null;
    state = state.copy(codeSent: false, verified: false, clearCode: true);
  }

  Future<bool> sendCode(String input) async {
    if (state.loading || state.loadFailed || state.application != null) {
      return false;
    }
    if (state.busy ||
        state.uncertain ||
        (state.retryAt?.isAfter(DateTime.now()) ?? false)) {
      return false;
    }
    final session = _session;
    final mobile = SaudiMobileNumber.tryParse(input);
    if (session == null ||
        mobile == null ||
        mobile.nationalNumber ==
            SaudiMobileNumber.tryParse(session.user.mobile)?.nationalNumber) {
      state = state.copy(
        error: const ApiFailure(type: ApiFailureType.validation),
      );
      return false;
    }
    _token = null;
    _verifiedAt = null;
    _mobile = mobile.nationalNumber;
    state = state.copy(
      busy: true,
      verified: false,
      clearCode: true,
      retryAt: DateTime.now().add(const Duration(seconds: 60)),
    );
    try {
      final code = await ref
          .read(sellerRegistrationActionsProvider)
          .sendCode(_mobile!);
      if (!_current(session)) return false;
      state = state.copy(
        busy: false,
        codeSent: true,
        testCode: ref.read(appConfigurationProvider).allowsTestingOtp
            ? code
            : null,
      );
      return true;
    } catch (error) {
      if (_current(session)) {
        state = state.copy(busy: false, error: _failure(error));
      }
      return false;
    }
  }

  Future<bool> verify(String code) async {
    if (state.busy ||
        !state.codeSent ||
        _mobile == null ||
        !RegExp(r'^\d{4}$').hasMatch(code)) {
      return false;
    }
    final session = _session;
    if (session == null) return false;
    state = state.copy(busy: true);
    try {
      final token = await ref
          .read(sellerRegistrationActionsProvider)
          .verifyCode(_mobile!, code);
      if (!_current(session)) return false;
      _token = token;
      _verifiedAt = DateTime.now();
      state = state.copy(busy: false, verified: true, clearCode: true);
      return true;
    } catch (error) {
      if (_current(session)) {
        state = state.copy(busy: false, error: _failure(error));
      }
      return false;
    }
  }

  Future<bool> submit(SellerApplicationDraft draft) async {
    if (state.loading || state.loadFailed) return false;
    if (state.busy || state.uncertain) return false;
    final session = _session;
    if (session == null) return false;
    final previous = state.application;
    if (previous == null &&
        (_token == null ||
            _verifiedAt == null ||
            DateTime.now().difference(_verifiedAt!).inMinutes >= 25)) {
      _token = null;
      state = state.copy(
        verified: false,
        error: const ApiFailure(type: ApiFailureType.validation),
      );
      return false;
    }
    state = state.copy(busy: true);
    final link = ref.keepAlive();
    try {
      final saved = await ref
          .read(sellerRegistrationActionsProvider)
          .submit(draft, token: _token, previous: previous);
      if (!_current(session)) return false;
      _token = null;
      state = SellerRegistrationState(application: saved, loading: false);
      return true;
    } catch (error) {
      if (_current(session)) {
        final failure = _failure(error);
        final uncertain =
            failure.statusCode == 409 ||
            [
              ApiFailureType.timeout,
              ApiFailureType.noConnection,
              ApiFailureType.server,
              ApiFailureType.unexpected,
              ApiFailureType.forbidden,
            ].contains(failure.type);
        _token = null;
        state = state.copy(
          busy: false,
          verified: false,
          codeSent: false,
          clearCode: true,
          error: failure,
          uncertain: uncertain,
        );
      }
      return false;
    } finally {
      link.close();
    }
  }
}
