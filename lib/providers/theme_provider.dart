// File: lib/providers/theme_provider.dart
// Description: Theme and preferences state management with Riverpod

// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_theme.dart';
import '../utils/constants.dart';

// ============================================================================
// THEME STATE
// ============================================================================

enum AppThemeMode { dark, light, system }

class ThemeState {
  final AppThemeMode themeMode;
  final bool isDarkMode;
  final bool useSystemTheme;
  final String language;
  final bool soundEnabled;
  final bool vibrationEnabled;
  final bool notificationsEnabled;
  final double musicVolume;
  final double sfxVolume;

  const ThemeState({
    this.themeMode = AppThemeMode.dark,
    this.isDarkMode = true,
    this.useSystemTheme = false,
    this.language = 'ku', // Kurdish as default
    this.soundEnabled = true,
    this.vibrationEnabled = true,
    this.notificationsEnabled = true,
    this.musicVolume = 0.7,
    this.sfxVolume = 0.8,
  });

  ThemeState copyWith({
    AppThemeMode? themeMode,
    bool? isDarkMode,
    bool? useSystemTheme,
    String? language,
    bool? soundEnabled,
    bool? vibrationEnabled,
    bool? notificationsEnabled,
    double? musicVolume,
    double? sfxVolume,
  }) {
    return ThemeState(
      themeMode: themeMode ?? this.themeMode,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      useSystemTheme: useSystemTheme ?? this.useSystemTheme,
      language: language ?? this.language,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      musicVolume: musicVolume ?? this.musicVolume,
      sfxVolume: sfxVolume ?? this.sfxVolume,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'themeMode': themeMode.index,
      'isDarkMode': isDarkMode,
      'useSystemTheme': useSystemTheme,
      'language': language,
      'soundEnabled': soundEnabled,
      'vibrationEnabled': vibrationEnabled,
      'notificationsEnabled': notificationsEnabled,
      'musicVolume': musicVolume,
      'sfxVolume': sfxVolume,
    };
  }

  factory ThemeState.fromMap(Map<String, dynamic> map) {
    return ThemeState(
      themeMode: AppThemeMode.values[map['themeMode'] ?? 0],
      isDarkMode: map['isDarkMode'] ?? true,
      useSystemTheme: map['useSystemTheme'] ?? false,
      language: map['language'] ?? 'ku',
      soundEnabled: map['soundEnabled'] ?? true,
      vibrationEnabled: map['vibrationEnabled'] ?? true,
      notificationsEnabled: map['notificationsEnabled'] ?? true,
      musicVolume: (map['musicVolume'] ?? 0.7).toDouble(),
      sfxVolume: (map['sfxVolume'] ?? 0.8).toDouble(),
    );
  }
}

// ============================================================================
// THEME NOTIFIER
// ============================================================================

class ThemeNotifier extends StateNotifier<ThemeState> {
  late SharedPreferences _prefs;
  bool _initialized = false;

  ThemeNotifier() : super(const ThemeState()) {
    _initializePreferences();
  }

