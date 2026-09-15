# Sahala — Project Documentation

## Purpose and current scope

Sahala is a Flutter mobile application scaffold for a Saudi phone-number authentication flow. A user enters a nine-digit mobile number (beginning with `5`), the app asks the API to send or register an OTP, then the user enters a four-digit OTP for verification.

The project is **not yet a complete application**. The login UI and API calls exist, while onboarding, authenticated navigation, session storage, error presentation, and the home feature are still scaffolds. This document describes the code as it exists, and labels unfinished work explicitly so it can be used reliably by both developers and AI assistants.

## Technology at a glance

| Area | Choice | Notes |
| --- | --- | --- |
| UI | Flutter / Material 3 | Custom Poppins font and a light brand theme |
| State | Riverpod (`NotifierProvider`) | Presentation state for login and OTP |
| Dependency injection | GetIt | Global service locator in `dependency_injection.dart` |
| Networking | Dio | Ten-second connect and receive timeouts; centralized, redacted request/response logging |
| Firebase services | Core, Messaging, Crashlytics | Push token handling plus environment-aware logs and error reporting |
| Model generation | `json_serializable` + `build_runner` | Generated `*.g.dart` files are committed |
| Supported platform in practice | Android and iOS | Flutter platform folders exist, but Firebase options intentionally throw on web, macOS, Windows, and Linux |

The package requires Dart SDK `^3.12.0`; use the Flutter SDK version that supplies a compatible Dart version.

## Quick start

```bash
flutter pub get
flutter run
```

Useful maintenance commands:

```bash
flutter analyze
flutter test
dart run build_runner build --delete-conflicting-outputs
dart run flutter_native_splash:create
dart run flutter_launcher_icons
```

Run the code-generation command after changing a class annotated with `@JsonSerializable`. Do not edit generated `*.g.dart` files manually.

### Local API requirement

The selected development URL is `http://0.0.0.0:8000/api/v1/` in `lib/core/config/app_config.dart`. `0.0.0.0` is a server bind address, not normally a reachable address from an emulator or physical device. Before testing login, replace or redesign this development configuration with an address reachable by the target:

- Android emulator: commonly `10.0.2.2` for a server on the host machine.
- iOS simulator: commonly `127.0.0.1` works for a host-local server.
- Physical device: use the development machine's LAN IP or a publicly reachable development API.

The app sends HTTP—not HTTPS—in development. Android may require a cleartext-traffic configuration before that URL can be reached.

## Repository map

```text
lib/
├── main.dart                         # Bootstrap; Firebase, GetIt, Riverpod, MaterialApp
├── dependency_injection.dart          # GetIt registrations
├── firebase_options.dart              # FlutterFire-generated Android/iOS Firebase options
├── core/
│   ├── api/                           # Dio client and generic API envelope
│   ├── config/                        # Environment enum and base URL selection
│   ├── routing/                       # Route names and route factory
│   ├── service/                       # Firebase Messaging lifecycle/token access
│   ├── theme/                         # Colors and ThemeData
│   └── widgets/                       # Shared scaffold, background, OTP input, timer
└── features/
    ├── authentication/                # Login/OTP feature in data, domain, presentation layers
    ├── intro/                         # Unconnected three-page onboarding prototype
    ├── home/                          # Unconnected placeholder Home screen
    └── example/                       # Template feature; not used by the app
assets/
├── fonts/                             # Poppins font files
├── icons/                             # App and splash artwork
└── images/                            # Intro artwork
android/, ios/                         # Native Flutter/Firebase projects
test/widget_test.dart                  # Legacy counter test; currently invalid for this app
```

`features/authentication` follows a clean-architecture-inspired split:

```text
presentation (screens + Riverpod notifiers)
        ↓
domain (use cases + repository contract)
        ↓
data (request/response models + repository implementation)
        ↓
core/api (Dio)
```

## Application startup and routing

`main()` performs these operations in order:

1. Initializes Flutter bindings.
2. Initializes Firebase using `DefaultFirebaseOptions.currentPlatform`.
3. Calls `setup()` to register dependencies with GetIt.
4. Initializes `FirebaseMessagingService`, which gets and logs an FCM token and listens for token changes.
5. Runs `ProviderScope(child: MyApp())`, which provides Riverpod to the widget tree.

