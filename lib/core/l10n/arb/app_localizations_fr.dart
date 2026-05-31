// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Quiz Sîra';

  @override
  String get home_title => 'Quiz Sîra';

  @override
  String get home_subtitle => 'Apprenez la vie du Prophète Mohammed ﷺ';

  @override
  String get home_start => 'Commencer le Quiz';

  @override
  String get home_settings => 'Paramètres';

  @override
  String get home_about => 'À propos';

  @override
  String get categories_title => 'Choisir une Catégorie';

  @override
  String get category_birth_youth => 'Naissance et Jeunesse';

  @override
  String get category_revelation => 'La Révélation';

  @override
  String get category_meccan_period => 'Période Mecquoise';

  @override
  String get category_hijra => 'La Hijra';

  @override
  String get category_medinan_period => 'Période Médinoise';

  @override
  String get category_expeditions => 'Expéditions et Batailles';

  @override
  String get category_family_companions => 'Famille et Compagnons';

  @override
  String get category_character => 'Caractère et Morale';

  @override
  String get category_final_days => 'Les Derniers Jours';

  @override
  String get category_quran_message => 'Coran et Message';

  @override
  String get difficulty_title => 'Difficulté';

  @override
  String get difficulty_beginner => 'Débutant';

  @override
  String get difficulty_intermediate => 'Intermédiaire';

  @override
  String get difficulty_advanced => 'Avancé';

  @override
  String get difficulty_beginner_desc => 'Les faits essentiels à connaître';

  @override
  String get difficulty_intermediate_desc =>
      'Une connaissance approfondie de la Sîra';

  @override
  String get difficulty_advanced_desc => 'Connaissances savantes détaillées';

  @override
  String difficulty_questions_available(num count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString questions disponibles',
      one: '$countString question disponible',
    );
    return '$_temp0';
  }

  @override
  String get difficulty_no_questions => 'Aucune question disponible';

  @override
  String difficulty_questions_remaining(int count) {
    return '$count restantes';
  }

  @override
  String get difficulty_completed_badge => 'Terminé';

  @override
  String quiz_question(int current, int total) {
    return 'Question $current sur $total';
  }

  @override
  String get quiz_next => 'Question Suivante';

  @override
  String get quiz_see_results => 'Voir les Résultats';

  @override
  String get quiz_true => 'Vrai';

  @override
  String get quiz_false => 'Faux';

  @override
  String get quiz_source => 'Source';

  @override
  String get quiz_explanation => 'Explication';

  @override
  String get quiz_correct => 'Correct !';

  @override
  String get quiz_incorrect => 'Incorrect';

  @override
  String get quizNoQuestions =>
      'Aucune question n\'est disponible pour cette sélection pour le moment.';

  @override
  String get mastered_title => 'Niveau maîtrisé';

  @override
  String get mastered_message =>
      'Vous avez répondu correctement à toutes les questions de ce niveau. Qu\'Allah augmente votre savoir.';

  @override
  String get mastered_reset_replay => 'Réinitialiser ce niveau et rejouer';

  @override
  String get mastered_back => 'Retour';

  @override
  String get result_title => 'Résultats';

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
      'Excellent ! Qu\'Allah bénisse votre savoir.';

  @override
  String get result_message_good =>
      'Bon effort ! Continuez à apprendre la vie du Prophète ﷺ.';

  @override
  String get result_message_keep_going =>
      'Continuez à étudier — la Sîra est riche en sagesse.';

  @override
  String get result_review_title => 'Réviser les Réponses';

  @override
  String get result_your_answer => 'Votre réponse';

  @override
  String get result_correct_answer => 'Bonne réponse';

  @override
  String get result_replay => 'Rejouer';

  @override
  String get result_home => 'Accueil';

  @override
  String get settings_title => 'Paramètres';

  @override
  String get settings_language => 'Langue';

  @override
  String get settings_theme => 'Thème';

  @override
  String get settings_theme_light => 'Clair';

  @override
  String get settings_theme_dark => 'Sombre';

  @override
  String get settings_theme_system => 'Système';

  @override
  String get settingsHaptic => 'Retour haptique';

  @override
  String get settingsHapticDesc => 'Vibration à la sélection d\'une réponse';

  @override
  String get settings_lang_fr => 'Français';

  @override
  String get settings_lang_en => 'Anglais';

  @override
  String get settings_reset_progress => 'Réinitialiser ma progression';

  @override
  String get settings_reset_progress_desc =>
      'Efface les questions déjà réussies pour les revoir';

  @override
  String get settings_reset_confirm_title => 'Réinitialiser la progression ?';

  @override
  String get settings_reset_confirm_message =>
      'Toutes vos questions réussies seront de nouveau proposées. Cette action est irréversible.';

  @override
  String get settings_reset_confirm_ok => 'Réinitialiser';

  @override
  String get settings_reset_confirm_cancel => 'Annuler';

  @override
  String get progress_reset_done => 'Progression réinitialisée';

  @override
  String get about_title => 'À propos';

  @override
  String get about_app_name => 'Quiz Sîra';

  @override
  String get about_description =>
      'Une application de quiz éducatif sur la vie du Prophète Mohammed ﷺ, basée sur des sources islamiques authentiques.';

  @override
  String get about_sources_title => 'Sources Utilisées';

  @override
  String get about_source_quran => 'Le Saint Coran';

  @override
  String get about_source_bukhari => 'Sahih al-Bukhari';

  @override
  String get about_source_muslim => 'Sahih Muslim';

  @override
  String get about_source_ibn_hisham =>
      'Sîra d\'Ibn Hisham (d\'après Ibn Ishaq)';

  @override
  String get about_methodology_title => 'Méthodologie';

  @override
  String get about_methodology_text =>
      'Les questions sont tirées exclusivement de rapports bien établis et authentifiés dans la Sîra classique et les collections de hadith sahih. En cas de doute, les questions sont omises plutôt que de risquer une inexactitude.';

  @override
  String get about_disclaimer_title => 'Avertissement Important';

  @override
  String get about_disclaimer_text =>
      'Cette application est un outil éducatif et n\'a pas été formellement examinée par des savants islamiques qualifiés. Le contenu doit être validé par une personne qualifiée avant de s\'y fier à des fins religieuses ou savantes. Toute erreur est involontaire.';

  @override
  String about_version(String version) {
    return 'Version $version';
  }

  @override
  String get common_back => 'Retour';

  @override
  String get common_loading => 'Chargement...';

  @override
  String get common_error => 'Une erreur est survenue.';
}
