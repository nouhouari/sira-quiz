#!/usr/bin/env bash
# tool/generate_store_screenshots.sh
# Quiz Sîra — Store screenshot generator
#
# Regenerates ALL store marketing assets (Google Play + App Store, en-US + fr-FR)
# by running the headless flutter test suite.  No emulator or simulator required.
#
# Output paths (relative to repo root):
#   android/fastlane/metadata/android/{en-US,fr-FR}/images/phoneScreenshots/
#   android/fastlane/metadata/android/{en-US,fr-FR}/images/featureGraphic.png
#   android/fastlane/metadata/android/{en-US,fr-FR}/images/icon.png
#   ios/fastlane/screenshots/{en-US,fr-FR}/
#
# Usage:
#   ./tool/generate_store_screenshots.sh          # from repo root
#   bash tool/generate_store_screenshots.sh        # from any directory
#   cd android && sh ../tool/generate_store_screenshots.sh  # from android/
#
# Requirements: Flutter SDK on PATH (or FLUTTER_BIN set to the flutter executable).

set -euo pipefail

# -- Resolve the repo root regardless of invocation directory -----------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

echo "[screenshots] Repo root: ${REPO_ROOT}"
cd "${REPO_ROOT}"

# Allow callers to override the flutter binary (e.g. FVM path in CI).
FLUTTER_BIN="${FLUTTER_BIN:-flutter}"
DART_BIN="${DART_BIN:-dart}"

# -- Step 1: Fetch pub dependencies -------------------------------------------
echo "[screenshots] Running flutter pub get..."
"${FLUTTER_BIN}" pub get

# -- Step 2: Run build_runner (safe if nothing to regenerate) -----------------
echo "[screenshots] Running build_runner..."
"${DART_BIN}" run build_runner build --delete-conflicting-outputs

# -- Step 3: Generate l10n ARB files ------------------------------------------
echo "[screenshots] Generating l10n..."
"${FLUTTER_BIN}" gen-l10n

# -- Step 4: Run the screenshot generator -------------------------------------
echo "[screenshots] Generating store screenshots (flutter test)..."
"${FLUTTER_BIN}" test test/store_screenshots_test.dart --timeout 180s

echo "[screenshots] Done. Screenshots written to:"
echo "  android/fastlane/metadata/android/en-US/images/"
echo "  android/fastlane/metadata/android/fr-FR/images/"
echo "  ios/fastlane/screenshots/en-US/"
echo "  ios/fastlane/screenshots/fr-FR/"
