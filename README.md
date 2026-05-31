# Quiz Sîra

An offline educational Flutter quiz application about the life of the Prophet Mohammed ﷺ, grounded in authentic Islamic sources (Qur'an, Sahih al-Bukhari, Sahih Muslim, and the Sîra of Ibn Hisham/Ibn Ishaq).

## Overview

Quiz Sîra is a single-restaurant MVP quiz application with no backend dependencies. All data is seeded locally on first launch and persists in SQLite. The app supports both **French (default)** and **English**, switchable at runtime via the Settings screen.

The quiz contains **70 questions** distributed across **10 categories** at **3 difficulty levels** (beginner, intermediate, advanced). Questions are presented as either multiple-choice (MCQ) or true/false, with detailed explanations and source citations for each correct answer.

## Features

- **Offline-First**: All data bundled in the app; no network requests required.
- **Multi-Language**: French and English with runtime language switching.
- **Structured Learning Paths**: 10 thematic categories (Birth & Youth, Revelation, Meccan Period, Hijra, Medinan Period, Expeditions & Battles, Family & Companions, Character & Morals, Final Days, Qur'an & Message).
- **Adaptive Difficulty**: Beginner, intermediate, and advanced questions in each category.
- **Authentic Sourcing**: Every question cites its source (Sahih al-Bukhari, Sahih Muslim, Ibn Hisham Sîra, etc.).
- **Islamic Compliance**: No figurative imagery; consistent use of the ﷺ honorific; appropriate disclaimer in the About screen.
- **Dark Mode Support**: Theme follows system preferences or user override in Settings.
- **Test Coverage**: Unit tests, widget tests, integration tests, and screenshot tour for UI validation.

## Screenshots

### Home Screen (French)
![Home Screen](./screenshots/01-home.png)
The main entry point with quiz navigation options and quick settings access.

### Categories Selection
![Categories](./screenshots/02-categories.png)
Browse the 10 quiz categories with progress indicators and difficulty levels.

### Difficulty Selection
![Difficulty](./screenshots/03-difficulty.png)
Choose between beginner, intermediate, and advanced questions within a category.

### Quiz Screen (Unanswered)
![Quiz Unanswered](./screenshots/04-quiz-unanswered.png)
A multiple-choice or true/false question with interactive answer selection.

### Quiz Screen (Answered)
![Quiz Answered](./screenshots/05-quiz-answered.png)
Visual feedback after submitting an answer, with the source citation displayed.

### Result Summary
![Result](./screenshots/06-result.png)
Category completion summary with score, total questions, and next-category navigation.

### Settings Screen
![Settings](./screenshots/07-settings.png)
Language and theme preferences (French/English, Light/Dark/System).

### About Screen
![About](./screenshots/08-about.png)
App information, source list, and Islamic compliance notice ("Avertissement Important" / "Important Notice").

### Home Screen (English)
![Home EN](./screenshots/09-home-EN.png)
The same interface in English, demonstrating full localization.

## Technology Stack

| Component | Technology | Version |
|-----------|-----------|---------|
| **Framework** | Flutter | 3.44.0 |
| **Language** | Dart | 3.12.0 |
| **State Management** | flutter_riverpod | 2.6.1 |
| **Navigation** | go_router | 17.2.3 |
| **Local Database** | Drift + drift_flutter | 2.33.0 |
| **Localization** | flutter_gen-l10n (ARB) | Built-in |
| **UI Design System** | ForUI | 0.22.3 |

## Project Structure

```
lib/
├── main.dart                          # App entry point; DB initialization
├── app.dart                           # Root MaterialApp router + theme
├── core/
│   ├── l10n/
│   │   └── arb/                       # Localization ARB files
│   │       ├── app_en.arb
│   │       └── app_fr.arb
│   ├── router/
│   │   └── app_router.dart            # GoRouter configuration
│   └── theme/
│       └── app_theme.dart             # ForUI theme setup
├── data/
│   ├── db/
│   │   ├── app_database.dart          # Drift database definition
│   │   ├── tables.dart                # Drift table schemas
│   │   └── seed/
│   │       ├── questions_seed.json    # Question/category data
│   │       └── seeder.dart            # Idempotent DB seeder
│   └── repositories/
│       └── quiz_repository.dart       # Data access + Riverpod providers
├── domain/
│   └── models/
│       ├── quiz_question.dart         # Domain models
│       ├── difficulty.dart
│       └── question_type.dart
└── features/
    ├── home/
    │   └── home_screen.dart           # Home screen (category list)
    ├── categories/
    │   └── categories_screen.dart
    ├── difficulty/
    │   └── difficulty_screen.dart
    ├── quiz/
    │   ├── quiz_screen.dart           # Quiz UI (MCQ / true-false)
    │   └── quiz_controller.dart       # Quiz state management
    ├── result/
    │   └── result_screen.dart         # Quiz result summary
    ├── settings/
    │   └── settings_screen.dart       # Language / theme preferences
    └── about/
        └── about_screen.dart          # About, sources, disclaimer

test/
├── quiz_controller_test.dart          # Controller unit tests
└── widget_test.dart                   # Widget smoke test

integration_test/
├── quiz_flow_test.dart                # End-to-end quiz flow
└── screenshot_tour_test.dart          # UI/UX validation screenshots

test_driver/
└── integration_test.dart              # Integration test driver
```

## Internationalization (i18n)

Localization is managed via **flutter_gen-l10n** (official Flutter localization) using ARB (Application Resource Bundle) files:

- **Template**: `lib/core/l10n/arb/app_en.arb` (English source)
- **Translations**: `lib/core/l10n/arb/app_fr.arb` (French)
- **Config**: `l10n.yaml` (specifies template, output class `AppLocalizations`)
- **Generated**: `lib/core/l10n/arb/app_localizations.dart` (auto-generated)

To add new strings, edit the `.arb` files and run `flutter gen-l10n` to regenerate the localization class.

**Important**: Arabic is intentionally **not** fully localized (no RTL app UI). Arabic is used only for source-text citations within answer explanations, wrapped in a `Directionality(textDirection: TextDirection.rtl, ...)` widget to render RTL without switching the app locale.

## Data & Seeding

All quiz questions are seeded on first launch from `lib/data/db/seed/questions_seed.json` into a Drift-managed SQLite database.

### JSON Schema

```json
{
  "categories": [
    {
      "slug": "birth_youth",
      "iconKey": "star",
      "nameFr": "Naissance et Jeunesse",
      "nameEn": "Birth & Youth",
      "sortOrder": 1
    }
  ],
  "questions": [
    {
      "id": 1,
      "categorySlug": "birth_youth",
      "difficulty": 1,
      "type": "mcq",
      "promptFr": "Dans quelle ville est né le Prophète Mohammed ﷺ ?",
      "promptEn": "In which city was the Prophet Mohammed ﷺ born?",
      "explanationFr": "Le Prophète ﷺ est né à La Mecque...",
      "explanationEn": "The Prophet ﷺ was born in Mecca...",
      "sourceArabic": null,
      "sourceReference": "Ibn Hisham, As-Sira an-Nabawiyya, Vol. 1",
      "options": [
        {
          "textFr": "La Mecque",
          "textEn": "Mecca",
          "isCorrect": true,
          "sortOrder": 1
        },
        {
          "textFr": "Médine",
          "textEn": "Medina",
          "isCorrect": false,
          "sortOrder": 2
        }
      ]
    }
  ]
}
```

**Key Constraints**:
- `id`: Globally unique question identifier (1–70 currently).
- `categorySlug`: Must match a category slug in the categories list.
- `difficulty`: 1 (beginner), 2 (intermediate), or 3 (advanced).
- `type`: `"mcq"` or `"true_false"`.
- `options[].sortOrder`: Display order within the question.

**Seeding Process**:
1. On first app launch, `DatabaseSeeder.seedIfNeeded()` checks if the database is empty.
2. If empty, it loads `questions_seed.json`, parses categories and questions, and inserts them via Drift.
3. On subsequent launches, the seeder skips the insert (idempotent).
4. To force re-seeding, delete the app data or manually clear the database.

## How to Run Tests

### Unit & Widget Tests

```bash
flutter test
```

Runs all tests in the `test/` directory:
- `quiz_controller_test.dart`: Quiz state management and scoring logic.
- `widget_test.dart`: Widget smoke test.

### Integration Test (End-to-End)

```bash
flutter test integration_test/quiz_flow_test.dart
```

Tests the complete user flow: navigate categories, select difficulty, answer questions, and view results.

### Screenshot Tour (UI/UX Validation)

Captures screenshots of every key screen on a physical device for manual UI/UX review:

```bash
flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/screenshot_tour_test.dart \
  -d <DEVICE_ID>
```

Screenshots are saved to `build/` and can be compared against the reference set in `screenshots/`.

## Islamic Compliance

Quiz Sîra adheres to Islamic principles:

1. **No Figurative Imagery**: The app contains no illustrations, paintings, or depictions of people (consistent with Islamic tradition).
2. **Honorific Usage**: The honorific "ﷺ" (Subḥānahu wa taʿālā / May God exalt him) is applied consistently throughout all question text and explanations.
3. **Source Citation**: Every question cites its source (e.g., "Sahih al-Bukhari, Hadith 3607" or "Ibn Hisham, As-Sira an-Nabawiyya"). See `CONTENT_VALIDATION.md` for the methodology.
4. **Disclaimer**: The About screen includes an "Avertissement Important" (Important Notice) in French and an equivalent notice in English, reminding users that the content is a draft requiring validation by qualified scholars before publication.

## Platforms

### Android
- **Fully Supported**: Build, test, and run on Android devices and emulators.
- **App ID**: `com.nour.siraquiz`
- **Min SDK**: API 19 (configurable in build settings).

### iOS
- **Code-Compatible**: The codebase is iOS-ready, but the current build machine lacks full Xcode/CocoaPods setup.
- **Prerequisites for iOS builds**: See `INSTALL.md` for detailed iOS setup instructions.

## Getting Help

- See `INSTALL.md` for prerequisites and step-by-step build instructions.
- See `DEPLOYMENT.md` for release checklists (Android APK/App Bundle, iOS IPA).
- See `CONTENT_VALIDATION.md` for the content validation methodology and flagged questions requiring scholarly review.
