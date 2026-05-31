// ignore_for_file: avoid_print
//
// Store Screenshot Generator — Quiz Sira
// -----------------------------------------------------------------------------
// Run with:
//   flutter test test/store_screenshots_test.dart --timeout 240s
//
// Produces device-framed, captioned marketing screenshots at exact store
// dimensions for:
//   • Google Play     1080×2160  (android/fastlane/…/phoneScreenshots/)
//   • App Store 6.7"  1290×2796  (ios/fastlane/screenshots/{locale}/)
//   • App Store 6.5"  1242×2688  (ios/fastlane/screenshots/{locale}/)
// plus the Play feature graphic (1024×500) and hi-res icon (512×512).
//
// NOTE: the app ships iPhone-only on the App Store (no iPad target).
// App Store Connect must have iPad support disabled; set
// TARGETED_DEVICE_FAMILY = 1 in Xcode build settings (see RELEASE.md §4).
//
// All output goes to the fastlane folders so `supply` / `deliver` can pick
// them up without extra config.
//
// -- Key implementation notes -------------------------------------------------
// 1. Fonts: real bundled fonts (Amiri, Inter, CrimsonPro) AND icon fonts
//    (MaterialIcons, CupertinoIcons) are loaded via FontLoader before any
//    widget is pumped.  Without this step Flutter's test renderer displays
//    replacement boxes ("tofu") instead of text/icon glyphs.
//    Font loading uses tester.runAsync() because FontLoader.load() completes
//    on the REAL event loop (not the fake-async clock).
//
// 2. Device framing: each screen widget is wrapped in a DeviceFrame mockup
//    (device_frame package) sized to the store canvas, then captured via
//    RepaintBoundary.toImage() -> PNG.  This gives exact pixel dimensions
//    deterministically, with no emulator involved.
//
// 3. Data: uses an in-memory Drift DB (NativeDatabase.memory()) seeded from
//    the real questions_seed.json asset.  An answered-state quiz screenshot is
//    produced by driving the controller through pump+tap.
//
// 4. PNGs are opaque: an opaque emerald/sand background is painted before
//    compositing the DeviceFrame, satisfying App Store + Play Store validators.
//
// 5. Real-async capture: toImage() / toByteData() / FontLoader.load() all
//    complete on the REAL event loop, which the test's fake-async clock never
//    pumps.  Every such call is therefore wrapped in tester.runAsync() so the
//    binding switches to the real event loop for the duration.
//
// 6. Config-driven targets: device targets are declared once in _deviceTargets
//    and every screen recipe is rendered for every target automatically.
//    Adding a new store size = add one entry to _deviceTargets.

import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:device_frame/device_frame.dart';
import 'package:drift/drift.dart' hide Column, isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:sira_quiz/core/l10n/arb/app_localizations.dart';
import 'package:sira_quiz/core/router/app_router.dart';
import 'package:sira_quiz/core/theme/app_theme.dart';
import 'package:sira_quiz/core/theme/islamic_pattern_painter.dart';
import 'package:sira_quiz/data/db/app_database.dart';
import 'package:sira_quiz/data/repositories/quiz_repository.dart';
import 'package:sira_quiz/domain/models/difficulty.dart';
import 'package:sira_quiz/features/about/about_screen.dart';
import 'package:sira_quiz/features/categories/categories_screen.dart';
import 'package:sira_quiz/features/difficulty/difficulty_screen.dart';
import 'package:sira_quiz/features/home/home_screen.dart';
import 'package:sira_quiz/features/quiz/quiz_controller.dart';
import 'package:sira_quiz/features/quiz/quiz_screen.dart';
import 'package:sira_quiz/features/result/result_screen.dart';

// -- Repo root resolution -----------------------------------------------------

/// `flutter test` always runs with the project root as the working directory.
/// `Directory.current.path` is therefore the repo root on all machines.
/// (Platform.script in test mode points to a temp compiled file, not the
///  source tree -- so we never use it for output paths.)
String get _repoRoot => Directory.current.path;

// -- Output path constants ----------------------------------------------------

String _playDir(String locale) =>
    '$_repoRoot/android/fastlane/metadata/android/$locale/images/phoneScreenshots';

String _appStoreDir(String locale) =>
    '$_repoRoot/ios/fastlane/screenshots/$locale';

String _featureGraphicPath(String locale) =>
    '$_repoRoot/android/fastlane/metadata/android/$locale/images/featureGraphic.png';

String _iconPath(String locale) =>
    '$_repoRoot/android/fastlane/metadata/android/$locale/images/icon.png';

// -- Store canvas sizes (exact) -----------------------------------------------

// Google Play phone -- exactly 2:1, passes the "max 2:1 aspect ratio" check.
const _playW = 1080.0;
const _playH = 2160.0;

// App Store 6.7" (iPhone 14/15/16 Pro Max class).
const _store67W = 1290.0;
const _store67H = 2796.0;

// App Store 6.5" (iPhone 11 Pro Max / XS Max class).
const _store65W = 1242.0;
const _store65H = 2688.0;

// Feature graphic
const _fgW = 1024.0;
const _fgH = 500.0;

// Hi-res icon
const _iconSz = 512.0;

