import '../../../../core/storage/app_storage.dart';

class SignOutUseCase {
  const SignOutUseCase(this._sessionStorage);

  final SessionStorage _sessionStorage;

  Future<void> call() => _sessionStorage.clearSession();
}
