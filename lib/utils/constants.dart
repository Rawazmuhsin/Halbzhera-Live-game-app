// File: lib/utils/constants.dart
// Description: All app constants, colors, dimensions, and text strings

// ignore_for_file: use_full_hex_values_for_flutter_colors

import 'package:flutter/material.dart';

// ============================================================================
// APP CONSTANTS
// ============================================================================
class AppConstants {
  // App Info
  static const String appName = 'Halbzhera';
  static const String appVersion = '1.0.0';
  static const String packageName = 'com.halbzhera.quizz';

  // Animation Durations
  static const Duration fastAnimation = Duration(milliseconds: 200);
  static const Duration normalAnimation = Duration(milliseconds: 400);
  static const Duration slowAnimation = Duration(milliseconds: 600);
  static const Duration backgroundAnimation = Duration(seconds: 20);
  static const Duration logoAnimation = Duration(seconds: 4);
  static const Duration titleAnimation = Duration(seconds: 3);

  // Quiz Settings
  static const int defaultQuestionTime = 15; // seconds
  static const int maxPlayersPerRoom = 8;
  static const int minPlayersToStart = 2;
  static const int maxQuestionsPerQuiz = 20;
  static const int minQuestionsPerQuiz = 5;

  // Scoring
  static const int correctAnswerPoints = 100;
  static const int speedBonusMultiplier = 10;
  static const int wrongAnswerPenalty = 0;
  static const int maxSpeedBonus = 50;

  // Room Settings
  static const int roomCodeLength = 6;
  static const int maxRoomNameLength = 30;
  static const Duration roomTimeout = Duration(minutes: 30);

  // API Settings
  static const Duration apiTimeout = Duration(seconds: 30);
  static const int maxRetryAttempts = 3;

  // Storage Keys
  static const String userTokenKey = 'user_token';
  static const String userDataKey = 'user_data';
  static const String settingsKey = 'app_settings';
  static const String themeKey = 'app_theme';
  static const String languageKey = 'app_language';

  // Asset Paths
  static const String logoPath = 'assets/applogo.png';
  static const String logoWhitePath = 'assets/images/logo.png';
  static const String splashLogoPath = 'assets/images/logo.png';
}

// ============================================================================
// COLOR CONSTANTS
// ============================================================================
class AppColors {
  // Primary Colors
  static const Color primaryRed = Color(0xFFff6b6b);
  static const Color primaryTeal = Color(0xFF4ecdc4);
  static const Color accentYellow = Color(0xFFffd93d);

  // Background Colors
  static const Color background = Color(0xFF121212);
  static const Color darkBlue1 = Color(0xFF1a1a2e);
  static const Color darkBlue2 = Color(0xFF16213e);
  static const Color darkBlue3 = Color(0xFF0f3460);

  // Text Colors
  static const Color lightText = Color(0xFFFAFAFA);
  static const Color mediumText = Color(0xffb3ffffff);
  static const Color subtleText = Color(0xff80ffffff);
  static const Color darkText = Color(0xFF2C2C2C);
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);

  // Status Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);

  // Social Colors
  static const Color googleRed = Color(0xFFDB4437);
  static const Color facebookBlue = Color(0xFF1877F2);

  // Surface Colors
  static const Color surface1 = Color(0xFF1F1F2F);
  static const Color surface2 = Color(0xFF2A2A3F);
  static const Color surface3 = Color(0xFF35354F);
  static const Color surface4 = Color(0xFF40405F);

  // Border Colors
  static const Color border1 = Color(0xff33ffffff);
  static const Color border2 = Color(0xff26ffffff);
  static const Color border3 = Color(0xff1affffff);

  // Overlay Colors
  static const Color overlay1 = Color(0x80000000);
  static const Color overlay2 = Color(0x99000000);
  static const Color overlay3 = Color(0xB3000000);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryRed, primaryTeal],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accentYellow, primaryRed],
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 0.5, 1.0],
    colors: [darkBlue1, darkBlue2, darkBlue3],
  );
}

// ============================================================================
// DIMENSION CONSTANTS
// ============================================================================
class AppDimensions {
  // Padding & Margins
  static const double paddingXS = 4.0;
  static const double paddingS = 8.0;
  static const double paddingM = 16.0;
  static const double paddingL = 24.0;
  static const double paddingXL = 32.0;
  static const double paddingXXL = 48.0;

  // Border Radius
  static const double radiusXS = 4.0;
  static const double radiusS = 8.0;
  static const double radiusM = 12.0;
  static const double radiusL = 16.0;
  static const double radiusXL = 20.0;
  static const double radiusXXL = 24.0;
  static const double radiusCircle = 50.0;

