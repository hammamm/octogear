import '../../../seller_registration/domain/entities/seller_application.dart';
import '../../domain/entities/provider_store_management.dart';
import '../../domain/repositories/provider_store_management_repository.dart';
import '../data_sources/provider_store_management_remote_data_source.dart';
import '../models/provider_store_write_dto.dart';

class ProviderStoreManagementRepositoryImpl
    implements ProviderStoreManagementRepository {
  const ProviderStoreManagementRepositoryImpl(this._remote);
  final ProviderStoreManagementRemoteDataSource _remote;
  @override
  Future<ProviderStoreDetails> fetchStore(int id) => _remote.fetchStore(id);
  @override
  Future<SellerApplication> requestStoreChange(
    int id,
    ProviderStoreDraft draft,
    String key,
  ) => _remote.requestStoreChange(id, ProviderStoreWriteDto(draft), key);
  @override
  Future<List<SellerApplication>> fetchApplications() =>
      _remote.fetchApplications();
  @override
  Future<SellerApplication> fetchApplication(int id) =>
      _remote.fetchApplication(id);
  @override
  Future<SellerApplication> submitApplication(
    ProviderStoreDraft draft,
    String key,
  ) => _remote.submitApplication(ProviderStoreWriteDto(draft), key);
  @override
  Future<SellerApplication> resubmitApplication(
    int id,
    ProviderStoreDraft draft,
  ) => _remote.resubmitApplication(id, ProviderStoreWriteDto(draft));
}
