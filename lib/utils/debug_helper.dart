// File: lib/utils/debug_helper.dart
// Description: Debug helper for troubleshooting Google Sign-In issues

// ignore_for_file: avoid_print

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DebugHelper {
  static void logGoogleSignInConfiguration() {
    print('🔍 === Google Sign-In Debug Information ===');
    print('🔍 Platform: ${kIsWeb ? 'Web' : 'Mobile'}');
    print('🔍 Debug Mode: $kDebugMode');
    print('🔍 Release Mode: $kReleaseMode');

    if (!kIsWeb) {
      print('🔍 Mobile platform detected');
      // Additional mobile-specific debugging can be added here
    } else {
      print('🔍 Web platform detected');
    }

    print('🔍 ========================================');
  }

  static Future<void> testGoogleSignInAvailability() async {
    try {
      print('🔍 Testing Google Sign-In availability...');

      final GoogleSignIn googleSignIn = GoogleSignIn();
      final bool isAvailable = await googleSignIn.isSignedIn();

      print(
        '🔍 Google Sign-In service available: ${isAvailable ? 'Yes' : 'No'}',
      );

      // Test if we can get current user without signing in
      final GoogleSignInAccount? currentUser = googleSignIn.currentUser;
      print('🔍 Current Google user: ${currentUser?.email ?? 'None'}');
    } catch (e) {
      print('❌ Error testing Google Sign-In availability: $e');
    }
  }

  static void logFirebaseConfiguration() {
    print('🔍 === Firebase Auth Debug Information ===');

    try {
      final FirebaseAuth auth = FirebaseAuth.instance;
      final User? currentUser = auth.currentUser;

      print('🔍 Firebase Auth instance: ${auth.app.name}');
      print('🔍 Current Firebase user: ${currentUser?.uid ?? 'None'}');
      print('🔍 Auth state changes stream: Available');
    } catch (e) {
      print('❌ Error accessing Firebase Auth: $e');
    }

    print('🔍 =======================================');
  }

  static Map<String, String> getCommonGoogleSignInErrors() {
    return {
      'PlatformException(sign_in_failed)':
          'Google Play Services not available or outdated. Update Google Play Services.',
      'PlatformException(network_error)':
          'Network connection issue. Check internet connectivity.',
      'PlatformException(sign_in_canceled)':
          'User canceled the sign-in process.',
      'PlatformException(sign_in_required)': 'User needs to sign in again.',
      'GoogleSignIn configuration error':
          'Check google-services.json file and ensure SHA-1 fingerprint is configured in Firebase Console.',
      'Invalid client ID':
          'Check client ID configuration in Firebase Console and google-services.json.',
      'API not enabled': 'Enable Google Sign-In API in Google Cloud Console.',
    };
  }

  static void printTroubleshootingGuide() {
    print('🔍 === Google Sign-In Troubleshooting Guide ===');
    print('');
    print('1. Check google-services.json:');
    print('   - File should be in android/app/ directory');
    print('   - Package name should match applicationId in build.gradle');
    print('   - Should contain oauth_client entries');
    print('');
    print('2. Check Firebase Console configuration:');
    print('   - Authentication > Sign-in method > Google should be enabled');
    print(
      '   - Project settings > Your apps > SHA certificate fingerprints should be configured',
    );
    print('   - For debug builds, add debug SHA-1 fingerprint');
    print('');
    print('3. Check Android configuration:');
    print('   - INTERNET permission in AndroidManifest.xml');
    print('   - Google Services plugin applied in build.gradle');
    print('   - Correct minSdkVersion (21 or higher recommended)');
    print('');
    print('4. For development:');
    print(
      '   - Run: keytool -list -v -alias androiddebugkey -keystore ~/.android/debug.keystore',
    );
    print('   - Default password is: android');
    print('   - Add the SHA-1 fingerprint to Firebase Console');
    print('');
    print('🔍 ============================================');
  }
}