// -- Device target configuration ----------------------------------------------
//
// Each entry drives one store-size output.  The screen "recipes" (which widget
// to render and which caption) are defined once and looped over every target.
//
// [slug]         Used in output filenames: ${index}_${slug}_${screenSlug}.png
//                For Play, slug is empty and the file is ${index}_${screenSlug}.png
// [deviceFrame]  The DeviceFrame to wrap the screen in.
// [canvasSize]   Exact pixel canvas the PNG must be.
// [outputDir]    Function from storeLocale -> absolute output directory path.
// [assertLabel]  Human-readable label for dimension assertions in logs.

class _TargetConfig {
  final String slug;
  final DeviceInfo deviceFrame;
  final Size canvasSize;
  final String Function(String storeLocale) outputDir;
  final String assertLabel;

  const _TargetConfig({
    required this.slug,
    required this.deviceFrame,
    required this.canvasSize,
    required this.outputDir,
    required this.assertLabel,
  });
}

final List<_TargetConfig> _deviceTargets = [
  // ---- Google Play 1080×2160 ------------------------------------------------
  _TargetConfig(
    slug: '', // no size suffix — filename: ${index}_${screenSlug}.png
    deviceFrame: Devices.android.samsungGalaxyS20,
    canvasSize: const Size(_playW, _playH),
    outputDir: _playDir,
    assertLabel: 'Play 1080×2160',
  ),
  // ---- App Store 6.7" 1290×2796 ---------------------------------------------
  _TargetConfig(
    slug: '67',
    deviceFrame: Devices.ios.iPhone13ProMax,
    canvasSize: const Size(_store67W, _store67H),
    outputDir: _appStoreDir,
    assertLabel: 'AppStore 6.7" 1290×2796',
  ),
  // ---- App Store 6.5" 1242×2688 ---------------------------------------------
  // iPhone 11 Pro Max (XS Max class) — screenSize 414×896, pixelRatio 3
  // → physical frame ~1242×2688, which matches the required canvas exactly.
  _TargetConfig(
    slug: '65',
    deviceFrame: Devices.ios.iPhone11ProMax,
    canvasSize: const Size(_store65W, _store65H),
    outputDir: _appStoreDir,
    assertLabel: 'AppStore 6.5" 1242×2688',
  ),
];

// -- Caption copy (localized) --------------------------------------------------
//
// MARKETING DRAFTS -- see _SCREENSHOT_COPY_DRAFT.md for review checklist.

const _captions = {
  'en': [
    'Learn the life of the Prophet Mohammed (SWS)',
    '10 thematic categories',
    'Three difficulty levels',
    'Authentic sources, cited',
    'Track your progress',
    '100% offline·no ads·no tracking',
  ],
  'fr': [
    'Apprenez la vie du Prophète Mohammed (SWS)',
    '10 catégories thématiques',
    '3 niveaux de difficulté',
    'Des sources authentiques, citées',
    'Suivez votre progression',
    '100% hors-ligne·sans pub·sans pistage',
  ],
};

const _screenSlugs = [
  'home',
  'categories',
  'difficulty',
  'quiz_answered',
  'result',
  'about',
];

// -- Font loading -------------------------------------------------------------

// -- Portable font-path helpers -----------------------------------------------

/// Parses `.dart_tool/package_config.json` and returns the absolute file-system
/// path for [relativeAssetPath] inside the given pub [packageName].
///
/// Example:
///   _packageAssetPath('cupertino_icons', 'assets/CupertinoIcons.ttf')
///   // => '/home/runner/.pub-cache/hosted/pub.dev/cupertino_icons-1.0.9/assets/CupertinoIcons.ttf'
///
/// Returns null if the package is not listed or the file does not exist.
String? _packageAssetPath(String packageName, String relativeAssetPath) {
  try {
    final configFile =
        File('${Directory.current.path}/.dart_tool/package_config.json');
    if (!configFile.existsSync()) return null;

    final json =
        jsonDecode(configFile.readAsStringSync()) as Map<String, dynamic>;
    final packages = json['packages'] as List<dynamic>;

    for (final pkg in packages) {
      if ((pkg as Map<String, dynamic>)['name'] == packageName) {
        final rootUri = pkg['rootUri'] as String;
        // rootUri is a file:// URI or a relative path.
        final rootPath = rootUri.startsWith('file://')
            ? Uri.parse(rootUri).toFilePath()
            : '${Directory.current.path}/.dart_tool/$rootUri';
        final assetPath = '$rootPath/$relativeAssetPath';
        if (File(assetPath).existsSync()) return assetPath;
        // Some paths have a trailing slash in rootUri; strip and retry.
        final stripped = rootPath.endsWith('/')
            ? rootPath.substring(0, rootPath.length - 1)
            : rootPath;
        final alt = '$stripped/$relativeAssetPath';
        if (File(alt).existsSync()) return alt;
        // Return regardless — caller will handle missing file gracefully.
        return assetPath;
      }
    }
  } catch (e) {
    print('[screenshots] WARNING: could not parse package_config.json: $e');
  }
  return null;
}

