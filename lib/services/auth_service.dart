// File: lib/services/auth_service.dart
// Description: Firebase Authentication service with improved error handling

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import '../config/firebase_config.dart';
import '../models/user_model.dart';
import 'database_service.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseConfig.auth;
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    // Explicitly set the client ID for Android to avoid configuration issues
    clientId:
        kIsWeb
            ? null // For web, this is configured in index.html
            : null, // For mobile, this should come from google-services.json
  );
  static final DatabaseService _databaseService = DatabaseService();

  // Get current user stream
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get current user
  static User? get currentUser => _auth.currentUser;

  // Sign in with Google
  static Future<UserModel?> signInWithGoogle() async {
    try {
      print('🔵 Starting Google Sign-In process...');

      if (kIsWeb) {
        print('🔵 Web platform detected, using popup flow');
        // Handle web platform
        GoogleAuthProvider googleProvider = GoogleAuthProvider();
        final UserCredential userCredential = await _auth.signInWithPopup(
          googleProvider,
        );

        if (userCredential.user != null) {
          final userModel = UserModel.fromFirebaseUser(
            userCredential.user!,
            provider: LoginProvider.google,
          );
          await _databaseService.createOrUpdateUser(userModel);
          print('✅ Web Google Sign-In successful');
          return userModel;
        }
      } else {
        print('🔵 Mobile platform detected, using Google Sign-In SDK');

        // Handle mobile platforms
        // Check if Google Services are available
        print('🔵 Attempting Google Sign-In...');

        // Trigger the authentication flow
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

        if (googleUser == null) {
          print('❌ Google sign-in was cancelled by user');
          throw Exception('Google sign-in was cancelled by user');
        }

        print('✅ Google user obtained: ${googleUser.email}');

        // Obtain the auth details from the request
        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;

        print('🔵 Google authentication tokens obtained');
        print(
          '🔵 Access Token: ${googleAuth.accessToken != null ? 'Present' : 'Missing'}',
        );
        print(
          '🔵 ID Token: ${googleAuth.idToken != null ? 'Present' : 'Missing'}',
        );

        // Create a new credential
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        print('🔵 Firebase credential created, signing in...');

        // Sign in to Firebase with the Google credential
        final UserCredential userCredential = await _auth.signInWithCredential(
          credential,
        );

        if (userCredential.user != null) {
          print('✅ Firebase sign-in successful');
          print('🔵 User UID: ${userCredential.user!.uid}');
          print('🔵 User Email: ${userCredential.user!.email}');
          print('🔵 User Name: ${userCredential.user!.displayName}');

          // Create user model
          final userModel = UserModel.fromFirebaseUser(
            userCredential.user!,
            provider: LoginProvider.google,
          );

          // Save user to database
          print('🔵 Saving user to database...');
          await _databaseService.createOrUpdateUser(userModel);
          print('✅ User saved to database successfully');

          return userModel;
        }
      }

      print('❌ Authentication failed - no user returned');
      return null;
    } on FirebaseAuthException catch (e) {
      // Handle specific Firebase Auth errors
      print('❌ FirebaseAuthException: ${e.code}, ${e.message}');
      String errorMessage;

      switch (e.code) {
        case 'account-exists-with-different-credential':
          errorMessage =
              'An account already exists with the same email address but different sign-in credentials.';
          break;
        case 'invalid-credential':
          errorMessage = 'The credential is malformed or has expired.';
          break;
        case 'operation-not-allowed':
          errorMessage = 'Google sign-in is not enabled for this project.';
          break;
        case 'user-disabled':
          errorMessage = 'This user account has been disabled.';
          break;
        case 'user-not-found':
          errorMessage = 'No user found corresponding to this credential.';
          break;
        case 'wrong-password':
          errorMessage = 'The password is invalid for the given email.';
          break;
        case 'invalid-verification-code':
          errorMessage = 'The verification code is invalid.';
          break;
        case 'invalid-verification-id':
          errorMessage = 'The verification ID is invalid.';
          break;
        case 'network-request-failed':
          errorMessage =
              'Network error occurred. Please check your internet connection.';
          break;
        default:
          errorMessage =
              e.message ?? 'An unknown error occurred during Google sign-in.';
          break;
      }

      throw Exception(errorMessage);
    } on Exception catch (e) {
      // Handle general errors
      print('❌ Exception during Google sign-in: $e');
      throw Exception('Failed to sign in with Google: ${e.toString()}');
    } catch (e) {
      // Handle any other errors
      print('❌ Unexpected error during Google sign-in: $e');
      throw Exception('An unexpected error occurred: ${e.toString()}');
    }
  }

  // Sign in anonymously
  static Future<UserModel?> signInAnonymously() async {
    try {
      final UserCredential userCredential = await _auth.signInAnonymously();

      if (userCredential.user != null) {
        // Create user model
        final userModel = UserModel.fromFirebaseUser(
          userCredential.user!,
          provider: LoginProvider.anonymous,
        );

        // Save user to database
        await _databaseService.createOrUpdateUser(userModel);

        return userModel;
      }

      return null;
    } on FirebaseAuthException catch (e) {
      print(
        'FirebaseAuthException during anonymous sign-in: ${e.code}, ${e.message}',
      );
      String errorMessage;

      switch (e.code) {
        case 'operation-not-allowed':
          errorMessage = 'Anonymous sign-in is not enabled for this project.';
          break;
        default:
          errorMessage =
              e.message ??
              'An unknown error occurred during anonymous sign-in.';
          break;
      }

      throw Exception(errorMessage);
    } catch (e) {
      print('Exception during anonymous sign-in: $e');
      throw Exception('Failed to sign in anonymously: ${e.toString()}');
    }
  }

  // Sign out
  static Future<void> signOut() async {
    try {
      // Update user online status before signing out (but don't let it block sign out)
      if (currentUser != null) {
        try {
          await _databaseService.updateUserOnlineStatus(
            currentUser!.uid,
            false,
          );
        } catch (e) {
          // Log the error but continue with sign out
          print('Warning: Could not update online status during sign out: $e');
        }
      }

      // Sign out from Google if signed in
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }

      // Sign out from Firebase
      await _auth.signOut();
    } catch (e) {
      print('Error signing out: $e');
      throw Exception('Failed to sign out: ${e.toString()}');
    }
  }

  // Delete account
  static Future<void> deleteAccount() async {
    try {
      final user = currentUser;
      if (user != null) {
        // Delete user data from database
        await _databaseService.deleteUser(user.uid);

        // Delete Firebase Auth account
        await user.delete();
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw Exception(
          'Please sign in again before deleting your account for security reasons.',
        );
      } else {
        throw Exception('Error deleting account: ${e.message}');
      }
    } catch (e) {
      print('Error deleting account: $e');
      throw Exception('Failed to delete account: ${e.toString()}');
    }
  }

  // Update user profile
  static Future<void> updateProfile({
    String? displayName,
    String? photoURL,
  }) async {
    try {
      final user = currentUser;
      if (user != null) {
        await user.updateDisplayName(displayName);
        await user.updatePhotoURL(photoURL);

        // Update in database as well
        final userModel = UserModel.fromFirebaseUser(user);
        await _databaseService.createOrUpdateUser(userModel);
      }
    } catch (e) {
      print('Error updating profile: $e');
      throw Exception('Failed to update profile: ${e.toString()}');
    }
  }

  // Convert anonymous account to permanent account with Google
  static Future<UserModel?> linkWithGoogle() async {
    try {
      final user = currentUser;
      if (user == null || !user.isAnonymous) {
        throw Exception('No anonymous user to link');
      }

      // Get Google credentials
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception('Google sign-in was cancelled');
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Link the accounts
      final UserCredential userCredential = await user.linkWithCredential(
        credential,
      );

      if (userCredential.user != null) {
        // Update user model
        final userModel = UserModel.fromFirebaseUser(
          userCredential.user!,
          provider: LoginProvider.google,
        );

        // Update user in database
        await _databaseService.createOrUpdateUser(userModel);

        return userModel;
      }

      return null;
    } catch (e) {
      print('Error linking with Google: $e');
      throw Exception('Failed to link with Google: ${e.toString()}');
    }
  }

  // Check if user is signed in
  static bool get isSignedIn => currentUser != null;

  // Check if user is anonymous
  static bool get isAnonymous => currentUser?.isAnonymous ?? false;

  // Get user UID
  static String? get currentUserId => currentUser?.uid;

  // Get user email
  static String? get currentUserEmail => currentUser?.email;

  // Get user display name
  static String? get currentUserDisplayName => currentUser?.displayName;

  // Get user photo URL
  static String? get currentUserPhotoURL => currentUser?.photoURL;
}
