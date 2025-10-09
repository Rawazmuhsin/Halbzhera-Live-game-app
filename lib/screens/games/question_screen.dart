// File: lib/screens/game/question_screen.dart
// Description: The main screen for displaying and interacting with live game questions.

// ignore_for_file: deprecated_member_use, avoid_print

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:vector_math/vector_math_64.dart' as vector;

// Core App Providers & Models
import '../../models/question_model.dart';
import '../../providers/live_game_provider.dart';
import '../../providers/auth_provider.dart' hide databaseServiceProvider;
import '../../config/firebase_config.dart';
import '../../services/game_result_service.dart';
import '../../providers/database_provider.dart';
import '../../screens/games/results_screen.dart';

// Provider that fetches all questions from Firestore
final allQuestionsProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  try {
    final snapshot = await FirebaseConfig.questions.get();
    if (snapshot.docs.isEmpty) {
      return [];
    }
    return snapshot.docs
        .map((doc) => doc.data() as Map<String, dynamic>)
        .toList();
  } catch (e) {
    print('Error fetching questions: $e');
    return [];
  }
});

final questionProvider = FutureProvider.autoDispose
    .family<QuestionModel?, String>((ref, questionId) async {
      final dbService = ref.read(databaseServiceProvider);
      final data = await dbService.getQuestion(questionId);
      if (data == null) return null;
      return QuestionModel(
        id: data['id'] ?? '',
        quizId: data['quizId'] ?? '',
        question: data['question'] ?? '',
        type: QuestionType.values[data['type'] ?? 0],
        options: List<String>.from(data['options'] ?? []),
        correctAnswer: data['correctAnswer'] ?? '',
        explanation: data['explanation'],
        category: data['category'] ?? '',
        difficulty: QuestionDifficulty.values[data['difficulty'] ?? 0],
        points: data['points'] ?? 100,
        timeLimit: data['timeLimit'] ?? 15,
        order: data['order'] ?? 0,
        imageUrl: data['imageUrl'],
        isActive: data['isActive'] ?? true,
        createdAt:
            (data['createdAt'] is DateTime)
                ? data['createdAt']
                : (data['createdAt']?.toDate() ?? DateTime.now()),
        updatedAt:
            (data['updatedAt'] is DateTime)
                ? data['updatedAt']
                : (data['updatedAt']?.toDate() ?? DateTime.now()),
        metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
      );
    });

class QuestionScreen extends ConsumerStatefulWidget {
  final String gameId;
  final List<Map<String, dynamic>> questions;

  const QuestionScreen({
    super.key,
    required this.gameId,
    required this.questions,
  });

  @override
  _QuestionScreenState createState() => _QuestionScreenState();
}

