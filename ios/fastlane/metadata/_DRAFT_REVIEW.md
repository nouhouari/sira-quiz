# iOS Store Metadata — Draft Review Checklist

> All copy in this directory is a DRAFT. It must be reviewed before submission.

## Islamic compliance review (mandatory)

- [ ] All descriptions use the correct honorific (SWS) consistently.
- [ ] No figurative imagery of the Prophet (SWS) or the Companions is referenced.
- [ ] A qualified Islamic scholar or subject-matter expert has reviewed the store copy.

## App Store policy review

- [ ] Primary category: Education; secondary category: Reference (optional).
- [ ] Age rating: 4+. Complete the IDFA/content questionnaire in App Store Connect.
- [ ] Privacy policy URL set in App Store Connect (can state "no data collected").
- [ ] Keywords (≤ 100 characters total per locale) verified.
- [ ] Subtitle (≤ 30 characters) verified.

## Copy accuracy

- [ ] `name.txt` matches the app display name exactly (≤ 30 characters).
- [ ] `description.txt` reviewed — no HTML tags (plain text only for App Store).
- [ ] French translations reviewed by a native French speaker.
- [ ] `release_notes.txt` updated for each release.

## Assets

- [ ] Screenshots for iPhone 6.7" added to `screenshots/en-US/` and `screenshots/fr-FR/`.
- [ ] Screenshots for iPad 12.9" added (if universal app).
- [ ] App icon at `assets/icon/app_icon.png` is exactly 1024×1024 px, PNG, no transparency.

## Review information

- [ ] `review_information/review_notes.txt` is accurate and up to date.
- [ ] No demo credentials are required (the app has no login).
