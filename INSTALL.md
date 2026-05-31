# Installation & Setup Guide

This guide walks you through building and running Quiz Sîra from source on Android and iOS.

## Prerequisites

### All Platforms

- **Flutter 3.44.0** or later
  - [Download Flutter](https://flutter.dev/docs/get-started/install)
  - Verify: `flutter --version`

- **Dart 3.12.0** or later
  - Included with Flutter
  - Verify: `dart --version`

- **Git** (to clone the repository)

### Android

- **Android SDK** (API level 19 or higher)
- **Android Emulator** or a physical Android device with USB debugging enabled
- Verify setup: `flutter doctor`

### iOS (Code-Compatible; Additional Setup Required)

Quiz Sîra is code-compatible with iOS, but the current build machine has an incomplete Xcode setup. To build for iOS, you must install:

1. **Full Xcode** (not just command-line tools)
   - Download from the App Store or [developer.apple.com](https://developer.apple.com)
   - Minimum version: Xcode 14 or later

2. **Xcode Command-Line Tools** (properly configured)
   ```bash
   sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
   sudo xcodebuild -runFirstLaunch
   ```

3. **CocoaPods** (Dart plugins require it)
   ```bash
   sudo gem install cocoapods
   # Or via Homebrew:
   brew install cocoapods
   ```

4. **iOS Deployment Target**: 11.0 or later (check `ios/Podfile` if building locally)

## Installation Steps

### 1. Clone or Navigate to the Repository

```bash
cd /Users/nourreddine/Projects/quiz
```

### 2. Install Dart Dependencies

```bash
flutter pub get
```

This downloads all Dart packages listed in `pubspec.yaml`, including `flutter_riverpod`, `go_router`, `drift`, `forui`, and localization dependencies.

### 3. Build Generated Code

Quiz Sîra uses `build_runner` to generate Drift (database) code and localization files:

```bash
dart run build_runner build --delete-conflicting-outputs
```

**What this does:**
- Generates `lib/data/db/app_database.g.dart` (Drift database adapter).
- Regenerates `lib/core/l10n/arb/app_localizations.dart` (localization class).

**Why `--delete-conflicting-outputs`?** Cleans up stale generated files to avoid conflicts.

### 4. Generate Localization Files

```bash
flutter gen-l10n
```

This explicitly generates the `AppLocalizations` class from the ARB files in `lib/core/l10n/arb/`. (This step may already be covered by `build_runner`, but running it explicitly ensures the localization output is up to date.)

### 5. Run on Android

#### List Available Devices

```bash
flutter devices
```

You should see your emulator or connected physical device.

#### Run the App

```bash
flutter run -d <DEVICE_ID>
```

Replace `<DEVICE_ID>` with the device ID from `flutter devices` (e.g., `emulator-5554` for an Android emulator, or a device serial number).

**Example:**
```bash
flutter run -d emulator-5554
```

**First Launch**: On the first run, the app initializes the SQLite database and seeds it with 70 questions from `lib/data/db/seed/questions_seed.json`. This may take a few seconds.

#### Build an Android APK (Release)

To create a standalone APK for distribution:

```bash
flutter build apk --release
```

**Output Path**: `build/app/outputs/flutter-apk/app-release.apk`

**Signing**: By default, Flutter uses a generic debug key. To sign with your own keystore, see `DEPLOYMENT.md`.

### 6. Run on iOS (After Prerequisites Are Installed)

#### Install iOS Dependencies

Once you have Xcode and CocoaPods set up:

```bash
cd ios
pod install
cd ..
```

This installs native iOS dependencies.

#### List Available Simulators

```bash
flutter devices
```

You should see iOS Simulator(s) listed.

#### Run the App

```bash
flutter run -d "<SIMULATOR_NAME>"
```

**Example:**
```bash
flutter run -d "iPhone 15"
```

#### Build an iOS IPA (Release)

To create a release build for App Store Connect:

```bash
flutter build ipa --release
```

**Output**: The IPA is saved to `build/ios/ipa/` and ready for upload to App Store Connect.

## Running Tests

### Unit & Widget Tests

Run all tests in the `test/` directory:

```bash
flutter test
```

This runs:
- `test/quiz_controller_test.dart` — Controller logic and scoring
- `test/widget_test.dart` — Widget smoke tests

### Integration Test (End-to-End Quiz Flow)

Run the full quiz navigation and submission flow:

```bash
flutter test integration_test/quiz_flow_test.dart
```

### Screenshot Tour (UI/UX Validation)

Capture screenshots on a physical Android device for UI/UX review:

```bash
flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/screenshot_tour_test.dart \
  -d <DEVICE_ID>
```

Replace `<DEVICE_ID>` with your device ID. Screenshots are saved to `build/` and the `screenshots/` directory.

## Troubleshooting

### "flutter: command not found"

Ensure Flutter is in your PATH:
```bash
which flutter
```

If not found, add Flutter to your PATH by editing `~/.zshrc` or `~/.bash_profile`:
```bash
export PATH="$PATH:<PATH_TO_FLUTTER>/bin"
```

Then reload the shell:
```bash
source ~/.zshrc
```

### "No Android devices found"

Start an Android emulator:
```bash
emulator -list-avds  # List available emulators
emulator -avd <AVD_NAME> &  # Start one
```

Or connect a physical device with USB debugging enabled.

### Gradle/Build Failures on Android

Clean the build cache:
```bash
flutter clean
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run -d <DEVICE_ID>
```

### iOS Pod Installation Errors

If `pod install` fails:
```bash
rm ios/Podfile.lock
cd ios
pod repo update
pod install
cd ..
```

### Database Seeding Errors

If the app crashes during first launch (database seeding), check:
1. The `questions_seed.json` file exists at `lib/data/db/seed/questions_seed.json`
2. The JSON is valid (use an online JSON validator if unsure)
3. Check logs: `flutter logs`

### Localization Strings Not Updating

Regenerate localization files:
```bash
flutter clean
dart run build_runner build --delete-conflicting-outputs
flutter gen-l10n
flutter run -d <DEVICE_ID>
```

## Next Steps

- **For Deployment**: See `DEPLOYMENT.md` for release checklists (keystore signing, versioning, Play Store/App Store uploads).
- **For Content Editing**: See `CONTENT_VALIDATION.md` for the question schema and how to add/edit questions.
- **For Development**: See `README.md` for project structure and feature overview.
