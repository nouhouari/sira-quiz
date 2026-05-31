# Content Validation & Data Schema Guide

This document describes the methodology for validating the 70-question Quiz Sîra dataset and explains how to edit or extend the content.

## Important: Pre-Publication Validation Required

The current 70-question seed dataset (`lib/data/db/seed/questions_seed.json`) is a **working draft** and must be reviewed and validated by a qualified Islamic scholar or subject-matter expert before any publication or distribution (Play Store, App Store, or otherwise).

This document identifies questions flagged for mandatory scholarly review and provides guidance for editors and validators.

## Sourcing Methodology

Every question in the dataset is grounded in authentic Islamic sources:

| Source | Abbreviation | Notes |
|--------|--------------|-------|
| **Qur'an** | Qur'an | Ayah (verse) references |
| **Sahih al-Bukhari** | Sahih Bukhari | Collection of authenticated hadith; classified by book and chapter |
| **Sahih Muslim** | Sahih Muslim | Second most authentic collection; similar structure to Bukhari |
| **As-Sira an-Nabawiyya** (Life of the Prophet) | Ibn Hisham Sira / Ibn Ishaq Sira | Compiled by Ibn Hisham (d. 833 CE) based on Ibn Ishaq's earlier work |
| **Al-Maghazi** (Expeditions) | Al-Maghazi | By Al-Waqidi; covers military campaigns and expeditions |

### Citation Convention

Citations in the seed JSON follow this pattern:

```
"sourceReference": "[Collection], [Book/Chapter], [Optional: Chapter Name or Volume]"
```

**Examples**:
- `"Ibn Hisham, As-Sira an-Nabawiyya, Vol. 1"` — Sira by Ibn Hisham, Volume 1
- `"Sahih al-Bukhari, Kitab (Book) al-Jumah"` — Bukhari's Book of Friday Prayer
- `"Qur'an 107:1-7"` — Qur'anic reference (Surah Al-Ma'un, verses 1–7)

**Why not Hadith Numbers?** Hadith numbering varies widely between editions and translations, so we cite sources by book/chapter name rather than fabricating specific hadith numbers. This approach is more robust for translation and validation.

## Questions Flagged for Mandatory Scholarly Review

The following questions require validation by a qualified person before publication:

### Q32: Number and Names of the Prophet's ﷺ Sons

**Issue**: Minor scholarly variance in historical sources regarding the exact identities and number of the Prophet's ﷺ sons.

**Current Content**: (Check `questions_seed.json` for the exact prompt, options, and source.)

**Validation Task**: Confirm the question's correct answer aligns with consensus hadith sources (Bukhari, Muslim, or Sira).

---

### Q39: Bukhari vs. Muslim Attribution

**Issue**: The question cites a specific book from Sahih al-Bukhari; this attribution must be confirmed by cross-referencing the source.

**Current Content**: (Check `questions_seed.json`.)

