// File: lib/services/google_sign_in_service.dart
// Description: Google Sign-In service with serverClientId for Android

import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class GoogleSignInService {
  // Initialize GoogleSignIn with proper serverClientId for Android
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    // Use serverClientId for Android instead of clientId
    serverClientId:
        '8499699117-s5evcg08sobcmr1ir0pejsrkdquu0jcq.apps.googleusercontent.com',

    // For iOS, you can specify separate client IDs if needed
    // clientId: 'YOUR_IOS_CLIENT_ID', // Only for iOS

    // Request email and profile scopes
    scopes: <String>['email', 'profile'],
  );

  static Future<UserCredential> signInWithGoogle() async {
    debugPrint('=== STARTING GOOGLE SIGN-IN PROCESS FROM SERVICE ===');

    try {
      // Step 1: Check if already signed in
      debugPrint('1. Checking if already signed in with Google');
      bool isSignedIn = await _googleSignIn.isSignedIn();
      debugPrint('2. Is already signed in with Google: $isSignedIn');

      if (isSignedIn) {
        // Try to get current user if already signed in
        debugPrint('3. Getting current user since already signed in');
        final GoogleSignInAccount? currentUser =
            await _googleSignIn.signInSilently();
        if (currentUser != null) {
          debugPrint(
            '4. Successfully got current Google user: ${currentUser.displayName}',
          );

          // Get authentication tokens
          final GoogleSignInAuthentication googleAuth =
              await currentUser.authentication;

          // Create Firebase credential
          final credential = GoogleAuthProvider.credential(
            accessToken: googleAuth.accessToken,
            idToken: googleAuth.idToken,
          );

          // Sign in with credential
          return await FirebaseAuth.instance.signInWithCredential(credential);
        }
      }

      // Step 2: Start the interactive sign-in flow
      debugPrint('3. Starting interactive sign-in flow with Google');
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        debugPrint('4. User cancelled Google sign-in');
        throw FirebaseAuthException(
          code: 'sign-in-cancelled',
          message: 'Sign in was cancelled by the user',
        );
      }

      debugPrint('4. Successfully got Google user: ${googleUser.displayName}');
      debugPrint('5. Google user email: ${googleUser.email}');

      // Step 3: Get authentication details from Google
      debugPrint('6. Getting authentication tokens');
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      debugPrint('7. Got tokens successfully');

      // Step 4: Create Firebase credential
      debugPrint('8. Creating Firebase credential with Google tokens');
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Step 5: Sign in to Firebase with credential
      debugPrint('9. Signing in to Firebase with Google credential');
      final UserCredential userCredential = await FirebaseAuth.instance
          .signInWithCredential(credential);

      debugPrint('10. SUCCESSFULLY signed in to Firebase');
      debugPrint('11. Firebase User ID: ${userCredential.user?.uid}');

      return userCredential;
    } catch (e, stack) {
      // Log detailed error information
      debugPrint('=== ERROR DURING GOOGLE SIGN-IN SERVICE ===');
      debugPrint('Error type: ${e.runtimeType}');
      debugPrint('Error message: $e');

      if (e is FirebaseAuthException) {
        debugPrint('Firebase Auth Error Code: ${e.code}');
        debugPrint('Firebase Auth Error Message: ${e.message}');
      } else if (e is Exception) {
        debugPrint('Exception details: $e');
      }

      debugPrint('Stack trace: $stack');

      // Rethrow to let caller handle the error
      rethrow;
    }
  }
}