`MyApp` applies `AppTheme` and delegates routes to `AppRouter.generateRoute`. It has no explicit `home` or `initialRoute`. Flutter therefore requests `/`; the router's default case returns `LoginScreen`, making login the effective entry screen.

| Route constant | Path | Current destination |
| --- | --- | --- |
| `AppRoutes.login` | `/login` | `LoginScreen` |
| `AppRoutes.otp` | `/otp` | `OTPScreen`; expects a phone-number `String` in route arguments |
| `AppRoutes.home` | `/home` | Declared only; not handled by `AppRouter` |

When adding a screen, add the path to `app_routes.dart`, implement it in `app_router.dart`, then navigate only through the route constant. Add an explicit `initialRoute` once start-up/session routing is designed.

## Authentication flow

```text
LoginScreen
  └─ phone number: 9 digits, starts with 5
       └─ LoginNotifier.login()
            └─ LoginUseCase
                 ├─ retrieves Firebase device token
                 └─ POST user/loginRegister
                      └─ success status → navigate to /otp with phone number

OTPScreen
  └─ four-digit OtpInput completion
       └─ OtpNotifier.otpVerify()
            └─ POST user/otpVerify
                 └─ current code only prints the response
```

### Login request

`LoginUseCase` uses `Platform.isIOS` to send `device_type: 1` on iOS and `0` otherwise. It currently uses `0.0` for both location values.

```http
POST {baseUrl}user/loginRegister
Content-Type: application/json

{
  "mobile_number": "5xxxxxxxx",
  "device_type": 0,
  "latitude": 0.0,
  "longitude": 0.0,
  "device_token": "<Firebase token or null>"
}
```

`LoginNotifier` marks navigation successful only if `response.data['status'] == 'success'`. Network and API errors are not caught in this notifier, so they currently surface as unhandled exceptions and no message is shown to the user.

### OTP request and expected data

```http
POST {baseUrl}user/otpVerify
Content-Type: application/json

{
  "mobile_number": "5xxxxxxxx",
  "otp": "1234"
}
```

`OtpVerifyResponseModel` models a successful payload with `customer`, `leadSourceList`, and `token`. The reusable `ApiResponse<T>` class represents an envelope shaped like `{status, message, data}`.

At present, `AuthenticationRepositoryImpl.otpVerify` returns raw `response.data` even though its contract promises `ApiResponse<OtpVerifyResponseModel>`. It does not construct that model, and the OTP notifier does not update UI state, save the returned token, handle errors, or navigate to home. These are required before OTP authentication is complete.

## Dependency and state ownership

`setup()` registers lazy singletons:

| Registration | Used by |
| --- | --- |
| `AuthenticationRepository` → `AuthenticationRepositoryImpl` | Login and OTP use cases |
| `FirebaseMessagingService` | `LoginUseCase`, startup |
| `LoginUseCase` | `LoginNotifier` |
| `OtpUseCase` | `OtpNotifier` |
| `ExampleRepository` → `ExampleRepositoryImpl` | No production caller |

Riverpod notifiers obtain use cases through GetIt. `LoginNotifier` owns its `TextEditingController` and disposes it with `ref.onDispose`. Its `LoginState` has only `isLoading` and `loginSuccess`; there is no error or response data state. `OtpState` is currently empty.

For a new feature, keep request/response serialization in `data`, business orchestration in a use case, presentation state in a Riverpod notifier, and register the production dependencies in `setup()`. Avoid calling Dio directly from a screen.

## Shared UI and visual system

- `AppScaffold` gives feature screens a transparent app bar and wraps them in `AppBackground`.
- `AppBackground` renders the white/pastel diagonal gradient background.
- `OtpInput` owns four one-character controllers and moves focus forward; it invokes `onCompleted` after the final digit.
- `CountdownTimer` is display-only today. It finishes after 36 seconds on the OTP screen, but no resend action is connected.
- `AppTheme` provides Material 3 light and dark themes. The core brand colors are teal (`AppColors.primary`), pink (`secondary`), blue-gray (`tertiary`), and a gray border.
- `pubspec.yaml` declares the `Poppins` font weights 400, 500, 600, and 700, as well as the `assets/images/` and `assets/icons/` directories.

## Configuration, Firebase, and security

### Environments

