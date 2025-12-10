# ggumdream

Dream diary marketplace app built with Flutter, Riverpod, and Firebase.

**App Version**: `1.0.0+1`  
**Dart SDK**: `>=3.4.0 <4.0.0`  
**Flutter**: Stable channel (3.x recommended)  
**Platforms**: Android, iOS, Web, Windows, macOS, Linux

## Features
- Dream diary creation, editing, and listing for sale.
- Marketplace support with Firebase Functions and Firestore.
- Sold-out and listed state enforcement (no delete/modify when sold/listed).
- Image attachments and OCR (Google ML Kit).
- Localizations and rich UI (Glass-style components, Google Fonts).

## Tech Stack
- UI: `flutter`, `flutter_riverpod`, `go_router`, `google_fonts`, `table_calendar`, `fl_chart`.
- Media: `image_picker`, `flutter_image_compress`, `just_audio`, `audio_service`.
- Firebase: `firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_storage`, `firebase_analytics`, `cloud_functions`.
- AI/OCR: `google_generative_ai` (Gemini), `google_mlkit_text_recognition`.
- Utilities: `intl`, `shared_preferences`, `flutter_secure_storage`, `uuid`, `connectivity_plus`.

## Project Structure
- App code: `lib/`
- Flutter platforms: `android/`, `ios/`, `web/`, `windows/`, `macos/`, `linux/`
- Firebase functions: `functions/`
- Assets: `assets/` (`icons/`, `images/`, `music/`)

## Requirements
- Flutter (stable channel). Install from: https://docs.flutter.dev/get-started/install
- Dart SDK `>=3.4.0 <4.0.0` (comes with Flutter).
- Firebase CLI (for `functions/` deployment): https://firebase.google.com/docs/cli
- Android Studio / Xcode for native builds.

## Configuration
1. Firebase setup
    - Place platform configs:
       - Android: `android/app/google-services.json`
       - iOS: `ios/Runner/GoogleService-Info.plist`
       - Web: `web/index.html` already includes Firebase init (ensure matching config).
    - Root configs: `firebase.json`, ensure your project ID is set.

2. Environment variables
    - Create a `.env` file at project root referenced in `pubspec.yaml` assets:
       ```
       GEMINI_API_KEY=your_api_key
       ```
    - Do not commit secrets.

3. Permissions
    - Android: confirm required permissions for `image_picker`, network, audio in `AndroidManifest.xml`.
    - iOS: add usage descriptions in `Info.plist` (camera, photo library, microphone if used).

## Install & Run
```powershell
flutter pub get
flutter analyze
flutter run
```

### Android release build
```powershell
flutter build apk
```

### iOS (macOS-only)
```bash
flutter build ios
```

### Web
```powershell
flutter build web
```

## Firebase Functions
- Source: `functions/` (TypeScript)
- Local dev:
```powershell
cd functions
npm install
firebase emulators:start
```
- Deploy:
```powershell
cd functions
firebase deploy --only functions
```

## Testing
- Widget tests: `test/`
```powershell
flutter test
```

## Versioning & Releases
- App version: managed in `pubspec.yaml` via `version: 1.0.0+1`.
- Android:
   - `build-name` → `versionName`
   - `build-number` → `versionCode`
- iOS:
   - `build-name` → `CFBundleShortVersionString`
   - `build-number` → `CFBundleVersion`
- Bump versions:
```powershell
flutter build apk --build-name 1.0.1 --build-number 2
```

## Notable Behaviors
- Entries listed for sale cannot be modified or deleted.
- Sold-out entries cannot be modified or deleted; dialogs explain why.
- Draft entries can be edited freely; delete confirmation prompts.

## Troubleshooting
- Dependency conflicts: run `flutter pub upgrade` or respect `dependency_overrides` in `pubspec.yaml`.
- Firebase initialization:
   - Ensure configs exist for all targeted platforms.
   - Check console logs for missing API keys.
- Analyzer errors: run `flutter analyze` and address indicated files.

## License
Private project; do not redistribute.
