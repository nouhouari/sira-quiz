// ignore_for_file: avoid_print
//
// Regression guards — Welcome sheet feature
//
// ─────────────────────────────────────────────────────────────────────────────
// Test 1 — Shows once on first launch
//   Pump HomeScreen with in-memory DB where welcome_seen is unset.
//   The sheet MUST appear (welcome_title + a verse ref found in the widget tree).
//   After settle the 'welcome_seen' flag MUST be 'true' in the DB.
//   Would FAIL if _maybeShowWelcome were removed or the DB write were skipped.
//
// Test 2 — Does NOT show when already seen
//   Pre-set welcome_seen='true' in the DB, pump HomeScreen, settle.
//   The sheet must NOT appear (welcome_title absent from the widget tree).
//   Would FAIL if the seen-flag check were removed or inverted.
//
// Test 3 — Reopen from About screen
//   Pump AboutScreen, tap the welcome_open entry card.
//   The sheet MUST open even when welcome_seen='true' (About uses direct call,
//   bypasses the seen guard).
//   Would FAIL if AboutScreen's _WelcomeEntryCard were wired to the wrong
//   callback or if showWelcomeSheet were gated behind the flag.
//
// Test 4a — Content and localisation (EN)
//   Open the sheet and assert BOTH verse references (al-Aḥzāb 33:21 and
//   Âl ʿImrān 3:31), the two Arabic āyāt strings, the free disclaimer,
//   the report-mistakes GitHub URL, and the du'a are present in EN locale.
//   Would FAIL if any content block were removed or the EN ref strings changed.
//
// Test 4b — Content and localisation (FR)
//   Same content assertions for FR locale (translations differ from EN, but
//   the Arabic āyāt and the GitHub URL are locale-invariant).
//   Would FAIL if ARB keys were missing in app_fr.arb.
//
// Test 5 — Begin button dismisses the sheet
//   With the sheet open, tap welcome_begin.
//   The sheet must close and HomeScreen must remain visible (no route change).
//   Would FAIL if the Begin button's Navigator.pop() were removed or replaced
//   with a route push.
//
// Harness: in-memory Drift DB via NativeDatabase.memory(), GoRouter shell
// (required by HomeScreen which calls context.push), UncontrolledProviderScope
// + ProviderContainer overrides, FTheme + AppLocalizations delegates.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:sira_quiz/core/constants/quran_ayat.dart';
import 'package:sira_quiz/core/l10n/arb/app_localizations.dart';
import 'package:sira_quiz/core/theme/app_theme.dart';
import 'package:sira_quiz/data/db/app_database.dart';
import 'package:sira_quiz/data/repositories/quiz_repository.dart';
import 'package:sira_quiz/features/about/about_screen.dart';
import 'package:sira_quiz/features/home/home_screen.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

AppDatabase _openMemoryDb() => AppDatabase(NativeDatabase.memory());

/// Silent SoundNotifier — never touches SharedPreferences in tests.
class _SilentSoundNotifier extends SoundNotifier {
  @override
  Future<bool> build() async => false;
}

ProviderContainer _makeContainer(AppDatabase db) {
  return ProviderContainer(
    overrides: [
      appDatabaseProvider.overrideWithValue(db),
      soundNotifierProvider.overrideWith(() => _SilentSoundNotifier()),
    ],
  );
}

/// Pumps a MaterialApp.router pointing to [initialLocation] with a minimal
/// GoRouter (/ → HomeScreen, /about → AboutScreen, /categories stub,
/// /settings stub). All routes that HomeScreen may push must be registered.
Future<void> _pumpHomeShell(
  WidgetTester tester, {
  required ProviderContainer container,
  String locale = 'en',
  String initialLocation = '/',
}) async {
  final router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/',
        builder: (ctx, s) => const HomeScreen(),
      ),
      GoRoute(
        path: '/about',
        builder: (ctx, s) => const AboutScreen(),
      ),
      GoRoute(
        path: '/categories',
        builder: (ctx, s) =>
            const Scaffold(body: Center(child: Text('CATEGORIES_STUB'))),
      ),
      GoRoute(
        path: '/settings',
        builder: (ctx, s) =>
            const Scaffold(body: Center(child: Text('SETTINGS_STUB'))),
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        routerConfig: router,
        locale: Locale(locale),
        supportedLocales: const [
          Locale('en'),
          Locale('fr'),
          ...FLocalizations.supportedLocales,
        ],
        localizationsDelegates: const [
          AppLocalizations.delegate,
          ...FLocalizations.localizationsDelegates,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: getForUiTheme(Brightness.light).toApproximateMaterialTheme(),
        builder: (context, child) => FTheme(
          data: getForUiTheme(Brightness.light),
          child: child!,
        ),
      ),
    ),
  );
  // Two pump passes: first lets async providers resolve; second lets
  // addPostFrameCallback (which calls _maybeShowWelcome) fire.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pumpAndSettle(const Duration(seconds: 3));
}