`AppConfig.environment` is a compile-time `const` set to `Environment.dev`. Base URLs are hard-coded in source for `dev`, `test`, and `prod`. For a maintainable release setup, replace this with build flavors or `--dart-define` configuration and keep environment-specific secrets out of source control.

### Firebase Messaging

Firebase project configuration is present in `firebase.json`, `android/app/google-services.json`, `ios/Runner/GoogleService-Info.plist`, and the generated `lib/firebase_options.dart`. Only Android and iOS options are configured. `firebase_options.dart` explicitly throws an `UnsupportedError` on web, macOS, Windows, and Linux; do not present those as supported until configured.

On iOS, the messaging service requests alert, badge, and sound permission. It logs the permission status and current/refreshed token. There is no notification-tap handler, foreground-message handler, token upload after refresh, or Android notification permission flow implemented yet.

### Sensitive data and logs

The committed Firebase configuration contains app identifiers and API keys, which are normal client Firebase configuration values but should still be governed by project access rules. `AppLogger` replaces Dio's default verbose logger. Debug builds print visually grouped app, network, error, push, and screen-navigation logs; profile/release builds send ordinary logs to Crashlytics and record errors as non-fatal Crashlytics events. Its network interceptor masks values whose keys contain `authorization`, `token`, `otp`, `password`, or `secret`. Do not pass other sensitive values to general logs. Flutter and uncaught asynchronous errors are also reported as fatal errors. Navigation is observed globally, so pushes, pops, replacements, and removals produce `OPENED`/`CLOSED` view logs without adding logging code to each screen.

Use the logger instead of `print` or `developer.log`:

```dart
await AppLogger.log('Profile loaded', category: 'PROFILE');

try {
  await repository.saveProfile(body);
} catch (error, stackTrace) {
  await AppLogger.error(
    error,
    stackTrace: stackTrace,
    reason: 'Saving profile failed',
  );
  rethrow;
}
```

`ApiClient` already installs `AppLogInterceptor`; do not add Dio's `LogInterceptor` to individual requests. Crashlytics must also be enabled for the existing Firebase project in the Firebase console before production reports can appear.

## Platform and release notes

- Application ID / iOS bundle ID: `com.jahr.sahala`.
- Android uses Java 17 and the Google Services Gradle plugin.
- Android release builds currently use the debug signing configuration. Configure a dedicated signing key and release signing before distribution.
- iOS enables background `remote-notification` and `fetch` modes.
- App version is `1.0.0+1` in `pubspec.yaml`.
- Splash and launcher icon configuration is in `pubspec.yaml`; regenerate native assets after replacing source artwork.

## Current quality status (verified 2026-09-14)

`flutter analyze` currently has no compilation errors, but reports 59 existing lint/style and unused-code items. `flutter test` fails. The sole test is the default counter-app test, but Sahala has no counter UI; it also pumps `MyApp` without its required `ProviderScope`, which causes `No ProviderScope found` while rendering `LoginScreen`.

Replace `test/widget_test.dart` with feature tests that wrap the app in `ProviderScope`, supply/mock dependencies, and verify at least phone validation, login loading/error/success states, OTP completion, and authenticated navigation.

## Delivery checklist for completing authentication

1. Parse the OTP API envelope into `ApiResponse<OtpVerifyResponseModel>` and make repository types non-`dynamic`.
2. Add OTP loading, success, and error state; show errors in both authentication screens.
3. Persist the verified access token securely (prefer secure storage, not the currently unused `shared_preferences` package) and attach it through a Dio interceptor.
4. Navigate to a real home/profile-completion route after verification; implement `/home` in the router.
5. Implement resend OTP and make the timer/control states accessible.
6. Decide whether location is needed; collect it with user permission or remove the placeholder fields.
7. Add session restoration and an initial route/guard that chooses login or authenticated content.
8. Configure release signing, production-safe logs, network transport, and notification behavior.
9. Replace the legacy widget test and add repository/use-case tests against mocked API/Firebase services.

## Working agreement for AI-assisted changes

When changing this project, first identify the affected layer and preserve the direction of dependencies: presentation → domain → data → core. Update models and regenerate code when API JSON changes; do not patch generated files. Treat API response shapes as assumptions until confirmed by backend examples. Do not claim a feature is complete merely because its screen exists: an authentication feature is only complete once it handles success, failure, session persistence, and its next route. Keep this document updated whenever routes, API contracts, environments, or ownership boundaries change.
