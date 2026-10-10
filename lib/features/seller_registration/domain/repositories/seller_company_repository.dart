import '../entities/seller_company.dart';

abstract interface class SellerCompanyRepository {
  Future<SellerCompanyPage> fetch(String query, int page);
}
