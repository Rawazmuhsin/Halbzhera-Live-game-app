// File: lib/utils/app_theme.dart
// Description: Theme-aware color constants and utilities for the app (dark mode only)

import 'package:flutter/material.dart';

/// App theme constants for dark mode
class AppTheme {
  /// Dark theme color scheme
  static const ColorScheme darkColorScheme = ColorScheme(
    // Primary colors
    primary: Color(0xFFff6b6b), // Bright Red
    onPrimary: Color(0xFFFFFFFF), // White
    primaryContainer: Color(0xFF930006), // Deep Red
    onPrimaryContainer: Color(0xFFFFDAD6), // Very Light Red
    // Secondary colors
    secondary: Color(0xFF4ecdc4), // Bright Teal
    onSecondary: Color(0xFF003735), // Very Dark Teal
    secondaryContainer: Color(0xFF00504D), // Dark Teal
    onSecondaryContainer: Color(0xFF71F7F2), // Light Teal
    // Tertiary colors
    tertiary: Color(0xFFffd93d), // Bright Yellow
    onTertiary: Color(0xFF000000), // Black
    tertiaryContainer: Color(0xFF614B00), // Dark Yellow/Brown
    onTertiaryContainer: Color(0xFFFFE085), // Near White
    surface: Color(0xFF1F1F2F), // Dark Blue Grey
    onSurface: Color(0xFFFAFAFA), // Near White
    // Surface variant colors
    surfaceContainerHighest: Color(0xFF2A2A3F), // Mid Dark Blue Grey
    onSurfaceVariant: Color(0xFFDCDCE9), // Light Grey Blue
    outline: Color(0xFF8A8A97), // Mid Grey
    outlineVariant: Color(0xFF404052), // Dark Grey Blue
    // Error colors
    error: Color(0xFFF44336), // Error Red
    onError: Color(0xFFFFFFFF), // White
    errorContainer: Color(0xFF930006), // Dark Error Red
    onErrorContainer: Color(0xFFFFDAD6), // Light Error Red
    // Brightness
    brightness: Brightness.dark,
  );

  // Status colors for dark theme (outside of ColorScheme)
  static const Color darkSuccess = Color(0xFF4CAF50); // Green
  static const Color darkWarning = Color(0xFFFF9800); // Orange
  static const Color darkInfo = Color(0xFF2196F3); // Blue

  /// Get surface color gradients for dark theme
  static LinearGradient getDarkGradient() {
    return const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      stops: [0.0, 0.5, 1.0],
      colors: [
        Color(0xFF1A1A2E), // darkBlue1
        Color(0xFF16213E), // darkBlue2
        Color(0xFF0F3460), // darkBlue3
      ],
    );
  }

  /// Get primary gradient
  static LinearGradient getPrimaryGradient() {
    return const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFff6b6b), Color(0xFF4ecdc4)], // primaryRed, primaryTeal
    );
  }

  /// Get accent gradient (works for both themes)
  static LinearGradient getAccentGradient() {
    return const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFFffd93d),
        Color(0xFFff6b6b),
      ], // accentYellow, primaryRed
    );
  }

  /// Get theme colors based on dark theme only
  static Color getThemeAwareColor({
    required BuildContext context,
    required Color darkColor,
    required Color lightColor, // Keeping parameter for compatibility
  }) {
    return darkColor; // Always return dark color
  }

  /// Get appropriate color from ColorScheme
  static Color getSchemeColor({
    required BuildContext context,
    required Color Function(ColorScheme) color,
  }) {
    return color(Theme.of(context).colorScheme);
  }

  /// Get surface color
  static Color getSurfaceColor(BuildContext context) {
    return Theme.of(context).colorScheme.surface;
  }

  /// Get on-surface color
  static Color getOnSurfaceColor(BuildContext context) {
    return Theme.of(context).colorScheme.onSurface;
  }

  /// Get background gradient (always dark)
  static LinearGradient getBackgroundGradient(BuildContext context) {
    return getDarkGradient();
  }

  /// Get success color
  static Color getSuccessColor(BuildContext context) {
    return darkSuccess;
  }

  /// Get warning color
  static Color getWarningColor(BuildContext context) {
    return darkWarning;
  }

  /// Get info color
  static Color getInfoColor(BuildContext context) {
    return darkInfo;
  }
}

/// Extension methods on BuildContext for easy theme access
extension ThemeExtension on BuildContext {
  /// Always dark mode
  bool get isDarkMode => true;

  /// Get dark color (always returns dark color for consistency)
  Color themeAwareColor({required Color darkColor, required Color lightColor}) {
    return darkColor;
  }

  /// Get the color scheme
  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  /// Get the text theme
  TextTheme get textTheme => Theme.of(this).textTheme;

  /// Get the dark background gradient
  LinearGradient get backgroundGradient => AppTheme.getDarkGradient();

  /// Get the primary color
  Color get primaryColor => Theme.of(this).colorScheme.primary;

  /// Get the surface color
  Color get surfaceColor => Theme.of(this).colorScheme.surface;

  /// Get the on-surface color
  Color get onSurfaceColor => Theme.of(this).colorScheme.onSurface;

  /// Get the success color
  Color get successColor => AppTheme.darkSuccess;

  /// Get the warning color
  Color get warningColor => AppTheme.darkWarning;

  /// Get the info color
  Color get infoColor => AppTheme.darkInfo;
}
