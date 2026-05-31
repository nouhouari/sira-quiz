// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Sîra Quiz';

  @override
  String get home_title => 'Sîra Quiz';

  @override
  String get home_subtitle => 'Learn about the life of the Prophet Mohammed ﷺ';

  @override
  String get home_start => 'Start Quiz';

  @override
  String get home_settings => 'Settings';

  @override
  String get home_about => 'About';

  @override
  String get categories_title => 'Choose a Category';

  @override
  String get category_birth_youth => 'Birth & Youth';

  @override
  String get category_revelation => 'Revelation';

  @override
  String get category_meccan_period => 'Meccan Period';

  @override
  String get category_hijra => 'The Hijra';

  @override
  String get category_medinan_period => 'Medinan Period';

  @override
  String get category_expeditions => 'Expeditions & Battles';

  @override
  String get category_family_companions => 'Family & Companions';

  @override
  String get category_character => 'Character & Morals';

  @override
  String get category_final_days => 'Final Days';

  @override
  String get category_quran_message => 'Qur\'an & Message';

  @override
  String get difficulty_title => 'Difficulty';

  @override
  String get difficulty_beginner => 'Beginner';

  @override
  String get difficulty_intermediate => 'Intermediate';

  @override
  String get difficulty_advanced => 'Advanced';

  @override
  String get difficulty_beginner_desc => 'Essential facts everyone should know';

  @override
  String get difficulty_intermediate_desc => 'Deeper knowledge of the Sîra';

  @override
  String get difficulty_advanced_desc => 'Detailed scholarly knowledge';

  @override
  String difficulty_questions_available(num count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString questions',
      one: '$countString question',
    );
    return '$_temp0 available';
  }

  @override
  String get difficulty_no_questions => 'No questions available';

  @override
  String difficulty_questions_remaining(int count) {
    return '$count remaining';
  }

  @override
  String get difficulty_completed_badge => 'Completed';

  @override
  String quiz_question(int current, int total) {
    return 'Question $current of $total';
  }

  @override
  String get quiz_next => 'Next Question';

  @override
  String get quiz_see_results => 'See Results';

  @override
  String get quiz_true => 'True';

  @override
  String get quiz_false => 'False';

  @override
  String get quiz_source => 'Source';

  @override
  String get quiz_explanation => 'Explanation';

  @override
  String get quiz_correct => 'Correct!';

  @override
  String get quiz_incorrect => 'Incorrect';

  @override
  String get quizNoQuestions =>
      'No questions are available for this selection yet.';

  @override
  String get mastered_title => 'Level mastered';

  @override
  String get mastered_message =>
      'You\'ve answered every question in this level correctly. May Allah increase your knowledge.';

  @override
  String get mastered_reset_replay => 'Reset this level & play again';

  @override
  String get mastered_back => 'Back';

  @override
  String get result_title => 'Results';

  @override
  String result_score(int score, int total) {
    return '$score / $total';
  }

  @override
  String result_percentage(int percent) {
    return '$percent%';
  }

  @override
  String get result_message_excellent =>
      'Excellent! May Allah bless your knowledge.';

  @override
  String get result_message_good =>
      'Good effort! Continue learning about the Prophet ﷺ.';

  @override
  String get result_message_keep_going =>
      'Keep studying — the Sîra is rich with wisdom.';

  @override
  String get result_review_title => 'Review Answers';

  @override
  String get result_your_answer => 'Your answer';

  @override
  String get result_correct_answer => 'Correct answer';

  @override
  String get result_replay => 'Play Again';

  @override
  String get result_home => 'Home';

  @override
  String get settings_title => 'Settings';

  @override
  String get settings_language => 'Language';

  @override
  String get settings_theme => 'Theme';

  @override
  String get settings_theme_light => 'Light';

  @override
  String get settings_theme_dark => 'Dark';

  @override
  String get settings_theme_system => 'System';

  @override
  String get settingsHaptic => 'Haptic Feedback';

  @override
  String get settingsHapticDesc => 'Vibration on answer selection';

  @override
  String get settings_lang_fr => 'French';

  @override
  String get settings_lang_en => 'English';

  @override
  String get settings_reset_progress => 'Reset my progress';

  @override
  String get settings_reset_progress_desc =>
      'Clears answered-correctly questions so you can review them again';

  @override
  String get settings_reset_confirm_title => 'Reset progress?';

  @override
  String get settings_reset_confirm_message =>
      'All your mastered questions will be proposed again. This cannot be undone.';

  @override
  String get settings_reset_confirm_ok => 'Reset';

  @override
  String get settings_reset_confirm_cancel => 'Cancel';

  @override
  String get progress_reset_done => 'Progress reset';

  @override
  String get about_title => 'About';

  @override
  String get about_app_name => 'Sîra Quiz';

  @override
  String get about_description =>
      'An educational quiz application about the life of the Prophet Mohammed ﷺ, based on authentic Islamic sources.';

  @override
  String get about_sources_title => 'Sources Used';

  @override
  String get about_source_quran => 'The Holy Qur\'an';

  @override
  String get about_source_bukhari => 'Sahih al-Bukhari';

  @override
  String get about_source_muslim => 'Sahih Muslim';

  @override
  String get about_source_ibn_hisham =>
      'Sîra of Ibn Hisham (based on Ibn Ishaq)';

  @override
  String get about_methodology_title => 'Methodology';

  @override
  String get about_methodology_text =>
      'Questions are drawn exclusively from well-established, authenticated reports in the classical Sîra and sahih hadith collections. Where uncertainty exists, questions are omitted rather than risk inaccuracy.';

  @override
  String get about_disclaimer_title => 'Important Disclaimer';

  @override
  String get about_disclaimer_text =>
      'This application is an educational aid and has not been formally reviewed by qualified Islamic scholars. The content must be validated by a qualified person before relying on it for religious or scholarly purposes. Any errors are unintentional.';

  @override
  String about_version(String version) {
    return 'Version $version';
  }

  @override
  String get common_back => 'Back';

  @override
  String get common_loading => 'Loading...';

  @override
  String get common_error => 'An error occurred.';
}
