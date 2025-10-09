// File: lib/providers/live_game_provider.dart
// Description: Live game state management with Riverpod

// ignore_for_file: avoid_print

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/live_game_model.dart';
import '../models/user_model.dart';
import '../services/database_service.dart';
import 'auth_provider.dart';

// ============================================================================
// LIVE GAME PROVIDERS
// ============================================================================

// Current live game stream
final currentLiveGameProvider = StreamProvider<LiveGameModel?>((ref) {
  final databaseService = ref.read(databaseServiceProvider);
  return databaseService.getCurrentLiveGameStream();
});

// Upcoming games stream
final upcomingGamesProvider = StreamProvider<List<LiveGameModel>>((ref) {
  final databaseService = ref.read(databaseServiceProvider);
  return databaseService.getUpcomingGamesStream();
});

// Specific live game stream
final liveGameProvider = StreamProvider.family<LiveGameModel?, String>((
  ref,
  gameId,
) {
  final databaseService = ref.read(databaseServiceProvider);
  return databaseService.getLiveGameStream(gameId);
});

// Live leaderboard stream
final liveLeaderboardProvider =
    StreamProvider.family<List<LiveAnswerModel>, String>((ref, gameId) {
      final databaseService = ref.read(databaseServiceProvider);
      return databaseService.getLiveLeaderboardStream(gameId);
    });

// User's live answer stream
final userLiveAnswerProvider = StreamProvider.family<LiveAnswerModel?, String>((
  ref,
  gameId,
) {
  final currentUser = ref.watch(currentUserProvider);
  if (currentUser == null) return Stream.value(null);

  final databaseService = ref.read(databaseServiceProvider);
  return databaseService.getUserLiveAnswerStream(gameId, currentUser.uid);
});

// Game schedules provider
final gameSchedulesProvider = FutureProvider<List<GameScheduleModel>>((
  ref,
) async {
  final databaseService = ref.read(databaseServiceProvider);
  return databaseService.getGameSchedules();
});

// ============================================================================
// LIVE GAME STATE
// ============================================================================

class LiveGameState {
  final LiveGameModel? currentGame;
  final LiveAnswerModel? userAnswer;
  final List<LiveAnswerModel> leaderboard;
  final List<LiveAnswerModel>
  eliminatedPlayers; // NEW: Track eliminated players
  final Map<String, dynamic>? currentQuestion;
  final bool isJoined;
  final bool hasAnsweredCurrentQuestion;
  final bool isEliminated; // NEW: Track if current user is eliminated
  final Duration? timeRemaining;
  final bool isLoading;
  final String? error;
  final int activePlayers; // NEW: Count of active players
  final String? eliminationReason; // NEW: Why user was eliminated

  const LiveGameState({
    this.currentGame,
    this.userAnswer,
    this.leaderboard = const [],
    this.eliminatedPlayers = const [], // NEW
    this.currentQuestion,
    this.isJoined = false,
    this.hasAnsweredCurrentQuestion = false,
    this.isEliminated = false, // NEW
    this.timeRemaining,
    this.isLoading = false,
    this.error,
    this.activePlayers = 0, // NEW
    this.eliminationReason, // NEW
  });

  LiveGameState copyWith({
    LiveGameModel? currentGame,
    LiveAnswerModel? userAnswer,
    List<LiveAnswerModel>? leaderboard,
    List<LiveAnswerModel>? eliminatedPlayers, // NEW
    Map<String, dynamic>? currentQuestion,
    bool? isJoined,
    bool? hasAnsweredCurrentQuestion,
    bool? isEliminated, // NEW
    Duration? timeRemaining,
    bool? isLoading,
    String? error,
    int? activePlayers, // NEW
    String? eliminationReason, // NEW
  }) {
    return LiveGameState(
      currentGame: currentGame ?? this.currentGame,
      userAnswer: userAnswer ?? this.userAnswer,
      leaderboard: leaderboard ?? this.leaderboard,
      eliminatedPlayers: eliminatedPlayers ?? this.eliminatedPlayers, // NEW
      currentQuestion: currentQuestion ?? this.currentQuestion,
      isJoined: isJoined ?? this.isJoined,
      hasAnsweredCurrentQuestion:
          hasAnsweredCurrentQuestion ?? this.hasAnsweredCurrentQuestion,
      isEliminated: isEliminated ?? this.isEliminated, // NEW
      timeRemaining: timeRemaining ?? this.timeRemaining,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      activePlayers: activePlayers ?? this.activePlayers, // NEW
      eliminationReason: eliminationReason ?? this.eliminationReason, // NEW
    );
  }