/// Resolves the path to `MaterialIcons-Regular.otf` from the Flutter SDK.
///
/// Resolution order:
///   1. `FLUTTER_ROOT` env var (set automatically by `flutter test`).
///   2. Walk up from the running Dart executable to find the SDK root
///      (Dart exe is at `<sdk>/bin/cache/dart-sdk/bin/dart`).
///   3. FVM default location (`~/fvm/versions/stable/...`) as last resort.
///
/// Returns null if none of the candidates exist.
String? _materialIconsPath() {
  const relPath =
      'bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf';

  // 1. FLUTTER_ROOT env var (most reliable in CI and `flutter test`).
  final flutterRoot = Platform.environment['FLUTTER_ROOT'];
  if (flutterRoot != null && flutterRoot.isNotEmpty) {
    final candidate = '$flutterRoot/$relPath';
    if (File(candidate).existsSync()) return candidate;
  }

  // 2. Derive SDK root from the running Dart executable.
  //    Layout: <flutter-sdk>/bin/cache/dart-sdk/bin/dart
  //    Walking up 4 levels gives the Flutter SDK root.
  try {
    final dartExe = File(Platform.resolvedExecutable);
    // bin/cache/dart-sdk/bin -> bin/cache/dart-sdk -> bin/cache -> bin -> <root>
    var dir = dartExe.parent; // .../bin
    for (var i = 0; i < 4; i++) {
      dir = dir.parent;
    }
    final candidate = '${dir.path}/$relPath';
    if (File(candidate).existsSync()) return candidate;
  } catch (_) {}

  // 3. FVM fallback (covers local dev on macOS with FVM).
  final home = Platform.environment['HOME'] ?? '';
  if (home.isNotEmpty) {
    final candidate = '$home/fvm/versions/stable/$relPath';
    if (File(candidate).existsSync()) return candidate;
  }

  return null;
}

/// Loads all bundled fonts AND icon fonts into the test font registry.
///
/// IMPORTANT: this must be called inside a tester.runAsync() block because
/// FontLoader.load() completes on the real event loop, which the fake-async
/// test clock never pumps.  Calling it outside runAsync causes a permanent hang.
///
/// Icon fonts (MaterialIcons, CupertinoIcons) are loaded from their on-disk
/// paths because they are not declared in pubspec.yaml as regular assets.
/// The runner passes --disable-asset-fonts so we MUST load every family we
/// depend on manually.
///
/// Paths are resolved dynamically so this works on any machine / CI runner:
///   - pub packages  → parsed from .dart_tool/package_config.json
///   - MaterialIcons → resolved from FLUTTER_ROOT env var or Dart exe location
Future<void> _loadFonts() async {
  Future<void> loadAsset(String family, String assetPath) async {
    final loader = FontLoader(family);
    final bytes = await rootBundle.load(assetPath);
    loader.addFont(Future.value(bytes));
    await loader.load();
  }

  Future<void> loadFile(String family, String filePath) async {
    final file = File(filePath);
    if (!file.existsSync()) {
      print('[screenshots] WARNING: font file not found, skipping: $filePath');
      return;
    }
    final loader = FontLoader(family);
    final bytes = file.readAsBytesSync();
    loader.addFont(Future.value(ByteData.sublistView(bytes)));
    await loader.load();
  }

  // Amiri (display / Arabic-capable)
  await loadAsset('Amiri', 'assets/fonts/Amiri-Regular.ttf');
  await loadAsset('Amiri', 'assets/fonts/Amiri-Bold.ttf');

  // Inter (UI body)
  await loadAsset('Inter', 'assets/fonts/Inter-Regular.ttf');
  await loadAsset('Inter', 'assets/fonts/Inter-Medium.ttf');
  await loadAsset('Inter', 'assets/fonts/Inter-SemiBold.ttf');
  await loadAsset('Inter', 'assets/fonts/Inter-Bold.ttf');

  // CrimsonPro (reading body)
  // The asset TTFs are genuine TrueType files (replaced 2025-05-31; magic bytes
  // 00 01 00 00 verified).  Load them via rootBundle like the other bundled fonts.
  await loadAsset('CrimsonPro', 'assets/fonts/CrimsonPro-Regular.ttf');
  await loadAsset('CrimsonPro', 'assets/fonts/CrimsonPro-SemiBold.ttf');
  await loadAsset('CrimsonPro', 'assets/fonts/CrimsonPro-Italic.ttf');

  // MaterialIcons -- required for all Icons.* glyphs used throughout the app
  // (book, chevron, check, cancel, refresh, settings, etc.).
  // Resolved dynamically from FLUTTER_ROOT / Dart exe location (CI-portable).
  final materialIconsPath = _materialIconsPath();
  if (materialIconsPath != null) {
    await loadFile('MaterialIcons', materialIconsPath);
  } else {
    print('[screenshots] WARNING: MaterialIcons-Regular.otf not found -- '
        'icon glyphs may render as tofu. Set FLUTTER_ROOT or run via flutter test.');
  }

  // CupertinoIcons -- resolved from .dart_tool/package_config.json (version-agnostic).
  final cupertinoIconsPath =
      _packageAssetPath('cupertino_icons', 'assets/CupertinoIcons.ttf');
  if (cupertinoIconsPath != null) {
    await loadFile('CupertinoIcons', cupertinoIconsPath);
  } else {
    print('[screenshots] WARNING: CupertinoIcons.ttf not found in pub cache -- '
        'Cupertino glyphs may render as tofu.');
  }

  // ForUI Lucide icons -- ForUI declares IconData with
  //   fontFamily: 'ForuiLucideIcons', fontPackage: 'forui_assets'
  // Flutter resolves packaged fonts as 'packages/<pkg>/<family>', so we must
  // register the font under the resolved name the Icon widget looks up at
  // paint time.
  // Resolved from .dart_tool/package_config.json (version-agnostic).
  final lucideFontPath =
      _packageAssetPath('forui_assets', 'assets/lucide.ttf');
  if (lucideFontPath != null) {
    await loadFile('packages/forui_assets/ForuiLucideIcons', lucideFontPath);
  } else {
    print('[screenshots] WARNING: forui_assets lucide.ttf not found -- '
        'ForUI icons may render as tofu.');
  }
}

