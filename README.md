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

The local Laravel API default is `http://127.0.0.1:8000/api`. When Laravel is
running on the Windows loopback address, bridge the active LDPlayer emulator to
that port before starting the app:

```powershell
C:\LDPlayer\LDPlayer9\adb.exe -s emulator-5554 reverse tcp:8000 tcp:8000
```

Repeat this command after restarting LDPlayer or ADB. An
`OCTOGEAR_API_BASE_URL=http://10.0.2.2:8000/api` override is appropriate only
when Laravel has been intentionally exposed to the emulator network.

## Verify a change

```powershell
flutter analyze
flutter test
```

Keep Flutter work in this repository. The Laravel backend lives separately at
`C:\Tamkkun\OctoGearProject\OctoGear-api` and must never be committed here.
