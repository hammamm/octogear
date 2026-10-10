import 'package:flutter_test/flutter_test.dart';
import 'package:octogear/core/api/api_failure.dart';
import 'package:octogear/features/authentication/data/data_sources/authentication_remote_data_source.dart';
import 'package:octogear/features/authentication/data/models/authentication_dtos.dart';

import 'package:octogear/features/authentication/data/repositories/authentication_repository_impl.dart';

void main() {
  group('AuthenticationRepositoryImpl.register', () {
    test(
      'registers with a trimmed name without Firebase dependencies',
      () async {
        final dataSource = _CapturingDataSource();
        final repository = AuthenticationRepositoryImpl(
          remoteDataSource: dataSource,
        );

        final accessToken = await repository.register(
          temporaryRegistrationToken: 'temporary-token',
          fullName: '  Amina  ',
          cityId: 3,
        );

        expect(accessToken, 'access-token');
        expect(dataSource.registration, ('temporary-token', 'Amina', 3));
      },
    );

    test('maps malformed registration responses to an API failure', () async {
      final dataSource = _CapturingDataSource(malformedResponse: true);
      final repository = AuthenticationRepositoryImpl(
        remoteDataSource: dataSource,
      );

      await expectLater(
        repository.register(
          temporaryRegistrationToken: 'temporary-token',
          fullName: 'Amina',
          cityId: 3,
        ),
        throwsA(isA<ApiFailure>()),
      );
    });
  });
}

class _CapturingDataSource implements AuthenticationRemoteDataSource {
  _CapturingDataSource({this.malformedResponse = false});

  final bool malformedResponse;
  (String, String, int)? registration;

  @override
  Future<AccessTokenDto> register({
    required String temporaryRegistrationToken,
    required String fullName,
    required int cityId,
  }) async {
    registration = (temporaryRegistrationToken, fullName, cityId);
    if (malformedResponse) throw const FormatException('Invalid response');
    return const AccessTokenDto('access-token');
  }

  @override
  Future<CityPageDto> fetchCities({String search = '', int page = 1}) =>
      throw UnimplementedError();

  @override
  Future<String?> sendOtp(String mobile) => throw UnimplementedError();

  @override
  Future<OtpVerificationDto> verifyOtp({
    required String mobile,
    required String otp,
  }) => throw UnimplementedError();
}
