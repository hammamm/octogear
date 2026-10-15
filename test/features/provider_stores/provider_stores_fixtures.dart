import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:octogear/core/localization/app_locale.dart';
import 'package:octogear/core/localization/app_locale_controller.dart';
import 'package:octogear/features/authentication/domain/entities/app_user.dart';
import 'package:octogear/features/authentication/domain/entities/session_outcome.dart';
import 'package:octogear/features/authentication/presentation/controllers/session_controller.dart';
import 'package:octogear/features/provider_stores/domain/entities/provider_store.dart';
import 'package:octogear/features/provider_stores/domain/repositories/provider_stores_repository.dart';

const owner = AppUser(
  id: 1,
  fullName: 'Owner',
  mobile: '+966500000001',
  role: AppUserRole.provider,
);
const store = ProviderStore(
  id: 1,
  name: 'Al Faris Parts',
  status: ProviderStoreStatus.active,
  mobile: '+966511111111',
  city: 'Riyadh',
  location: 'https://maps.example.test/store',
  brands: ['Toyota', 'Honda'],
);

class StoreSession extends SessionController {
  @override
  Future<SessionOutcome> build() async => const AuthenticatedSession(owner);
  void replace(SessionOutcome session) => state = AsyncData(session);
}

class StoreLocale extends AppLocaleController {
  StoreLocale([this.initial = AppLocale.english]);
  final AppLocale initial;
  @override
  AppLocale build() => initial;
  @override
  Future<void> select(AppLocale locale) async => state = locale;
}

class FakeStores implements ProviderStoresRepository {
  int calls = 0;
  Future<List<ProviderStore>> Function() response = () async => [store];
  @override
  Future<List<ProviderStore>> fetchStores() {
    calls++;
    return response();
  }
}