/// Pumps a MaterialApp.router starting at /about (AboutScreen).
/// AboutScreen uses FScaffold which relies on GoRouter for its back action,
/// so we wire a minimal router with both /about and / routes.
Future<void> _pumpAboutShell(
  WidgetTester tester, {
  required ProviderContainer container,
  String locale = 'en',
}) async {
  final router = GoRouter(
    initialLocation: '/about',
    routes: [
      GoRoute(
        path: '/',
        builder: (ctx, s) =>
            const Scaffold(body: Center(child: Text('HOME_STUB'))),
      ),
      GoRoute(
        path: '/about',
        builder: (ctx, s) => const AboutScreen(),
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        routerConfig: router,
        locale: Locale(locale),
        supportedLocales: const [
          Locale('en'),
          Locale('fr'),
          ...FLocalizations.supportedLocales,
        ],
        localizationsDelegates: const [
          AppLocalizations.delegate,
          ...FLocalizations.localizationsDelegates,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: getForUiTheme(Brightness.light).toApproximateMaterialTheme(),
        builder: (context, child) => FTheme(
          data: getForUiTheme(Brightness.light),
          child: child!,
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pumpAndSettle(const Duration(seconds: 3));
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  // ══════════════════════════════════════════════════════════════════════════
  // Test 1 — Shows once on first launch
  // ══════════════════════════════════════════════════════════════════════════
  group('welcome sheet — shows once on first launch', () {
    late AppDatabase db;
    late ProviderContainer container;

    setUp(() {
      db = _openMemoryDb();
      container = _makeContainer(db);
    });

    tearDown(() async {
      container.dispose();
      await db.close();
    });

    testWidgets(
        'welcome_title and verse refs appear when welcome_seen is unset; '
        'flag is written to DB after display', (tester) async {
      // Arrange: DB is fresh — welcome_seen is null (never been shown).
      final repo = SettingsRepository(db);
      expect(await repo.get(kKeyWelcomeSeen), isNull,
          reason: 'Pre-condition: flag must be absent in a fresh DB');

      // Act: pump HomeScreen without pre-seeding the flag.
      await _pumpHomeShell(tester, container: container);

      // Assert: sheet is visible — welcome_title must be in the widget tree.
      expect(
        find.text('Welcome'),
        findsOneWidget,
        reason:
            'welcome_title must appear on first launch. '
            'FAILS if _maybeShowWelcome is not called or skips when flag is null.',
      );

      // Assert: at least one verse reference is present (proves sheet content rendered).
      expect(
        find.textContaining('33:21'),
        findsAtLeastNWidgets(1),
        reason:
            'Verse reference for Al-Aḥzāb 33:21 must be present in the sheet. '
            'FAILS if the verse block was removed from welcome_sheet.dart.',
      );

      // Dismiss the sheet so _maybeShowWelcome can complete the await and
      // run repo.set(kKeyWelcomeSeen, 'true').
      // _BeginButton calls Navigator.of(context).pop(), which returns the
      // Future from showModalBottomSheet, allowing the awaiting code to proceed.
      await tester.tap(find.text('Begin'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Assert: flag is now written to the DB.
      final seenValue = await repo.get(kKeyWelcomeSeen);
      expect(
        seenValue,
        equals('true'),
        reason:
            "welcome_seen must be set to 'true' after the sheet is shown. "
            'FAILS if the repo.set call after showWelcomeSheet is missing.',
      );
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // Test 2 — Does NOT show when already seen
  // ══════════════════════════════════════════════════════════════════════════
  group('welcome sheet — suppressed when already seen', () {
    late AppDatabase db;
    late ProviderContainer container;

    setUp(() {
      db = _openMemoryDb();
      container = _makeContainer(db);
    });

    tearDown(() async {
      container.dispose();
      await db.close();
    });

    testWidgets(
        'welcome sheet is absent when welcome_seen is already true',
        (tester) async {
      // Arrange: pre-set the seen flag before pumping.
      await db.setSetting(kKeyWelcomeSeen, 'true');

      // Act: pump HomeScreen.
      await _pumpHomeShell(tester, container: container);

      // Assert: no sheet content is shown.
      expect(
        find.text('Welcome'),
        findsNothing,
        reason:
            'welcome_title must NOT appear when welcome_seen is already true. '
            "FAILS if the repo.get check is removed or the '== true' guard is inverted.",
      );
      expect(
        find.textContaining('33:21'),
        findsNothing,
        reason:
            'Verse reference must not appear when sheet is suppressed.',
      );
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // Test 3 — Reopen from About screen
  // ══════════════════════════════════════════════════════════════════════════
  group('welcome sheet — reopen from About via _WelcomeEntryCard', () {
    late AppDatabase db;
    late ProviderContainer container;

    setUp(() {
      db = _openMemoryDb();
      container = _makeContainer(db);
    });

    tearDown(() async {
      container.dispose();
      await db.close();
    });

    testWidgets(
        'tapping welcome_open in About opens sheet even when flag is true',
        (tester) async {
      // Arrange: flag is already set (user has seen the sheet on first launch).
      await db.setSetting(kKeyWelcomeSeen, 'true');

      // Pump AboutScreen inside a GoRouter shell (FScaffold/FHeader.nested
      // requires a Navigator that GoRouter provides).
      await _pumpAboutShell(tester, container: container);

      // The welcome_open card may be below the fold — scroll down to it.
      await tester.scrollUntilVisible(
        find.text('Welcome message'),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      // Assert: welcome_open card is present after scrolling.
      expect(
        find.text('Welcome message'),
        findsOneWidget,
        reason:
            'The welcome_open entry card must be visible in AboutScreen. '
            'FAILS if _WelcomeEntryCard was removed.',
      );

      // Act: tap the entry card.
      await tester.tap(find.text('Welcome message'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Assert: sheet is open.
      expect(
        find.text('Welcome'),
        findsOneWidget,
        reason:
            'Tapping _WelcomeEntryCard must open the welcome sheet. '
            'FAILS if the onTap callback is missing or calls a different function.',
      );
      expect(
        find.textContaining('3:31'),
        findsAtLeastNWidgets(1),
        reason:
            'Âl ʿImrān 3:31 verse ref must be present in the reopened sheet.',
      );
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // Test 4a — Content and localisation (EN)
  // ══════════════════════════════════════════════════════════════════════════
  group('welcome sheet — full content check (EN locale)', () {
    late AppDatabase db;
    late ProviderContainer container;

    setUp(() {
      db = _openMemoryDb();
      container = _makeContainer(db);
    });

    tearDown(() async {
      container.dispose();
      await db.close();
    });

    testWidgets(
        "EN: both verse refs, both Arabic ayat, disclaimer, GitHub issues URL, and du'a "
        'are all present', (tester) async {
      // Open via first-launch (flag unset) — ensures real widget path is exercised.
      await _pumpHomeShell(tester, container: container, locale: 'en');

      // ── Verse references ───────────────────────────────────────────────
      // EN: "Qur'an — Sûrat al-Aḥzāb, 33:21"
      expect(
        find.textContaining('33:21'),
        findsAtLeastNWidgets(1),
        reason:
            'EN ref for Al-Aḥzāb 33:21 must appear. '
            "FAILS if welcome_verse_ahzab_ref key is removed from app_en.arb.",
      );
      // EN: "Qur'an — Sûrat Âl ʿImrān, 3:31"  (note the ʿImrān with curly apostrophe)
      expect(
        find.textContaining('ʿImrān'),
        findsAtLeastNWidgets(1),
        reason:
            'EN imran ref must contain "ʿImrān" (with ʿayn + macron). '
            "FAILS if the transliteration in app_en.arb changes.",
      );
      expect(
        find.textContaining('3:31'),
        findsAtLeastNWidgets(1),
        reason: 'Verse number 3:31 must appear in the EN sheet.',
      );

      // ── Arabic āyāt ────────────────────────────────────────────────────
      expect(
        find.textContaining(kAyahAhzab33_21.substring(0, 10)),
        findsAtLeastNWidgets(1),
        reason:
            'Arabic text for kAyahAhzab33_21 must be rendered. '
            "FAILS if the kAyahAhzab33_21 const is removed from quran_ayat.dart.",
      );
      expect(
        find.textContaining(kAyahImran3_31.substring(0, 10)),
        findsAtLeastNWidgets(1),
        reason:
            'Arabic text for kAyahImran3_31 must be rendered. '
            "FAILS if kAyahImran3_31 is removed or the verse block dropped.",
      );

      // ── Disclaimer: free & ad-free ─────────────────────────────────────
      expect(
        find.textContaining('free of advertising'),
        findsAtLeastNWidgets(1),
        reason:
            'welcome_free_disclaimer must mention "free of advertising" in EN. '
            "FAILS if the disclaimer block is absent from _DisclaimerCard.",
      );

      // ── Report-mistakes / GitHub URL ──────────────────────────────────
      expect(
        find.textContaining('github.com/nouhouari/sira-quiz/issues'),
        findsAtLeastNWidgets(1),
        reason:
            'The GitHub issues URL must appear in the sheet (SelectableText). '
            'FAILS if _SelectableReportLine is removed or the URL changed.',
      );

      // ── Du'a ───────────────────────────────────────────────────────────
      expect(
        find.textContaining('Âmīn'),
        findsAtLeastNWidgets(1),
        reason:
            'welcome_dua must end with "Âmīn" in EN. '
            "FAILS if the du'a block is removed from the sheet.",
      );
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // Test 4b — Content and localisation (FR)
  // ══════════════════════════════════════════════════════════════════════════
  group('welcome sheet — full content check (FR locale)', () {
    late AppDatabase db;
    late ProviderContainer container;

    setUp(() {
      db = _openMemoryDb();
      container = _makeContainer(db);
    });

    tearDown(() async {
      container.dispose();
      await db.close();
    });

    testWidgets(
        "FR: title, both verse refs, Arabic ayat, disclaimer, GitHub issues URL, and du'a "
        'are all present', (tester) async {
      await _pumpHomeShell(tester, container: container, locale: 'fr');

      // FR title
      expect(
        find.text('Bienvenue'),
        findsOneWidget,
        reason:
            'FR welcome_title must be "Bienvenue". '
            "FAILS if app_fr.arb welcome_title key is missing.",
      );

      // FR verse references
      expect(
        find.textContaining('33:21'),
        findsAtLeastNWidgets(1),
        reason: 'Al-Aḥzāb verse number must appear in FR sheet.',
      );
      // FR: "Coran — Sourate Âl ʿImrān, 3:31"
      expect(
        find.textContaining('ʿImrān'),
        findsAtLeastNWidgets(1),
        reason:
            'FR imran ref must still contain "ʿImrān". '
            "FAILS if the transliteration was changed in app_fr.arb.",
      );
      expect(
        find.textContaining('3:31'),
        findsAtLeastNWidgets(1),
        reason: 'Verse number 3:31 must appear in the FR sheet.',
      );

      // Arabic āyāt — locale-invariant (same Arabic const in both locales)
      expect(
        find.textContaining(kAyahAhzab33_21.substring(0, 10)),
        findsAtLeastNWidgets(1),
        reason: 'Arabic kAyahAhzab33_21 must render in FR locale.',
      );
      expect(
        find.textContaining(kAyahImran3_31.substring(0, 10)),
        findsAtLeastNWidgets(1),
        reason: 'Arabic kAyahImran3_31 must render in FR locale.',
      );

      // FR disclaimer
      expect(
        find.textContaining('sans publicité'),
        findsAtLeastNWidgets(1),
        reason:
            'FR free disclaimer must contain "sans publicité". '
            "FAILS if welcome_free_disclaimer is absent from app_fr.arb.",
      );

      // GitHub URL — locale-invariant
      expect(
        find.textContaining('github.com/nouhouari/sira-quiz/issues'),
        findsAtLeastNWidgets(1),
        reason: 'The GitHub issues URL must appear in the FR sheet.',
      );

      // FR du'a
      expect(
        find.textContaining('Âmīn'),
        findsAtLeastNWidgets(1),
        reason:
            "FR welcome_dua must end with 'Âmīn'. "
            "FAILS if welcome_dua is absent from app_fr.arb.",
      );
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // Test 5 — Begin button dismisses the sheet
  // ══════════════════════════════════════════════════════════════════════════
  group('welcome sheet — Begin button pops the sheet', () {
    late AppDatabase db;
    late ProviderContainer container;

    setUp(() {
      db = _openMemoryDb();
      container = _makeContainer(db);
    });

    tearDown(() async {
      container.dispose();
      await db.close();
    });

    testWidgets(
        'tapping welcome_begin closes the sheet and leaves HomeScreen visible; '
        'no route change occurs', (tester) async {
      // Open via first-launch so the sheet appears.
      await _pumpHomeShell(tester, container: container);

      // Pre-condition: sheet is open.
      expect(
        find.text('Welcome'),
        findsOneWidget,
        reason: 'Pre-condition: sheet must be open before tapping Begin.',
      );
      expect(
        find.text('Begin'),
        findsOneWidget,
        reason: 'Pre-condition: Begin button must be present.',
      );

      // Act: tap Begin.
      await tester.tap(find.text('Begin'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Assert: sheet is gone.
      expect(
        find.text('Welcome'),
        findsNothing,
        reason:
            'welcome_title must disappear after tapping Begin. '
            'FAILS if _BeginButton no longer calls Navigator.of(context).pop().',
      );
      expect(
        find.text('Begin'),
        findsNothing,
        reason: 'Begin button must be gone after dismissal.',
      );

      // Assert: HomeScreen is still visible (no route push side-effects).
      expect(
        find.byKey(const Key('home_start_btn')),
        findsOneWidget,
        reason:
            'HomeScreen start button must be visible after sheet dismissal. '
            'FAILS if Begin triggers a route change instead of pop.',
      );
    });
  });
}