  // Icon Sizes
  static const double iconXS = 12.0;
  static const double iconS = 16.0;
  static const double iconM = 24.0;
  static const double iconL = 32.0;
  static const double iconXL = 48.0;
  static const double iconXXL = 64.0;

  // Button Heights
  static const double buttonHeightS = 36.0;
  static const double buttonHeightM = 48.0;
  static const double buttonHeightL = 56.0;
  static const double buttonHeightXL = 64.0;

  // Logo Sizes
  static const double logoS = 40.0;
  static const double logoM = 60.0;
  static const double logoL = 80.0;
  static const double logoXL = 100.0;
  static const double logoXXL = 120.0;

  // Elevation & Shadows
  static const double elevation1 = 2.0;
  static const double elevation2 = 4.0;
  static const double elevation3 = 8.0;
  static const double elevation4 = 12.0;
  static const double elevation5 = 16.0;

  // Border Width
  static const double borderThin = 0.5;
  static const double borderNormal = 1.0;
  static const double borderThick = 2.0;
  static const double borderBold = 3.0;
}

// ============================================================================
// TEXT CONSTANTS
// ============================================================================
class AppTexts {
  // App Identity
  static const String appTitle = 'Halbzhera';
  static const String appSubtitle =
      'یاریبکەو خەڵات ببەوە - تاقیکردنەوەی زیرەکی و زانست';

  // Authentication
  static const String getStarted = 'دەستپێبکە';
  static const String chooseLoginMethod = 'شێوازی چوونەژوورەوە هەلبژێرە';
  static const String loginDescription =
      'بۆ هەژمارکردنی خاڵەکان و یاریکردن لەگەڵ هاوڕێکان';
  static const String continueAsGuest = 'بەردەوامبوون وەک میوان';
  static const String continueWithGoogle = 'Continue with Google';
  static const String continueWithFacebook = 'Continue with Facebook';
  static const String login = 'چوونەژوورەوە';
  static const String logout = 'چوونەدەرەوە';
  static const String welcome = 'بەخێرهاتن';

  // Features
  static const String fastFeature = 'خێرا';
  static const String rewardFeature = 'خەڵات';
  static const String funFeature = 'سەرگەرم';

  // Home & Navigation
  static const String home = 'سەرەکی';
  static const String profile = 'پڕۆفایل';
  static const String leaderboard = 'پێشەنگەکان';
  static const String settings = 'ڕێکخستنەکان';
  static const String categories = 'جۆرەکان';
  static const String history = 'مێژوو';

  // Quiz & Game
  static const String createRoom = 'ژووری نوێ دروستبکە';
  static const String joinRoom = 'چوونە ناو ژوور';
  static const String roomCode = 'کۆدی ژوور';
  static const String startGame = 'یاری دەستپێبکە';
  static const String waitingForPlayers = 'چاوەڕوانی یاریزانەکان';
  static const String question = 'پرسیار';
  static const String answer = 'وەڵام';
  static const String timeLeft = 'کاتی ماوە';
  static const String score = 'خاڵ';
  static const String correctAnswer = 'وەڵامی دروست';
  static const String wrongAnswer = 'وەڵامی هەڵە';
  static const String finalResults = 'ئەنجامی کۆتایی';
  static const String playAgain = 'دووبارە یاری بکە';
  static const String nextQuestion = 'پرسیاری داهاتوو';
  static const String gameFinished = 'یاری تەواوبوو';

  // Common Actions
  static const String loading = 'بارکردن...';
  static const String error = 'هەڵە';
  static const String retry = 'دووبارە هەوڵبدەوە';
  static const String cancel = 'پاشگەزبوونەوە';
  static const String confirm = 'پشتڕاستکردنەوە';
  static const String save = 'پاشەکەوتکردن';
  static const String edit = 'دەستکاریکردن';
  static const String delete = 'سڕینەوە';
  static const String close = 'داخستن';
  static const String back = 'گەڕانەوە';
  static const String next = 'داهاتوو';
  static const String done = 'تەواو';

  // Status Messages
  static const String success = 'سەرکەوتوو';
  static const String failed = 'شکستخوارد';
  static const String connecting = 'پەیوەندیکردن...';
  static const String connected = 'پەیوەندی کرا';
  static const String disconnected = 'پەیوەندی پچڕا';
  static const String networkError = 'هەڵەی ئینتەرنێت';
  static const String serverError = 'هەڵەی سێرڤەر';
  static const String unknownError = 'هەڵەی نەناسراو';
}
