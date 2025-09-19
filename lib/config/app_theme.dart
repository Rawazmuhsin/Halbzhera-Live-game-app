// File: lib/config/app_theme.dart
// Description: App theme configuration with Material 3 design

// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/constants.dart';

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      // Color Scheme
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primaryRed,
        secondary: AppColors.primaryTeal,
        tertiary: AppColors.accentYellow,
        surface: AppColors.surface1,
        error: AppColors.error,
        onPrimary: AppColors.white,
        onSecondary: AppColors.white,
        onSurface: AppColors.lightText,
        onError: AppColors.white,
      ),

      // App Bar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: AppColors.lightText,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(
          color: AppColors.lightText,
          size: AppDimensions.iconM,
        ),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
      ),

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryRed,
          foregroundColor: AppColors.white,
          elevation: AppDimensions.elevation3,
          shadowColor: AppColors.primaryRed.withOpacity(0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          ),
          minimumSize: const Size(double.infinity, AppDimensions.buttonHeightL),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.lightText,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          ),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),

      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.lightText,
          side: const BorderSide(
            color: AppColors.border1,
            width: AppDimensions.borderNormal,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          ),
          minimumSize: const Size(double.infinity, AppDimensions.buttonHeightL),
        ),
      ),

      // Card Theme
      cardTheme: const CardThemeData(
        color: AppColors.surface2,
        elevation: AppDimensions.elevation2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppDimensions.radiusL)),
        ),
        margin: EdgeInsets.all(AppDimensions.paddingS),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface2,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          borderSide: const BorderSide(color: AppColors.border1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          borderSide: const BorderSide(color: AppColors.border1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          borderSide: const BorderSide(color: AppColors.primaryRed, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        labelStyle: const TextStyle(color: AppColors.mediumText),
        hintStyle: const TextStyle(color: AppColors.subtleText),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingM,
          vertical: AppDimensions.paddingM,
        ),
      ),

      // Bottom Sheet Theme
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface2,
        modalBackgroundColor: AppColors.surface2,
        elevation: AppDimensions.elevation4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppDimensions.radiusXXL),
          ),
        ),
      ),

      // Dialog Theme
      dialogTheme: const DialogThemeData(
        backgroundColor: AppColors.surface2,
        elevation: AppDimensions.elevation4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppDimensions.radiusXL)),
        ),
        titleTextStyle: TextStyle(
          color: AppColors.lightText,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        contentTextStyle: TextStyle(
          color: AppColors.mediumText,
          fontSize: 14,
        ),
      ),

      // Snack Bar Theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surface3,
        contentTextStyle: const TextStyle(
          color: AppColors.lightText,
          fontSize: 14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        ),
        behavior: SnackBarBehavior.floating,
        elevation: AppDimensions.elevation3,
      ),

      // Switch Theme
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primaryRed;
          }
          return AppColors.subtleText;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primaryRed.withOpacity(0.3);
          }
          return AppColors.surface3;
        }),
      ),

      // Progress Indicator Theme
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primaryRed,
        linearTrackColor: AppColors.surface3,
        circularTrackColor: AppColors.surface3,
      ),

      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: AppColors.border1,
        thickness: AppDimensions.borderThin,
        space: AppDimensions.paddingM,
      ),

      // Text Theme
      textTheme: _buildTextTheme(),

      // Icon Theme
      iconTheme: const IconThemeData(
        color: AppColors.lightText,
        size: AppDimensions.iconM,
      ),

      // Floating Action Button Theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primaryRed,
        foregroundColor: AppColors.white,
        elevation: AppDimensions.elevation3,
      ),

      // Tab Bar Theme
      tabBarTheme: const TabBarThemeData(
        labelColor: AppColors.primaryRed,
        unselectedLabelColor: AppColors.mediumText,
        indicatorColor: AppColors.primaryRed,
        indicatorSize: TabBarIndicatorSize.label,
      ),
    );
  }

  static TextTheme _buildTextTheme() {
    return const TextTheme(
      // Display styles
      displayLarge: TextStyle(
        fontSize: 48,
        fontWeight: FontWeight.w900,
        color: AppColors.lightText,
        height: 1.2,
      ),
      displayMedium: TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.w800,
        color: AppColors.lightText,
        height: 1.2,
      ),
      displaySmall: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: AppColors.lightText,
        height: 1.2,
      ),

      // Headline styles
      headlineLarge: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: AppColors.lightText,
        height: 1.3,
      ),
      headlineMedium: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: AppColors.lightText,
        height: 1.3,
      ),
      headlineSmall: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.lightText,
        height: 1.3,
      ),

      // Title styles
      titleLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.lightText,
        height: 1.4,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: AppColors.lightText,
        height: 1.4,
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.lightText,
        height: 1.4,
      ),

      // Body styles
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: AppColors.mediumText,
        height: 1.5,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.mediumText,
        height: 1.5,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.subtleText,
        height: 1.4,
      ),

      // Label styles
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.lightText,
        height: 1.4,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.mediumText,
        height: 1.4,
      ),
      labelSmall: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: AppColors.subtleText,
        height: 1.4,
      ),
    );
  }
}
