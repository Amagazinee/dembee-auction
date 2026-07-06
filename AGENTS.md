# AGENTS.md

## Cursor Cloud specific instructions

This is a **Flutter + Firebase** app (Дэмбээ / Dembee Auction). See `README.md` and `SETUP.md` for the project overview and full setup guide.

### Toolchain
- The Flutter SDK (stable 3.44.4, Dart 3.12.2 — matches `.metadata`) is installed at `/opt/flutter` with `flutter` and `dart` symlinked into `/usr/local/bin`, so they are already on `PATH`. Web support is enabled.
- The update script runs `flutter pub get`. Standard commands live in `pubspec.yaml` / `README.md` / `SETUP.md`.

### Lint / test / build / run
- Lint: `flutter analyze` (there are a few pre-existing unused-import warnings; not errors).
- Test: `flutter test`.
- Run (dev, web): `flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8080`. Chrome is installed if you prefer `-d chrome`. First web compile is slow (~15-20s); wait before loading the page.

### Firebase gotcha (non-obvious)
- `lib/firebase_options.dart` ships with **placeholder** values (`YOUR_PROJECT_ID`, etc.), so no real Firebase project is wired up in this environment.
- Because of this, the app intentionally boots to the **Setup screen** ("Тохиргоо шаардлагатай") instead of a live auction list. `FirebaseService.isConfigured` checks for the `YOUR_PROJECT_ID` placeholder to detect this. Tapping "Firebase тохируулсан — үргэлжлүүлэх" continues to the login screen. This is expected dev behavior — the app runs fine; auth/Firestore calls simply won't succeed without a real project.
- To exercise real auth/Firestore, run `flutterfire configure` against a Firebase project (regenerates `lib/firebase_options.dart`). Do NOT commit service-account JSON (see `SETUP.md` §8).
