// File: lib/providers/app_theme_provider.dart
// Description: Simplified theme providers (dark mode only)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_theme.dart';

/// Provider that exposes the current ThemeData (always dark)
final currentThemeDataProvider = Provider<ThemeData>((ref) {
  return AppTheme.darkTheme;
});

/// Provider that indicates if the current theme is dark (always true)
final isDarkModeProvider = Provider<bool>((ref) {
  return true;
});

/// Theme controller mixin to help components respond to theme changes
mixin ThemeAware<T extends StatefulWidget> on State<T> {
  bool isDarkMode(WidgetRef ref) {
    return true;
  }

  ThemeData currentTheme(WidgetRef ref) {
    return AppTheme.darkTheme;
  }
}