// -- In-memory DB with real seed data -----------------------------------------

AppDatabase _openMemoryDb() => AppDatabase(NativeDatabase.memory());

/// Seeds the in-memory DB from the real questions_seed.json asset.
Future<void> _seedFromJson(AppDatabase db) async {
  final jsonString =
      await rootBundle.loadString('lib/data/db/seed/questions_seed.json');
  final data = jsonDecode(jsonString) as Map<String, dynamic>;

  final rawCategories = data['categories'] as List<dynamic>;
  final rawQuestions = data['questions'] as List<dynamic>;

  final cats = rawCategories.map((c) {
    final m = c as Map<String, dynamic>;
    return CategoriesCompanion.insert(
      slug: m['slug'] as String,
      iconKey: m['iconKey'] as String,
      nameFr: m['nameFr'] as String,
      nameEn: m['nameEn'] as String,
      sortOrder: Value(m['sortOrder'] as int),
    );
  }).toList();

  final questionCompanions = <QuestionsCompanion>[];
  final optionsByQuestionId = <int, List<Map<String, dynamic>>>{};

  for (final q in rawQuestions) {
    final m = q as Map<String, dynamic>;
    final qId = m['id'] as int;
    questionCompanions.add(QuestionsCompanion.insert(
      id: Value(qId),
      categorySlug: m['categorySlug'] as String,
      difficulty: m['difficulty'] as int,
      type: m['type'] as String,
      promptFr: m['promptFr'] as String,
      promptEn: m['promptEn'] as String,
      explanationFr: m['explanationFr'] as String,
      explanationEn: m['explanationEn'] as String,
      sourceArabic: Value(m['sourceArabic'] as String?),
      sourceReference: m['sourceReference'] as String,
    ));
    optionsByQuestionId[qId] =
        (m['options'] as List<dynamic>).cast<Map<String, dynamic>>();
  }

  int optionAutoId = 1;
  final optionCompanions = <QuestionOptionsCompanion>[];
  for (final entry in optionsByQuestionId.entries) {
    for (final o in entry.value) {
      optionCompanions.add(QuestionOptionsCompanion.insert(
        id: Value(optionAutoId++),
        questionId: entry.key,
        textFr: o['textFr'] as String,
        textEn: o['textEn'] as String,
        isCorrect: Value(o['isCorrect'] as bool),
        sortOrder: Value(o['sortOrder'] as int),
      ));
    }
  }

  await db.seedAll(cats: cats, qs: questionCompanions, opts: optionCompanions);
}

// -- SilentSoundNotifier ------------------------------------------------------

class _SilentSoundNotifier extends SoundNotifier {
  @override
  Future<bool> build() async => false;
}

// -- Provider container -------------------------------------------------------

ProviderContainer _makeContainer(AppDatabase db) {
  return ProviderContainer(
    overrides: [
      appDatabaseProvider.overrideWithValue(db),
      soundNotifierProvider.overrideWith(() => _SilentSoundNotifier()),
    ],
  );
}

// -- App shell widget ---------------------------------------------------------

/// Wraps a widget in the full app shell (theme, l10n, ProviderScope).
Widget _appShell({
  required AppDatabase db,
  required String locale,
  required Widget child,
  ProviderContainer? container,
}) {
  final c = container ?? _makeContainer(db);
  return UncontrolledProviderScope(
    container: c,
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: Locale(locale),
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
      builder: (context, _) => FTheme(
        data: getForUiTheme(Brightness.light),
        child: child,
      ),
      home: FTheme(
        data: getForUiTheme(Brightness.light),
        child: child,
      ),
    ),
  );
}

/// Router-backed shell -- needed for screens that use context.pop() or push().
Widget _appShellWithRouter({
  required AppDatabase db,
  required String locale,
  required ProviderContainer container,
}) {
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp.router(
      debugShowCheckedModeBanner: false,
      routerConfig: appRouter,
      locale: Locale(locale),
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
      builder: (context, child) => FTheme(
        data: getForUiTheme(Brightness.light),
        child: child!,
      ),
    ),
  );
}

// -- PNG capture --------------------------------------------------------------

