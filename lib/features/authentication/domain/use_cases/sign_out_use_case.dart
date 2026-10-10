import '../../../../core/storage/app_storage.dart';

class SignOutUseCase {
  const SignOutUseCase(this._sessionStorage, {this.beforeClear});

  final SessionStorage _sessionStorage;
  final Future<void> Function()? beforeClear;

  Future<void> call() async {
    try {
      await beforeClear?.call();
    } finally {
      await _sessionStorage.clearSession();
    }
  }
}