  // Get user's rank in leaderboard
  int get userRank {
    if (userAnswer == null) return 0;

    final sortedLeaderboard = List<LiveAnswerModel>.from(leaderboard)
      ..sort((a, b) => b.totalScore.compareTo(a.totalScore));

    return sortedLeaderboard.indexWhere(
          (answer) => answer.userId == userAnswer!.userId,
        ) +
        1;
  }

  // Check if game is active and user can still play
  bool get isGameActive => (currentGame?.isActive ?? false) && !isEliminated;

  // Check if game is live
  bool get isGameLive => currentGame?.status == LiveGameStatus.live;

  // Check if user can still participate (not eliminated)
  bool get canParticipate => isJoined && !isEliminated;

  // Get survival rate
  double get survivalRate {
    final totalPlayers = leaderboard.length + eliminatedPlayers.length;
    if (totalPlayers == 0) return 0.0;
    return (leaderboard.length / totalPlayers) * 100;
  }

  // Get current question number (1-based)
  int get currentQuestionNumber => (currentGame?.currentQuestion ?? 0) + 1;

  // Get total questions
  int get totalQuestions => currentGame?.totalQuestions ?? 15;

  // Calculate progress percentage
  double get progress {
    if (totalQuestions == 0) return 0.0;
    return currentQuestionNumber / totalQuestions;
  }
}

// ============================================================================
// LIVE GAME NOTIFIER
// ============================================================================

class LiveGameNotifier extends StateNotifier<LiveGameState> {
  final DatabaseService _databaseService;
  final Ref _ref;
  Timer? _questionTimer;
  StreamSubscription? _leaderboardSubscription;
  StreamSubscription? _userAnswerSubscription;
  bool _listenersInitialized = false;

  LiveGameNotifier(this._databaseService, this._ref)
    : super(const LiveGameState()) {
    // Don't initialize listeners automatically - wait until user joins a game
    // This prevents unnecessary Firestore queries on app startup
  }

  // Call this when user joins a game
  void initializeListeners() {
    if (_listenersInitialized) return; // Already initialized

    _listenersInitialized = true;
    _setupListeners();
  }

  void _setupListeners() {
    // Listen to current live game using the provider
    _ref.listen(currentLiveGameProvider, (previous, next) {
      next.when(
        data: (game) => _onGameUpdated(game),
        loading: () => state = state.copyWith(isLoading: true),
        error:
            (error, _) =>
                state = state.copyWith(
                  error: error.toString(),
                  isLoading: false,
                ),
      );
    });
  }

  void _onGameUpdated(LiveGameModel? game) {
    final previousGame = state.currentGame;
    state = state.copyWith(currentGame: game, isLoading: false, error: null);

    if (game != null) {
      // Check if user is joined
      final currentUser = _ref.read(currentUserProvider);
      final isJoined =
          currentUser != null && game.isParticipant(currentUser.uid);
      state = state.copyWith(isJoined: isJoined);

      // Setup question timer if game is live
      if (game.status == LiveGameStatus.live) {
        _setupQuestionTimer(game);
        _loadCurrentQuestion(game);
      }

      // Setup leaderboard listener if joined
      if (isJoined) {
        _setupLeaderboardListener(game.id);
        _setupUserAnswerListener(game.id, currentUser.uid);
      }

      // Check if question changed
      if (previousGame?.currentQuestion != game.currentQuestion) {
        _onQuestionChanged(game);
      }
    } else {
      _clearListeners();
    }
  }

