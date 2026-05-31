import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

/// Returns the ForUI touch theme for the given brightness.
/// Uses the built-in FThemes.neutral palette as the base.
FThemeData getForUiTheme(Brightness brightness) {
  final isMobile = const {
    TargetPlatform.android,
    TargetPlatform.iOS,
    TargetPlatform.fuchsia,
  }.contains(defaultTargetPlatform);

  if (brightness == Brightness.dark) {
    return isMobile ? FThemes.neutral.dark.touch : FThemes.neutral.dark.desktop;
  }
  return isMobile ? FThemes.neutral.light.touch : FThemes.neutral.light.desktop;
}

/// Authoritative success / correct-answer green used throughout the quiz UI.
/// All inline `Color(0xFF166534)` literals must reference this constant.
const successGreen = Color(0xFF166534);

/// Sand/warm neutral for card backgrounds in light mode.
const sandLight = Color(0xFFFAF7F0);
