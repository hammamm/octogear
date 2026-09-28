import '../entities/storefront_filters.dart';
import '../entities/storefront_page.dart';
import '../repositories/storefront_repository.dart';

class SearchStoresUseCase {
  const SearchStoresUseCase(this._repository);

  final StorefrontRepository _repository;

  Future<StorefrontPage> call(StorefrontFilters filters, {required int page}) {
    return _repository.searchStores(filters, page: page);
  }
}
