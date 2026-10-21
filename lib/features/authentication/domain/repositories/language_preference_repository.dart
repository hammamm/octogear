abstract interface class LanguagePreferenceRepository {
  Future<void> save({required String language, required String sessionToken});
}
