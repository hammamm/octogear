/// Non-sensitive filter preferences, scoped to the authenticated account.
abstract interface class ProviderOrderFilterStorage {
  int? readProviderOrderCity(int userId);
  Future<void> saveProviderOrderCity(int userId, int? cityId);
}