**Validation Task**: Verify the hadith is in the cited book of Bukhari (or clarify if it's in Muslim instead).

---

### Q52: Book Attribution in Sahih al-Bukhari

**Issue**: Similar to Q39; the book attribution needs confirmation.

**Current Content**: (Check `questions_seed.json`.)

**Validation Task**: Verify the hadith book attribution in Bukhari.

---

### Q56: Succession and Sectarian Sensitivity

**Issue**: The question addresses succession after the Prophet ﷺ, which is a historically sensitive topic with different Sunni and Shia perspectives. The current version is framed as the majority Sunni historical consensus.

**Current Content**: (Check `questions_seed.json`.)

**Validation Task**: Confirm the phrasing and answer are historically accurate and appropriately neutral for an educational context. Ensure the source and framing reflect the Sunni scholarly consensus.

---

### Q57: Al-Maghazi Attribution

**Issue**: The question cites Al-Maghazi (expeditions); the attribution to a specific account must be verified.

**Current Content**: (Check `questions_seed.json`.)

**Validation Task**: Verify the account is accurately attributed to Al-Maghazi or its source.

---

### Q67: Duration of the Prophet's ﷺ Final Illness

**Issue**: The duration is given as a range (e.g., "10-14 days") based on historical sources, but the exact duration varies in different reports. This must be confirmed as the most reliable estimate.

**Current Content**: (Check `questions_seed.json`.)

**Validation Task**: Confirm the range is accurate and matches the most reliable source accounts (Bukhari, Muslim, Sira).

---

## Previously Corrected Issues

The following issues were identified and corrected during development:

1. **Q34** — Epithet/gloss accuracy: Corrected
2. **Q48** — Arabic snippet accuracy: Corrected
3. **Q51** — Citation home/source: Corrected

These corrections are already in the current `questions_seed.json` and do not require re-validation.

## JSON Schema

The seed JSON is organized into two top-level arrays: `categories` and `questions`.

### Categories Object

```json
{
  "slug": "birth_youth",
  "iconKey": "star",
  "nameFr": "Naissance et Jeunesse",
  "nameEn": "Birth & Youth",
  "sortOrder": 1
}
```

| Field | Type | Notes |
|-------|------|-------|
| `slug` | string | Unique identifier; used to link questions to categories. No spaces or special characters. |
| `iconKey` | string | ForUI LucideIcon key (e.g., `"star"`, `"book_open"`, `"mosque"`). |
| `nameFr` | string | French category name. |
| `nameEn` | string | English category name. |
| `sortOrder` | integer | Display order (1–10 for the 10 categories). |

### Question Object

```json
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
    }
  ]
}
```

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `id` | integer | Yes | Globally unique (1–70 currently). |
| `categorySlug` | string | Yes | Must match a category slug. |
| `difficulty` | integer | Yes | 1 (beginner), 2 (intermediate), 3 (advanced). |
| `type` | string | Yes | `"mcq"` (multiple-choice) or `"true_false"` (true/false). |
| `promptFr` | string | Yes | French question text. Must include ﷺ where appropriate. |
| `promptEn` | string | Yes | English question text. |
| `explanationFr` | string | Yes | French explanation shown after answer. Include source if not redundant with `sourceReference`. |
| `explanationEn` | string | Yes | English explanation. |
| `sourceArabic` | string or null | No | Optional: Arabic text of the hadith or Qur'anic verse (for advanced learners). Usually null. |
| `sourceReference` | string | Yes | Citation of the source (see Citation Convention above). |
| `options` | array | Yes | Array of 2–4 option objects (MCQ) or exactly 2 (True/False). |

### Option Object

```json
{
  "textFr": "La Mecque",
  "textEn": "Mecca",
  "isCorrect": true,
  "sortOrder": 1
}
```

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `textFr` | string | Yes | French option text. |
| `textEn` | string | Yes | English option text. |
| `isCorrect` | boolean | Yes | `true` for the correct answer; `false` for distractors. Exactly one option per question should have `isCorrect: true`. |
| `sortOrder` | integer | Yes | Display order (typically 1–4). Used to randomize options on display if needed. |

## How to Edit or Add Questions

### Editing an Existing Question

1. Open `lib/data/db/seed/questions_seed.json` in a text editor.
2. Locate the question by `id`.
3. Edit the fields (e.g., `promptFr`, `explanationEn`, `sourceReference`).
4. Ensure all required fields are present and valid JSON.
5. **Validate the JSON** (use an online JSON validator or `jq`):
   ```bash
   jq . lib/data/db/seed/questions_seed.json > /dev/null && echo "Valid JSON"
   ```
6. To re-seed the app with the updated data:
   - **On a new/clean device or emulator**: Just run the app; it will seed on first launch.
   - **On an existing device**: Delete the app's data or manually clear the database, then reinstall.

### Adding a New Question

1. Open `lib/data/db/seed/questions_seed.json`.
2. Find the last question (currently Q70) and note its `id`.
3. Add a new question object with `id: 71` (or the next available number).
4. Ensure all required fields are populated:
   - Use a valid `categorySlug` (must exist in the categories list).
   - Set `difficulty` to 1, 2, or 3.
   - Set `type` to `"mcq"` or `"true_false"`.
   - For `"mcq"`: provide 2–4 options; for `"true_false"`: provide exactly 2 options (textFr: "Vrai" / "Faux", textEn: "True" / "False").
   - Exactly one option must have `isCorrect: true`.
   - Populate `promptFr`, `promptEn`, `explanationFr`, `explanationEn`, and `sourceReference`.
5. Validate the JSON:
   ```bash
   jq . lib/data/db/seed/questions_seed.json > /dev/null && echo "Valid JSON"
   ```
6. Run `flutter clean && flutter pub get && flutter run` to re-seed.

### Example: Adding a New True/False Question

```json
{
  "id": 71,
  "categorySlug": "quran_message",
  "difficulty": 2,
  "type": "true_false",
  "promptFr": "Le Coran a été révélé en entier au Prophète ﷺ en une seule nuit.",
  "promptEn": "The Qur'an was revealed entirely to the Prophet ﷺ in a single night.",
  "explanationFr": "Faux. Le Coran a été révélé progressivement sur 23 années du ministère du Prophète ﷺ.",
  "explanationEn": "False. The Qur'an was revealed gradually over 23 years of the Prophet's ﷺ ministry.",
  "sourceArabic": "Qur'an 25:32",
  "sourceReference": "Qur'an, Al-Furqan (The Criterion), 25:32",
  "options": [
    {
      "textFr": "Vrai",
      "textEn": "True",
      "isCorrect": false,
      "sortOrder": 1
    },
    {
      "textFr": "Faux",
      "textEn": "False",
      "isCorrect": true,
      "sortOrder": 2
    }
  ]
}
```

## Validation Checklist for Reviewers

Before approving any release, a validator should:

- [ ] **Spot-check 10–15 random questions** for factual accuracy against the cited sources.
- [ ] **Verify the flagged questions** (Q32, Q39, Q52, Q56, Q57, Q67) against authentic sources.
- [ ] **Confirm all ﷺ honorifics** are present in question prompts and explanations.
- [ ] **Check that sources are cited** correctly (book/chapter names are accurate).
- [ ] **Verify option text** (distractors are plausible but clearly incorrect; correct answers are unambiguous).
- [ ] **Test the app** on both Android and iOS (if applicable) to ensure:
  - Questions display correctly in both French and English.
  - Explanations appear after answers are submitted.
  - Source citations are readable and properly formatted.
- [ ] **Test dark mode** to ensure text contrast is readable.
- [ ] **Confirm no spelling or grammatical errors** in French and English.

## Updating After Validation

Once a validator has reviewed the content and approved it for publication:

1. Increment the version in `pubspec.yaml` (e.g., `1.0.0+1` → `1.0.0+2`).
2. Document any corrections or additions in a changelog (e.g., `CHANGELOG.md`).
3. Proceed with the release checklist in `DEPLOYMENT.md`.

## Future Enhancements

Potential improvements to the content system:

- **Difficulty Calibration**: Analyze user performance to adjust difficulty ratings.
- **Question Pool Expansion**: Add 50–100 more questions as the app grows.
- **Source Verification**: Cross-check all 70 questions against multiple editions of Bukhari/Muslim.
- **Arabic Snippet Expansion**: Add the original Arabic hadith text to more questions for advanced learners.
- **Category Reorganization**: Reorganize or merge categories based on user feedback.

## Support

If you have questions about the schema, sourcing methodology, or content editing, please refer to:
- `README.md` — Project overview
- `INSTALL.md` — Build and test instructions
- `DEPLOYMENT.md` — Release process
- The source code in `lib/data/db/seed/seeder.dart` for database seeding logic
