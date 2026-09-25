import '../../../../core/api/api_failure.dart';
import '../../../../core/storage/app_storage.dart';
import '../data_sources/profile_remote_data_source.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/session_repository.dart';
import '../models/current_user_dto.dart';

class SessionRepositoryImpl implements SessionRepository {
  const SessionRepositoryImpl({
    required ProfileRemoteDataSource profileRemoteDataSource,
    required ProfileCacheStorage profileCacheStorage,
  }) : _profileRemoteDataSource = profileRemoteDataSource,
       _profileCacheStorage = profileCacheStorage;

  final ProfileRemoteDataSource _profileRemoteDataSource;
  final ProfileCacheStorage _profileCacheStorage;

  @override
  Future<AppUser> getProfile() async {
    final dto = await _profileRemoteDataSource.fetchProfile();

    try {
      final user = dto.toEntity();
      await _cacheProfile(dto);
      return user;
    } on FormatException {
      throw const ApiFailure.unexpected();
    }
  }

  Future<void> _cacheProfile(CurrentUserDto profile) async {
    try {
      await _profileCacheStorage.saveCachedProfileJson(profile.toCacheJson());
    } catch (_) {
      // Caching improves the next render but must never reject a valid server
      // session when the preferences backend is temporarily unavailable.
    }
  }
}