  Future<void> _initializePreferences() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      _loadSettings();
      _initialized = true;
    } catch (e) {
      print('Error initializing preferences: $e');
      _initialized = true;
    }
  }

  void _loadSettings() {
    final settingsString = _prefs.getString(AppConstants.settingsKey);
    if (settingsString != null) {
      try {
        // Parse the settings if they're stored as JSON
        // For now, load individual settings
        final themeMode = AppThemeMode.values[_prefs.getInt('themeMode') ?? 0];
        final isDarkMode = _prefs.getBool('isDarkMode') ?? true;
        final useSystemTheme = _prefs.getBool('useSystemTheme') ?? false;
        final language = _prefs.getString('language') ?? 'ku';
        final soundEnabled = _prefs.getBool('soundEnabled') ?? true;
        final vibrationEnabled = _prefs.getBool('vibrationEnabled') ?? true;
        final notificationsEnabled =
            _prefs.getBool('notificationsEnabled') ?? true;
        final musicVolume = _prefs.getDouble('musicVolume') ?? 0.7;
        final sfxVolume = _prefs.getDouble('sfxVolume') ?? 0.8;

        state = ThemeState(
          themeMode: themeMode,
          isDarkMode: isDarkMode,
          useSystemTheme: useSystemTheme,
          language: language,
          soundEnabled: soundEnabled,
          vibrationEnabled: vibrationEnabled,
          notificationsEnabled: notificationsEnabled,
          musicVolume: musicVolume,
          sfxVolume: sfxVolume,
        );
      } catch (e) {
        print('Error loading settings: $e');
      }
    }
  }

  Future<void> _saveSettings() async {
    if (!_initialized) return;

    try {
      await _prefs.setInt('themeMode', state.themeMode.index);
      await _prefs.setBool('isDarkMode', state.isDarkMode);
      await _prefs.setBool('useSystemTheme', state.useSystemTheme);
      await _prefs.setString('language', state.language);
      await _prefs.setBool('soundEnabled', state.soundEnabled);
      await _prefs.setBool('vibrationEnabled', state.vibrationEnabled);
      await _prefs.setBool('notificationsEnabled', state.notificationsEnabled);
      await _prefs.setDouble('musicVolume', state.musicVolume);
      await _prefs.setDouble('sfxVolume', state.sfxVolume);
    } catch (e) {
      print('Error saving settings: $e');
    }
  }

  // Theme methods
  Future<void> setThemeMode(AppThemeMode mode) async {
    state = state.copyWith(
      themeMode: mode,
      useSystemTheme: mode == AppThemeMode.system,
      isDarkMode: mode == AppThemeMode.dark,
    );
    await _saveSettings();
  }

  Future<void> setDarkMode(bool isDark) async {
    state = state.copyWith(
      isDarkMode: isDark,
      themeMode: isDark ? AppThemeMode.dark : AppThemeMode.light,
      useSystemTheme: false,
    );
    await _saveSettings();
  }

  Future<void> toggleDarkMode() async {
    await setDarkMode(!state.isDarkMode);
  }

  // Language methods
  Future<void> setLanguage(String languageCode) async {
    state = state.copyWith(language: languageCode);
    await _saveSettings();
  }

  // Audio methods
  Future<void> setSoundEnabled(bool enabled) async {
    state = state.copyWith(soundEnabled: enabled);
    await _saveSettings();
  }

  Future<void> setVibrationEnabled(bool enabled) async {
    state = state.copyWith(vibrationEnabled: enabled);
    await _saveSettings();
  }

  Future<void> setMusicVolume(double volume) async {
    state = state.copyWith(musicVolume: volume.clamp(0.0, 1.0));
    await _saveSettings();
  }

  Future<void> setSfxVolume(double volume) async {
    state = state.copyWith(sfxVolume: volume.clamp(0.0, 1.0));
    await _saveSettings();
  }

  // Notification methods
  Future<void> setNotificationsEnabled(bool enabled) async {
    state = state.copyWith(notificationsEnabled: enabled);
    await _saveSettings();
  }

  // Reset to defaults
  Future<void> resetToDefaults() async {
    state = const ThemeState();
    await _saveSettings();
  }

  // Get theme data based on current state
  ThemeData get themeData {
    return AppTheme.darkTheme; // Currently only dark theme is implemented
  }

  // Update theme based on system theme
  void updateSystemTheme(bool isSystemDark) {
    if (state.useSystemTheme) {
      state = state.copyWith(isDarkMode: isSystemDark);
    }
  }
}

// ============================================================================
// PROVIDER INSTANCES
// ============================================================================

// Theme notifier provider
final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeState>((ref) {
  return ThemeNotifier();
});

// ============================================================================
// CONVENIENCE PROVIDERS
// ============================================================================

// Current theme data provider
final currentThemeProvider = Provider<ThemeData>((ref) {
  final themeNotifier = ref.read(themeProvider.notifier);
  return themeNotifier.themeData;
});

// Is dark mode provider
final isDarkModeProvider = Provider<bool>((ref) {
  final themeState = ref.watch(themeProvider);
  return themeState.isDarkMode;
});

// Current language provider
final currentLanguageProvider = Provider<String>((ref) {
  final themeState = ref.watch(themeProvider);
  return themeState.language;
});

