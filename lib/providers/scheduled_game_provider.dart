// File: lib/providers/scheduled_game_provider.dart
// Description: Provider for scheduled games management

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/scheduled_game_model.dart';
import '../services/database_service.dart';
import '../services/game_notification_manager.dart';
import 'auth_provider.dart';

// Scheduled games stream provider
final scheduledGamesProvider = StreamProvider<List<ScheduledGameModel>>((ref) {
  final databaseService = ref.read(databaseServiceProvider);
  return databaseService.getScheduledGamesStream();
});

// Upcoming scheduled games stream provider
final upcomingScheduledGamesProvider = StreamProvider<List<ScheduledGameModel>>(
  (ref) {
    final databaseService = ref.read(databaseServiceProvider);
    return databaseService.getUpcomingScheduledGamesStream();
  },
);

// Scheduled games by category provider
final scheduledGamesByCategoryProvider =
    StreamProvider.family<List<ScheduledGameModel>, String>((ref, categoryId) {
      final databaseService = ref.read(databaseServiceProvider);
      return databaseService.getScheduledGamesByCategoryStream(categoryId);
    });

// Single scheduled game provider
final scheduledGameProvider =
    FutureProvider.family<ScheduledGameModel?, String>((ref, gameId) async {
      final databaseService = ref.read(databaseServiceProvider);
      return databaseService.getScheduledGame(gameId);
    });

// Scheduled game notifier for CRUD operations
class ScheduledGameNotifier extends StateNotifier<AsyncValue<void>> {
  final DatabaseService _databaseService;
  final Ref _ref;

  ScheduledGameNotifier(this._databaseService, this._ref)
    : super(const AsyncValue.data(null));

  // Create new scheduled game
  Future<String?> createGame(ScheduledGameModel game) async {
    state = const AsyncValue.loading();

    try {
      final gameId = await _databaseService.createScheduledGame(game);

      // Schedule notifications for the game
      try {
        final notificationManager = _ref.read(gameNotificationManagerProvider);
        final gameWithId = game.copyWith(id: gameId);
        await notificationManager.notifyNewGame(gameWithId);
        await notificationManager.scheduleGameReminder(gameWithId);
      } catch (notificationError) {
        print('Failed to schedule notifications: $notificationError');
        // Continue anyway, don't fail the game creation
      }

      state = const AsyncValue.data(null);
      return gameId;
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      return null;
    }
  }

  // Update existing scheduled game
  Future<bool> updateGame(ScheduledGameModel game) async {
    state = const AsyncValue.loading();

    try {
      await _databaseService.updateScheduledGame(game);

      // Reschedule notifications for the updated game
      try {
        final notificationManager = _ref.read(gameNotificationManagerProvider);
        // Also notify that the game has been updated
        await notificationManager.notifyNewGame(game);
        await notificationManager.scheduleGameReminder(game);
      } catch (notificationError) {
        print('Failed to reschedule notifications: $notificationError');
        // Continue anyway, don't fail the game update
      }

      state = const AsyncValue.data(null);
      return true;
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      return false;
    }
  }

  // Delete scheduled game
  Future<bool> deleteGame(String gameId) async {
    state = const AsyncValue.loading();

    try {
      await _databaseService.deleteScheduledGame(gameId);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      return false;
    }
  }

  // Update game status
  Future<bool> updateGameStatus(String gameId, GameStatus status) async {
    state = const AsyncValue.loading();

    try {
      await _databaseService.updateGameStatus(gameId, status);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      return false;
    }
  }

  // Start scheduled game (convert to live game)
  Future<String?> startGame(String scheduledGameId) async {
    state = const AsyncValue.loading();

    try {
      final liveGameId = await _databaseService.startScheduledGame(
        scheduledGameId,
      );
      state = const AsyncValue.data(null);
      return liveGameId;
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      return null;
    }
  }

  // Cancel scheduled game
  Future<bool> cancelGame(String gameId) async {
    return updateGameStatus(gameId, GameStatus.cancelled);
  }
}

// Scheduled game notifier provider
final scheduledGameNotifierProvider =
    StateNotifierProvider<ScheduledGameNotifier, AsyncValue<void>>((ref) {
      final databaseService = ref.read(databaseServiceProvider);
      return ScheduledGameNotifier(databaseService, ref);
    });

// Games ready to start provider
final gamesReadyToStartProvider = FutureProvider<List<ScheduledGameModel>>((
  ref,
) async {
  final databaseService = ref.read(databaseServiceProvider);
  return databaseService.getGamesReadyToStart();
});

// Convenience providers for loading states
final scheduledGamesLoadingProvider = Provider<bool>((ref) {
  final scheduledGamesState = ref.watch(scheduledGamesProvider);
  return scheduledGamesState.isLoading;
});

final scheduledGamesErrorProvider = Provider<String?>((ref) {
  final scheduledGamesState = ref.watch(scheduledGamesProvider);
  return scheduledGamesState.when(
    data: (_) => null,
    loading: () => null,
    error: (error, _) => error.toString(),
  );
});

// Game creation loading state
final gameCreationLoadingProvider = Provider<bool>((ref) {
  final notifierState = ref.watch(scheduledGameNotifierProvider);
  return notifierState.isLoading;
});

// Game creation error state
final gameCreationErrorProvider = Provider<String?>((ref) {
  final notifierState = ref.watch(scheduledGameNotifierProvider);
  return notifierState.when(
    data: (_) => null,
    loading: () => null,
    error: (error, _) => error.toString(),
  );
});
