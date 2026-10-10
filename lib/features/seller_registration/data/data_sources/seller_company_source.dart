import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_failure.dart';

import '../../domain/entities/seller_company.dart';
import '../../domain/repositories/seller_company_repository.dart';

class SellerCompanySource implements SellerCompanyRepository {
  const SellerCompanySource(this.api);
  final ApiClient api;
  @override
  Future<SellerCompanyPage> fetch(String query, int page) async {
    final result = await api.get<List<SellerCompany>>(
      'reference/companies',
      queryParameters: {'search': query, 'page': page, 'per_page': 20},
      decode: (value) {
        if (value is! List) {
          throw const FormatException('Invalid manufacturers.');
        }
        return value.map((item) {
          if (item is! Map ||
              item['id'] is! int ||
              item['id'] < 1 ||
              item['name'] is! String) {
            throw const FormatException('Invalid manufacturer.');
          }
          return SellerCompany(item['id'], item['name']);
        }).toList();
      },
    );
    if (result.data == null ||
        result.pagination == null ||
        result.pagination!.currentPage != page) {
      throw const ApiFailure.unexpected();
    }
    return SellerCompanyPage(result.data!, page < result.pagination!.lastPage);
  }
}
