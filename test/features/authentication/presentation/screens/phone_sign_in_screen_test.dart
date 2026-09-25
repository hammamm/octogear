import 'dart:async';
import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:octogear/core/api/api_failure.dart';
import 'package:octogear/core/localization/app_locale.dart';
import 'package:octogear/core/localization/app_locale_controller.dart';
import 'package:octogear/features/authentication/domain/entities/app_user.dart';
import 'package:octogear/features/authentication/domain/entities/otp_verification_result.dart';
import 'package:octogear/features/authentication/domain/entities/saudi_mobile_number.dart';
import 'package:octogear/features/authentication/domain/repositories/authentication_repository.dart';
import 'package:octogear/features/authentication/presentation/controllers/session_providers.dart';
import 'package:octogear/features/authentication/presentation/screens/phone_sign_in_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _rateLimitMessage = 'Too many attempts. Please try again later.';
const _rateLimitFailure = ApiFailure(
  type: ApiFailureType.rateLimited,
  statusCode: 429,
  serverMessage: _rateLimitMessage,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late final AssetLoader translations;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    translations = _PreloadedTranslations(
      jsonDecode(await rootBundle.loadString('assets/translations/en.json'))
          as Map<String, dynamic>,
    );
  });

  testWidgets('editing clears an old send error, but selection does not', (
    tester,
  ) async {
    final repository = _FakeAuthenticationRepository();
    await _pumpScreen(tester, repository, translations);
    final phoneField = find.byType(TextFormField);
    final continueButton = find.byType(FilledButton);

    await tester.enterText(phoneField, '500000001');
    await tester.pump();
    await tester.ensureVisible(continueButton);
    await tester.tap(continueButton);
    await tester.pump();
    repository.pendingSends.single.completeError(_rateLimitFailure);
    await tester.pumpAndSettle();

    expect(find.text(_rateLimitMessage), findsOneWidget);

    // Moving the cursor changes the controller value, but not the phone text.
    tester.testTextInput.updateEditingValue(
      const TextEditingValue(
        text: '500000001',
        selection: TextSelection.collapsed(offset: 3),
      ),
    );
    await tester.pump();
    expect(find.text(_rateLimitMessage), findsOneWidget);

    await tester.enterText(phoneField, '500000002');
    await tester.pump();

    expect(find.text(_rateLimitMessage), findsNothing);
    expect(repository.submittedNumbers, ['500000001']);
    expect(find.byType(PhoneSignInScreen), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.ensureVisible(continueButton);
    await tester.tap(continueButton);
    await tester.pump();
    repository.pendingSends.last.completeError(_rateLimitFailure);
    await tester.pumpAndSettle();

    expect(repository.submittedNumbers, ['500000001', '500000002']);
    expect(find.text(_rateLimitMessage), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      '500000002',
    );
  });

  testWidgets('a pending send locks the number and rejects duplicate submits', (
    tester,
  ) async {
    final repository = _FakeAuthenticationRepository();
    await _pumpScreen(tester, repository, translations);
    final phoneField = find.byType(TextFormField);
    final continueButton = find.byType(FilledButton);

    await tester.enterText(phoneField, '500000001');
    await tester.pump();
    await tester.ensureVisible(continueButton);
    // Two taps before the next frame also exercise the controller's guard.
    await tester.tap(continueButton);
    await tester.tap(continueButton);
    await tester.pump();

    expect(repository.submittedNumbers, ['500000001']);
    expect(tester.widget<TextField>(find.byType(TextField)).readOnly, isTrue);
    expect(tester.widget<FilledButton>(continueButton).onPressed, isNull);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.tap(continueButton);
    expect(repository.submittedNumbers, ['500000001']);

    repository.pendingSends.single.completeError(_rateLimitFailure);
    await tester.pumpAndSettle();

    expect(tester.widget<TextField>(find.byType(TextField)).readOnly, isFalse);
    expect(tester.widget<FilledButton>(continueButton).onPressed, isNotNull);
    expect(find.text(_rateLimitMessage), findsOneWidget);
  });

  testWidgets(
    'the unchanged number can be retried after a connection failure',
    (tester) async {
      final repository = _FakeAuthenticationRepository();
      await _pumpScreen(tester, repository, translations);
      final phoneField = find.byType(TextFormField);
      final continueButton = find.byType(FilledButton);

      await tester.enterText(phoneField, '500000001');
      await tester.pump();
      await tester.ensureVisible(continueButton);
      await tester.tap(continueButton);
      await tester.pump();
      repository.pendingSends.single.completeError(
        const ApiFailure(type: ApiFailureType.noConnection),
      );
      await tester.pumpAndSettle();

      expect(tester.widget<FilledButton>(continueButton).onPressed, isNotNull);
      expect(find.text('Retry'), findsOneWidget);

      await tester.tap(continueButton);
      await tester.pump();

      expect(repository.submittedNumbers, ['500000001', '500000001']);
    },
  );
}

Future<void> _pumpScreen(
  WidgetTester tester,
  _FakeAuthenticationRepository repository,
  AssetLoader translations,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authenticationRepositoryProvider.overrideWithValue(repository),
        appLocaleProvider.overrideWith(_EnglishLocaleController.new),
      ],
      child: EasyLocalization(
        supportedLocales: const [Locale('en'), Locale('ar')],
        startLocale: const Locale('en'),
        path: 'assets/translations',
        assetLoader: translations,
        saveLocale: false,
        child: Builder(
          builder: (context) => MaterialApp(
            locale: context.locale,
            supportedLocales: context.supportedLocales,
            localizationsDelegates: context.localizationDelegates,
            home: const PhoneSignInScreen(),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _PreloadedTranslations extends AssetLoader {
  const _PreloadedTranslations(this.translations);

  final Map<String, dynamic> translations;

  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) =>
      Future.value(translations);
}

class _EnglishLocaleController extends AppLocaleController {
  @override
  AppLocale build() => AppLocale.english;
}

class _FakeAuthenticationRepository implements AuthenticationRepository {
  final submittedNumbers = <String>[];
  final pendingSends = <Completer<void>>[];

  @override
  Future<void> sendOtp(SaudiMobileNumber mobile) {
    submittedNumbers.add(mobile.nationalNumber);
    final pending = Completer<void>();
    pendingSends.add(pending);
    return pending.future;
  }

  @override
  Future<OtpVerificationResult> verifyOtp({
    required SaudiMobileNumber mobile,
    required String otp,
  }) => throw UnimplementedError();

  @override
  Future<String> register({
    required String temporaryRegistrationToken,
    required String fullName,
    required int cityId,
  }) => throw UnimplementedError();

  @override
  Future<List<AppCity>> getRegistrationCities() => throw UnimplementedError();
}
