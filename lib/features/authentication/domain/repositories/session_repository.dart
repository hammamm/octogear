import '../entities/app_user.dart';

abstract interface class SessionRepository {
  Future<AppUser> getProfile();
}