  void _setupQuestionTimer(LiveGameModel game) {
    _questionTimer?.cancel();

    final timeRemaining = game.timeRemainingForQuestion;
    if (timeRemaining != null && timeRemaining.inMilliseconds > 0) {
      state = state.copyWith(timeRemaining: timeRemaining);

      _questionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        final remaining = game.timeRemainingForQuestion;
        if (remaining == null || remaining.inMilliseconds <= 0) {
          timer.cancel();
          state = state.copyWith(timeRemaining: Duration.zero);
          _onQuestionTimeUp();
        } else {
          state = state.copyWith(timeRemaining: remaining);
        }
      });
    }
  }

  void _setupLeaderboardListener(String gameId) {
    _leaderboardSubscription?.cancel();
    _leaderboardSubscription = _databaseService
        .getLiveLeaderboardStream(gameId)
        .listen((leaderboard) {
          state = state.copyWith(
            leaderboard: leaderboard,
            activePlayers: leaderboard.length,
          );
        });

    // Also listen to eliminated players
    _databaseService.getEliminatedPlayersInGame(gameId).then((
      eliminatedPlayers,
    ) {
      state = state.copyWith(eliminatedPlayers: eliminatedPlayers);
    });
  }

  void _setupUserAnswerListener(String gameId, String userId) {
    _userAnswerSubscription?.cancel();
    _userAnswerSubscription = _databaseService
        .getUserLiveAnswerStream(gameId, userId)
        .listen((userAnswer) {
          if (userAnswer != null) {
            final hasAnswered = userAnswer.hasAnsweredQuestion(
              state.currentGame?.currentQuestion ?? 0,
            );
            final isEliminated = userAnswer.isEliminated;

            state = state.copyWith(
              userAnswer: userAnswer,
              hasAnsweredCurrentQuestion: hasAnswered,
              isEliminated: isEliminated,
              eliminationReason: userAnswer.eliminationReason,
            );

            // If user was just eliminated, show elimination message
            if (isEliminated && !state.isEliminated) {
              _showEliminationMessage(
                userAnswer.eliminationReason ?? 'unknown',
              );
            }
          }
        });
  }

  Future<void> _loadCurrentQuestion(LiveGameModel game) async {
    try {
      final questionId = game.currentQuestionId;
      if (questionId != null) {
        final question = await _databaseService.getQuestion(questionId);
        state = state.copyWith(currentQuestion: question);
      }
    } catch (e) {
      state = state.copyWith(error: 'Failed to load question: $e');
    }
  }

  void _onQuestionChanged(LiveGameModel game) {
    state = state.copyWith(
      hasAnsweredCurrentQuestion: false,
      currentQuestion: null,
    );
    _loadCurrentQuestion(game);
  }

  void _onQuestionTimeUp() {
    // Auto-eliminate user if they haven't answered
    if (!state.hasAnsweredCurrentQuestion &&
        state.isJoined &&
        !state.isEliminated) {
      _eliminateUserForTimeout();
    }
  }

  // Eliminate user due to timeout
  Future<void> _eliminateUserForTimeout() async {
    try {
      final currentUser = _ref.read(currentUserProvider);
      final game = state.currentGame;

      if (currentUser != null && game != null) {
        await _databaseService.eliminateUserTimeout(
          game.id,
          currentUser.uid,
          game.currentQuestion,
        );
      }
    } catch (e) {
      print('Error eliminating user for timeout: $e');
    }
  }

  // Show elimination message
  void _showEliminationMessage(String reason) {
    // This would trigger UI to show elimination screen
    // You can emit this through a callback or state change
    print('User eliminated: $reason');
  }

  void _clearListeners() {
    _questionTimer?.cancel();
    _leaderboardSubscription?.cancel();
    _userAnswerSubscription?.cancel();
  }

  // ============================================================================
  // PUBLIC METHODS
  // ============================================================================

  // Join live game
  Future<void> joinGame(String gameId) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final currentUser = _ref.read(currentUserProvider);
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final userModel = UserModel.fromFirebaseUser(currentUser);
      await _databaseService.joinLiveGame(gameId, userModel);

      // Initialize listeners now that user has joined
      initializeListeners();

      state = state.copyWith(isJoined: true, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  // Leave live game
  Future<void> leaveGame(String gameId) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final currentUser = _ref.read(currentUserProvider);
      if (currentUser == null) return;

      await _databaseService.leaveLiveGame(gameId, currentUser.uid);

      state = state.copyWith(isJoined: false, isLoading: false);
      _clearListeners();
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  // Submit answer with automatic elimination logic
  Future<void> submitAnswer(String answer) async {
    try {
      if (state.hasAnsweredCurrentQuestion ||
          !state.isJoined ||
          state.isEliminated ||
          state.currentGame == null) {
        return;
      }

      final currentUser = _ref.read(currentUserProvider);
      if (currentUser == null) return;

      final game = state.currentGame!;
      final questionId = game.currentQuestionId;
      if (questionId == null) return;

      // Submit answer with elimination logic
      final isCorrect = await _databaseService.submitLiveAnswerWithElimination(
        gameId: game.id,
        userId: currentUser.uid,
        questionIndex: game.currentQuestion,
        answer: answer,
        questionId: questionId,
      );

      // Update local state immediately
      state = state.copyWith(hasAnsweredCurrentQuestion: true);

      // If answer was wrong, user will be eliminated (handled by listener)
      if (!isCorrect) {
        print('Wrong answer submitted - user will be eliminated');
      }
    } catch (e) {
      state = state.copyWith(error: 'Failed to submit answer: $e');
    }
  }

  // Check elimination status
  Future<void> checkEliminationStatus() async {
    try {
      final currentUser = _ref.read(currentUserProvider);
      final game = state.currentGame;

      if (currentUser != null && game != null) {
        final isEliminated = await _databaseService.isUserEliminated(
          game.id,
          currentUser.uid,
        );
        if (isEliminated != state.isEliminated) {
          state = state.copyWith(isEliminated: isEliminated);
        }
      }
    } catch (e) {
      print('Error checking elimination status: $e');
    }
  }

  // Reset state
  void reset() {
    _clearListeners();
    state = const LiveGameState();
  }

  // Get game statistics including elimination data
  Future<Map<String, dynamic>> getGameStats() async {
    try {
      final game = state.currentGame;
      if (game == null) return {};

      return await _databaseService.getGameEliminationStats(game.id);
    } catch (e) {
      return {};
    }
  }

  // Get elimination summary
  Map<String, dynamic> getEliminationSummary() {
    return {
      'totalPlayers': state.leaderboard.length + state.eliminatedPlayers.length,
      'activePlayers': state.activePlayers,
      'eliminatedPlayers': state.eliminatedPlayers.length,
      'survivalRate': state.survivalRate,
      'userEliminated': state.isEliminated,
      'eliminationReason': state.eliminationReason,
    };
  }

  @override
  void dispose() {
    _clearListeners();
    super.dispose();
  }
}

