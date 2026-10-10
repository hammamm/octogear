import '../entities/seller_company.dart';
import '../repositories/seller_company_repository.dart';

class LoadSellerCompanies {
  const LoadSellerCompanies(this.repository);
  final SellerCompanyRepository repository;
  Future<SellerCompanyPage> call(String query, int page) =>
      repository.fetch(query.trim(), page < 1 ? 1 : page);
}
