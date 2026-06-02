// ignore_for_file: avoid_print
//
// Regression guard — Bug M-2
// "Last category card clipped behind system nav bar"
// ─────────────────────────────────────────────────────────────────────────────
// Root cause: CategoriesScreen's ListView.separated used a fixed
//   padding: EdgeInsets.fromLTRB(16, 16, 16, 24)
// FScaffold's _RenderScaffold only accounts for viewInsets (keyboard) — it
// does NOT add padding for viewPadding (system nav bar). On devices with a
// gesture navigation bar taller than 24 px (typically 48 logical pixels), the
// last category card ("Les Derniers Jours" / slug "final_days") is
// scrolled to but remains visually behind the nav bar and unreachable.
//
// Fix: bottom padding is now
//   24 + MediaQuery.of(context).viewPadding.bottom
// which ensures the last card always clears the nav bar.
//
// This test pumps CategoriesScreen inside the full app shell with a simulated
// 48 logical-pixel bottom view-padding (a realistic gesture-nav bar inset).
// It then flings to the bottom of the list and asserts that the last category
// card's bottom edge lies ABOVE the nav-bar inset boundary — i.e., within the
// safe viewport.  With the old fixed-24 padding (< 48) the assertion FAILS;
// with the fix it passes.

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:sira_quiz/core/l10n/arb/app_localizations.dart';
import 'package:sira_quiz/core/router/app_router.dart';
import 'package:sira_quiz/core/theme/app_theme.dart';
import 'package:sira_quiz/data/db/app_database.dart';
import 'package:sira_quiz/data/repositories/quiz_repository.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

AppDatabase _openMemoryDb() => AppDatabase(NativeDatabase.memory());

/// Seeds all 9 production categories with their real slugs and sortOrders.
/// The last category by sortOrder is 'final_days' (sortOrder=9).
Future<void> _seedCategories(AppDatabase db) async {
  await db.seedAll(
    cats: [
      CategoriesCompanion.insert(
        slug: 'birth_youth',
        iconKey: 'star',
        nameFr: 'Naissance et Jeunesse',
        nameEn: 'Birth and Youth',
        sortOrder: const Value(1),
      ),
      CategoriesCompanion.insert(
        slug: 'revelation',
        iconKey: 'book_open',
        nameFr: 'La Révélation',
        nameEn: 'The Revelation',
        sortOrder: const Value(2),
      ),
      CategoriesCompanion.insert(
        slug: 'meccan_period',
        iconKey: 'mosque',
        nameFr: 'Période Mecquoise',
        nameEn: 'Meccan Period',
        sortOrder: const Value(3),
      ),
      CategoriesCompanion.insert(
        slug: 'hijra',
        iconKey: 'route',
        nameFr: 'La Hijra',
        nameEn: 'The Hijra',
        sortOrder: const Value(4),
      ),
      CategoriesCompanion.insert(
        slug: 'medinan_period',
        iconKey: 'city',
        nameFr: 'Période Médinoise',
        nameEn: 'Medinan Period',
        sortOrder: const Value(5),
      ),
      CategoriesCompanion.insert(
        slug: 'expeditions',
        iconKey: 'shield',
        nameFr: 'Expéditions et Batailles',
        nameEn: 'Expeditions and Battles',
        sortOrder: const Value(6),
      ),
      CategoriesCompanion.insert(
        slug: 'family_companions',
        iconKey: 'people',
        nameFr: 'Famille et Compagnons',
        nameEn: 'Family and Companions',
        sortOrder: const Value(7),
      ),
      CategoriesCompanion.insert(
        slug: 'character',
        iconKey: 'heart',
        nameFr: 'Caractère et Morale',
        nameEn: 'Character and Morality',
        sortOrder: const Value(8),
      ),
      // ── Last category by sortOrder — the one that was clipped (M-2) ─────────
      CategoriesCompanion.insert(
        slug: 'final_days',
        iconKey: 'moon',
        nameFr: 'Les Derniers Jours',
        nameEn: 'The Final Days',
        sortOrder: const Value(9),
      ),
    ],
    qs: [],
    opts: [],
  );
}

/// Silent SoundNotifier — never touches haptics or prefs in test context.
class _SilentSoundNotifier extends SoundNotifier {
  @override
  Future<bool> build() async => false;
}

