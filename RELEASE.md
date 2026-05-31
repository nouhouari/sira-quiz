# Release Guide — Quiz Sîra (fastlane + GitHub Actions)

> This document extends DEPLOYMENT.md (manual release steps) with automated fastlane lanes
> and GitHub Actions CI for store submission.  
> See `DEPLOYMENT.md` for the release checklist and versioning strategy.

---

## Table of Contents

1. [Prerequisites](#1-prerequisites)
2. [Secrets Checklist](#2-secrets-checklist)
3. [Android Setup](#3-android-setup)
4. [iOS Setup](#4-ios-setup)
5. [Running Lanes Locally](#5-running-lanes-locally)
6. [CI via GitHub Actions](#6-ci-via-github-actions)
7. [First-Time Setup Checklist](#7-first-time-setup-checklist)

---

## 1. Prerequisites

### All platforms

| Tool | Minimum version | Install |
|------|----------------|---------|
| Flutter | 3.44.0 (FVM stable) | `fvm install stable` |
| Ruby | 2.7+ | pre-installed on macOS |
| Bundler | any | `gem install bundler` |
| fastlane | ~> 2.235 | installed via `bundle install` |

### Android

| Requirement | Notes |
|---|---|
| Java 17 | `brew install openjdk@17` or use Android Studio's JDK |
| Android SDK | via Android Studio or `sdkmanager` |
| Google Play Console app record | App must exist at `com.nour.siraquiz.sira_quiz` |
| Google Play service account | See §2 for setup |
| Release keystore | Generate once with `keytool` (see §3) |

### iOS (macOS only — not available on this machine)

| Requirement | Notes |
|---|---|
| macOS 13+ | Required for Xcode 15+ |
| Xcode 15+ (full install) | Not just command-line tools |
| CocoaPods | `sudo gem install cocoapods` |
| Apple Developer Program | Paid membership required |
| App Store Connect app record | Must exist for `com.nour.siraquiz.sira_quiz` |
| Private match git repo | A separate private repo to store certs/profiles |
| App Store Connect API key | `.p8` file with Developer role |

---

## 2. Secrets Checklist

### Android secrets

| Secret | Used where | How to obtain |
|--------|-----------|---------------|
| `android/fastlane/play-store-service-account.json` | local lanes | Google Play Console → Setup → API access → Link to GCP → create service account → grant "Release Manager" role → download JSON |
| `android/key.properties` | local signing | Copy from `android/key.properties.example`; fill in keystore path + passwords |
| `android/sira_quiz.keystore` | local signing | Generate with `keytool` (§3) |

### Android GitHub Secrets (Settings → Secrets → Actions)

| Secret name | Value |
|---|---|
| `PLAY_SERVICE_ACCOUNT_JSON_BASE64` | `base64 < android/fastlane/play-store-service-account.json` |
| `ANDROID_KEYSTORE_BASE64` | `base64 < /path/to/sira_quiz.keystore` |
| `ANDROID_KEY_ALIAS` | Key alias (e.g. `sira_quiz`) |
| `ANDROID_STORE_PASSWORD` | Keystore store password |
| `ANDROID_KEY_PASSWORD` | Key password |

### iOS GitHub Secrets (Settings → Secrets → Actions)

| Secret name | Value |
|---|---|
| `ASC_KEY_ID` | App Store Connect → Users and Access → Keys → Key ID |
| `ASC_ISSUER_ID` | App Store Connect → Users and Access → Keys → Issuer ID |
| `ASC_KEY_P8_BASE64` | `base64 < AuthKey_<KEY_ID>.p8` (download once from ASC) |
| `MATCH_GIT_URL` | URL of your private match certificates repo |
| `MATCH_PASSWORD` | Encryption passphrase set when initialising match |
| `MATCH_DEPLOY_KEY` | SSH private key with read access to the match repo |
| `APPLE_ID` | Your Apple ID email address |
| `ITC_TEAM_ID` | App Store Connect team ID (numeric) |
| `TEAM_ID` | Apple Developer team ID (10-char alphanumeric) |

**Never echo or print any secret in CI steps.**

---

## 3. Android Setup

### 3a. Generate a release keystore (once)

```bash
keytool -genkey -v \
  -keystore ~/sira_quiz.keystore \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias sira_quiz \
  -storepass <STORE_PASSWORD> \
  -keypass <KEY_PASSWORD>
```

- Store the keystore in a safe location (NOT in the repo).
- Back it up — losing it means you can never update the app on Google Play.

### 3b. Configure local signing

```bash
cp android/key.properties.example android/key.properties
# Edit android/key.properties — fill in storeFile (absolute path), passwords, alias.
```

The `android/app/build.gradle.kts` conditionally loads `key.properties`.
If the file is absent, it falls back to debug signing — release builds still work without it.

### 3c. Install Android fastlane dependencies

```bash
cd android
bundle install
```

### 3d. Configure Play Store service account

1. In Google Play Console → Setup → API access, link to a GCP project.
2. Create a service account with "Release Manager" role.
3. Download the JSON key.
4. Copy to `android/fastlane/play-store-service-account.json` (gitignored).

---

## 4. iOS Setup

### 4a. Install iOS fastlane dependencies

```bash
cd ios
bundle install
```

### 4b. Initialise match (once, on a Mac with Xcode)

```bash
cd ios
bundle exec fastlane match init
# Choose: git
# Enter your private match repo URL as MATCH_GIT_URL
```

Then generate certificates and profiles:

```bash
bundle exec fastlane match appstore
```

This encrypts and pushes signing assets to your private match repo.

### 4c. CocoaPods

```bash
cd ios
pod install
```

---

## 5. Running Lanes Locally

### Android

```bash
cd android
bundle install

# Build AAB only (no upload):
bundle exec fastlane android build

# Upload to internal test track:
bundle exec fastlane android beta

# Upload to production (as draft — you confirm rollout in Play Console):
bundle exec fastlane android release

# Promote internal → production:
bundle exec fastlane android promote

# Validate metadata/AAB against Play API (dry run):
bundle exec fastlane android validate_play
```

Set the `FLUTTER_BIN` env var if using FVM:

```bash
FLUTTER_BIN=~/fvm/versions/stable/bin/flutter bundle exec fastlane android beta
```

### iOS (macOS with Xcode only)

```bash
cd ios
bundle install

# Build IPA only:
bundle exec fastlane ios build

# Upload to TestFlight:
bundle exec fastlane ios beta

# Prepare App Store release (human confirms in ASC):
bundle exec fastlane ios release
```

Required env vars for iOS (set in your shell or a gitignored `.env` file):

```bash
export ASC_KEY_ID=<KEY_ID>
export ASC_ISSUER_ID=<ISSUER_ID>
export ASC_KEY_FILEPATH=/path/to/AuthKey_<KEY_ID>.p8
export MATCH_GIT_URL=git@github.com:yourorg/match-repo.git
export MATCH_PASSWORD=<passphrase>
export APPLE_ID=you@example.com
export ITC_TEAM_ID=<numeric>
export TEAM_ID=<10-char>
```

---

## 6. CI via GitHub Actions

### Triggering a release

**Manual trigger** (any branch):

```
GitHub → Actions → "Android Release" or "iOS Release" → Run workflow
```

**Tag-based trigger** (recommended for production releases):

```bash
git tag v1.0.0
git push origin v1.0.0
# Both android-release.yml and ios-release.yml will start automatically.
```

### Workflows

| Workflow file | Runner | Lane |
|---|---|---|
| `.github/workflows/android-release.yml` | `ubuntu-latest` | `android beta` |
| `.github/workflows/ios-release.yml` | `macos-latest` | `ios beta` |

Both workflows call the `beta` lane (internal/TestFlight). To deploy to production,
run `bundle exec fastlane android release` / `ios release` locally after testing on beta.

### Version bump workflow (recommended)

Before pushing a release tag:

1. Edit `pubspec.yaml` — increment `version: X.Y.Z+BUILD`
2. `flutter pub get`
3. Commit: `git commit -am "Bump version to vX.Y.Z"`
4. Tag: `git tag vX.Y.Z && git push origin vX.Y.Z`

---

## 7. First-Time Setup Checklist

### Android

- [ ] Google Play Console app created for `com.nour.siraquiz.sira_quiz`
- [ ] Google Play service account created and JSON downloaded
- [ ] `android/fastlane/play-store-service-account.json` in place (gitignored)
- [ ] Release keystore generated and backed up
- [ ] `android/key.properties` filled in (gitignored)
- [ ] `cd android && bundle install` passes
- [ ] `bundle exec fastlane android build` produces AAB at expected path
- [ ] All GitHub secrets for Android added to the repo
- [ ] Store metadata in `android/fastlane/metadata/` reviewed (see `_DRAFT_REVIEW.md`)
- [ ] Store images added (see `images/README.md`)

### iOS

- [ ] Apple Developer Program membership active
- [ ] App Store Connect app record created for `com.nour.siraquiz.sira_quiz`
- [ ] Private match git repo created
- [ ] `fastlane match init` run; `fastlane match appstore` run to generate certs
- [ ] App Store Connect API key generated and `.p8` file downloaded
- [ ] `cd ios && bundle install` passes
- [ ] `cd ios && pod install` passes
- [ ] All GitHub secrets for iOS added to the repo
- [ ] Store metadata in `ios/fastlane/metadata/` reviewed (see `_DRAFT_REVIEW.md`)
- [ ] Screenshots added (see `screenshots/en-US/README.md`)
- [ ] App icon at `assets/icon/app_icon.png` is 1024×1024 px

### Content validation (mandatory before any public release)

- [ ] Store copy reviewed by a qualified Islamic scholar (see `CONTENT_VALIDATION.md`)
- [ ] `_DRAFT_REVIEW.md` checklists completed for both platforms
