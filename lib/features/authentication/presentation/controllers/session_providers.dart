import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_providers.dart';
import '../../../../core/service/device_token_reader.dart';
import '../../../../core/storage/storage_providers.dart';
import '../../data/data_sources/authentication_remote_data_source.dart';
import '../../data/data_sources/profile_remote_data_source.dart';
import '../../data/repositories/authentication_repository_impl.dart';
import '../../data/repositories/session_repository_impl.dart';
import '../../domain/repositories/authentication_repository.dart';
import '../../domain/repositories/session_repository.dart';
import '../../domain/use_cases/get_registration_cities_use_case.dart';
import '../../domain/use_cases/register_use_case.dart';
import '../../domain/use_cases/restore_session_use_case.dart';
import '../../domain/use_cases/send_otp_use_case.dart';
import '../../domain/use_cases/sign_out_use_case.dart';
import '../../domain/use_cases/verify_otp_use_case.dart';

final authenticationRemoteDataSourceProvider =
    Provider<AuthenticationRemoteDataSource>((ref) {
      return AuthenticationRemoteDataSourceImpl(
        apiClient: ref.watch(apiClientProvider),
      );
    });

final authenticationRepositoryProvider = Provider<AuthenticationRepository>((
  ref,
) {
  return AuthenticationRepositoryImpl(
    remoteDataSource: ref.watch(authenticationRemoteDataSourceProvider),
    deviceTokenReader: ref.watch(deviceTokenReaderProvider),
  );
});

final sendOtpUseCaseProvider = Provider<SendOtpUseCase>((ref) {
  return SendOtpUseCase(ref.watch(authenticationRepositoryProvider));
});

final verifyOtpUseCaseProvider = Provider<VerifyOtpUseCase>((ref) {
  return VerifyOtpUseCase(
    repository: ref.watch(authenticationRepositoryProvider),
    sessionStorage: ref.watch(sessionStorageProvider),
  );
});

final registerUseCaseProvider = Provider<RegisterUseCase>((ref) {
  return RegisterUseCase(
    repository: ref.watch(authenticationRepositoryProvider),
    sessionStorage: ref.watch(sessionStorageProvider),
  );
});

final getRegistrationCitiesUseCaseProvider =
    Provider<GetRegistrationCitiesUseCase>((ref) {
      return GetRegistrationCitiesUseCase(
        ref.watch(authenticationRepositoryProvider),
      );
    });

final profileRemoteDataSourceProvider = Provider<ProfileRemoteDataSource>((
  ref,
) {
  return ProfileRemoteDataSourceImpl(apiClient: ref.watch(apiClientProvider));
});

final sessionRepositoryProvider = Provider<SessionRepository>((ref) {
  return SessionRepositoryImpl(
    profileRemoteDataSource: ref.watch(profileRemoteDataSourceProvider),
    profileCacheStorage: ref.watch(profileCacheStorageProvider),
  );
});

final restoreSessionUseCaseProvider = Provider<RestoreSessionUseCase>((ref) {
  return RestoreSessionUseCase(
    sessionStorage: ref.watch(sessionStorageProvider),
    sessionRepository: ref.watch(sessionRepositoryProvider),
  );
});

final signOutUseCaseProvider = Provider<SignOutUseCase>((ref) {
  return SignOutUseCase(ref.watch(sessionStorageProvider));
});
