import '../../domain/repositories/language_preference_repository.dart';
import '../data_sources/language_preference_remote_data_source.dart';

class LanguagePreferenceRepositoryImpl implements LanguagePreferenceRepository {
  const LanguagePreferenceRepositoryImpl(this._remote);
  final LanguagePreferenceRemoteDataSource _remote;

  @override
  Future<void> save({required String language, required String sessionToken}) =>
      _remote.save(language: language, sessionToken: sessionToken);
}
