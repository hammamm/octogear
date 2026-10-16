import '../../../../core/api/api_failure.dart';
import '../../../seller_registration/domain/entities/seller_application.dart';
import '../entities/provider_store_management.dart';
import '../repositories/provider_store_management_repository.dart';

class ManageProviderStores {
  const ManageProviderStores(this._repository);
  final ProviderStoreManagementRepository _repository;
  void _id(int id) {
    if (id < 1) throw const ApiFailure(type: ApiFailureType.validation);
  }

  void _draft(ProviderStoreDraft draft) {
    if (!draft.isValid) throw const ApiFailure(type: ApiFailureType.validation);
  }

  Future<ProviderStoreDetails> store(int id) async {
    _id(id);
    final result = await _repository.fetchStore(id);
    if (result.store.id != id) throw const ApiFailure.unexpected();
    return result;
  }

  Future<List<SellerApplication>> applications() =>
      _repository.fetchApplications();
  Future<SellerApplication> application(int id) async {
    _id(id);
    final result = await _repository.fetchApplication(id);
    if (result.id != id) throw const ApiFailure.unexpected();
    return result;
  }

  Future<SellerApplication> requestChange(
    int id,
    ProviderStoreDraft draft,
    String key,
  ) async {
    _id(id);
    if (!draft.isValidChange ||
        !RegExp(
          r'^[a-fA-F0-9]{8}-(?:[a-fA-F0-9]{4}-){3}[a-fA-F0-9]{12}$',
        ).hasMatch(key)) {
      throw const ApiFailure(type: ApiFailureType.validation);
    }
    final result = await _repository.requestStoreChange(id, draft, key);
    if (result.storeId != id ||
        result.idempotencyKey != key ||
        result.mobile != draft.normalizedMobile ||
        result.name != draft.details.name.trim() ||
        result.city.id != draft.details.cityId ||
        result.changeReason != draft.changeReason.trim()) {
      throw const ApiFailure.unexpected();
    }
    return result;
  }

  Future<SellerApplication> submit(
    ProviderStoreDraft draft,
    String key,
    String accountMobile,
  ) async {
    _draft(draft);
    if (draft.details.document == null ||
        draft.normalizedMobile == accountMobile ||
        !RegExp(
          r'^[a-fA-F0-9]{8}-(?:[a-fA-F0-9]{4}-){3}[a-fA-F0-9]{12}$',
        ).hasMatch(key)) {
      throw const ApiFailure(type: ApiFailureType.validation);
    }
    final result = await _repository.submitApplication(draft, key);
    if (result.id < 1 ||
        result.mobile != draft.normalizedMobile ||
        !result.hasDocument) {
      throw const ApiFailure.unexpected();
    }
    return result;
  }

  Future<SellerApplication> resubmit(
    SellerApplication previous,
    ProviderStoreDraft draft,
  ) async {
    _id(previous.id);
    _draft(draft);
    if (previous.isStoreChange ||
        previous.status != SellerApplicationStatus.rejected ||
        draft.normalizedMobile != previous.mobile ||
        (!previous.hasDocument && draft.details.document == null)) {
      throw const ApiFailure(type: ApiFailureType.validation);
    }
    final result = await _repository.resubmitApplication(previous.id, draft);
    if (result.id != previous.id ||
        result.status != SellerApplicationStatus.pending ||
        result.mobile != previous.mobile ||
        result.name != draft.details.name.trim() ||
        result.city.id != draft.details.cityId ||
        !result.hasDocument) {
      throw const ApiFailure.unexpected();
    }
    return result;
  }
}
