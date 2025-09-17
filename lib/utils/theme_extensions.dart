// File: lib/utils/theme_extensions.dart
// Description: Extension methods to simplify theme-related code (dark mode only)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Extension to simplify theme access throughout the app
extension BuildContextThemeExtension on BuildContext {
  /// Always dark mode
  bool get isDarkMode => true;

  /// Always return dark color for consistency
  Color themeAwareColor({required Color darkColor, required Color lightColor}) {
    return darkColor;
  }

  /// Get surface color
  Color get themeAwareBackgroundColor {
    return Theme.of(this).colorScheme.surface;
  }

  /// Get surface color
  Color get themeAwareSurfaceColor {
    return Theme.of(this).colorScheme.surface;
  }

  /// Get text color
  Color get themeAwareTextColor {
    return Theme.of(this).colorScheme.onSurface;
  }
}

/// Extension to simplify theme access for Riverpod consumers
extension WidgetRefThemeExtension on WidgetRef {
  /// Always dark mode
  bool get isDarkMode => true;

  /// Get the current theme data
  ThemeData get currentTheme {
    return Theme.of(context);
  }
}
