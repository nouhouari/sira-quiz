# Deployment Guide

This guide covers building release versions of Quiz Sîra for Android and iOS, and preparing them for distribution via Google Play Store and Apple App Store.

## Important: No Secrets Management Required

Quiz Sîra is a **fully offline application** with no backend, authentication, or external API dependencies. There are **no environment variables, API keys, or secrets to manage**. All app state is local and persists in SQLite.

## Android Release

### Prerequisites

- Flutter 3.44.0+
- Android SDK (API 19+)
- A keystore file for signing (see "Creating a Keystore" below if you don't have one)
- Google Play Developer account (for distribution)

### Creating a Keystore (If You Don't Have One)

A keystore is a file that contains your app's signing certificate. Generate one with `keytool`:

```bash
keytool -genkey -v -keystore ~/sira_quiz.keystore \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias sira_quiz -storepass <PASSWORD> -keypass <PASSWORD>
```

Replace `<PASSWORD>` with a strong, unique password. This command creates `~/sira_quiz.keystore`.

**Important**: 
- Keep the keystore file safe and backed up (you will need it for every future release).
- Never commit the keystore to version control.
- The keystore should already be in `.gitignore`.

### Configuring Signing in Flutter

Create or update `android/key.properties`:

```properties
storePassword=<PASSWORD>
keyPassword=<PASSWORD>
keyAlias=sira_quiz
storeFile=<PATH_TO_KEYSTORE>
```

Replace:
- `<PASSWORD>` with the password used when creating the keystore
- `<PATH_TO_KEYSTORE>` with the absolute path (e.g., `/Users/nour/sira_quiz.keystore`)

**Important**: This file is gitignored (`.gitignore` includes `android/key.properties`). Never commit it.

Configure `android/app/build.gradle` to use the keystore for release builds. The configuration should look like:

```gradle
android {
  ...
  signingConfigs {
    release {
      keyAlias keystoreProperties['keyAlias']
      keyPassword keystoreProperties['keyPassword']
      storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
      storePassword keystoreProperties['storePassword']
    }
  }
  buildTypes {
    release {
      signingConfig signingConfigs.release
    }
  }
}
```

If this is not already in place, add it manually or consult the Flutter [Android signing documentation](https://flutter.dev/docs/deployment/android).

### Updating App Version

Edit `pubspec.yaml`:

```yaml
version: 1.0.0+1
```

- The first number (1.0.0) is the **version name** displayed to users.
- The second number (+1) is the **build number** (used internally by Google Play; increment for each build).

**Example progression**:
- Release 1: `1.0.0+1`
- Release 2: `1.0.0+2`
- Release 3 (minor feature): `1.0.1+3`

Run `flutter pub get` after changing `pubspec.yaml`.

### Building a Release APK

For testing on a physical device or distributing outside Google Play:

```bash
flutter build apk --release
```

**Output**: `build/app/outputs/flutter-apk/app-release.apk`

You can then install it on a device:
```bash
adb install build/app/outputs/flutter-apk/app-release.apk
```

### Building a Release App Bundle (For Google Play)

Google Play requires the Android App Bundle (AAB) format:

```bash
flutter build appbundle --release
```

**Output**: `build/app/outputs/bundle/release/app-release.aab`

### Uploading to Google Play Store

1. **Sign in** to [Google Play Console](https://play.google.com/console)
2. **Select** your app (or create a new entry if this is the first release)
3. **Go to "Release" > "Production"** (or alpha/beta for testing)
4. **Upload** `build/app/outputs/bundle/release/app-release.aab`
5. **Complete store listing**: 
   - App name: "Quiz Sîra"
   - Short description: "Educational quiz about the Prophet Mohammed (SWS)"
   - Full description: (include sources, Islamic compliance note)
   - Screenshots: (upload from `screenshots/` directory)
   - Icon, feature graphic, etc.
6. **Add content rating** (IARC questionnaire)
7. **Set privacy policy** (if applicable)
8. **Review and publish**

**App ID**: `com.nour.siraquiz` (defined in `android/app/src/main/AndroidManifest.xml`)

## iOS Release

### Prerequisites

- macOS 12 or later
- Full Xcode 14+ (not just command-line tools)
- CocoaPods
- An Apple Developer account
- A provisioning profile and certificate (managed via Xcode or Apple Developer Portal)

### Installing iOS Dependencies

If not already done:

```bash
cd ios
pod install
cd ..
```

### Updating App Version

Same as Android — edit `pubspec.yaml`:

```yaml
version: 1.0.0+1
```

Run `flutter pub get`.

### Building a Release IPA

```bash
flutter build ipa --release
```

**Output**: `build/ios/ipa/sira_quiz.ipa`

### Uploading to App Store Connect

1. **Sign in** to [App Store Connect](https://appstoreconnect.apple.com)
2. **Select** your app (or create a new entry)
3. **Go to "TestFlight"** (for beta testing) or **"App Store"** (for production)
4. **Upload** the `.ipa` via Transporter:
   ```bash
   xcrun altool --upload-app --type ios \
     --file build/ios/ipa/sira_quiz.ipa \
     --username <APPLE_ID_EMAIL> \
     --password <APP_SPECIFIC_PASSWORD>
   ```
   Or use the GUI: [Download Transporter](https://apps.apple.com/app/transporter/id1450874784)

5. **Complete app information**:
   - App name: "Quiz Sîra"
   - Subtitle: "Educational Quiz"
   - Description: (include sources, Islamic compliance note)
   - Keywords: "quiz", "Islamic", "Sira", "Prophet"
   - Category: Education
   - Privacy policy: (if applicable)

6. **Add test information** (for App Review):
   - Demo account (if needed): Not required for this app
   - Notes: "Fully offline; no special access needed"

7. **Add version information**:
   - Version: (should match `pubspec.yaml`)
   - Build: (submit the IPA you uploaded)
   - Screenshots: (upload from `screenshots/` directory — you may need different sizes for iPhone, iPad)
   - App Preview: (optional)

8. **Submit for review**

### App Store Review Notes

For Apple's review process:

- **Functional Description**: "Quiz Sîra is an offline educational quiz about the life of the Prophet Mohammed (SWS) based on authentic Islamic sources (Qur'an, Hadith, Sîra)."
- **Content Rating**: Indicate the primary language, age rating (likely 4+), and any content warnings.
- **Privacy Policy**: If you collect any usage data, link to a privacy policy. Currently, the app collects no data.
- **Sign-In**: Not required (no backend).
- **Ads**: Not present in this version.
- **Third-Party Content**: Acknowledge use of ForUI (design system) and Drift (database).

## Release Checklist

### Before Every Release

- [ ] Update version in `pubspec.yaml` (e.g., `1.0.0+1` → `1.0.0+2`)
- [ ] Run `flutter test` — all tests pass
- [ ] Run `flutter build apk --release` / `flutter build ipa --release` — builds succeed
- [ ] Test the release build on a physical device:
  ```bash
  flutter run -d <DEVICE> --release
  ```
- [ ] Verify all text is localized (French and English)
- [ ] Verify dark mode works correctly
- [ ] Verify the About screen displays the Islamic compliance notice

### Android

- [ ] Keystore file exists and password is secure
- [ ] `android/key.properties` is configured and gitignored
- [ ] App ID is `com.nour.siraquiz`
- [ ] App Bundle (AAB) built successfully
- [ ] Google Play Store listing is complete
- [ ] Release is reviewed by a qualified person (see `CONTENT_VALIDATION.md`)

### iOS

- [ ] Full Xcode and CocoaPods are installed
- [ ] `ios/` Pods are up to date (`pod install`)
- [ ] Provisioning profile and certificate are valid
- [ ] IPA built successfully
- [ ] App Store Connect entry is complete
- [ ] App is submitted for review (or TestFlight for beta testing)

## Content Validation Before Release

**Critical**: Before publishing any release, the 70-question dataset must be reviewed by a qualified Islamic scholar or subject-matter expert. See `CONTENT_VALIDATION.md` for the list of questions flagged for mandatory scholarly validation and the methodology.

## Versioning Strategy

Semantic Versioning: `MAJOR.MINOR.PATCH+BUILD`

- **MAJOR**: Breaking changes (e.g., major redesign)
- **MINOR**: New features (e.g., new category of questions)
- **PATCH**: Bug fixes and minor improvements
- **BUILD**: Incremental build number for the store (always increment)

**Example timeline**:
- v1.0.0+1 — Initial release
- v1.0.1+2 — Bug fix
- v1.0.1+3 — Another bug fix
- v1.1.0+4 — New category added

## Troubleshooting

### "Signature invalid: the certificate expired"

Re-run the keystore creation with a longer validity (the example above uses 10,000 days ≈ 27 years).

### "Flutter build fails with 'signing configuration'"

Ensure:
1. `android/key.properties` exists and contains the correct paths/passwords
2. The keystore file path is absolute (not relative)
3. The keystore file is readable (`chmod 644 ~/sira_quiz.keystore`)

### "Pod install fails"

Update CocoaPods and try again:
```bash
cd ios
rm -rf Pods Podfile.lock
pod repo update
pod install
cd ..
```

### "App Store Connect says 'Invalid Binary'"

Check Xcode logs for more details. Common issues:
- Bitcode is enabled (should be disabled for Flutter apps)
- Provisioning profile doesn't match the app ID
- Min iOS deployment target is too old

## No Backend Required

Quiz Sîra requires **no backend infrastructure**, environment variables, or external services. All data is:
- **Bundled** in the app (`questions_seed.json`)
- **Seeded locally** on first launch
- **Persisted** in SQLite

This means:
- ✓ No CI/CD deployments for a backend
- ✓ No secrets to rotate
- ✓ No monitoring of cloud services
- ✓ No database migrations to manage post-release
- ✓ Offline-first from day one

## Further Reading

- [Flutter Deployment for Android](https://flutter.dev/docs/deployment/android)
- [Flutter Deployment for iOS](https://flutter.dev/docs/deployment/ios)
- [Google Play Console Help](https://support.google.com/googleplay/android-developer)
- [App Store Connect Help](https://help.apple.com/app-store-connect)