// ============================================================================
// ADMIN LIVE GAME NOTIFIER
// ============================================================================

class AdminLiveGameNotifier extends StateNotifier<AsyncValue<void>> {
  final DatabaseService _databaseService;

  AdminLiveGameNotifier(this._databaseService)
    : super(const AsyncValue.data(null));

  // Create live game
  Future<String> createLiveGame({
    required String title,
    required String category,
    required DateTime scheduledTime,
    required List<String> questionIds,
  }) async {
    state = const AsyncValue.loading();

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('Admin not authenticated');
      }

      final game = LiveGameModel(
        id: '', // Will be set by database service
        title: title,
        category: category,
        scheduledTime: scheduledTime,
        questions: questionIds,
        totalQuestions: questionIds.length,
        createdBy: currentUser.uid,
        createdAt: DateTime.now(),
      );

      final gameId = await _databaseService.createLiveGame(game);

      state = const AsyncValue.data(null);
      return gameId;
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      rethrow;
    }
  }

  // Start live game
  Future<void> startLiveGame(String gameId) async {
    state = const AsyncValue.loading();

    try {
      await _databaseService.startLiveGame(gameId);
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  // Move to next question
  Future<void> nextQuestion(String gameId, int nextQuestionIndex) async {
    try {
      await _databaseService.moveToNextQuestion(gameId, nextQuestionIndex);
    } catch (e) {
      print('Error moving to next question: $e');
    }
  }

  // Finish live game
  Future<void> finishLiveGame(String gameId) async {
    state = const AsyncValue.loading();

    try {
      await _databaseService.finishLiveGame(gameId);
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  // Create game schedule
  Future<String> createGameSchedule({
    required int dayOfWeek,
    required String time,
    required String category,
    required String title,
    required String description,
  }) async {
    try {
      final schedule = GameScheduleModel(
        id: '', // Will be set by database service
        dayOfWeek: dayOfWeek,
        time: time,
        category: category,
        title: title,
        description: description,
        createdAt: DateTime.now(),
      );

      return await _databaseService.createGameSchedule(schedule);
    } catch (e) {
      rethrow;
    }
  }
}

// ============================================================================
// PROVIDER INSTANCES
// ============================================================================

// Live game notifier provider
final liveGameNotifierProvider =
    StateNotifierProvider<LiveGameNotifier, LiveGameState>((ref) {
      final databaseService = ref.read(databaseServiceProvider);
      return LiveGameNotifier(databaseService, ref);
    });

// Admin live game notifier provider
final adminLiveGameNotifierProvider =
    StateNotifierProvider<AdminLiveGameNotifier, AsyncValue<void>>((ref) {
      final databaseService = ref.read(databaseServiceProvider);
      return AdminLiveGameNotifier(databaseService);
    });

// ============================================================================
// CONVENIENCE PROVIDERS
// ============================================================================

// Is in live game provider (only if not eliminated)
final isInLiveGameProvider = Provider<bool>((ref) {
  final gameState = ref.watch(liveGameNotifierProvider);
  return gameState.isJoined &&
      gameState.isGameActive &&
      !gameState.isEliminated;
});

// Is eliminated provider
final isEliminatedProvider = Provider<bool>((ref) {
  final gameState = ref.watch(liveGameNotifierProvider);
  return gameState.isEliminated;
});

// Active players count provider
final activePlayersCountProvider = Provider<int>((ref) {
  final gameState = ref.watch(liveGameNotifierProvider);
  return gameState.activePlayers;
});

// Elimination reason provider
final eliminationReasonProvider = Provider<String?>((ref) {
  final gameState = ref.watch(liveGameNotifierProvider);
  return gameState.eliminationReason;
});

// Survival rate provider
final survivalRateProvider = Provider<double>((ref) {
  final gameState = ref.watch(liveGameNotifierProvider);
  return gameState.survivalRate;
});

// Eliminated players provider
final eliminatedPlayersProvider = Provider<List<LiveAnswerModel>>((ref) {
  final gameState = ref.watch(liveGameNotifierProvider);
  return gameState.eliminatedPlayers;
});

// Can answer provider (updated with elimination check)
final canAnswerQuestionProvider = Provider<bool>((ref) {
  final gameState = ref.watch(liveGameNotifierProvider);
  return gameState.isGameLive &&
      gameState.isJoined &&
      !gameState.isEliminated && // NEW: Check if not eliminated
      !gameState.hasAnsweredCurrentQuestion &&
      (gameState.timeRemaining?.inMilliseconds ?? 0) > 0;
});

// Game winner provider
final gameWinnerProvider = Provider<String?>((ref) {
  final gameState = ref.watch(liveGameNotifierProvider);
  return gameState.currentGame?.winnerId;
});

// Is spectating provider (eliminated but still watching)
final isSpectatingProvider = Provider<bool>((ref) {
  final gameState = ref.watch(liveGameNotifierProvider);
  return gameState.isJoined && gameState.isEliminated && gameState.isGameLive;
});
