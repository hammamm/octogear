import '../../../seller_registration/domain/entities/seller_application.dart';
import '../entities/provider_store_management.dart';

abstract interface class ProviderStoreManagementRepository {
  Future<ProviderStoreDetails> fetchStore(int id);
  Future<SellerApplication> requestStoreChange(
    int id,
    ProviderStoreDraft draft,
    String key,
  );
  Future<List<SellerApplication>> fetchApplications();
  Future<SellerApplication> fetchApplication(int id);
  Future<SellerApplication> submitApplication(
    ProviderStoreDraft draft,
    String key,
  );
  Future<SellerApplication> resubmitApplication(
    int id,
    ProviderStoreDraft draft,
  );
}
