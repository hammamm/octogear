import '../entities/storefront_store_details.dart';
import '../repositories/storefront_repository.dart';

class GetStoreDetailsUseCase {
  const GetStoreDetailsUseCase(this._repository);

  final StorefrontRepository _repository;

  Future<StorefrontStoreDetails> call(int storeId) {
    return _repository.getStoreDetails(storeId);
  }
}
