// File: lib/providers/system_theme_listener.dart
// Description: Previously listened for system theme changes - now a placeholder since dark mode only

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A dummy provider that used to listen to system theme changes
/// Now just a placeholder to avoid breaking imports
final systemThemeListenerProvider = Provider<_SystemThemeListener>((ref) {
  return _SystemThemeListener();
});

class _SystemThemeListener {
  // No functionality needed anymore
}

/// This function is kept as a placeholder to avoid breaking imports
/// but does nothing since we always use dark mode now
void initializeSystemThemeListener(WidgetRef ref) {
  // No functionality needed
}
