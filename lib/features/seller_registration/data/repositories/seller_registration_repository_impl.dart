import '../../domain/entities/seller_application.dart';
import '../../domain/repositories/seller_registration_repository.dart';
import '../data_sources/seller_registration_remote_data_source.dart';

class SellerRegistrationRepositoryImpl implements SellerRegistrationRepository {
  const SellerRegistrationRepositoryImpl(this.remote);
  final SellerRegistrationRemoteDataSource remote;
  @override
  Future<SellerApplication?> application() => remote.application();
  @override
  Future<String?> sendCode(String mobile) => remote.sendCode(mobile);
  @override
  Future<String> verifyCode(String mobile, String code) =>
      remote.verifyCode(mobile, code);
  @override
  Future<SellerApplication> submit(
    SellerApplicationDraft draft,
    String token,
  ) => remote.submit(draft, token: token);
  @override
  Future<SellerApplication> resubmit(int id, SellerApplicationDraft draft) =>
      remote.submit(draft, requestId: id);
}
