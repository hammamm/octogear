import '../entities/saudi_mobile_number.dart';
import '../repositories/authentication_repository.dart';

class SendOtpUseCase {
  const SendOtpUseCase(this._repository);

  final AuthenticationRepository _repository;

  Future<void> call(SaudiMobileNumber mobile) => _repository.sendOtp(mobile);
}