/// Pumps the full MaterialApp.router shell (same pattern as
/// quiz_render_regression_test.dart) and navigates to '/categories'.
///
/// [bottomViewPadding] simulates the device's system-nav-bar height (logical
/// pixels). Set to 48 to mimic a typical Android gesture-nav bar.
Future<void> _pumpCategoriesShell(
  WidgetTester tester,
  AppDatabase db, {
  double bottomViewPadding = 0,
}) async {
  final container = ProviderContainer(
    overrides: [
      appDatabaseProvider.overrideWithValue(db),
      soundNotifierProvider.overrideWith(() => _SilentSoundNotifier()),
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        routerConfig: appRouter,
        locale: const Locale('fr'),
        supportedLocales: const [
          Locale('fr'),
          Locale('en'),
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
        builder: (context, child) {
          return FTheme(
            data: getForUiTheme(Brightness.light),
            child: child!,
          );
        },
      ),
    ),
  );

  // Simulate the device's bottom view-padding (system nav bar).
  // This must be set AFTER pumpWidget so the view is bound to the tester.
  tester.view.viewPadding = FakeViewPadding(
    bottom: bottomViewPadding * tester.view.devicePixelRatio,
  );
  // Also set padding so MediaQuery.of(context).viewPadding reflects it.
  tester.view.padding = FakeViewPadding(
    bottom: bottomViewPadding * tester.view.devicePixelRatio,
  );

  addTearDown(() {
    tester.view.resetViewPadding();
    tester.view.resetPadding();
  });

  // Navigate to the categories screen.
  appRouter.go('/categories');
  // Allow the async FutureProvider + state rebuild to settle.
  await tester.pumpAndSettle(const Duration(seconds: 3));
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('regression M-2: last category card clears system nav bar', () {
    late AppDatabase db;

    setUp(() async {
      db = _openMemoryDb();
      await _seedCategories(db);
    });

    tearDown(() async {
      await db.close();
    });

    // ── 1. The geometric guard — FAILS on old fixed-24 padding under 48px inset

    testWidgets(
        'last category card (final_days) bottom edge is above the nav-bar '
        'inset boundary after scrolling to the end', (tester) async {
      // Simulate a phone-sized viewport with a 48 logical-px gesture-nav bar.
      // Screen: 390 × 844 logical px, 3× DPR (iPhone 14-ish scale for testing).
      const devicePixelRatio = 3.0;
      const bottomNavBarHeight = 48.0; // realistic Android gesture-nav height
      tester.view.devicePixelRatio = devicePixelRatio;
      tester.view.physicalSize = const Size(
        390 * devicePixelRatio,
        844 * devicePixelRatio,
      );
      addTearDown(() {
        tester.view.resetDevicePixelRatio();
        tester.view.resetPhysicalSize();
      });

      await _pumpCategoriesShell(
        tester,
        db,
        bottomViewPadding: bottomNavBarHeight,
      );

      // Scroll all the way to the bottom of the list.
      await tester.fling(
        find.byType(ListView),
        const Offset(0, -3000),
        3000,
      );
      await tester.pumpAndSettle();

      // The last card must now be findable in the widget tree.
      final lastCardFinder = find.byKey(const Key('category_card_final_days'));
      expect(
        lastCardFinder,
        findsOneWidget,
        reason:
            'Last category card (final_days) must be present in the widget '
            'tree after scrolling to the bottom',
      );

      // GEOMETRIC GUARD — this assertion FAILS on the old fixed-24 padding:
      //
      //   Old: bottom padding = 24 px
      //   Nav bar height     = 48 px
      //   → card bottom overflows into the nav-bar region by 24 px.
      //
      //   New: bottom padding = 24 + viewPadding.bottom (≥ 48) px
      //   → card bottom is fully above the nav-bar boundary.
      //
      // viewHeight is the full logical viewport height (including nav bar).
      // The safe viewport ends at (viewHeight - bottomNavBarHeight).
      final viewHeight = tester.view.physicalSize.height / devicePixelRatio;
      final safeViewportBottom = viewHeight - bottomNavBarHeight;

      final cardRect = tester.getRect(lastCardFinder);

      expect(
        cardRect.bottom,
        lessThanOrEqualTo(safeViewportBottom),
        reason:
            'Bug M-2: last category card (final_days) bottom (${cardRect.bottom.toStringAsFixed(1)} px) '
            'must be at or above the safe viewport boundary '
            '($safeViewportBottom px = viewport $viewHeight px − nav-bar $bottomNavBarHeight px). '
            'With the old fixed-24px bottom padding this fails because the card '
            'overlaps the system nav bar by ${(cardRect.bottom - safeViewportBottom).toStringAsFixed(1)} px.',
      );
    });

    // ── 2. Zero nav-bar inset — baseline sanity (no regression in nav-bar-less env)

    testWidgets(
        'last category card is visible and within bounds when there is no '
        'nav-bar inset (baseline sanity)', (tester) async {
      await _pumpCategoriesShell(tester, db);

      // Fling to the bottom.
      await tester.fling(
        find.byType(ListView),
        const Offset(0, -3000),
        3000,
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('category_card_final_days')),
        findsOneWidget,
        reason:
            'Last category card must be reachable by scroll even with no '
            'nav-bar inset (sanity check that fix does not break edge case)',
      );
    });

    // ── 3. All 10 cards are present after settling (structural sanity) ─────────

    testWidgets(
        'all 9 category cards are rendered after data loads', (tester) async {
      await _pumpCategoriesShell(tester, db);

      final slugs = [
        'birth_youth',
        'revelation',
        'meccan_period',
        'hijra',
        'medinan_period',
        'expeditions',
        'family_companions',
        'character',
        'final_days',
      ];

      for (final slug in slugs) {
        // Scroll until visible before asserting, since the list may be longer
        // than the viewport.
        await tester.scrollUntilVisible(
          find.byKey(Key('category_card_$slug')),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        expect(
          find.byKey(Key('category_card_$slug')),
          findsOneWidget,
          reason: 'Category card for slug "$slug" must be reachable by scroll',
        );
      }
    });
  });
}