class _QuestionScreenState extends ConsumerState<QuestionScreen>
    with TickerProviderStateMixin {
  Timer? _timer;
  int _timeRemaining = 15; // Will be set to question's actual time limit
  late AnimationController _timerAnimationController;
  int _currentQuestionIndex = 0;
  List<Map<String, dynamic>> _allQuestions = [];
  bool _isLoading = true;
  bool _isSpectator = false; // Indicates if user is eliminated
  bool _hasLost =
      false; // NEW: Boolean flag to track if user has lost/eliminated
  int? _eliminatedAtQuestion; // Track which question user was eliminated at
  String? _selectedAnswer;
  String? _correctAnswer;
  bool _showResult = false; // Shows result after answering
  bool _answerLocked = false; // Prevents multiple answers

  @override
  void initState() {
    super.initState();
    _initializeTimerAnimation();
    _loadAllQuestions();
  }

  void _initializeTimerAnimation() {
    _timerAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(
        seconds: 15,
      ), // Initial duration, will be updated per question
    );
  }

  void _loadAllQuestions() async {
    setState(() => _isLoading = true);
    try {
      // First try to use the questions passed from the lobby screen
      if (widget.questions.isNotEmpty) {
        setState(() {
          _allQuestions = widget.questions;
          _isLoading = false;
        });
        _startQuestionTimer();
        return;
      }

      // If no questions were passed, fetch all questions from Firestore
      final snapshot = await FirebaseConfig.questions.get();
      if (snapshot.docs.isEmpty) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _allQuestions =
            snapshot.docs
                .map((doc) => doc.data() as Map<String, dynamic>)
                .toList();
        _isLoading = false;
      });

      _startQuestionTimer();
    } catch (e) {
      print('Error loading questions: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _startQuestionTimer() {
    if (_allQuestions.isEmpty || !mounted) return;

    // If user has lost, they become spectator but continue to next questions
    if (_hasLost) {
      setState(() {
        _isSpectator = true;
      });
    }

    // Get current question's time limit
    final currentQuestion = _allQuestions[_currentQuestionIndex];
    final questionTimeLimit = currentQuestion['timeLimit'] as int? ?? 15;

    setState(() {
      _timeRemaining = questionTimeLimit; // Use question's actual time limit
      _showResult = false;
      _selectedAnswer = null;
      _answerLocked = false;
    });

    _timer?.cancel();

    // Update animation controller duration to match question time limit
    _timerAnimationController.dispose();
    _timerAnimationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: questionTimeLimit),
    );
    _timerAnimationController.forward();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        if (_timeRemaining > 0) {
          _timeRemaining--;
        } else {
          // Time's up
          timer.cancel();
          if (!_showResult) {
            if (_selectedAnswer == null) {
              // Time's up without answering - this counts as a wrong answer
              _checkAnswer(null);

              // Mark as spectator and lost because they didn't answer in time
              setState(() {
                _isSpectator = true;
                _hasLost = true;
                _eliminatedAtQuestion = _currentQuestionIndex;
              });

              // Eliminate player for not answering in time
              _eliminatePlayer();
            }
            // Handle timer end - show results and check answer
            _handleTimerEnd();
          }
        }
      });
    });
  }

  void _checkAnswer(String? answer) {
    if (_answerLocked) return;

    setState(() {
      _answerLocked = true;
      _selectedAnswer = answer;
      // Don't show the result immediately - will show when timer ends
      // _showResult = true;
    });

    // Don't cancel the timer - let it run to completion
    // _timer?.cancel();

    // Submit answer to the provider
    ref.read(liveGameNotifierProvider.notifier).submitAnswer(answer ?? "");
  }

  void _handleTimerEnd() {
    // Get correct answer
    final currentQuestion = _allQuestions[_currentQuestionIndex];
    _correctAnswer = currentQuestion['correctAnswer'];

    setState(() {
      _showResult = true;
    });

    // Check if answer is correct
    final isCorrect = _selectedAnswer == _correctAnswer;

    if (!isCorrect) {
      // User is eliminated
      setState(() {
        _isSpectator = true;
        _hasLost = true; // Set the loss flag
        _eliminatedAtQuestion =
            _currentQuestionIndex; // Remember which question
      });

      // Save elimination to Firestore
      _eliminatePlayer();
    }

    // Wait for 3 seconds to show the result
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;

      if (isCorrect) {
        _goToNextQuestion();
      } else {
        // If user lost, continue to next question as spectator
        if (_hasLost) {
          _goToNextQuestion();
        }
      }
    });
  }

  void _goToNextQuestion() {
    if (_currentQuestionIndex < _allQuestions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
      _startQuestionTimer();
    } else {
      // End of questions - User has completed all questions successfully
      _completeGameAsWinner();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('سەرجەم پرسیارەکان تەواو بوون!')),
      );
    }
  }

  void _completeGameAsWinner() {
    // Get user ID from auth provider
    final userId = ref.read(authStateProvider).value?.uid;
    if (userId == null) return;

    // Calculate score based on number of questions completed plus a bonus for winning
    // Each correct question = 10 points + 15 bonus points for winning
    final questionPoints = _allQuestions.length * 10;
    final winnerBonus = 15;
    final score = questionPoints + winnerBonus;

    // Save game result with user as winner
    ref
        .read(databaseServiceProvider)
        .saveGameResult(
          gameId: widget.gameId,
          userId: userId,
          score: score,
          isWinner: true,
          eliminatedAtQuestion: null, // Winner completed all questions
        );

    // Show celebration or navigate to results screen
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;

      // Navigate to results screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => ResultsScreen(gameId: widget.gameId),
        ),
      );
    });
  }

  void _eliminatePlayer() {
    // Get user ID from auth provider
    final userId = ref.read(authStateProvider).value?.uid;
    if (userId == null) return;

    // Calculate partial score based on questions answered correctly
    final score = _currentQuestionIndex * 10; // 10 points per question

    // Save game result with user as eliminated
    ref
        .read(databaseServiceProvider)
        .saveGameResult(
          gameId: widget.gameId,
          userId: userId,
          score: score,
          isWinner: false,
          eliminatedAtQuestion:
              _currentQuestionIndex, // Current question where they were eliminated
        );

    // Show message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'بەداخەوە دەرچووی لە یارییەکە. دەتوانی سەیری پێشبڕکێکە بکەی!',
        ),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _selectChoice(String choiceAnswer) {
    if (_showResult || _answerLocked || _isSpectator || _hasLost) return;
    _checkAnswer(choiceAnswer);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timerAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildGradientScaffold(
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFF2DCCDB)),
        ),
        appBar: AppBar(title: const Text("بارکردنی پرسیارەکان...")),
      );
    }

    if (_allQuestions.isEmpty) {
      return _buildGradientScaffold(
        body: const Center(
          child: Text(
            "هیچ پرسیارێک نەدۆزرایەوە لە داتابەیس.",
            style: TextStyle(fontSize: 18, color: Colors.white),
          ),
        ),
        appBar: AppBar(title: const Text("هیچ پرسیارێک نەدۆزرایەوە")),
      );
    }

    final currentQuestion = _allQuestions[_currentQuestionIndex];
    _correctAnswer = currentQuestion['correctAnswer'];
    final String gameTitle =
        "مێژووی کوردستان"; // Can be dynamic based on game category

    // Create options with letters
    final options = currentQuestion['options'] as List<dynamic>? ?? [];
    final letters = ['أ', 'ب', 'ج', 'د', 'ه', 'و', 'ز', 'ح'];
    Map<String, String> optionsWithLetters = {};
    List<Map<String, String>> choicesWithLetters = [];

    for (var i = 0; i < options.length; i++) {
      if (i < letters.length) {
        final letter = letters[i];
        final option = options[i].toString();
        optionsWithLetters[letter] = option;
        choicesWithLetters.add({'letter': letter, 'text': option});
      }
    }

    return _buildGradientScaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1A1F36).withOpacity(0.95),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Text(
                          gameTitle,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF2DCCDB), Color(0xFF45E4B8)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _isSpectator
                                ? "پرسیار ${_currentQuestionIndex + 1} لە ${_allQuestions.length} (تەماشاکەر)"
                                : "پرسیار ${_currentQuestionIndex + 1} لە ${_allQuestions.length}",
                            style: const TextStyle(
                              color: Color(0xFF0B1120),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder:
                            (context) => AlertDialog(
                              backgroundColor: const Color(0xFF1A1F36),
                              title: const Text(
                                "دڵنیایت لە جێهێشتنی یاری؟",
                                style: TextStyle(color: Colors.white),
                                textAlign: TextAlign.center,
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text(
                                    "نا",
                                    style: TextStyle(color: Color(0xFF2DCCDB)),
                                  ),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFEF4444),
                                  ),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                    Navigator.of(
                                      context,
                                    ).pop(); // Go back to previous screen
                                  },
                                  child: const Text(
                                    "بەڵێ",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "جێهێشتنی یاری",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 40),

              // Timer Section
              _buildTimerSection(),

              // Status Message
              _buildStatusMessage(),

              // Question Section
              Container(
                margin: const EdgeInsets.symmetric(vertical: 24),
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF1A1F36).withOpacity(0.8),
                      const Color(0xFF151B2C).withOpacity(0.9),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.15),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Question Text
                    Text(
                      currentQuestion['question'] ?? "پرسیارێک نییە",
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.right,
                    ),

                    const SizedBox(height: 40),

                    // Choices Grid
                    _buildChoicesGrid(choicesWithLetters),

                    // Results Section
                    if (_showResult) _buildResultsSection(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGradientScaffold({
    required Widget body,
    PreferredSizeWidget? appBar,
  }) {
    return Scaffold(
      appBar: appBar,
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0B1120),
              Color(0xFF1A1F36),
              Color(0xFF2A1B3D),
              Color(0xFF151B2C),
            ],
            stops: [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Animated background with radial gradients
            Positioned.fill(
              child: CustomPaint(painter: RadialGradientPainter()),
            ),
            // Main content
            SafeArea(child: body),
            // Spectator Overlay
            if (_isSpectator && !_showResult)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.05),
                  child: const Center(
                    child: Text(
                      "تۆ دەرچوویت لە پێشبڕکێکە و ئێستا تەنها دەتوانیت سەیر بکەیت",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            // Home Button Overlay - Shows when user has lost (only on elimination question)
            if (_hasLost &&
                _showResult &&
                _eliminatedAtQuestion == _currentQuestionIndex)
              Positioned(
                top: 100,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1A1F36), Color(0xFF2A1B3D)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFEF4444).withOpacity(0.5),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.cancel_outlined,
                          color: Color(0xFFEF4444),
                          size: 64,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "بەداخەوە دەرچوویت!",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "دەتوانیت گەڕێیتەوە سەرەکی یان سەیری یارییەکە بکەیت",
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF9CA3AF),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () {
                            // Navigate to home page
                            Navigator.of(
                              context,
                            ).popUntil((route) => route.isFirst);
                          },
                          icon: const Icon(Icons.home, size: 24),
                          label: const Text(
                            "گەڕانەوە بۆ سەرەکی",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2DCCDB),
                            foregroundColor: const Color(0xFF0B1120),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () {
                            // Dismiss the overlay - continue as spectator
                            setState(() {
                              // Just hide the overlay, user continues as spectator
                            });
                          },
                          child: const Text(
                            "درێژە پێبدە وەک تەماشاکەر",
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF9CA3AF),
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimerSection() {
    String timerClass = 'normal';
    if (_timeRemaining <= 3) {
      timerClass = 'danger';
    } else if (_timeRemaining <= 5) {
      timerClass = 'warning';
    }

    return Column(
      children: [
        // Question Counter at the top
        Container(
          alignment: Alignment.centerRight,
          margin: const EdgeInsets.only(bottom: 16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6366F1).withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.question_answer_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  "${_currentQuestionIndex + 1}/${_allQuestions.length}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Timer Container
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF0B1120).withOpacity(0.8),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color:
                  timerClass == 'danger'
                      ? const Color(0xFFEF4444).withOpacity(0.8)
                      : timerClass == 'warning'
                      ? const Color(0xFFF59E0B).withOpacity(0.6)
                      : const Color(0xFFE84855).withOpacity(0.4),
              width: 2,
            ),
            boxShadow:
                timerClass == 'danger'
                    ? [
                      BoxShadow(
                        color: const Color(0xFFEF4444).withOpacity(0.3),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    ]
                    : [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "$_timeRemaining",
                style: TextStyle(
                  fontFamily: 'Courier New',
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  color:
                      timerClass == 'danger'
                          ? const Color(0xFFEF4444)
                          : timerClass == 'warning'
                          ? const Color(0xFFF59E0B)
                          : const Color(0xFFE84855),
                  shadows: [
                    Shadow(
                      color:
                          timerClass == 'danger'
                              ? const Color(0xFFEF4444).withOpacity(0.6)
                              : timerClass == 'warning'
                              ? const Color(0xFFF59E0B).withOpacity(0.3)
                              : const Color(0xFFE84855).withOpacity(0.3),
                      blurRadius: 12,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                "چرکە",
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF9CA3AF),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Timer Bar
        Container(
          width: 200,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(2),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final currentQuestion = _allQuestions[_currentQuestionIndex];
              final questionTimeLimit =
                  currentQuestion['timeLimit'] as int? ?? 15;

              return Stack(
                children: [
                  Container(
                    width:
                        constraints.maxWidth *
                        (_timeRemaining / questionTimeLimit),
                    height: 4,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFE84855), Color(0xFF2DCCDB)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.all(Radius.circular(2)),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatusMessage() {
    String messageText = "وەڵامەکەت هەڵبژێرە";
    Color messageColor = const Color(0xFF2DCCDB);
    Color backgroundColor = const Color(0xFF2DCCDB).withOpacity(0.1);
    Color borderColor = const Color(0xFF2DCCDB).withOpacity(0.3);

    if (_showResult) {
      if (_selectedAnswer == _correctAnswer) {
        messageText = "✓ وەڵامەکەت ڕاستە! چاوەڕێی پرسیاری داهاتوو بکە...";
        messageColor = const Color(0xFF22C55E);
        backgroundColor = const Color(0xFF22C55E).withOpacity(0.1);
        borderColor = const Color(0xFF22C55E).withOpacity(0.3);
      } else if (_selectedAnswer != null) {
        messageText = "✗ وەڵامەکەت هەڵەیە! تۆ بوویت بە بینەر";
        messageColor = const Color(0xFFEF4444);
        backgroundColor = const Color(0xFFEF4444).withOpacity(0.1);
        borderColor = const Color(0xFFEF4444).withOpacity(0.3);
      } else {
        messageText = "✗ کات تەواو بوو! تۆ بوویت بە بینەر";
        messageColor = const Color(0xFFF59E0B);
        backgroundColor = const Color(0xFFF59E0B).withOpacity(0.1);
        borderColor = const Color(0xFFF59E0B).withOpacity(0.3);
      }
    } else if (_timeRemaining == 0) {
      messageText = "کات تەواو بوو! پیشاندانی ئەنجامەکان...";
      messageColor = const Color(0xFFF59E0B);
      backgroundColor = const Color(0xFFF59E0B).withOpacity(0.1);
      borderColor = const Color(0xFFF59E0B).withOpacity(0.3);
    } else if (_hasLost) {
      messageText =
          "تۆ دەرچوویت - دەتوانیت سەیری پرسیارەکان بکەیت یان بگەڕێیتەوە سەرەکی";
      messageColor = const Color(0xFFF59E0B);
      backgroundColor = const Color(0xFFF59E0B).withOpacity(0.1);
      borderColor = const Color(0xFFF59E0B).withOpacity(0.3);
    } else if (_isSpectator) {
      messageText = "تۆ تەنها تەماشاکەریت";
      messageColor = const Color(0xFFF59E0B);
      backgroundColor = const Color(0xFFF59E0B).withOpacity(0.1);
      borderColor = const Color(0xFFF59E0B).withOpacity(0.3);
    } else if (_selectedAnswer != null) {
      messageText = "چاوەڕوانی کۆتایی کات بکە...";
    }

    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      width: double.infinity,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        messageText,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: messageColor,
        ),
      ),
    );
  }

  Widget _buildChoicesGrid(List<Map<String, String>> choices) {
    if (choices.isEmpty) {
      return const Text(
        "هیچ بژاردەیەک بەردەست نییە بۆ ئەم پرسیارە",
        style: TextStyle(fontStyle: FontStyle.italic, color: Colors.white),
        textAlign: TextAlign.center,
      );
    }

    // Create a list view instead of a grid to better handle variable text lengths
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: choices.length,
      itemBuilder: (context, index) {
        final choice = choices[index];
        final letter = choice['letter'] ?? '';
        final text = choice['text'] ?? '';
        final isSelected = _selectedAnswer == text;
        final isCorrect = _showResult && text == _correctAnswer;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: GestureDetector(
            onTap:
                (_showResult || _isSpectator || _hasLost)
                    ? null
                    : () => _selectChoice(text),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    if (_showResult && isCorrect)
                      const Color(0xFF22C55E).withOpacity(0.2)
                    else if (_showResult && isSelected)
                      const Color(0xFFEF4444).withOpacity(0.2)
                    else if (isSelected)
                      const Color(0xFF2DCCDB).withOpacity(0.2)
                    else
                      Colors.white.withOpacity(0.08),

                    if (_showResult && isCorrect)
                      const Color(0xFF22C55E).withOpacity(0.1)
                    else if (_showResult && isSelected)
                      const Color(0xFFEF4444).withOpacity(0.1)
                    else if (isSelected)
                      const Color(0xFF2DCCDB).withOpacity(0.1)
                    else
                      Colors.white.withOpacity(0.03),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color:
                      _showResult
                          ? isCorrect
                              ? const Color(0xFF22C55E).withOpacity(0.8)
                              : isSelected
                              ? const Color(0xFFEF4444).withOpacity(0.8)
                              : Colors.white.withOpacity(0.15)
                          : isSelected
                          ? const Color(0xFF2DCCDB).withOpacity(0.5)
                          : Colors.white.withOpacity(0.15),
                  width: isSelected || (_showResult && isCorrect) ? 2 : 1,
                ),
                boxShadow:
                    isSelected || (_showResult && isCorrect)
                        ? [
                          BoxShadow(
                            color:
                                isCorrect
                                    ? const Color(0xFF22C55E).withOpacity(0.3)
                                    : isSelected
                                    ? const Color(0xFF2DCCDB).withOpacity(0.3)
                                    : Colors.transparent,
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ]
                        : null,
              ),
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
              child: Row(
                children: [
                  // Choice Letter (on the left)
                  Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors:
                            _showResult && isCorrect
                                ? [
                                  const Color(0xFF22C55E),
                                  const Color(0xFF16A34A),
                                ]
                                : _showResult && isSelected
                                ? [
                                  const Color(0xFFEF4444),
                                  const Color(0xFFDC2626),
                                ]
                                : [
                                  const Color(0xFF2DCCDB),
                                  const Color(0xFF45E4B8),
                                ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      letter,
                      style: TextStyle(
                        color:
                            _showResult && (isCorrect || isSelected)
                                ? Colors.white
                                : const Color(0xFF0B1120),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  // Choice Text (on the right)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 12, left: 44),
                      child: Text(
                        text,
                        overflow: TextOverflow.visible,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w500,
                          color: Colors.white,
                          height: 1.4, // Add line height for better readability
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ),

                  // Check/X icon when showing result
                  if (_showResult)
                    Icon(
                      isCorrect
                          ? Icons.check_circle
                          : isSelected
                          ? Icons.cancel
                          : Icons.circle_outlined,
                      color:
                          isCorrect
                              ? const Color(0xFF22C55E)
                              : isSelected
                              ? const Color(0xFFEF4444)
                              : Colors.white.withOpacity(0.6),
                      size: 24,
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildResultsSection() {
    // Watch the live leaderboard to get real-time statistics
    final leaderboardAsync = ref.watch(liveLeaderboardProvider(widget.gameId));

    return leaderboardAsync.when(
      data: (leaderboard) {
        // Filter only active (non-eliminated) players
        final activePlayers =
            leaderboard.where((p) => !p.isEliminated).toList();

        if (activePlayers.isEmpty) {
          // If no active players, show just this user's result
          final bool isCorrect = _selectedAnswer == _correctAnswer;
          final correctPercentage = isCorrect ? 100 : 0;
          final wrongPercentage = isCorrect ? 0 : 100;

          return _buildResultsBars(correctPercentage, wrongPercentage);
        }

        // Count how many active players answered correctly for THIS question
        int correctCount = 0;
        int totalAnswered = 0;

        for (final player in activePlayers) {
          final answer = player.getAnswerForQuestion(_currentQuestionIndex);
          if (answer != null) {
            totalAnswered++;
            if (answer['isCorrect'] == true) {
              correctCount++;
            }
          }
        }

        // Calculate percentages based on active players only
        final correctPercentage =
            totalAnswered > 0
                ? ((correctCount / totalAnswered) * 100).round()
                : 0;
        final wrongPercentage =
            totalAnswered > 0
                ? (((totalAnswered - correctCount) / totalAnswered) * 100)
                    .round()
                : 0;

        return _buildResultsBars(correctPercentage, wrongPercentage);
      },
      loading: () {
        // While loading, show user's own result
        final bool isCorrect = _selectedAnswer == _correctAnswer;
        final correctPercentage = isCorrect ? 100 : 0;
        final wrongPercentage = isCorrect ? 0 : 100;

        return _buildResultsBars(correctPercentage, wrongPercentage);
      },
      error: (_, __) {
        // On error, show user's own result
        final bool isCorrect = _selectedAnswer == _correctAnswer;
        final correctPercentage = isCorrect ? 100 : 0;
        final wrongPercentage = isCorrect ? 0 : 100;

        return _buildResultsBars(correctPercentage, wrongPercentage);
      },
    );
  }

  Widget _buildResultsBars(int correctPercentage, int wrongPercentage) {
    return Container(
      margin: const EdgeInsets.only(top: 40),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F36).withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
      ),
      child: Column(
        children: [
          const Text(
            "ئەنجامەکان",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle, color: Color(0xFF22C55E)),
                        SizedBox(width: 8),
                        Text(
                          "وەڵامی ڕاست",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF22C55E),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return Stack(
                            children: [
                              Container(
                                width:
                                    constraints.maxWidth *
                                    (correctPercentage / 100),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF22C55E),
                                      Color(0xFF16A34A),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "$correctPercentage%",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF22C55E),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 20),

              Expanded(
                child: Column(
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.cancel, color: Color(0xFFEF4444)),
                        SizedBox(width: 8),
                        Text(
                          "وەڵامی هەڵە",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFEF4444),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return Stack(
                            children: [
                              Container(
                                width:
                                    constraints.maxWidth *
                                    (wrongPercentage / 100),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFEF4444),
                                      Color(0xFFDC2626),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "$wrongPercentage%",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFEF4444),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Custom painter for the radial gradients in the background
class RadialGradientPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint();

    // First gradient - Red/Pink
    paint.shader = RadialGradient(
      colors: [const Color(0xFFE84855).withOpacity(0.05), Colors.transparent],
      radius: 0.5,
    ).createShader(
      Rect.fromCircle(
        center: Offset(size.width * 0.2, size.height * 0.5),
        radius: size.width * 0.5,
      ),
    );
    canvas.drawCircle(
      Offset(size.width * 0.2, size.height * 0.5),
      size.width * 0.5,
      paint,
    );

    // Second gradient - Cyan
    paint.shader = RadialGradient(
      colors: [const Color(0xFF2DCCDB).withOpacity(0.05), Colors.transparent],
      radius: 0.5,
    ).createShader(
      Rect.fromCircle(
        center: Offset(size.width * 0.8, size.height * 0.2),
        radius: size.width * 0.5,
      ),
    );
    canvas.drawCircle(
      Offset(size.width * 0.8, size.height * 0.2),
      size.width * 0.5,
      paint,
    );

    // Third gradient - Green
    paint.shader = RadialGradient(
      colors: [const Color(0xFF45E4B8).withOpacity(0.03), Colors.transparent],
      radius: 0.5,
    ).createShader(
      Rect.fromCircle(
        center: Offset(size.width * 0.4, size.height * 0.8),
        radius: size.width * 0.5,
      ),
    );
    canvas.drawCircle(
      Offset(size.width * 0.4, size.height * 0.8),
      size.width * 0.5,
      paint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
