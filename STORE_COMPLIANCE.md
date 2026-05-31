# Store Compliance Answer Sheet — Quiz Sîra

Ready-to-paste answers for the Google Play and App Store privacy/rating forms.
Every answer below is **verified against the actual app** — fill the consoles exactly as shown.

## Verified facts (the basis for every answer)
- **App id:** `com.nour.siraquiz.sira_quiz` · **Category:** Education
- **Fully offline.** The **release APK requests no `INTERNET` permission** and the app makes no
  network calls. (Only the dev-only debug/profile manifests add INTERNET, for hot-reload — it is
  **not** in the release build.) The only permission in the release build is an auto-generated
  internal `…DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION` (signature-level, not user-facing — nothing to
  declare).
- **iOS:** `Info.plist` has **no `NS…UsageDescription` keys** (no camera/location/contacts/etc.).
- **No SDKs** that collect data — no ads, no analytics, no crash reporting, no third-party trackers.
- **No account / sign-in.** Quiz content + progress + settings are stored **only on-device** (local
  SQLite) and are **never transmitted**.
- **Privacy Policy URL:** **https://nouhouari.github.io/sira-quiz/**

---

## 1. Google Play — Data safety
Play Console → **App content → Data safety**.

| Form question | Answer |
|---|---|
| Does your app collect or share any of the required user data types? | **No** |
| Does your app share user data with third parties? | **No** |
| Privacy policy URL | `https://nouhouari.github.io/sira-quiz/` |

**Why "No" even though the app stores progress locally:** Google defines *collection* as data
**transmitted off the device**. Data kept only on-device and never sent anywhere is **not** collected.
The release build has no INTERNET permission, so nothing can leave the device.

Because you answer "No data collected", the form **skips** the data-type, "encrypted in transit", and
"data deletion request" sub-sections. Resulting store label: **"No data collected."**

---

## 2. Apple — App Privacy
App Store Connect → your app → **App Privacy → Get Started**.

| Form question | Answer |
|---|---|
| Do you or your third-party partners collect data from this app? | **No, we do not collect data from this app** |
| Privacy Policy URL (App Information) | `https://nouhouari.github.io/sira-quiz/` |

Resulting label: **"Data Not Collected."** No data types to configure.

---

## 3. Google Play — Content rating (IARC questionnaire)
Play Console → **App content → Content ratings → Start questionnaire**.

- **Category:** Reference / News / Educational (i.e. **Education**).
- Answer **No** to every content question:
  - Violence (realistic or fantasy) — **No**
  - Sexual content / nudity — **No**
  - Profanity / crude humor — **No**
  - Controlled substances (drugs, alcohol, tobacco) — **No**
  - Gambling (real or simulated) — **No**
  - User-generated content, user-to-user interaction, content sharing — **No**
  - Shares the user's location — **No**
  - Shares personal information — **No**
  - Digital purchases — **No**
- If asked about references to religion: answer truthfully — the app is **educational content about
  Islamic history**; there is no mature element.
- **Expected result:** Everyone / PEGI 3 / ESRB Everyone (lowest age band).

---

## 4. Apple — Age Rating
App Store Connect → App Information → **Age Rating → Edit**.

- Set **every** content descriptor to **None**:
  Cartoon/Fantasy/Realistic Violence, Sexual Content/Nudity, Profanity, Alcohol/Tobacco/Drugs, Mature/
  Suggestive Themes, Horror, Gambling, Contests, Medical/Treatment Info, Unrestricted Web Access — all **None**.
- "Made for Kids" / Kids Category — **No** (general audience).
- **Expected result: 4+.**

---

## 5. Other declarations
- **Ads:** Play *App content → Ads* → **No, my app does not contain ads.** · App Store → **does not
  use IDFA / no ads.**
- **In-app purchases:** **None.**
- **App access (Play) / App Review notes (Apple):** "No account or login required; the app is fully
  offline and all features are available without an internet connection." (Apple notes already drafted
  in `ios/fastlane/metadata/review_information/review_notes.txt`.)
- **Government / financial / health app:** **No** to all.
- **Target audience & content (Play → App content):** recommend selecting **13 and older** (the app is
  suitable for everyone, but choosing children's age bands enrolls you in Google Play's **Families
  Policy** with extra obligations). The app's zero-data design *would* satisfy Families requirements,
  so if you specifically want to target children you may — just complete the Families section. For the
  simplest first submission, target **13+** (still visible to all users).
- **Data deletion (Play, optional):** not required (no off-device data). You may note that users can
  clear local data via **Settings → Reset progress** or by uninstalling.

---

## 6. Permissions disclosure
Nothing to disclose. Verified:
- **Android (release):** no INTERNET, no sensitive permissions (only the internal signature-level
  `DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION`).
- **iOS:** no usage-description keys → no permission prompts.

---

## Quick reference
| Field | Google Play | App Store |
|---|---|---|
| Collects data | **No** | **No (Data Not Collected)** |
| Shares data | **No** | **No** |
| Ads | **No** | **No** |
| In-app purchases | **None** | **None** |
| Account required | **No** | **No** |
| Age rating | Everyone / 3+ | 4+ |
| Privacy policy URL | `https://nouhouari.github.io/sira-quiz/` | same |

> Note: the **store listing text** is final, but the **in-app question content** still needs a
> qualified scholarly review before public release — see `CONTENT_VALIDATION.md`. That is a content
> gate, separate from these privacy/rating forms.
