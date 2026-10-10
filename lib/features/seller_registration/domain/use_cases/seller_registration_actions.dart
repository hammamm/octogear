import '../../../../core/api/api_failure.dart';
import '../../../authentication/domain/entities/saudi_mobile_number.dart';
import '../entities/seller_application.dart';
import '../repositories/seller_registration_repository.dart';
import 'submit_seller_application.dart';

class SellerRegistrationActions {
  const SellerRegistrationActions(this.repository);
  final SellerRegistrationRepository repository;

  Future<SellerApplication?> application() => repository.application();

  Future<String?> sendCode(String mobile) {
    if (SaudiMobileNumber.tryParse(mobile) == null) {
      throw const ApiFailure(type: ApiFailureType.validation);
    }
    return repository.sendCode(mobile);
  }

  Future<String> verifyCode(String mobile, String code) {
    if (SaudiMobileNumber.tryParse(mobile) == null ||
        !RegExp(r'^\d{4}$').hasMatch(code)) {
      throw const ApiFailure(type: ApiFailureType.validation);
    }
    return repository.verifyCode(mobile, code);
  }

  Future<SellerApplication> submit(
    SellerApplicationDraft draft, {
    String? token,
    SellerApplication? previous,
  }) => SubmitSellerApplication(repository)(
    draft,
    token: token,
    previous: previous,
  );
}