/// Renders [widget] at [logicalSize], advances frames, then captures to PNG.
///
/// FIX for the permanent-hang bug: toImage() and toByteData() must complete
/// on the REAL event loop.  In flutter test, the event loop is fake by default
/// and awaiting real-async Futures inside the test body causes a deadlock.
/// We wrap both calls in `tester.runAsync()` which temporarily switches the
/// binding to the real event loop for the duration of the closure.
///
/// Uses `pump(Duration)` with a large elapsed time rather than `pumpAndSettle`
/// -- the latter never returns when there are repeating or long-duration
/// animations (e.g. AnimationController that drives a score ring or home
/// entrance), causing the test to time out.
///
/// By advancing the clock by [settle] we ensure all one-shot animations
/// (max 660ms on HomeScreen, 900ms score ring) have completed their final
/// frame without triggering an infinite wait.
Future<Uint8List> _captureWidget(
  WidgetTester tester, {
  required Widget widget,
  required Size logicalSize,
  Duration settle = const Duration(milliseconds: 2500),
}) async {
  final boundaryKey = GlobalKey();

  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: MediaQuery(
        data: MediaQueryData(size: logicalSize),
        child: RepaintBoundary(
          key: boundaryKey,
          child: SizedBox(
            width: logicalSize.width,
            height: logicalSize.height,
            child: widget,
          ),
        ),
      ),
    ),
  );

  // Pump initial frame + any post-frame callbacks.
  await tester.pump();

  // Advance by [settle] so all one-shot animations reach their end state.
  // This is safer than pumpAndSettle for screens with AnimationControllers
  // that schedule frames (pumpAndSettle never returns until zero pending frames,
  // which can stall if an animation controller keeps firing).
  await tester.pump(settle);

  // One final pump to pick up any layout triggered by the settled state.
  await tester.pump(const Duration(milliseconds: 100));

  final boundary = boundaryKey.currentContext!.findRenderObject()!
      as RenderRepaintBoundary;

  // FIX: wrap toImage() + toByteData() in tester.runAsync() so they execute
  // on the REAL event loop.  Without this they await forever in the fake-async
  // environment, causing the permanent deadlock.
  final png = await tester.runAsync(() async {
    final ui.Image image = await boundary.toImage(pixelRatio: 1.0);
    final byteData =
        await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return byteData!.buffer.asUint8List();
  });

  return png!;
}

// -- Store canvas composition -------------------------------------------------

/// Produces a fully-composed store screenshot:
///   background (sand + subtle emerald) -> DeviceFrame -> caption banner.
Widget _storeCanvas({
  required Widget screenWidget,
  required DeviceInfo deviceFrame,
  required double canvasW,
  required double canvasH,
  required String caption,
}) {
  final frameH = canvasH * 0.80;

  return SizedBox(
    width: canvasW,
    height: canvasH,
    child: Stack(
      children: [
        // Opaque background
        Positioned.fill(
          child: CustomPaint(painter: _BgPainter()),
        ),
        // Device frame in upper 80%
        Positioned(
          top: 0,
          left: 0,
          width: canvasW,
          height: frameH,
          child: Center(
            child: DeviceFrame(
              device: deviceFrame,
              screen: screenWidget,
            ),
          ),
        ),
        // Caption banner in lower 20%
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: canvasH * 0.20,
          child: _CaptionBanner(caption: caption),
        ),
      ],
    ),
  );
}

/// Opaque sand background with subtle emerald radial and khatam watermark.
class _BgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = sandBg,
    );

    final glow = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0, -0.6),
        radius: 0.85,
        colors: [
          emerald.withAlpha(28),
          sandBg.withAlpha(0),
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, glow);

    IslamicPatternPainter(
      color: gold.withAlpha(18),
      cellSize: 48,
      strokeWidth: 0.8,
    ).paint(canvas, size);
  }

  @override
  bool shouldRepaint(_BgPainter old) => false;
}

/// Emerald caption banner -- Amiri headline, white on emerald (legible).
class _CaptionBanner extends StatelessWidget {
  final String caption;

  const _CaptionBanner({required this.caption});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [emerald, emeraldDark],
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(height: 1.5, color: gold.withAlpha(160)),
          const SizedBox(height: 16),
          Text(
            caption,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: kDisplayFont,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: -0.3,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: gold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// -- Feature graphic widget ---------------------------------------------------

Widget _featureGraphicWidget(String locale) {
  final tagline = locale == 'fr'
      ? 'Quiz interactif sur la vie du Prophète (SWS)'
      : 'Interactive quiz on the life of the Prophet (SWS)';

  return SizedBox(
    width: _fgW,
    height: _fgH,
    child: Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(painter: _FgBgPainter()),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 64, vertical: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withAlpha(25),
                  border: Border.all(color: gold.withAlpha(180), width: 2),
                ),
                child: const Icon(
                  Icons.menu_book_rounded,
                  color: Colors.white,
                  size: 38,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Quiz Sîra',
                style: TextStyle(
                  fontFamily: kDisplayFont,
                  fontSize: 56,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: -1.0,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 10),
              Container(width: 80, height: 2, color: gold),
              const SizedBox(height: 14),
              Text(
                tagline,
                style: TextStyle(
                  fontFamily: kBodyFont,
                  fontFamilyFallback: const [kDisplayFont],
                  fontSize: 22,
                  color: Colors.white.withAlpha(220),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _FgBgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [emeraldDark, emerald, emeraldLight],
          stops: [0.0, 0.6, 1.0],
        ).createShader(Offset.zero & size),
    );
    IslamicPatternPainter(
      color: gold.withAlpha(40),
      cellSize: 56,
      strokeWidth: 1.0,
    ).paint(canvas, size);
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0.85, 0.1),
          radius: 0.45,
          colors: [gold.withAlpha(40), gold.withAlpha(0)],
        ).createShader(Offset.zero & size),
    );
  }

  @override
  bool shouldRepaint(_FgBgPainter old) => false;
}

// -- Hi-res icon widget -------------------------------------------------------

