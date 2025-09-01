// File: lib/screens/game/question_screen.dart
// Description: The main screen for displaying and interacting with live game questions.

// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:vector_math/vector_math_64.dart' as vector;

// Core App Providers & Models
import '../../models/question_model.dart';
import '../../providers/live_game_provider.dart';
import '../../providers/auth_provider.dart';
import '../../config/firebase_config.dart';
// import '../../services/database_service.dart';

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
  int _timeRemaining = 15; // Default time per question
  late AnimationController _timerAnimationController;
  int _currentQuestionIndex = 0;
  List<Map<String, dynamic>> _allQuestions = [];
  bool _isLoading = true;
  bool _isSpectator = false; // Indicates if user is eliminated
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
      duration: const Duration(seconds: 15), // Default duration
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
    if (_allQuestions.isEmpty || !mounted || _isSpectator) return;

    setState(() {
      _timeRemaining = 15; // Reset timer for each question
      _showResult = false;
      _selectedAnswer = null;
      _answerLocked = false;
    });

    _timer?.cancel();

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
              // Time's up without answering
              _checkAnswer(null);
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
      });
    }

    // Wait for 3 seconds to show the result
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;

      if (isCorrect) {
        _goToNextQuestion();
      }
      // If incorrect, user stays on current question as spectator
    });
  }

  void _goToNextQuestion() {
    if (_currentQuestionIndex < _allQuestions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
      _startQuestionTimer();
    } else {
      // End of questions
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('سەرجەم پرسیارەکان تەواو بوون!')),
      );
    }
  }

  void _selectChoice(String choiceAnswer) {
    if (_showResult || _answerLocked || _isSpectator) return;
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
              return Stack(
                children: [
                  Container(
                    width: constraints.maxWidth * (_timeRemaining / 15),
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
                (_showResult || _isSpectator)
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
    // Calculate actual percentages based on the user's answer
    final bool isCorrect = _selectedAnswer == _correctAnswer;

    // If the user answers correctly, show 100% correct, 0% wrong
    // If the user answers incorrectly, show 0% correct, 100% wrong
    final correctPercentage = isCorrect ? 100 : 0;
    final wrongPercentage = isCorrect ? 0 : 100;

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
