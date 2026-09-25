import 'package:flutter_test/flutter_test.dart';
import 'package:octogear/core/service/device_token_reader.dart';
import 'package:octogear/features/authentication/data/data_sources/authentication_remote_data_source.dart';
import 'package:octogear/features/authentication/data/models/authentication_dtos.dart';
import 'package:octogear/features/authentication/data/models/current_user_dto.dart';
import 'package:octogear/features/authentication/data/repositories/authentication_repository_impl.dart';

void main() {
  group('AuthenticationRepositoryImpl.register', () {
    test('passes the captured device token to registration', () async {
      final dataSource = _CapturingDataSource();
      final repository = AuthenticationRepositoryImpl(
        remoteDataSource: dataSource,
        deviceTokenReader: _FakeDeviceTokenReader(() async => 'fcm-token'),
      );

      final accessToken = await repository.register(
        temporaryRegistrationToken: 'temporary-token',
        fullName: 'Amina',
        cityId: 3,
      );

      expect(accessToken, 'access-token');
      expect(dataSource.deviceToken, 'fcm-token');
    });

    test('does not block registration when the token reader fails', () async {
      final dataSource = _CapturingDataSource();
      final repository = AuthenticationRepositoryImpl(
        remoteDataSource: dataSource,
        deviceTokenReader: _FakeDeviceTokenReader(
          () async => throw StateError('Firebase unavailable'),
        ),
      );

      final accessToken = await repository.register(
        temporaryRegistrationToken: 'temporary-token',
        fullName: 'Amina',
        cityId: 3,
      );

      expect(accessToken, 'access-token');
      expect(dataSource.deviceToken, isNull);
    });
  });
}

class _FakeDeviceTokenReader implements DeviceTokenReader {
  const _FakeDeviceTokenReader(this._read);

  final Future<String?> Function() _read;

  @override
  Future<String?> read() => _read();
}

class _CapturingDataSource implements AuthenticationRemoteDataSource {
  String? deviceToken;

  @override
  Future<AccessTokenDto> register({
    required String temporaryRegistrationToken,
    required String fullName,
    required int cityId,
    required String? deviceToken,
  }) async {
    this.deviceToken = deviceToken;
    return const AccessTokenDto('access-token');
  }

  @override
  Future<List<CityDto>> fetchCities() => throw UnimplementedError();

  @override
  Future<void> sendOtp(String mobile) => throw UnimplementedError();

  @override
  Future<OtpVerificationDto> verifyOtp({
    required String mobile,
    required String otp,
  }) => throw UnimplementedError();
}
