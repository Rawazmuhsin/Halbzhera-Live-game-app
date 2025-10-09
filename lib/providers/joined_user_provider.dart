// File: lib/providers/joined_user_provider.dart
// Description: Provider for joined users functionality

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/joined_user_model.dart';
import '../services/database_service.dart';
import 'auth_provider.dart';

// Stream provider for joined users in a specific game
final joinedUsersProvider =
    StreamProvider.family<List<JoinedUserModel>, String>((ref, gameId) {
      final databaseService = ref.read(databaseServiceProvider);
      return databaseService.getJoinedUsersStream(gameId);
    });

// Stream provider for games joined by current user
final userJoinedGamesProvider = StreamProvider<List<JoinedUserModel>>((ref) {
  final currentUser = ref.watch(currentUserProvider);
  if (currentUser == null) {
    return Stream.value([]);
  }

  final databaseService = ref.read(databaseServiceProvider);
  // Limit to 5 most recent games for better performance
  return databaseService.getUserJoinedGamesStream(currentUser.uid, limit: 5);
});

// Provider to check if current user has joined a specific game
final hasUserJoinedGameProvider = FutureProvider.family<bool, String>((
  ref,
  gameId,
) async {
  final currentUser = ref.watch(currentUserProvider);
  if (currentUser == null) return false;

  final databaseService = ref.read(databaseServiceProvider);
  return databaseService.hasUserJoinedGame(gameId, currentUser.uid);
});

// Provider for joined user count in a specific game
final joinedUserCountProvider = FutureProvider.family<int, String>((
  ref,
  gameId,
) async {
  final databaseService = ref.read(databaseServiceProvider);
  return databaseService.getJoinedUserCount(gameId);
});

// Notifier for join/leave game operations
class JoinedUserNotifier extends StateNotifier<AsyncValue<void>> {
  final DatabaseService _databaseService;
  final Ref _ref;

  JoinedUserNotifier(this._databaseService, this._ref)
    : super(const AsyncValue.data(null));

  // Join a game
  Future<String?> joinGame({
    required String gameId,
    String? guestAccountNumber,
  }) async {
    state = const AsyncValue.loading();

    try {
      final currentUser = _ref.read(currentUserProvider);
      if (currentUser == null) {
        throw Exception('کاربەر نەناسراوە');
      }

      // Determine account type and details
      String accountType = 'registered';
      String? displayName = currentUser.displayName;
      String? photoUrl = currentUser.photoURL;

      // Check if this is a guest account (anonymous or specific email patterns)
      if (currentUser.isAnonymous || guestAccountNumber != null) {
        accountType = 'guest';
      }

      final joinId = await _databaseService.joinGame(
        gameId: gameId,
        userId: currentUser.uid,
        userEmail: currentUser.email ?? '',
        userDisplayName: displayName,
        userPhotoUrl: photoUrl,
        accountType: accountType,
        guestAccountNumber: guestAccountNumber,
      );

      state = const AsyncValue.data(null);

      // Invalidate related providers to refresh data
      _ref.invalidate(hasUserJoinedGameProvider(gameId));
      _ref.invalidate(joinedUsersProvider(gameId));
      _ref.invalidate(joinedUserCountProvider(gameId));
      _ref.invalidate(userJoinedGamesProvider);

      return joinId;
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      return null;
    }
  }

  // Leave a game
  Future<bool> leaveGame(String gameId) async {
    state = const AsyncValue.loading();

    try {
      final currentUser = _ref.read(currentUserProvider);
      if (currentUser == null) {
        throw Exception('کاربەر نەناسراوە');
      }

      await _databaseService.leaveGame(gameId, currentUser.uid);
      state = const AsyncValue.data(null);

      // Invalidate related providers to refresh data
      _ref.invalidate(hasUserJoinedGameProvider(gameId));
      _ref.invalidate(joinedUsersProvider(gameId));
      _ref.invalidate(joinedUserCountProvider(gameId));
      _ref.invalidate(userJoinedGamesProvider);

      return true;
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      return false;
    }
  }
}

// Provider for the joined user notifier
final joinedUserNotifierProvider =
    StateNotifierProvider<JoinedUserNotifier, AsyncValue<void>>((ref) {
      final databaseService = ref.read(databaseServiceProvider);
      return JoinedUserNotifier(databaseService, ref);
    });

// Convenience providers for loading and error states
final joinGameLoadingProvider = Provider<bool>((ref) {
  final state = ref.watch(joinedUserNotifierProvider);
  return state.isLoading;
});

final joinGameErrorProvider = Provider<String?>((ref) {
  final state = ref.watch(joinedUserNotifierProvider);
  return state.when(
    data: (_) => null,
    loading: () => null,
    error: (error, _) => error.toString(),
  );
});
