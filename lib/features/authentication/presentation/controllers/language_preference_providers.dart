import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_providers.dart';
import '../../data/data_sources/language_preference_remote_data_source.dart';
import '../../data/repositories/language_preference_repository_impl.dart';
import '../../domain/use_cases/save_language_preference_use_case.dart';

final saveLanguagePreferenceUseCaseProvider =
    Provider<SaveLanguagePreferenceUseCase>((ref) {
      return SaveLanguagePreferenceUseCase(
        LanguagePreferenceRepositoryImpl(
          LanguagePreferenceRemoteDataSource(ref.watch(apiClientProvider)),
        ),
      );
    });
