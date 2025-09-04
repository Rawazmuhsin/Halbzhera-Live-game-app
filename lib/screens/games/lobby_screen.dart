// Fixed lobby_screen.dart with proper countdown management
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'dart:async';
import '../../utils/constants.dart';
import '../../widgets/lobby/lobby_header.dart';
import '../../widgets/lobby/countdown_timer.dart';
import '../../widgets/lobby/status_message.dart';
import '../../widgets/lobby/users_list.dart';
import '../../models/scheduled_game_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/joined_user_provider.dart';
import 'question_screen.dart';
import '../../providers/live_game_provider.dart';
import '../../config/firebase_config.dart';

class LobbyScreen extends ConsumerStatefulWidget {
  final ScheduledGameModel game;
  final bool isPreviewMode;

  const LobbyScreen({
    super.key,
    required this.game,
    this.isPreviewMode = false,
  });

  @override
  ConsumerState<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends ConsumerState<LobbyScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  Timer? _countdownTimer;
  Timer? _gameTimeChecker;
  int _timeRemaining = 60;
  String _statusMessage = 'چاوەڕوانی یاریکەرانی تر بکە...';
  Color _statusColor = AppColors.primaryTeal;
  bool _isGameActive = false;

  // FIX: Store the actual game start time to calculate remaining time correctly
  DateTime? _gameStartedAt;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _determineGameState();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _animationController.forward();
  }

  void _determineGameState() {
    final now = DateTime.now();
    final scheduledTime = widget.game.scheduledTime;

    if (scheduledTime.isAfter(now)) {
      // Game hasn't started yet - preview mode
      _isGameActive = false;
      _statusMessage = 'یاری هێشتا دەست نەکردووە';
      _statusColor = AppColors.primaryTeal;

      // Start checking for game time
      _startGameTimeChecker();

      final timeUntilGame = scheduledTime.difference(now);
      _statusMessage =
          'یاری ${_formatTimeUntilStart(timeUntilGame)} دەست پێدەکات';
    } else {
      // FIX: Game time has passed - calculate actual remaining time
      _activateGameWithCorrectTime(scheduledTime);
    }
  }

  // FIX: New method to activate game with correct countdown
  void _activateGameWithCorrectTime(DateTime scheduledTime) {
    final now = DateTime.now();

    // Calculate how much time has passed since the scheduled time
    final timeSinceScheduled = now.difference(scheduledTime);

    // If more than 60 seconds have passed, the lobby period is over
    if (timeSinceScheduled.inSeconds >= 60) {
      // Lobby time has expired, redirect to game
      _timeRemaining = 0;
      _redirectToQuestionScreen();
      return;
    }

    // Calculate actual remaining time
    _gameStartedAt = scheduledTime;
    _timeRemaining = 60 - timeSinceScheduled.inSeconds;
    _isGameActive = true;

    // Start the countdown with the correct remaining time
    _startCountdown();
  }

  String _formatTimeUntilStart(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays} ڕۆژ دیکە';
    } else if (duration.inHours > 0) {
      return '${duration.inHours} کاتژمێر دیکە';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes} خولەک دیکە';
    } else {
      return 'ئێستا';
    }
  }

  void _startGameTimeChecker() {
    // Check every second for more accurate timing
    _gameTimeChecker = Timer.periodic(const Duration(seconds: 1), (timer) {
      final now = DateTime.now();
      final scheduledTime = widget.game.scheduledTime;

      if (!scheduledTime.isAfter(now) && !_isGameActive) {
        // Game time has arrived! Activate with correct time
        _gameTimeChecker?.cancel();

        setState(() {
          _activateGameWithCorrectTime(scheduledTime);
        });

        // Show notification that game has started
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎮 یاری دەست پێکرد! ١ خولەک بۆ ئامادەبوون'),
            backgroundColor: AppColors.primaryRed,
            duration: Duration(seconds: 3),
          ),
        );
      } else if (scheduledTime.isAfter(now)) {
        // Update preview message
        final timeUntilGame = scheduledTime.difference(now);
        setState(() {
          _statusMessage =
              'یاری ${_formatTimeUntilStart(timeUntilGame)} دەست پێدەکات';
        });
      }
    });
  }

  void _startCountdown() {
    // FIX: Cancel any existing timer to prevent duplicates
    _countdownTimer?.cancel();

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        // FIX: Calculate time based on actual game start time
        if (_gameStartedAt != null) {
          final now = DateTime.now();
          final elapsed = now.difference(_gameStartedAt!);
          _timeRemaining = 60 - elapsed.inSeconds;

          if (_timeRemaining < 0) {
            _timeRemaining = 0;
          }
        } else {
          _timeRemaining--;
        }

        _updateStatusMessage();
      });

      if (_timeRemaining <= 0) {
        _countdownTimer?.cancel();
        _redirectToQuestionScreen();
      }
    });
  }

  void _updateStatusMessage() {
    if (!_isGameActive) return;

    if (_timeRemaining > 45) {
      _statusMessage = '🎮 چاوەڕوانی یاریکەرانی تر بکە...';
      _statusColor = AppColors.primaryTeal;
    } else if (_timeRemaining > 30) {
      _statusMessage = '⚡ یاریکەرانی زیاتر دێن...';
      _statusColor = AppColors.primaryTeal;
    } else if (_timeRemaining > 15) {
      _statusMessage = '🔥 ئامادەبە! یاری نزیک دەبێتەوە';
      _statusColor = AppColors.accentYellow;
    } else if (_timeRemaining > 10) {
      _statusMessage = '🚀 یاری زوو دەست پێدەکات!';
      _statusColor = AppColors.accentYellow;
    } else if (_timeRemaining > 5) {
      _statusMessage = '⚠️ ئامادەبە! کەمتر لە ١٠ چرکە ماوە!';
      _statusColor = AppColors.error;
    } else if (_timeRemaining > 0) {
      _statusMessage = '🎯 یاری ئێستا دەست پێدەکات!';
      _statusColor = AppColors.error;
    }
  }

  Future<bool> _doesGameExist(String gameId) async {
    try {
      final gameDoc = await FirebaseConfig.getLiveGameDoc(gameId).get();
      return gameDoc.exists;
    } catch (e) {
      return false;
    }
  }

  Future<void> _createGameDocument(String gameId) async {
    try {
      await FirebaseConfig.getLiveGameDoc(
        gameId,
      ).set({'status': 'pending', 'createdAt': DateTime.now()});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to create game document: $e")),
      );
    }
  }

  Future<void> _redirectToQuestionScreen() async {
    final gameId = widget.game.id;
    try {
      // Check if the game document exists
      final gameExists = await _doesGameExist(gameId);
      if (!gameExists) {
        await _createGameDocument(gameId);
      }

      // Fetch all questions for the game
      final questions = await _fetchQuestions(gameId);

      // 1. Start the game (set status to live in Firestore)
      await ref
          .read(adminLiveGameNotifierProvider.notifier)
          .startLiveGame(gameId);

      // 2. Navigate to the QuestionScreen with questions
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder:
              (context) => QuestionScreen(gameId: gameId, questions: questions),
        ),
      );
    } catch (e) {
      // 3. Handle errors
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to start the game: $e")));
    }
  }

  void _leaveGame() async {
    // Show confirmation dialog
    final shouldLeave = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: AppColors.surface2,
            title: const Text('جێهێشتنی یاری'),
            content: const Text('دڵنیایت لە جێهێشتنی یاری؟'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('نەخێر'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: AppColors.error),
                child: const Text('بەڵێ'),
              ),
            ],
          ),
    );

    if (shouldLeave == true) {
      // TODO: Handle leaving game logic
      Navigator.pop(context);
    }
  }

  Future<List<Map<String, dynamic>>> _fetchQuestions(String gameId) async {
    try {
      final questionsSnapshot =
          await FirebaseConfig.firestore
              .collection('questions')
              .where('gameId', isEqualTo: gameId)
              .get();

      if (questionsSnapshot.docs.isEmpty) {
        return [];
      }

      return questionsSnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to fetch questions: $e")));
      return [];
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _countdownTimer?.cancel();
    _gameTimeChecker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: LobbyHeader(
        game: widget.game,
        onLeave: _leaveGame,
        isPreviewMode: widget.isPreviewMode,
      ),
      body: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppDimensions.paddingL),
                child: Column(
                  children: [
                    // Countdown Timer (only show if game is active)
                    if (_isGameActive) ...[
                      CountdownTimer(timeRemaining: _timeRemaining),
                      const SizedBox(height: AppDimensions.paddingXL),
                    ] else ...[
                      // Preview mode - show game info
                      _buildGamePreview(),
                      const SizedBox(height: AppDimensions.paddingXL),
                    ],

                    // Status Message
                    StatusMessage(message: _statusMessage, color: _statusColor),

                    const SizedBox(height: AppDimensions.paddingXL),

                    // Users List (real-time)
                    Consumer(
                      builder: (context, ref, _) {
                        final joinedUsersAsync = ref.watch(
                          joinedUsersProvider(widget.game.id),
                        );
                        return joinedUsersAsync.when(
                          data: (users) => UsersList(users: users),
                          loading:
                              () => const Center(
                                child: CircularProgressIndicator(),
                              ),
                          error:
                              (e, _) => Center(
                                child: Text(
                                  'هەڵەیەک لە بارکردنی یاریکەران: $e',
                                ),
                              ),
                        );
                      },
                    ),

                    const SizedBox(height: AppDimensions.paddingXL),

                    // Leaderboard Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _navigateToLeaderboard(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryTeal,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            vertical: AppDimensions.paddingM,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppDimensions.radiusL,
                            ),
                          ),
                        ),
                        icon: const Icon(Icons.emoji_events),
                        label: const Text(
                          'پێشەنگەکانی ئەم یارییە',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _navigateToLeaderboard(BuildContext context) {
    Navigator.of(
      context,
    ).pushNamed('/game-leaderboard', arguments: {'gameId': widget.game.id});
  }

  Widget _buildGamePreview() {
    final now = DateTime.now();
    final timeUntilGame = widget.game.scheduledTime.difference(now);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.paddingXXL),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.surface2.withOpacity(0.8),
            AppColors.surface1.withOpacity(0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusXXL),
        border: Border.all(color: AppColors.border1.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.schedule, size: 48, color: AppColors.primaryTeal),
          const SizedBox(height: AppDimensions.paddingL),
          const Text(
            'پێشبینینی لۆبی',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: AppColors.lightText,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppDimensions.paddingM),
          Text(
            timeUntilGame.inSeconds > 0
                ? 'یاری ${_formatTimeUntilStart(timeUntilGame)} دەست پێدەکات'
                : 'یاری ئامادەیە بۆ دەستپێکردن',
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.mediumText,
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
