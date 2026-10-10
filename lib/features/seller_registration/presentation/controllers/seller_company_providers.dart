import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_providers.dart';
import '../../data/data_sources/seller_company_source.dart';
import '../../domain/repositories/seller_company_repository.dart';
import '../../domain/use_cases/load_seller_companies.dart';

final sellerCompanyRepositoryProvider = Provider<SellerCompanyRepository>(
  (ref) => SellerCompanySource(ref.watch(apiClientProvider)),
);
final loadSellerCompaniesProvider = Provider(
  (ref) => LoadSellerCompanies(ref.watch(sellerCompanyRepositoryProvider)),
);
