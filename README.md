# OctoGear mobile app

OctoGear is a bilingual Flutter marketplace for automotive spare parts. The
app serves customers and store owners through separate, role-aware feature
flows.

The engineering rules, architecture, API contracts, environment setup, and
delivery requirements live in [PROJECT_DOCUMENTATION.md](PROJECT_DOCUMENTATION.md).
Read that document before changing code.

## Run locally

```powershell
flutter pub get
flutter run --dart-define=OCTOGEAR_ENV=development
```

The local Laravel API default is `http://127.0.0.1:8000/api`. Android emulators
normally need an explicit host override:

```powershell
flutter run --dart-define=OCTOGEAR_API_BASE_URL=http://10.0.2.2:8000/api
```

## Verify a change

```powershell
flutter analyze
flutter test
```

Keep Flutter work in this repository. The Laravel backend lives separately at
`C:\Tamkkun\OctoGearProject\OctoGear-api` and must never be committed here.
