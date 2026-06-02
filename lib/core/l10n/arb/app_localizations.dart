import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'arb/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr'),
  ];

  /// Application title
  ///
  /// In en, this message translates to:
  /// **'Sîra Quiz'**
  String get appTitle;

  /// Home screen title
  ///
  /// In en, this message translates to:
  /// **'Sîra Quiz'**
  String get home_title;

  /// Home screen subtitle
  ///
  /// In en, this message translates to:
  /// **'Learn about the life of the Prophet Mohammed (SWS)'**
  String get home_subtitle;

  /// Start quiz button
  ///
  /// In en, this message translates to:
  /// **'Start Quiz'**
  String get home_start;

  /// Settings button
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get home_settings;

  /// About button
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get home_about;

  /// Categories screen title
  ///
  /// In en, this message translates to:
  /// **'Choose a Category'**
  String get categories_title;

  /// Category: birth and youth
  ///
  /// In en, this message translates to:
  /// **'Birth & Youth'**
  String get category_birth_youth;

  /// Category: revelation
  ///
  /// In en, this message translates to:
  /// **'Revelation'**
  String get category_revelation;

  /// Category: meccan period
  ///
  /// In en, this message translates to:
  /// **'Meccan Period'**
  String get category_meccan_period;

  /// Category: hijra
  ///
  /// In en, this message translates to:
  /// **'The Hijra'**
  String get category_hijra;

  /// Category: medinan period
  ///
  /// In en, this message translates to:
  /// **'Medinan Period'**
  String get category_medinan_period;

  /// Category: expeditions
  ///
  /// In en, this message translates to:
  /// **'Expeditions & Battles'**
  String get category_expeditions;

  /// Category: family and companions
  ///
  /// In en, this message translates to:
  /// **'Family & Companions'**
  String get category_family_companions;

  /// Category: character
  ///
  /// In en, this message translates to:
  /// **'Character & Morals'**
  String get category_character;

  /// Category: final days
  ///
  /// In en, this message translates to:
  /// **'Final Days'**
  String get category_final_days;

  /// Difficulty screen title
  ///
  /// In en, this message translates to:
  /// **'Difficulty'**
  String get difficulty_title;

  /// Beginner difficulty
  ///
  /// In en, this message translates to:
  /// **'Beginner'**
  String get difficulty_beginner;

  /// Intermediate difficulty
  ///
  /// In en, this message translates to:
  /// **'Intermediate'**
  String get difficulty_intermediate;

  /// Advanced difficulty
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get difficulty_advanced;

  /// Beginner description
  ///
  /// In en, this message translates to:
  /// **'Essential facts everyone should know'**
  String get difficulty_beginner_desc;

  /// Intermediate description
  ///
  /// In en, this message translates to:
  /// **'Deeper knowledge of the Sîra'**
  String get difficulty_intermediate_desc;

  /// Advanced description
  ///
  /// In en, this message translates to:
  /// **'Detailed scholarly knowledge'**
  String get difficulty_advanced_desc;

  /// Questions available count
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} question} other{{count} questions}} available'**
  String difficulty_questions_available(num count);

  /// No questions for this level
  ///
  /// In en, this message translates to:
  /// **'No questions available'**
  String get difficulty_no_questions;

  /// Remaining (not yet mastered) question count for a level
  ///
  /// In en, this message translates to:
  /// **'{count} remaining'**
  String difficulty_questions_remaining(int count);

  /// Badge shown when all questions in a level are mastered
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get difficulty_completed_badge;

  /// Quiz progress indicator
  ///
  /// In en, this message translates to:
  /// **'Question {current} of {total}'**
  String quiz_question(int current, int total);

  /// Next question button
  ///
  /// In en, this message translates to:
  /// **'Next Question'**
  String get quiz_next;

  /// See results button
  ///
  /// In en, this message translates to:
  /// **'See Results'**
  String get quiz_see_results;

  /// True option
  ///
  /// In en, this message translates to:
  /// **'True'**
  String get quiz_true;

  /// False option
  ///
  /// In en, this message translates to:
  /// **'False'**
  String get quiz_false;

  /// Source label
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get quiz_source;

  /// Explanation label
  ///
  /// In en, this message translates to:
  /// **'Explanation'**
  String get quiz_explanation;

  /// Correct answer feedback
  ///
  /// In en, this message translates to:
  /// **'Correct!'**
  String get quiz_correct;

  /// Incorrect answer feedback
  ///
  /// In en, this message translates to:
  /// **'Incorrect'**
  String get quiz_incorrect;

  /// Error shown when no questions exist for the chosen category/difficulty
  ///
  /// In en, this message translates to:
  /// **'No questions are available for this selection yet.'**
  String get quizNoQuestions;

  /// Title shown when user has mastered all questions in a level
  ///
  /// In en, this message translates to:
  /// **'Level mastered'**
  String get mastered_title;

  /// Congratulatory message on the level-mastered screen
  ///
  /// In en, this message translates to:
  /// **'You\'ve answered every question in this level correctly. May Allah increase your knowledge.'**
  String get mastered_message;

  /// Button to reset mastered level and start a new session
  ///
  /// In en, this message translates to:
  /// **'Reset this level & play again'**
  String get mastered_reset_replay;

  /// Button to go back from the mastered screen
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get mastered_back;

  /// Results screen title
  ///
  /// In en, this message translates to:
  /// **'Results'**
  String get result_title;

  /// Score display
  ///
  /// In en, this message translates to:
  /// **'{score} / {total}'**
  String result_score(int score, int total);

  /// Percentage display
  ///
  /// In en, this message translates to:
  /// **'{percent}%'**
  String result_percentage(int percent);

  /// Result message for >=80%
  ///
  /// In en, this message translates to:
  /// **'Excellent! May Allah bless your knowledge.'**
  String get result_message_excellent;

  /// Result message for >=50%
  ///
  /// In en, this message translates to:
  /// **'Good effort! Continue learning about the Prophet (SWS).'**
  String get result_message_good;

  /// Result message for <50%
  ///
  /// In en, this message translates to:
  /// **'Keep studying — the Sîra is rich with wisdom.'**
  String get result_message_keep_going;

  /// Review section title
  ///
  /// In en, this message translates to:
  /// **'Review Answers'**
  String get result_review_title;

  /// Your answer label
  ///
  /// In en, this message translates to:
  /// **'Your answer'**
  String get result_your_answer;

  /// Correct answer label
  ///
  /// In en, this message translates to:
  /// **'Correct answer'**
  String get result_correct_answer;

  /// Replay button
  ///
  /// In en, this message translates to:
  /// **'Play Again'**
  String get result_replay;

  /// Button to return to the difficulty screen for the same category
  ///
  /// In en, this message translates to:
  /// **'Choose level'**
  String get result_choose_level;

  /// Home button
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get result_home;

  /// Settings screen title
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings_title;

  /// Language setting
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settings_language;

  /// Theme setting
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settings_theme;

  /// Light theme
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settings_theme_light;

  /// Dark theme
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settings_theme_dark;

  /// System theme
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settings_theme_system;

  /// Haptic feedback section label (replaces 'Sound Effects')
  ///
  /// In en, this message translates to:
  /// **'Haptic Feedback'**
  String get settingsHaptic;

  /// Haptic feedback description
  ///
  /// In en, this message translates to:
  /// **'Vibration on answer selection'**
  String get settingsHapticDesc;

  /// French language
  ///
  /// In en, this message translates to:
  /// **'French'**
  String get settings_lang_fr;

  /// English language
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get settings_lang_en;

  /// Label for the reset progress tile in settings
  ///
  /// In en, this message translates to:
  /// **'Reset my progress'**
  String get settings_reset_progress;

  /// Description for the reset progress tile
  ///
  /// In en, this message translates to:
  /// **'Clears answered-correctly questions so you can review them again'**
  String get settings_reset_progress_desc;

  /// Title of the reset progress confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Reset progress?'**
  String get settings_reset_confirm_title;

  /// Body of the reset progress confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'All your mastered questions will be proposed again. This cannot be undone.'**
  String get settings_reset_confirm_message;

  /// Confirm button in the reset progress dialog
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get settings_reset_confirm_ok;

  /// Cancel button in the reset progress dialog
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get settings_reset_confirm_cancel;

  /// Snackbar message after all progress is reset
  ///
  /// In en, this message translates to:
  /// **'Progress reset'**
  String get progress_reset_done;

  /// About screen title
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about_title;

  /// App name in about
  ///
  /// In en, this message translates to:
  /// **'Sîra Quiz'**
  String get about_app_name;

  /// App description
  ///
  /// In en, this message translates to:
  /// **'An educational quiz application about the life of the Prophet Mohammed (SWS), based on authentic Islamic sources.'**
  String get about_description;

  /// Methodology section title
  ///
  /// In en, this message translates to:
  /// **'Methodology'**
  String get about_methodology_title;

  /// Methodology text
  ///
  /// In en, this message translates to:
  /// **'Questions are drawn exclusively from well-established, authenticated reports in the classical Sîra and sahih hadith collections. Where uncertainty exists, questions are omitted rather than risk inaccuracy.'**
  String get about_methodology_text;

  /// Disclaimer title
  ///
  /// In en, this message translates to:
  /// **'Important Disclaimer'**
  String get about_disclaimer_title;

  /// Disclaimer text
  ///
  /// In en, this message translates to:
  /// **'This application is an educational aid and has not been formally reviewed by qualified Islamic scholars. The content must be validated by a qualified person before relying on it for religious or scholarly purposes. Any errors are unintentional.'**
  String get about_disclaimer_text;

  /// Version string
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String about_version(String version);

  /// Welcome sheet title
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcome_title;

  /// Welcome sheet intro paragraph
  ///
  /// In en, this message translates to:
  /// **'Knowing the life (Sîra) of the Prophet Mohammed (SWS) is part of knowing our religion and learning how to live it. Allah has invited us to follow the example of His Messenger:'**
  String get welcome_intro;

  /// Translation of Al-Ahzab 33:21
  ///
  /// In en, this message translates to:
  /// **'“There has certainly been for you in the Messenger of Allah an excellent example…”'**
  String get welcome_verse_ahzab_translation;

  /// Reference for Al-Ahzab 33:21
  ///
  /// In en, this message translates to:
  /// **'Qur’an — Sûrat al-Aḥzāb, 33:21'**
  String get welcome_verse_ahzab_ref;

  /// Translation of Al Imran 3:31
  ///
  /// In en, this message translates to:
  /// **'“Say: ‘If you love Allah, then follow me, and Allah will love you…’”'**
  String get welcome_verse_imran_translation;

  /// Reference for Al Imran 3:31
  ///
  /// In en, this message translates to:
  /// **'Qur’an — Sûrat Âl ʿImrān, 3:31'**
  String get welcome_verse_imran_ref;

  /// Welcome sheet closing line
  ///
  /// In en, this message translates to:
  /// **'May this quiz help you draw closer to his noble example.'**
  String get welcome_closing;

  /// Free and ad-free disclaimer in welcome sheet
  ///
  /// In en, this message translates to:
  /// **'This application is — and will always remain — completely free and free of advertising.'**
  String get welcome_free_disclaimer;

  /// Invitation to report mistakes in welcome sheet
  ///
  /// In en, this message translates to:
  /// **'If you notice any mistake, please report it on our GitHub issues page and we will correct it, in shā’ Allah: https://github.com/nouhouari/sira-quiz/issues'**
  String get welcome_report_mistakes;

  /// Closing du'a in welcome sheet
  ///
  /// In en, this message translates to:
  /// **'May Allah accept our deeds and reward us for our good actions. Âmīn.'**
  String get welcome_dua;

  /// Begin button in welcome sheet
  ///
  /// In en, this message translates to:
  /// **'Begin'**
  String get welcome_begin;

  /// Label to re-open the welcome sheet
  ///
  /// In en, this message translates to:
  /// **'Welcome message'**
  String get welcome_open;

  /// Back button
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get common_back;

  /// Loading text
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get common_loading;

  /// Error text
  ///
  /// In en, this message translates to:
  /// **'An error occurred.'**
  String get common_error;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
