import '../entities/app_user.dart';
import '../repositories/authentication_repository.dart';

class GetRegistrationCitiesUseCase {
  const GetRegistrationCitiesUseCase(this._repository);

  final AuthenticationRepository _repository;

  Future<List<AppCity>> call() => _repository.getRegistrationCities();
}