Widget _iconWidget() {
  return SizedBox(
    width: _iconSz,
    height: _iconSz,
    child: CustomPaint(
      painter: _IconBgPainter(),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withAlpha(30),
                border: Border.all(color: gold.withAlpha(200), width: 4),
              ),
              child: const Icon(
                Icons.menu_book_rounded,
                color: Colors.white,
                size: 130,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'سيرة',
              style: TextStyle(
                fontFamily: kDisplayFont,
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _IconBgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(100),
    );
    canvas.drawRRect(
      rrect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [emeraldDark, emerald],
        ).createShader(Offset.zero & size),
    );
    canvas.clipRRect(rrect);
    IslamicPatternPainter(
      color: gold.withAlpha(50),
      cellSize: 56,
      strokeWidth: 1.2,
    ).paint(canvas, size);
  }

  @override
  bool shouldRepaint(_IconBgPainter old) => false;
}

// -- File write helper --------------------------------------------------------

/// Writes PNG bytes to disk.
///
/// FIX: file.parent.create() and file.writeAsBytes() are real async I/O.
/// Inside the flutter-test fake-async environment they never resolve unless
/// wrapped in tester.runAsync().  We therefore require the caller to pass
/// tester and call those operations inside runAsync.
Future<void> _writePng(
    WidgetTester tester, String path, Uint8List bytes) async {
  await tester.runAsync(() async {
    final file = File(path);
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes);
  });
  print('[screenshots] Written: $path (${(bytes.length / 1024).round()} KB)');
}

// -- PNG dimension assertion --------------------------------------------------

/// Reads width+height from the PNG IHDR chunk and reports.
void _assertPngDimensions(
    Uint8List png, int expectedW, int expectedH, String label) {
  if (png.length < 24) {
    print('[screenshots] WARNING: $label PNG too short to verify dimensions');
    return;
  }
  // IHDR: bytes 16-23 (after 8-byte sig + 4-byte len + 4-byte "IHDR")
  final w = (png[16] << 24) | (png[17] << 16) | (png[18] << 8) | png[19];
  final h = (png[20] << 24) | (png[21] << 16) | (png[22] << 8) | png[23];
  if (w != expectedW || h != expectedH) {
    print(
        '[screenshots] WARNING: $label expected ${expectedW}x$expectedH, '
        'got ${w}x$h');
  } else {
    print('[screenshots] OK: $label is ${w}x$h');
  }
}

// -- Output filename for a target + screen ------------------------------------

String _outputPath({
  required _TargetConfig target,
  required String storeLocale,
  required int index,
  required String screenSlug,
}) {
  final dir = target.outputDir(storeLocale);
  // Play has no size suffix — keep existing naming: ${index}_${screenSlug}.png
  // iOS targets include the size suffix: ${index}_${slug}_${screenSlug}.png
  final name = target.slug.isEmpty
      ? '${index}_$screenSlug.png'
      : '${index}_${target.slug}_$screenSlug.png';
  return '$dir/$name';
}

// -- Per-screen, per-target static capture ------------------------------------

/// Captures a static (non-interactive) screen widget for every device target
/// and writes PNGs for the given [locale] / [storeLocale].
Future<void> _captureScreenAllTargets({
  required WidgetTester tester,
  required AppDatabase db,
  required String locale,
  required String storeLocale,
  required Widget Function() screenWidgetBuilder,
  required String caption,
  required String screenSlug,
}) async {
  final index = _screenSlugs.indexOf(screenSlug) + 1;

  for (final target in _deviceTargets) {
    tester.view.physicalSize = target.canvasSize;
    tester.view.devicePixelRatio = 1.0;

    final canvas = _storeCanvas(
      screenWidget: screenWidgetBuilder(),
      deviceFrame: target.deviceFrame,
      canvasW: target.canvasSize.width,
      canvasH: target.canvasSize.height,
      caption: caption,
    );

    final bytes = await _captureWidget(
      tester,
      widget: canvas,
      logicalSize: target.canvasSize,
    );

    final path = _outputPath(
      target: target,
      storeLocale: storeLocale,
      index: index,
      screenSlug: screenSlug,
    );
    await _writePng(tester, path, bytes);
    _assertPngDimensions(
      bytes,
      target.canvasSize.width.toInt(),
      target.canvasSize.height.toInt(),
      '${target.assertLabel} $screenSlug [$locale]',
    );
  }
}

// -- Quiz answered state capture (interactive, all targets) -------------------

