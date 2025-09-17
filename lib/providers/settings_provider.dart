// File: lib/providers/settings_provider.dart
// Description: User settings provider with Riverpod

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

// Settings keys
const String _notificationsEnabledKey = 'notifications_enabled';

/// User settings state class
class UserSettings {
  final bool notificationsEnabled;

  const UserSettings({this.notificationsEnabled = true});

  // Copy with method for updates
  UserSettings copyWith({bool? notificationsEnabled}) {
    return UserSettings(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    );
  }

  // Convert to JSON for shared preferences
  Map<String, dynamic> toJson() {
    return {_notificationsEnabledKey: notificationsEnabled};
  }

  // Create from shared preferences
  factory UserSettings.fromPrefs(SharedPreferences prefs) {
    return UserSettings(
      notificationsEnabled: prefs.getBool(_notificationsEnabledKey) ?? true,
    );
  }
}

/// Settings notifier to manage user settings
class SettingsNotifier extends StateNotifier<UserSettings> {
  SettingsNotifier() : super(const UserSettings());

  // SharedPreferences instance
  SharedPreferences? _prefs;

  // Initialize settings from shared preferences
  Future<void> loadSettings() async {
    _prefs = await SharedPreferences.getInstance();
    state = UserSettings.fromPrefs(_prefs!);
  }

  // Set notifications enabled/disabled
  Future<void> setNotificationsEnabled(bool value) async {
    await _prefs?.setBool(_notificationsEnabledKey, value);
    state = state.copyWith(notificationsEnabled: value);
  }

  // Save user preferences to Firestore
  Future<void> saveToFirestore(UserModel user) async {
    // Don't save if anonymous user or no uid
    if (user.uid.isEmpty) return;

    final updatedPrefs = {
      ...user.preferences,
      'notificationsEnabled': state.notificationsEnabled,
    };

    // Get database service and update user preferences
    // This would update the user record in Firestore
    // Implementation depends on your database service
    try {
      // TODO: Add proper implementation to update user preferences in Firestore
      // DatabaseService().updateUserPreferences(user.uid, updatedPrefs);
      debugPrint('Updated user ${user.uid} preferences: $updatedPrefs');
    } catch (e) {
      debugPrint('Error updating user preferences: $e');
    }
  }
}

// Provider for settings notifier
final settingsProvider = StateNotifierProvider<SettingsNotifier, UserSettings>((
  ref,
) {
  final notifier = SettingsNotifier();
  notifier.loadSettings();
  return notifier;
});

// Provider for theme mode - always dark
final themeModeProvider = Provider<ThemeMode>((ref) {
  return ThemeMode.dark;
});
