import '../entities/seller_application.dart';

abstract interface class SellerRegistrationRepository {
  Future<SellerApplication?> application();
  Future<String?> sendCode(String mobile);
  Future<String> verifyCode(String mobile, String code);
  Future<SellerApplication> submit(SellerApplicationDraft draft, String token);
  Future<SellerApplication> resubmit(int id, SellerApplicationDraft draft);
}
