import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/arb/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/design_widgets.dart';
import '../../data/repositories/quiz_repository.dart';
import 'welcome_sheet.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  // E-3: staggered reveal animations (600ms controller, respects reduced motion).
  // Header slides down (0–350ms easeOutCubic)
  late final Animation<Offset> _headerSlide;
  // Icon chip scale-in 0.85→1.0 (150–400ms easeOutBack)
  late final Animation<double> _chipScale;
  // Title + subtitle fade (300–500ms)
  late final Animation<double> _titleFade;
  // Buttons slide up +16→0 px (380–660ms)
  late final Animation<Offset> _buttonsSlide;
  late final Animation<double> _buttonsFade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 660),
    );
    _headerSlide = Tween<Offset>(
      begin: const Offset(0, -0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.0, 0.53, curve: Curves.easeOutCubic),
    ));
    _chipScale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.23, 0.61, curve: Curves.easeOutBack),
      ),
    );
    _titleFade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.45, 0.76, curve: Curves.easeOut),
    );
    _buttonsSlide = Tween<Offset>(
      begin: const Offset(0, 0.10),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.58, 1.0, curve: Curves.easeOutCubic),
    ));
    _buttonsFade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.58, 1.0, curve: Curves.easeOut),
    );

    // Respect reduced-motion accessibility preference.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final disableAnimations =
          MediaQuery.of(context).disableAnimations;
      if (disableAnimations) {
        _ctrl.value = 1.0;
      } else {
        _ctrl.forward();
      }
      // First-launch welcome sheet: show once, never auto-show again.
      _maybeShowWelcome();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  // In-memory guard: prevents double-show if initState fires more than once
  // (e.g. hot-restart edge case) or if _maybeShowWelcome is somehow called
  // concurrently before the first call completes.
  bool _welcomeCheckStarted = false;

  /// Checks the 'welcome_seen' settings flag. If not set, shows the sheet
  /// and marks it as seen so it never auto-shows again.
  /// Wrapped in try/catch so a DB write failure never crashes the home screen.
  Future<void> _maybeShowWelcome() async {
    if (_welcomeCheckStarted) return;
    _welcomeCheckStarted = true;
    try {
      final repo = ref.read(settingsRepositoryProvider);
      if (await repo.get(kKeyWelcomeSeen) == 'true') return;
      if (!mounted) return;
      await showWelcomeSheet(context);
      if (!mounted) return;
      await repo.set(kKeyWelcomeSeen, 'true');
    } catch (e, st) {
      debugPrint('_maybeShowWelcome error: $e\n$st');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = context.theme;
    final isDark = theme.colors.background.computeLuminance() < 0.2;

    return Scaffold(
      backgroundColor: theme.colors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Emerald gradient header with pattern ──────────────────────────
          Expanded(
            flex: 5,
            child: SlideTransition(
              position: _headerSlide,
              child: EmeraldHeader(
                child: SafeArea(
                  bottom: false,
                  child: Stack(
                    children: [
                      // ── Centered content (unchanged) ──────────────────
                      SingleChildScrollView(
                        physics: const NeverScrollableScrollPhysics(),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 16),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ScaleTransition(
                                scale: _chipScale,
                                child: AppIconChip(
                                  size: 80,
                                  dark: isDark,
                                ),
                              ),
                              const SizedBox(height: 16),
                              FadeTransition(
                                opacity: _titleFade,
                                child: Column(
                                  children: [
                                    Text(
                                      l10n.home_title,
                                      style: const TextStyle(
                                        fontFamily: kDisplayFont,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        letterSpacing: -0.3,
                                        height: 1.2,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      l10n.home_subtitle,
                                      style: TextStyle(
                                        fontFamily: kBodyFont,
                                        fontSize: 13,
                                        color: Colors.white.withAlpha(195),
                                        height: 1.4,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // ── Welcome re-open affordance (top-right, unobtrusive) ──
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Tooltip(
                          message: l10n.welcome_open,
                          child: GestureDetector(
                            key: const Key('home_welcome_btn'),
                            onTap: () => showWelcomeSheet(context),
                            behavior: HitTestBehavior.opaque,
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Icon(
                                Icons.info_outline_rounded,
                                size: 22,
                                color: Colors.white.withAlpha(180),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Button group ──────────────────────────────────────────────────
          Expanded(
            flex: 4,
            child: ColoredBox(
              // E-12: give lower panel a distinct dark (#0D1714) vs the header
              // emerald gradient, so the two-zone composition holds in dark mode.
              // In light mode this is transparent — the sand scaffold bg shows.
              color: isDark ? darkBg : Colors.transparent,
              child: SafeArea(
                top: false,
                child: FadeTransition(
                  opacity: _buttonsFade,
                  child: SlideTransition(
                    position: _buttonsSlide,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(28, 20, 28, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _EmeraldPrimaryButton(
                            key: const Key('home_start_btn'),
                            label: l10n.home_start,
                            onTap: () => context.push('/categories'),
                          ),
                          const SizedBox(height: 14),
                          _EmeraldOutlineButton(
                            key: const Key('home_settings_btn'),
                            label: l10n.home_settings,
                            onTap: () => context.push('/settings'),
                          ),
                          const SizedBox(height: 8),
                          _EmeraldGhostButton(
                            key: const Key('home_about_btn'),
                            label: l10n.home_about,
                            onTap: () => context.push('/about'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared button widgets ─────────────────────────────────────────────────────

class _EmeraldPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _EmeraldPrimaryButton({
    super.key,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final isDark = theme.colors.background.computeLuminance() < 0.2;
    // C-1: explicitly bind to darkEmeraldButton in dark mode (#0F7A63) so
    // white text achieves ≥4.5:1. In light mode use emerald (#0B6B57 → 4.6:1).
    final bg = isDark ? darkEmeraldButton : emerald;
    return _PressableButton(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: emerald.withAlpha(60),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: kBodyFont,
              fontSize: 15,
              fontWeight: FontWeight.w600,
              // White on #0F7A63 = ~4.7:1 (dark) / white on #0B6B57 = ~4.6:1 (light).
              color: Colors.white,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
  }
}

class _EmeraldOutlineButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _EmeraldOutlineButton({
    super.key,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return _PressableButton(
      onTap: onTap,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: theme.colors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: theme.colors.primary.withAlpha(180),
            width: 1.5,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontFamily: kBodyFont,
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: theme.colors.primary,
            ),
          ),
        ),
      ),
    );
  }
}

class _EmeraldGhostButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _EmeraldGhostButton({
    super.key,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return _PressableButton(
      onTap: onTap,
      child: Container(
        height: 44,
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontFamily: kBodyFont,
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: theme.colors.primary.withAlpha(210),
          ),
        ),
      ),
    );
  }
}

/// A pressable wrapper that applies a subtle scale animation on press.
class _PressableButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _PressableButton({required this.child, required this.onTap});

  @override
  State<_PressableButton> createState() => _PressableButtonState();
}

class _PressableButtonState extends State<_PressableButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) => _ctrl.reverse(),
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, child) =>
            Transform.scale(scale: _scale.value, child: child),
        child: widget.child,
      ),
    );
  }
}
