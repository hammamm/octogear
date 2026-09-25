import 'dart:async';

import '../../../../core/api/api_failure.dart';
import '../../../../core/service/device_token_reader.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/entities/otp_verification_result.dart';
import '../../domain/entities/saudi_mobile_number.dart';
import '../../domain/repositories/authentication_repository.dart';
import '../data_sources/authentication_remote_data_source.dart';

class AuthenticationRepositoryImpl implements AuthenticationRepository {
  const AuthenticationRepositoryImpl({
    required AuthenticationRemoteDataSource remoteDataSource,
    required DeviceTokenReader deviceTokenReader,
  }) : _remoteDataSource = remoteDataSource,
       _deviceTokenReader = deviceTokenReader;

  static const _deviceTokenReadTimeout = Duration(seconds: 3);

  final AuthenticationRemoteDataSource _remoteDataSource;
  final DeviceTokenReader _deviceTokenReader;

  @override
  Future<void> sendOtp(SaudiMobileNumber mobile) {
    return _remoteDataSource.sendOtp(mobile.nationalNumber);
  }

  @override
  Future<OtpVerificationResult> verifyOtp({
    required SaudiMobileNumber mobile,
    required String otp,
  }) async {
    try {
      final dto = await _remoteDataSource.verifyOtp(
        mobile: mobile.nationalNumber,
        otp: otp,
      );
      return dto.isNew
          ? NewAccountOtpResult(dto.temporaryRegistrationToken!)
          : ExistingAccountOtpResult(dto.accessToken!);
    } on ApiFailure {
      rethrow;
    } on FormatException {
      throw const ApiFailure.unexpected();
    }
  }

  @override
  Future<String> register({
    required String temporaryRegistrationToken,
    required String fullName,
    required int cityId,
  }) async {
    try {
      final deviceToken = await _readDeviceToken();
      final dto = await _remoteDataSource.register(
        temporaryRegistrationToken: temporaryRegistrationToken,
        fullName: fullName.trim(),
        cityId: cityId,
        deviceToken: deviceToken,
      );
      return dto.value;
    } on ApiFailure {
      rethrow;
    } on FormatException {
      throw const ApiFailure.unexpected();
    }
  }

  Future<String?> _readDeviceToken() async {
    try {
      return await _deviceTokenReader.read().timeout(_deviceTokenReadTimeout);
    } on TimeoutException {
      return null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<AppCity>> getRegistrationCities() async {
    try {
      final cities = await _remoteDataSource.fetchCities();
      return cities
          .map((city) => AppCity(id: city.id, name: city.name))
          .toList(growable: false);
    } on ApiFailure {
      rethrow;
    } on FormatException {
      throw const ApiFailure.unexpected();
    }
  }
}
