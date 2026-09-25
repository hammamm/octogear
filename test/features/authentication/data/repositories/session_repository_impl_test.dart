import 'package:flutter_test/flutter_test.dart';
import 'package:octogear/core/storage/app_storage.dart';
import 'package:octogear/features/authentication/data/data_sources/profile_remote_data_source.dart';
import 'package:octogear/features/authentication/data/models/current_user_dto.dart';
import 'package:octogear/features/authentication/data/repositories/session_repository_impl.dart';
import 'package:octogear/features/authentication/domain/entities/app_user.dart';

void main() {
  group('SessionRepositoryImpl', () {
    test(
      'maps and caches a safe shared profile after a successful read',
      () async {
        final cache = _FakeProfileCacheStorage();
        final repository = SessionRepositoryImpl(
          profileRemoteDataSource: _FakeProfileRemoteDataSource(
            _profileDto(type: 'customer'),
          ),
          profileCacheStorage: cache,
        );

        final user = await repository.getProfile();

        expect(user.role, AppUserRole.customer);
        expect(
          cache.cachedProfileJson,
          '{"id":7,"full_name":"Amina","type":"customer","city":{"id":3,"name":"Riyadh"}}',
        );
      },
    );

    test('maps the API service-provider value to the provider role', () async {
      final repository = SessionRepositoryImpl(
        profileRemoteDataSource: _FakeProfileRemoteDataSource(
          _profileDto(type: 'service provider'),
        ),
        profileCacheStorage: _FakeProfileCacheStorage(),
      );

      final user = await repository.getProfile();

      expect(user.role, AppUserRole.provider);
    });

    test('does not reject a valid profile when local caching fails', () async {
      final repository = SessionRepositoryImpl(
        profileRemoteDataSource: _FakeProfileRemoteDataSource(
          _profileDto(type: 'customer'),
        ),
        profileCacheStorage: _FakeProfileCacheStorage(failWrites: true),
      );

      await expectLater(repository.getProfile(), completion(isA<AppUser>()));
    });
  });
}

CurrentUserDto _profileDto({required String type}) {
  return CurrentUserDto.fromJson({
    'id': 7,
    'full_name': 'Amina',
    'mobile': '500000007',
    'type': type,
    'city': {'id': 3, 'name': 'Riyadh'},
  });
}

class _FakeProfileRemoteDataSource implements ProfileRemoteDataSource {
  const _FakeProfileRemoteDataSource(this.profile);

  final CurrentUserDto profile;

  @override
  Future<CurrentUserDto> fetchProfile() async => profile;
}

class _FakeProfileCacheStorage implements ProfileCacheStorage {
  _FakeProfileCacheStorage({this.failWrites = false});

  final bool failWrites;
  String? _cachedProfileJson;

  @override
  String? get cachedProfileJson => _cachedProfileJson;

  @override
  Future<void> clearCachedProfile() async {
    _cachedProfileJson = null;
  }

  @override
  Future<String?> readCachedProfileJson() async => _cachedProfileJson;

  @override
  Future<void> saveCachedProfileJson(String profileJson) async {
    if (failWrites) throw StateError('Preferences unavailable');
    _cachedProfileJson = profileJson;
  }
}
