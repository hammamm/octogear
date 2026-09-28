import '../entities/storefront_filter_options.dart';
import '../repositories/storefront_repository.dart';

class GetStorefrontFilterOptionsUseCase {
  const GetStorefrontFilterOptionsUseCase(this._repository);

  final StorefrontRepository _repository;

  Future<StorefrontFilterOptions> call() => _repository.getFilterOptions();
}