/// Drives the quiz to the answered state (option tapped → feedback + source
/// visible) then captures for every device target.
///
/// Because driving interaction requires a live widget tree, we re-pump a fresh
/// QuizScreen for each target size so the layout is correct for that canvas.
Future<void> _captureQuizAnsweredAllTargets({
  required WidgetTester tester,
  required AppDatabase db,
  required String locale,
  required String storeLocale,
  required String caption,
}) async {
  const screenSlug = 'quiz_answered';
  final index = _screenSlugs.indexOf(screenSlug) + 1;

  for (final target in _deviceTargets) {
    tester.view.physicalSize = target.canvasSize;
    tester.view.devicePixelRatio = 1.0;

    final container = _makeContainer(db);
    // Pre-set session params so QuizScreen's initState finds them.
    container.read(sessionParamsProvider.notifier).state = SessionParams(
      categorySlug: 'revelation',
      difficulty: Difficulty.beginner,
    );

    final screenWidget = _appShell(
      db: db,
      locale: locale,
      child: const QuizScreen(),
      container: container,
    );

    final boundaryKey = GlobalKey();

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
          data: MediaQueryData(size: target.canvasSize),
          child: RepaintBoundary(
            key: boundaryKey,
            child: SizedBox(
              width: target.canvasSize.width,
              height: target.canvasSize.height,
              child: _storeCanvas(
                screenWidget: screenWidget,
                deviceFrame: target.deviceFrame,
                canvasW: target.canvasSize.width,
                canvasH: target.canvasSize.height,
                caption: caption,
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    // Advance clock so the async DB load resolves and options appear.
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 500));

    // Tap the first option tile to reach the answered state
    // (feedback card + source citation become visible).
    final tiles = find.byWidgetPredicate(
      (w) => w.key != null && w.key.toString().contains('option_tile_'),
    );
    if (tiles.evaluate().isNotEmpty) {
      await tester.tap(tiles.first);
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(milliseconds: 500));
    }

    // Pump long enough to fully complete the feedback card scale animation
    // (260ms) and any trailing layout work, then settle.
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pump(const Duration(milliseconds: 200));

    final boundary = boundaryKey.currentContext!.findRenderObject()!
        as RenderRepaintBoundary;
    final bytes = await tester.runAsync(() async {
      final ui.Image image = await boundary.toImage(pixelRatio: 1.0);
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      return byteData!.buffer.asUint8List();
    });

    final path = _outputPath(
      target: target,
      storeLocale: storeLocale,
      index: index,
      screenSlug: screenSlug,
    );
    await _writePng(tester, path, bytes!);
    _assertPngDimensions(
      bytes,
      target.canvasSize.width.toInt(),
      target.canvasSize.height.toInt(),
      '${target.assertLabel} quiz_answered [$locale]',
    );

    // Allow the tree to fully settle before the next iteration.
    await tester.pump(const Duration(seconds: 1));
    container.dispose();
  }
}

// -- Main test suite ----------------------------------------------------------

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // FIX: FontLoader.load() completes on the REAL event loop.  setUpAll does
    // NOT provide a WidgetTester, so we use the binding's own runAsync helper
    // (AutomatedTestWidgetsFlutterBinding.instance.runAsync) to escape the
    // fake-async zone while loading fonts.
    print('[screenshots] Loading bundled fonts...');
    await TestWidgetsFlutterBinding.instance.runAsync(_loadFonts);
    print('[screenshots] Fonts loaded.');

    final draftPath = '$_repoRoot/_SCREENSHOT_COPY_DRAFT.md';
    final draftFile = File(draftPath);
    if (!draftFile.existsSync()) {
      await draftFile.writeAsString(_copyDraftContent);
      print('[screenshots] Written: $draftPath');
    }
  });

  group('store screenshot generator', () {
    late AppDatabase db;

    setUp(() async {
      db = _openMemoryDb();
      await _seedFromJson(db);
    });

    tearDown(() async {
      await db.close();
    });

    for (final locale in ['en', 'fr']) {
      final storeLocale = locale == 'en' ? 'en-US' : 'fr-FR';
      final captions = _captions[locale]!;

      // -- Screen 1: Home -------------------------------------------------------

      testWidgets('screen 1 home [$locale]', (tester) async {
        tester.view.devicePixelRatio = 1.0;
        await _captureScreenAllTargets(
          tester: tester,
          db: db,
          locale: locale,
          storeLocale: storeLocale,
          screenWidgetBuilder: () =>
              _appShell(db: db, locale: locale, child: const HomeScreen()),
          caption: captions[0],
          screenSlug: _screenSlugs[0],
        );
      }, timeout: const Timeout(Duration(minutes: 4)));

      // -- Screen 2: Categories -------------------------------------------------

      testWidgets('screen 2 categories [$locale]', (tester) async {
        tester.view.devicePixelRatio = 1.0;
        await _captureScreenAllTargets(
          tester: tester,
          db: db,
          locale: locale,
          storeLocale: storeLocale,
          screenWidgetBuilder: () =>
              _appShell(db: db, locale: locale, child: const CategoriesScreen()),
          caption: captions[1],
          screenSlug: _screenSlugs[1],
        );
      }, timeout: const Timeout(Duration(minutes: 4)));

      // -- Screen 3: Difficulty -------------------------------------------------

      testWidgets('screen 3 difficulty [$locale]', (tester) async {
        tester.view.devicePixelRatio = 1.0;
        await _captureScreenAllTargets(
          tester: tester,
          db: db,
          locale: locale,
          storeLocale: storeLocale,
          screenWidgetBuilder: () => _appShell(
            db: db,
            locale: locale,
            child: const DifficultyScreen(categorySlug: 'birth_youth'),
          ),
          caption: captions[2],
          screenSlug: _screenSlugs[2],
        );
      }, timeout: const Timeout(Duration(minutes: 4)));

      // -- Screen 4: Quiz answered state ----------------------------------------
      // Interactive: option tap drives quiz to answered/feedback state.
      // Captured for ALL targets via _captureQuizAnsweredAllTargets.

      testWidgets('screen 4 quiz answered [$locale]', (tester) async {
        tester.view.devicePixelRatio = 1.0;
        await _captureQuizAnsweredAllTargets(
          tester: tester,
          db: db,
          locale: locale,
          storeLocale: storeLocale,
          caption: captions[3],
        );
      }, timeout: const Timeout(Duration(minutes: 5)));

      // -- Screen 5: Result -----------------------------------------------------

      testWidgets('screen 5 result [$locale]', (tester) async {
        tester.view.devicePixelRatio = 1.0;
        final container = _makeContainer(db);
        addTearDown(container.dispose);

        container.read(sessionParamsProvider.notifier).state = SessionParams(
          categorySlug: 'revelation',
          difficulty: Difficulty.beginner,
        );

        // Use the router-backed shell so navigation to /result works.
        await tester.pumpWidget(
          _appShellWithRouter(db: db, locale: locale, container: container),
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 3));

        // Start a quiz session programmatically.
        await container
            .read(quizNotifierProvider.notifier)
            .startSession('revelation', Difficulty.beginner);
        await tester.pump(const Duration(seconds: 2));
        await tester.pump(const Duration(milliseconds: 500));

        // Answer all questions to complete the session.
        for (var i = 0; i < 20; i++) {
          final state = container.read(quizNotifierProvider);
          if (state.isComplete || state.hasError) break;

          final tiles = find.byWidgetPredicate(
            (w) => w.key != null && w.key.toString().contains('option_tile_'),
          );
          if (tiles.evaluate().isNotEmpty) {
            await tester.tap(tiles.first);
            await tester.pump(const Duration(milliseconds: 800));
          }
          final nextBtn = find.byKey(const Key('quiz_next_btn'));
          if (nextBtn.evaluate().isNotEmpty) {
            await tester.tap(nextBtn);
            await tester.pump(const Duration(milliseconds: 800));
          }
        }

        // Let the push-replacement navigation complete.
        await tester.pump(const Duration(seconds: 2));

        await _captureScreenAllTargets(
          tester: tester,
          db: db,
          locale: locale,
          storeLocale: storeLocale,
          screenWidgetBuilder: () => _appShell(
            db: db,
            locale: locale,
            child: const ResultScreen(),
            container: container,
          ),
          caption: captions[4],
          screenSlug: _screenSlugs[4],
        );
      }, timeout: const Timeout(Duration(minutes: 5)));

      // -- Screen 6: About ------------------------------------------------------

      testWidgets('screen 6 about [$locale]', (tester) async {
        tester.view.devicePixelRatio = 1.0;
        await _captureScreenAllTargets(
          tester: tester,
          db: db,
          locale: locale,
          storeLocale: storeLocale,
          screenWidgetBuilder: () =>
              _appShell(db: db, locale: locale, child: const AboutScreen()),
          caption: captions[5],
          screenSlug: _screenSlugs[5],
        );
      }, timeout: const Timeout(Duration(minutes: 4)));

      // -- Feature graphic ------------------------------------------------------

      testWidgets('feature graphic [$locale]', (tester) async {
        tester.view.devicePixelRatio = 1.0;
        tester.view.physicalSize = const Size(_fgW, _fgH);

        final bytes = await _captureWidget(
          tester,
          widget: _featureGraphicWidget(locale),
          logicalSize: const Size(_fgW, _fgH),
        );
        await _writePng(tester, _featureGraphicPath(storeLocale), bytes);
        _assertPngDimensions(
            bytes, _fgW.toInt(), _fgH.toInt(), 'feature graphic [$locale]');
      }, timeout: const Timeout(Duration(minutes: 2)));

      // -- Hi-res icon ----------------------------------------------------------

      testWidgets('hi-res icon [$locale]', (tester) async {
        tester.view.devicePixelRatio = 1.0;
        tester.view.physicalSize = const Size(_iconSz, _iconSz);

        final bytes = await _captureWidget(
          tester,
          widget: _iconWidget(),
          logicalSize: const Size(_iconSz, _iconSz),
        );
        await _writePng(tester, _iconPath(storeLocale), bytes);
        _assertPngDimensions(
            bytes, _iconSz.toInt(), _iconSz.toInt(), 'icon [$locale]');
      }, timeout: const Timeout(Duration(minutes: 2)));
    }
  });
}

