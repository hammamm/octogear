import '../../../../core/api/api_failure.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/entities/otp_verification_result.dart';
import '../../domain/entities/saudi_mobile_number.dart';
import '../../domain/repositories/authentication_repository.dart';
import '../data_sources/authentication_remote_data_source.dart';

class AuthenticationRepositoryImpl implements AuthenticationRepository {
  const AuthenticationRepositoryImpl({
    required AuthenticationRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  final AuthenticationRemoteDataSource _remoteDataSource;

  @override
  Future<String?> sendOtp(SaudiMobileNumber mobile) {
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
      final dto = await _remoteDataSource.register(
        temporaryRegistrationToken: temporaryRegistrationToken,
        fullName: fullName.trim(),
        cityId: cityId,
      );
      return dto.value;
    } on ApiFailure {
      rethrow;
    } on FormatException {
      throw const ApiFailure.unexpected();
    }
  }

  @override
  Future<AppCityPage> getRegistrationCities({
    String search = '',
    int page = 1,
  }) async {
    try {
      final result = await _remoteDataSource.fetchCities(
        search: search,
        page: page,
      );
      return AppCityPage(
        items: List.unmodifiable(
          result.items.map((city) => AppCity(id: city.id, name: city.name)),
        ),
        page: result.page,
        lastPage: result.lastPage,
      );
    } on ApiFailure {
      rethrow;
    } on FormatException {
      throw const ApiFailure.unexpected();
    }
  }
}
