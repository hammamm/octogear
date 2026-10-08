# OctoGear mobile app

OctoGear is a bilingual Flutter marketplace for automotive spare parts. The
app serves customers and store owners through separate, role-aware feature
flows.

The engineering rules, architecture, API contracts, environment setup, and
delivery requirements live in [PROJECT_DOCUMENTATION.md](PROJECT_DOCUMENTATION.md).
Read that document before changing code.

## Run locally

### One file, three environments

Edit `lib/core/configuration/app_configuration.dart`:

```dart
static const developmentApiBaseUrl = 'http://127.0.0.1:8000/api'; // Requires adb reverse on Android.
static const productionApiBaseUrl = '';  // Your production HTTPS domain + /api.
```

Development uses the local Laravel URL supplied by the owner; production stays empty until supplied. Include
`/api` exactly once; do not include credentials, query parameters or fragments.
Staging gets its URL from Firebase project `octogear-1d72b` → Remote Config →
**Client** → String parameter `api_base_url`. Save and publish an HTTPS URL ending
in `/api`. No Firebase service URL needs to be entered into Flutter.

| Environment | URL source |
| --- | --- |
| `development` / `dev` (default) | `developmentApiBaseUrl` in the file |
| `staging` | Firebase Remote Config `api_base_url` |
| `production` / `prod` | `productionApiBaseUrl` in the file |

Run from this repository with the environment you want:

```powershell
flutter run --dart-define=OCTOGEAR_ENV=development
flutter run --dart-define=OCTOGEAR_ENV=staging
flutter run --dart-define=OCTOGEAR_ENV=production
```

Build an Android APK with the same selection (run one command):

```powershell
flutter build apk --release --dart-define=OCTOGEAR_ENV=development
flutter build apk --release --dart-define=OCTOGEAR_ENV=staging
flutter build apk --release --dart-define=OCTOGEAR_ENV=production
```

Output: `build/app/outputs/flutter-apk/app-release.apk`. Each build overwrites
that output. The environment is baked into the APK. Changing a manual URL or
environment requires a full rerun/rebuild; hot reload is not sufficient.
An empty/invalid manual URL shows a configuration error and never falls back
to staging. Development/production do not fetch or read cached Remote Config
URLs. Other existing Firebase services remain initialized.

The API/session tree starts after the URL resolves and keeps that URL for the
launch. All repositories still use `appConfigurationProvider` and the existing
`apiClientProvider`, headers and authentication. Environment builds currently
share the same Android application ID, so they replace one another when installed.

### Direct local development

For the configured loopback URL on an ADB-connected emulator/device, run:

```powershell
adb reverse tcp:8000 tcp:8000
flutter run --dart-define=OCTOGEAR_ENV=dev
```

Keep Laravel running at `http://127.0.0.1:8000`. Repeat the reverse command after
reconnecting/restarting the device if the mapping is lost. The APK alone does
not create this connection to your PC.

For a phone on your PC's LAN, use the PC's reachable LAN IP in the development
constant, for example `http://192.168.1.100:8000/api` (replace this example IP).
Start Laravel so it accepts connections from that network:

```powershell
cd C:\Tamkkun\OctoGearProject\OctoGear-api
php artisan serve --host=0.0.0.0 --port=8000
```

Keep the database running and permit the connection through your Windows
firewall on your private network. A phone/emulator's `127.0.0.1` refers to that
device, not your PC. With an ADB-connected device, another option is
`adb reverse tcp:8000 tcp:8000`, which lets `http://127.0.0.1:8000/api` reach the
PC's Laravel server. Android development builds allow HTTP even in release
mode; staging/production API configuration requires HTTPS.

### Staging through Cloudflare Tunnel

Run Laravel on `127.0.0.1:8000` and start the tunnel separately:

```powershell
cloudflared tunnel --protocol http2 --url http://127.0.0.1:8000
```

Publish `https://YOUR-TUNNEL.trycloudflare.com/api` as the Client Remote Config
`api_base_url`, then fully restart the staging app. Keep Laravel, the database
and the tunnel running. Staging attempts a fetch each launch, subject to Firebase
throttling. The SDK timeout is 10 seconds and the startup fetch bound is 12 seconds.
On failure it can use a validated activated value or saved staging URL. A fresh
install with no valid value shows Retry. Cached URLs can still point to expired
tunnels; publish a working URL and restart when necessary.

The current Firebase configuration is Android only. Android release signing
still uses the existing development key; configure release signing before Play
distribution. Choosing `production` selects the backend, not signing credentials.

If Flutter reports that plugins require symlink support on Windows, enable
Windows Developer Mode and rerun `flutter pub get`. Rebuild the app after adding
the native Remote Config plugin; hot reload cannot register it.

## Android build memory failures

If Gradle reports `daemon disappeared`, inspect the `hs_err_pid*.log` path
printed in the error. `Native memory allocation` failures or Windows error
1455 (`The paging file is too small`) indicate exhausted system committed
memory. Close unused IDEs/apps and keep free disk space on the Windows
page-file drive; if needed, increase Windows virtual memory on a drive with
enough space before retrying.

`android/gradle.properties` limits the Gradle heap to 2 GB, metaspace to 1 GB,
workers to two, and the Kotlin daemon heap to 1 GB to leave room for Flutter
and the emulator. These limits cannot compensate for an already exhausted
Windows memory budget. Avoid running multiple Android builds at once.

Retry from this directory after freeing resources:

```powershell
flutter run --dart-define=OCTOGEAR_ENV=dev
```

## Verify a change

```powershell
flutter analyze
flutter test
```

Keep Flutter work in this repository. The Laravel backend lives separately at
`C:\Tamkkun\OctoGearProject\OctoGear-api` and must never be committed here.
