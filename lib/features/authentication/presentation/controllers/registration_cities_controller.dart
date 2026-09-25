import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/app_user.dart';
import 'session_providers.dart';

final registrationCitiesProvider =
    AsyncNotifierProvider<RegistrationCitiesController, List<AppCity>>(
      RegistrationCitiesController.new,
    );

class RegistrationCitiesController extends AsyncNotifier<List<AppCity>> {
  @override
  Future<List<AppCity>> build() {
    return ref.read(getRegistrationCitiesUseCaseProvider).call();
  }

  void retry() => ref.invalidateSelf();
}
