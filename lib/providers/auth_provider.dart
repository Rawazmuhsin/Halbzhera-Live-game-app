// File: lib/providers/auth_provider.dart
// Description: Updated authentication state management with live game integration

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';

// ============================================================================
// AUTH STATE PROVIDERS
// ============================================================================

// Firebase Auth state stream
final authStateProvider = StreamProvider<User?>((ref) {
  return AuthService.authStateChanges;
});

// Current user provider
final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) => user,
    loading: () => null,
    error: (_, __) => null,
  );
});

// Current user model provider
final currentUserModelProvider = StreamProvider<UserModel?>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    return Stream.value(null);
  }

  final databaseService = ref.read(databaseServiceProvider);
  return databaseService.getUserStream(user.uid);
});

// ============================================================================
// AUTH NOTIFIER
// ============================================================================

class AuthNotifier extends StateNotifier<AsyncValue<UserModel?>> {
  final DatabaseService _databaseService;

  AuthNotifier(this._databaseService) : super(const AsyncValue.data(null));

  // Sign in with Google
  Future<void> signInWithGoogle() async {
    state = const AsyncValue.loading();

    try {
      final userModel = await AuthService.signInWithGoogle();
      state = AsyncValue.data(userModel);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  // Sign in anonymously
  Future<void> signInAnonymously() async {
    state = const AsyncValue.loading();

    try {
      final userModel = await AuthService.signInAnonymously();
      state = AsyncValue.data(userModel);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  // Sign out
  Future<void> signOut() async {
    state = const AsyncValue.loading();

    try {
      await AuthService.signOut();
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  // Delete account
  Future<void> deleteAccount() async {
    state = const AsyncValue.loading();

    try {
      await AuthService.deleteAccount();
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  // Link anonymous account with Google
  Future<void> linkWithGoogle() async {
    state = const AsyncValue.loading();

    try {
      final userModel = await AuthService.linkWithGoogle();
      state = AsyncValue.data(userModel);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  // Update profile
  Future<void> updateProfile({String? displayName, String? photoURL}) async {
    try {
      await AuthService.updateProfile(
        displayName: displayName,
        photoURL: photoURL,
      );

      // Refresh the current user data
      final currentUser = AuthService.currentUser;
      if (currentUser != null) {
        final userModel = UserModel.fromFirebaseUser(currentUser);
        state = AsyncValue.data(userModel);
      }
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  // Update user score (for live games)
  Future<void> updateUserScore(int scoreToAdd) async {
    try {
      final currentUser = AuthService.currentUser;
      if (currentUser != null) {
        await _databaseService.updateUserScore(currentUser.uid, scoreToAdd);
        // Also update global leaderboard
        await _databaseService.updateGlobalLeaderboard(
          currentUser.uid,
          scoreToAdd,
        );
      }
    } catch (e) {
      // Handle error silently or show notification
      print('Error updating user score: $e');
    }
  }

  // Update user win (for completed live games)
  Future<void> updateUserWin() async {
    try {
      final currentUser = AuthService.currentUser;
      if (currentUser != null) {
        // Update wins count in user document
        await _databaseService.updateUserScore(
          currentUser.uid,
          0,
        ); // Just increment games played
        // Note: You might want to add a separate method for updating wins
      }
    } catch (e) {
      print('Error updating user win: $e');
    }
  }

  // Update online status
  Future<void> updateOnlineStatus(bool isOnline) async {
    try {
      final currentUser = AuthService.currentUser;
      if (currentUser != null) {
        await _databaseService.updateUserOnlineStatus(
          currentUser.uid,
          isOnline,
        );
      }
    } catch (e) {
      print('Error updating online status: $e');
    }
  }
}

// ============================================================================
// ADMIN AUTH NOTIFIER
// ============================================================================

class AdminAuthNotifier extends StateNotifier<AsyncValue<UserModel?>> {
  final DatabaseService _databaseService;

  AdminAuthNotifier(this._databaseService) : super(const AsyncValue.data(null));

  // Admin login (could be same as regular login but with role check)
  Future<void> adminSignIn() async {
    state = const AsyncValue.loading();

    try {
      final userModel = await AuthService.signInWithGoogle();

      // Check if user has admin privileges
      if (userModel != null && await _isAdminUser(userModel.uid)) {
        state = AsyncValue.data(userModel);
      } else {
        await AuthService.signOut();
        throw Exception('Access denied. Admin privileges required.');
      }
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  // Check if user is admin (you can implement your own logic)
  Future<bool> _isAdminUser(String uid) async {
    try {
      // Get current user to check email
      final currentUser = FirebaseAuth.instance.currentUser;

      // Option 1: Check against admin email addresses
      const adminEmails = [
        'rawazm318@gmail.com', // Your admin email
        // Add more admin emails as needed
      ];

      if (currentUser?.email != null &&
          adminEmails.contains(currentUser!.email)) {
        return true;
      }

      // Option 2: Check against a list of admin UIDs
      const adminUIDs = [
        // Add specific UIDs if needed
      ];

      if (adminUIDs.contains(uid)) {
        return true;
      }

      // Option 3: Check user document for admin role
      final user = await _databaseService.getUser(uid);
      return user?.preferences['isAdmin'] == true;
    } catch (e) {
      print('Error checking admin status: $e');
      return false;
    }
  }

  // Get all users for admin dashboard
  Future<List<UserModel>> getAllUsers() async {
    try {
      return await _databaseService.getAllUsers(limit: 100);
    } catch (e) {
      throw Exception('Failed to get users: $e');
    }
  }

  // Get live game statistics
  Future<Map<String, dynamic>> getLiveGameStats() async {
    try {
      return await _databaseService.getLiveGameStats();
    } catch (e) {
      throw Exception('Failed to get live game stats: $e');
    }
  }
}

// ============================================================================
// PROVIDER INSTANCES
// ============================================================================

// Database service provider
final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService();
});

// Auth notifier provider
final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<UserModel?>>((ref) {
      final databaseService = ref.read(databaseServiceProvider);
      return AuthNotifier(databaseService);
    });

// Admin auth notifier provider
final adminAuthNotifierProvider =
    StateNotifierProvider<AdminAuthNotifier, AsyncValue<UserModel?>>((ref) {
      final databaseService = ref.read(databaseServiceProvider);
      return AdminAuthNotifier(databaseService);
    });

// ============================================================================
// CONVENIENCE PROVIDERS
// ============================================================================

// Is signed in provider
final isSignedInProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) => user != null,
    loading: () => false,
    error: (_, __) => false,
  );
});

// Is anonymous provider
final isAnonymousProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  return user?.isAnonymous ?? false;
});

// Current user ID provider
final currentUserIdProvider = Provider<String?>((ref) {
  final user = ref.watch(currentUserProvider);
  return user?.uid;
});

// Current user email provider
final currentUserEmailProvider = Provider<String?>((ref) {
  final user = ref.watch(currentUserProvider);
  return user?.email;
});

// Current user display name provider
final currentUserDisplayNameProvider = Provider<String?>((ref) {
  final user = ref.watch(currentUserProvider);
  return user?.displayName;
});

// Auth loading provider
final authLoadingProvider = Provider<bool>((ref) {
  final authNotifierState = ref.watch(authNotifierProvider);
  return authNotifierState.isLoading;
});

// Auth error provider
final authErrorProvider = Provider<String?>((ref) {
  final authNotifierState = ref.watch(authNotifierProvider);
  return authNotifierState.when(
    data: (_) => null,
    loading: () => null,
    error: (error, _) => error.toString(),
  );
});

// Global leaderboard provider
final globalLeaderboardProvider = FutureProvider<List<UserModel>>((ref) {
  final databaseService = ref.read(databaseServiceProvider);
  return databaseService.getLeaderboard(limit: 50);
});

// User game history provider (for live games)
final userLiveGameHistoryProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((ref, userId) {
      final databaseService = ref.read(databaseServiceProvider);
      return databaseService.getUserGameHistory(userId, limit: 20);
    });

// ============================================================================
// ADMIN PROVIDERS
// ============================================================================

// All users provider for admin
final allUsersProvider = FutureProvider<List<UserModel>>((ref) async {
  final adminNotifier = ref.read(adminAuthNotifierProvider.notifier);
  return adminNotifier.getAllUsers();
});

// Live game stats provider for admin
final liveGameStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final adminNotifier = ref.read(adminAuthNotifierProvider.notifier);
  return adminNotifier.getLiveGameStats();
});

// Is admin provider
final isAdminProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return false;

  // Check admin emails
  const adminEmails = [
    'rawazm318@gmail.com', // Your admin email
    // Add more admin emails as needed
  ];

  return adminEmails.contains(user.email);
});

// Admin user type provider
final userTypeProvider = Provider<String>((ref) {
  final isAdmin = ref.watch(isAdminProvider);
  return isAdmin ? 'admin' : 'user';
});

// Categories provider for admin
final categoriesProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final databaseService = ref.read(databaseServiceProvider);
  return databaseService.getCategories();
});

// Questions by category provider for admin
final questionsByCategoryProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((
      ref,
      categoryId,
    ) async {
      final databaseService = ref.read(databaseServiceProvider);
      return databaseService.getQuestionsByCategory(categoryId);
    });
