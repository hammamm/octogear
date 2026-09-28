import '../entities/storefront_store_cars_page.dart';
import '../repositories/storefront_repository.dart';

class GetStoreCarsUseCase {
  const GetStoreCarsUseCase(this._repository);

  final StorefrontRepository _repository;

  Future<StorefrontStoreCarsPage> call(int storeId, {required int page}) {
    return _repository.getStoreCars(storeId, page: page);
  }
}
