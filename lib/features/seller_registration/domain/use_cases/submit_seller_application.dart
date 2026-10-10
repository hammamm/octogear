import '../../../../core/api/api_failure.dart';
import '../entities/seller_application.dart';
import '../repositories/seller_registration_repository.dart';

class SubmitSellerApplication {
  const SubmitSellerApplication(this.repository);
  final SellerRegistrationRepository repository;
  Future<SellerApplication> call(
    SellerApplicationDraft draft, {
    String? token,
    SellerApplication? previous,
  }) async {
    if (!draft.isValid ||
        (draft.document == null && previous?.hasDocument != true) ||
        (previous == null && (token == null || token.isEmpty)) ||
        (previous != null &&
            previous.status != SellerApplicationStatus.rejected)) {
      throw const ApiFailure(type: ApiFailureType.validation);
    }
    final result = previous == null
        ? await repository.submit(draft, token!)
        : await repository.resubmit(previous.id, draft);
    if (result.status != SellerApplicationStatus.pending ||
        (previous != null && result.id != previous.id) ||
        result.name != draft.name.trim() ||
        result.city.id != draft.cityId ||
        !result.hasDocument) {
      throw const ApiFailure.unexpected();
    }
    return result;
  }
}
