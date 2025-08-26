// File: lib/providers/auto_navigation_provider.dart
// Description: Provider for automatic navigation to lobby when game starts

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../models/scheduled_game_model.dart';
import 'scheduled_game_provider.dart';
import 'joined_user_provider.dart';
import 'auth_provider.dart';

// State class for auto navigation
class AutoNavigationState {
  final bool shouldNavigate;
  final ScheduledGameModel? gameToNavigate;
  final DateTime? lastCheckTime;

  AutoNavigationState({
    this.shouldNavigate = false,
    this.gameToNavigate,
    this.lastCheckTime,
  });

  AutoNavigationState copyWith({
    bool? shouldNavigate,
    ScheduledGameModel? gameToNavigate,
    DateTime? lastCheckTime,
  }) {
    return AutoNavigationState(
      shouldNavigate: shouldNavigate ?? this.shouldNavigate,
      gameToNavigate: gameToNavigate ?? this.gameToNavigate,
      lastCheckTime: lastCheckTime ?? this.lastCheckTime,
    );
  }
}

// Stream provider that monitors for game starts
final gameStartMonitorProvider = StreamProvider<AutoNavigationState>((
  ref,
) async* {
  final currentUser = ref.watch(currentUserProvider);
  if (currentUser == null) {
    yield AutoNavigationState();
    return;
  }

  // Create a periodic stream that checks every second
  await for (final _ in Stream.periodic(const Duration(seconds: 1))) {
    final now = DateTime.now();

    // Get upcoming games
    final upcomingGamesAsync = await ref.read(
      upcomingScheduledGamesProvider.future,
    );

    // Get user's joined games
    final userJoinedGames = await ref.read(userJoinedGamesProvider.future);

    // Check each upcoming game
    for (final game in upcomingGamesAsync) {
      // Check if game has started (within last 5 seconds to catch it)
      final timeSinceStart = now.difference(game.scheduledTime);
      final hasJustStarted =
          timeSinceStart.inSeconds >= 0 && timeSinceStart.inSeconds <= 5;

      if (hasJustStarted) {
        // Check if user has joined this game
        final hasJoined = userJoinedGames.any(
          (joinedGame) =>
              joinedGame.gameId == game.id &&
              joinedGame.userId == currentUser.uid &&
              joinedGame.isActive,
        );

        if (hasJoined) {
          // Emit navigation signal
          yield AutoNavigationState(
            shouldNavigate: true,
            gameToNavigate: game,
            lastCheckTime: now,
          );

          // Reset after emitting
          await Future.delayed(const Duration(seconds: 2));
          yield AutoNavigationState(shouldNavigate: false, lastCheckTime: now);

          break; // Only navigate to one game at a time
        }
      }
    }

    // Yield current state
    yield AutoNavigationState(lastCheckTime: now);
  }
});

// Alternative: Notifier-based approach for more control
class AutoNavigationNotifier extends StateNotifier<AutoNavigationState> {
  final Ref _ref;
  Timer? _checkTimer;
  final Set<String> _navigatedGames =
      {}; // Track games we've already navigated to

  AutoNavigationNotifier(this._ref) : super(AutoNavigationState()) {
    _startMonitoring();
  }

  void _startMonitoring() {
    // Check immediately
    _checkForGameStarts();

    // Then check every second
    _checkTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _checkForGameStarts();
    });
  }

  Future<void> _checkForGameStarts() async {
    final currentUser = _ref.read(currentUserProvider);
    if (currentUser == null) return;

    try {
      final now = DateTime.now();
      final upcomingGamesAsync = _ref.read(upcomingScheduledGamesProvider);

      if (upcomingGamesAsync is AsyncData<List<ScheduledGameModel>>) {
        for (final game in upcomingGamesAsync.value) {
          // Skip if we've already navigated to this game
          if (_navigatedGames.contains(game.id)) continue;

          // Check if game time has arrived (with 2-second buffer)
          final timeUntilStart = game.scheduledTime.difference(now);
          final hasStarted = timeUntilStart.inSeconds <= 0;
          final isWithinStartWindow =
              timeUntilStart.inSeconds >= -60; // Within 1 minute of start

          if (hasStarted && isWithinStartWindow) {
            // Check if user has joined this game
            final hasJoinedAsync = await _ref.read(
              hasUserJoinedGameProvider(game.id).future,
            );

            if (hasJoinedAsync == true) {
              // Mark as navigated
              _navigatedGames.add(game.id);

              // Update state to trigger navigation
              state = AutoNavigationState(
                shouldNavigate: true,
                gameToNavigate: game,
                lastCheckTime: now,
              );

              // Reset after a delay
              Future.delayed(const Duration(seconds: 3), () {
                if (mounted) {
                  state = AutoNavigationState(
                    shouldNavigate: false,
                    lastCheckTime: now,
                  );
                }
              });

              break; // Only navigate to one game at a time
            }
          }
        }
      }
    } catch (e) {
      print('Error checking for game starts: $e');
    }
  }

  void markAsNavigated(String gameId) {
    _navigatedGames.add(gameId);
  }

  void reset() {
    state = AutoNavigationState();
    _navigatedGames.clear();
  }

  @override
  void dispose() {
    _checkTimer?.cancel();
    super.dispose();
  }
}

// Provider for the auto navigation notifier
final autoNavigationProvider =
    StateNotifierProvider<AutoNavigationNotifier, AutoNavigationState>((ref) {
      return AutoNavigationNotifier(ref);
    });
