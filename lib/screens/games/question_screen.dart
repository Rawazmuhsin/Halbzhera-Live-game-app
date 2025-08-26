// File: lib/screens/game/question_screen.dart
// Description: The main screen for displaying and interacting with live game questions.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:vector_math/vector_math_64.dart' as vector;

// Core App Providers & Models
import '../../models/live_game_model.dart';
import '../../models/question_model.dart';
import '../../providers/live_game_provider.dart';
import '../../providers/auth_provider.dart';
// import '../../services/database_service.dart';

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
    Key? key,
    required this.gameId,
    required this.questions,
  }) : super(key: key);

  @override
  _QuestionScreenState createState() => _QuestionScreenState();
}

class _QuestionScreenState extends ConsumerState<QuestionScreen>
    with TickerProviderStateMixin {
  Timer? _timer;
  int _timeRemaining = 0;
  late AnimationController _timerAnimationController;
  late Animation<double> _pulseAnimation;
  int _currentQuestionIndex = 0;

  @override
  void initState() {
    super.initState();

    _timerAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15), // Default duration
    );

    final pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: pulseController, curve: Curves.easeInOut),
    );
  }

  void _selectChoice(String choiceAnswer) {
    // The notifier handles all the logic of submitting, checking, and elimination.
    ref.read(liveGameNotifierProvider.notifier).submitAnswer(choiceAnswer);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timerAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text("No Questions Available")),
        body: const Center(
          child: Text(
            "No questions were found for this game.",
            style: TextStyle(fontSize: 18),
          ),
        ),
      );
    }

    // Randomly pick a question
    final random = (widget.questions..shuffle()).first;

    return Scaffold(
      appBar: AppBar(title: const Text("Random Question")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              random['question'],
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ...List.generate(random['options'].length, (index) {
              return ElevatedButton(
                onPressed: () {},
                child: Text(random['options'][index]),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionCard(QuestionModel question, LiveGameState gameState) {
    const choiceLetters = ['أ', 'ب', 'ج', 'د'];
    final canAnswer = ref.watch(canAnswerQuestionProvider);
    final selectedAnswer =
        gameState
            .userAnswer
            ?.answers[gameState.currentQuestionNumber - 1]
            ?.answer;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1A1F36).withOpacity(0.8),
            const Color(0xFF151B2C).withOpacity(0.9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            question.question,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 40),
          ...List.generate(question.options.length, (index) {
            final optionText = question.options[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: _ChoiceOption(
                letter: choiceLetters[index],
                text: optionText,
                isSelected: selectedAnswer == optionText,
                isDisabled: !canAnswer,
                onTap: () => _selectChoice(optionText),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _ChoiceOption extends StatelessWidget {
  final String letter;
  final String text;
  final bool isSelected;
  final bool isDisabled;
  final VoidCallback onTap;

  const _ChoiceOption({
    Key? key,
    required this.letter,
    required this.text,
    required this.isSelected,
    required this.isDisabled,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: isDisabled && !isSelected ? 0.5 : 1.0,
      child: InkWell(
        onTap: isDisabled ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors:
                  isSelected
                      ? [
                        const Color(0xFF2DCCDB).withOpacity(0.2),
                        const Color(0xFF45E4B8).withOpacity(0.1),
                      ]
                      : [
                        Colors.white.withOpacity(0.08),
                        Colors.white.withOpacity(0.03),
                      ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color:
                  isSelected
                      ? const Color(0xFF2DCCDB)
                      : Colors.white.withOpacity(0.15),
              width: 2,
            ),
            boxShadow:
                isSelected
                    ? [
                      BoxShadow(
                        color: const Color(0xFF2DCCDB).withOpacity(0.3),
                        blurRadius: 10,
                      ),
                    ]
                    : [],
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFF2DCCDB), Color(0xFF45E4B8)],
                  ),
                ),
                child: Text(
                  letter,
                  style: const TextStyle(
                    color: Color(0xFF0B1120),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  text,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