// -- Draft copy markdown ------------------------------------------------------

const _copyDraftContent = r'''
# Screenshot Copy -- DRAFT FOR REVIEW

> These captions are MARKETING DRAFTS generated by `test/store_screenshots_test.dart`.
> They MUST be reviewed before any public store submission.
>
> In particular: the (SWS) honorific and all Arabic/Islamic content must be
> validated by a qualified reviewer. See `CONTENT_VALIDATION.md`.

## English captions (App Store / Google Play en-US)

1. Home: "Learn the life of the Prophet Mohammed"
2. Categories: "10 thematic categories"
3. Difficulty: "Three difficulty levels"
4. Quiz answered: "Authentic sources, cited"
5. Result: "Track your progress"
6. About: "100% offline - no ads - no tracking"

## French captions (App Store / Google Play fr-FR)

1. Home: "Apprenez la vie du Prophete Mohammed"
2. Categories: "10 categories thematiques"
3. Difficulty: "3 niveaux de difficulte"
4. Quiz answered: "Des sources authentiques, citees"
5. Result: "Suivez votre progression"
6. About: "100% hors-ligne - sans pub - sans pistage"

## Feature graphic taglines

- EN: "Interactive quiz on the life of the Prophet"
- FR: "Quiz interactif sur la vie du Prophete"

## Review checklist

- [ ] All copy reviewed by a native French speaker
- [ ] All Islamic references reviewed by a qualified scholar
- [ ] (SWS) honorific renders correctly as plain text in all generated PNGs
- [ ] No text rendered as tofu/boxes (verify visually)
- [ ] App Store copy matches `ios/fastlane/metadata/` text
- [ ] Play Store copy matches `android/fastlane/metadata/` text
''';