// Sound settings providers
final soundEnabledProvider = Provider<bool>((ref) {
  final themeState = ref.watch(themeProvider);
  return themeState.soundEnabled;
});

final vibrationEnabledProvider = Provider<bool>((ref) {
  final themeState = ref.watch(themeProvider);
  return themeState.vibrationEnabled;
});

final musicVolumeProvider = Provider<double>((ref) {
  final themeState = ref.watch(themeProvider);
  return themeState.musicVolume;
});

final sfxVolumeProvider = Provider<double>((ref) {
  final themeState = ref.watch(themeProvider);
  return themeState.sfxVolume;
});

// Notification settings provider
final notificationsEnabledProvider = Provider<bool>((ref) {
  final themeState = ref.watch(themeProvider);
  return themeState.notificationsEnabled;
});

// ============================================================================
// LANGUAGE CONSTANTS
// ============================================================================

class LanguageConstants {
  static const Map<String, String> supportedLanguages = {
    'ku': 'کوردی',
    'ar': 'العربية',
    'en': 'English',
  };

  static const Map<String, Locale> locales = {
    'ku': Locale('ku'),
    'ar': Locale('ar'),
    'en': Locale('en'),
  };

  static String getLanguageName(String code) {
    return supportedLanguages[code] ?? code;
  }

  static Locale getLocale(String code) {
    return locales[code] ?? const Locale('ku');
  }
}

// Current locale provider
final currentLocaleProvider = Provider<Locale>((ref) {
  final language = ref.watch(currentLanguageProvider);
  return LanguageConstants.getLocale(language);
});

// ============================================================================
// PREFERENCES STATE
// ============================================================================

class PreferencesState {
  final bool autoPlay;
  final bool skipIntro;
  final bool showHints;
  final int questionTimeLimit;
  final bool shuffleQuestions;
  final bool shuffleAnswers;
  final String defaultCategory;
  final int maxQuestionsPerQuiz;

  const PreferencesState({
    this.autoPlay = false,
    this.skipIntro = false,
    this.showHints = true,
    this.questionTimeLimit = 15,
    this.shuffleQuestions = true,
    this.shuffleAnswers = true,
    this.defaultCategory = 'general',
    this.maxQuestionsPerQuiz = 10,
  });

  PreferencesState copyWith({
    bool? autoPlay,
    bool? skipIntro,
    bool? showHints,
    int? questionTimeLimit,
    bool? shuffleQuestions,
    bool? shuffleAnswers,
    String? defaultCategory,
    int? maxQuestionsPerQuiz,
  }) {
    return PreferencesState(
      autoPlay: autoPlay ?? this.autoPlay,
      skipIntro: skipIntro ?? this.skipIntro,
      showHints: showHints ?? this.showHints,
      questionTimeLimit: questionTimeLimit ?? this.questionTimeLimit,
      shuffleQuestions: shuffleQuestions ?? this.shuffleQuestions,
      shuffleAnswers: shuffleAnswers ?? this.shuffleAnswers,
      defaultCategory: defaultCategory ?? this.defaultCategory,
      maxQuestionsPerQuiz: maxQuestionsPerQuiz ?? this.maxQuestionsPerQuiz,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'autoPlay': autoPlay,
      'skipIntro': skipIntro,
      'showHints': showHints,
      'questionTimeLimit': questionTimeLimit,
      'shuffleQuestions': shuffleQuestions,
      'shuffleAnswers': shuffleAnswers,
      'defaultCategory': defaultCategory,
      'maxQuestionsPerQuiz': maxQuestionsPerQuiz,
    };
  }

  factory PreferencesState.fromMap(Map<String, dynamic> map) {
    return PreferencesState(
      autoPlay: map['autoPlay'] ?? false,
      skipIntro: map['skipIntro'] ?? false,
      showHints: map['showHints'] ?? true,
      questionTimeLimit: map['questionTimeLimit'] ?? 15,
      shuffleQuestions: map['shuffleQuestions'] ?? true,
      shuffleAnswers: map['shuffleAnswers'] ?? true,
      defaultCategory: map['defaultCategory'] ?? 'general',
      maxQuestionsPerQuiz: map['maxQuestionsPerQuiz'] ?? 10,
    );
  }
}

