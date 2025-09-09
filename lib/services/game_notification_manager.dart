// File: lib/services/game_notification_manager.dart
// Description: Service to handle game-specific notifications

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/live_game_model.dart';
import '../models/scheduled_game_model.dart';
import 'notification_service.dart';
import 'database_service.dart';
import '../providers/database_provider.dart';

class GameNotificationManager {
  final NotificationService _notificationService;
  final DatabaseService _databaseService;

  GameNotificationManager(this._notificationService, this._databaseService);

  // Send notification when a new game is created
  Future<void> notifyNewGame(ScheduledGameModel game) async {
    await _notificationService.sendNewGameNotification(
      gameId: game.id,
      gameTitle: game.name,
      gameStartTime: game.scheduledTime,
    );
  }

  // Schedule a reminder for an upcoming game (5 minutes before start)
  Future<void> scheduleGameReminder(ScheduledGameModel game) async {
    await _notificationService.scheduleGameReminderNotification(
      gameId: game.id,
      gameTitle: game.name,
      gameStartTime: game.scheduledTime,
    );
  }

  // Send notification about daily winners for a specific game
  Future<void> notifyGameWinners(String gameId) async {
    try {
      // Fetch the top winners for this game
      final winners = await _databaseService.getGameTopWinners(gameId: gameId);

      if (winners.isEmpty) {
        print('No winners found for game $gameId, skipping notification');
        return;
      }

      // Get top winner name
      final topWinner = winners.first;
      final topWinnerName = topWinner['displayName'] as String? ?? 'بەکارهێنەر';

      // Send notification with top winner and count
      await _notificationService.sendDailyWinnersNotification(
        winnerCount: winners.length,
        topWinnerName: topWinnerName,
        gameId: gameId,
      );

      print('Winner notification sent for game $gameId');
    } catch (e) {
      print('Error notifying game winners: $e');
    }
  }

  // Handle notifications for game lifecycle events
  Future<void> handleGameStatusChange(LiveGameModel game) async {
    // Game status changed to live - notify registered participants
    if (game.status == LiveGameStatus.live) {
      print('Game ${game.id} is now live, sending live notification');
      // Also send a notification when the game goes live
      await _notificationService.show(
        id: game.id.hashCode + 4,
        title: 'یاری زیندو: ${game.title}',
        body: 'یاریەکە ئێستا دەستیپێکرد و زیندووە!',
        payload: game.id,
        channelId: 'games_channel',
      );
    }
    // Game ended - notify about winners
    else if (game.status == LiveGameStatus.finished) {
      print('Game ${game.id} finished, scheduling winners notification');
      // Get the winners list and notify after a delay to allow scoring to complete
      Future.delayed(const Duration(minutes: 1), () {
        notifyGameWinners(game.id);
      });
    }
  }
}

// Provider for accessing the game notification manager
final gameNotificationManagerProvider = Provider<GameNotificationManager>((
  ref,
) {
  final notificationService = ref.read(notificationServiceProvider);
  final databaseService = ref.read(databaseServiceProvider);

  return GameNotificationManager(notificationService, databaseService);
});
