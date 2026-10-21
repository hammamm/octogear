import '../repositories/language_preference_repository.dart';

class SaveLanguagePreferenceUseCase {
  const SaveLanguagePreferenceUseCase(this._repository);
  final LanguagePreferenceRepository _repository;

  Future<void> call({required String language, required String sessionToken}) {
    if (language != 'ar' && language != 'en') {
      throw ArgumentError.value(language, 'language');
    }
    return _repository.save(language: language, sessionToken: sessionToken);
  }
}