// ============================================================================
// PREFERENCES NOTIFIER
// ============================================================================

class PreferencesNotifier extends StateNotifier<PreferencesState> {
  late SharedPreferences _prefs;
  bool _initialized = false;

  PreferencesNotifier() : super(const PreferencesState()) {
    _initializePreferences();
  }

  Future<void> _initializePreferences() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      _loadPreferences();
      _initialized = true;
    } catch (e) {
      print('Error initializing preferences: $e');
      _initialized = true;
    }
  }

  void _loadPreferences() {
    try {
      final autoPlay = _prefs.getBool('autoPlay') ?? false;
      final skipIntro = _prefs.getBool('skipIntro') ?? false;
      final showHints = _prefs.getBool('showHints') ?? true;
      final questionTimeLimit = _prefs.getInt('questionTimeLimit') ?? 15;
      final shuffleQuestions = _prefs.getBool('shuffleQuestions') ?? true;
      final shuffleAnswers = _prefs.getBool('shuffleAnswers') ?? true;
      final defaultCategory = _prefs.getString('defaultCategory') ?? 'general';
      final maxQuestionsPerQuiz = _prefs.getInt('maxQuestionsPerQuiz') ?? 10;

      state = PreferencesState(
        autoPlay: autoPlay,
        skipIntro: skipIntro,
        showHints: showHints,
        questionTimeLimit: questionTimeLimit,
        shuffleQuestions: shuffleQuestions,
        shuffleAnswers: shuffleAnswers,
        defaultCategory: defaultCategory,
        maxQuestionsPerQuiz: maxQuestionsPerQuiz,
      );
    } catch (e) {
      print('Error loading preferences: $e');
    }
  }

  Future<void> _savePreferences() async {
    if (!_initialized) return;

    try {
      await _prefs.setBool('autoPlay', state.autoPlay);
      await _prefs.setBool('skipIntro', state.skipIntro);
      await _prefs.setBool('showHints', state.showHints);
      await _prefs.setInt('questionTimeLimit', state.questionTimeLimit);
      await _prefs.setBool('shuffleQuestions', state.shuffleQuestions);
      await _prefs.setBool('shuffleAnswers', state.shuffleAnswers);
      await _prefs.setString('defaultCategory', state.defaultCategory);
      await _prefs.setInt('maxQuestionsPerQuiz', state.maxQuestionsPerQuiz);
    } catch (e) {
      print('Error saving preferences: $e');
    }
  }

  Future<void> setAutoPlay(bool value) async {
    state = state.copyWith(autoPlay: value);
    await _savePreferences();
  }

  Future<void> setSkipIntro(bool value) async {
    state = state.copyWith(skipIntro: value);
    await _savePreferences();
  }

  Future<void> setShowHints(bool value) async {
    state = state.copyWith(showHints: value);
    await _savePreferences();
  }

  Future<void> setQuestionTimeLimit(int seconds) async {
    state = state.copyWith(questionTimeLimit: seconds.clamp(5, 60));
    await _savePreferences();
  }

  Future<void> setShuffleQuestions(bool value) async {
    state = state.copyWith(shuffleQuestions: value);
    await _savePreferences();
  }

  Future<void> setShuffleAnswers(bool value) async {
    state = state.copyWith(shuffleAnswers: value);
    await _savePreferences();
  }

  Future<void> setDefaultCategory(String category) async {
    state = state.copyWith(defaultCategory: category);
    await _savePreferences();
  }

  Future<void> setMaxQuestionsPerQuiz(int count) async {
    state = state.copyWith(maxQuestionsPerQuiz: count.clamp(5, 50));
    await _savePreferences();
  }

  Future<void> resetToDefaults() async {
    state = const PreferencesState();
    await _savePreferences();
  }
}

// Preferences provider
final preferencesProvider =
    StateNotifierProvider<PreferencesNotifier, PreferencesState>((ref) {
      return PreferencesNotifier();
    });
