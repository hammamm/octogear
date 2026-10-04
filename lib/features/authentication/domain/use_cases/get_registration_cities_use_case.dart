import '../entities/app_user.dart';
import '../repositories/authentication_repository.dart';

class GetRegistrationCitiesUseCase {
  const GetRegistrationCitiesUseCase(this._repository);

  final AuthenticationRepository _repository;

  Future<AppCityPage> call({String search = '', int page = 1}) =>
      _repository.getRegistrationCities(search: search, page: page);
}
