// File: lib/providers/quiz_provider.dart
// Description: Updated Quiz state management with live game integration

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/category_model.dart';
import '../services/database_service.dart';
import 'auth_provider.dart';

// ============================================================================
// CATEGORY PROVIDERS (Replace old quiz providers)
// ============================================================================

// Get categories (replaces quiz categories)
final categoriesProvider = FutureProvider<List<CategoryModel>>((ref) async {
  final databaseService = ref.read(databaseServiceProvider);
  final categoriesData = await databaseService.getCategories();

  return categoriesData
      .map(
        (data) => CategoryModel(
          id: data['id'],
          name: data['name'] ?? '',
          nameEn: data['nameEn'] ?? '',
          description: data['description'] ?? '',
          icon: data['icon'] ?? 'category',
          color: data['color'] ?? '#FF6B6B',
          difficulty: data['difficulty'] ?? 'medium',
          isActive: data['isActive'] ?? true,
          totalQuestions: data['totalQuestions'] ?? 0,
          totalPlays: data['totalPlays'] ?? 0,
          averageRating: (data['averageRating'] ?? 0.0).toDouble(),
          totalRatings: data['totalRatings'] ?? 0,
          createdAt: data['createdAt']?.toDate() ?? DateTime.now(),
          updatedAt: data['updatedAt']?.toDate() ?? DateTime.now(),
          createdBy: data['createdBy'] ?? '',
        ),
      )
      .toList();
});

// Get category by ID
final categoryProvider = FutureProvider.family<CategoryModel?, String>((
  ref,
  categoryId,
) async {
  final databaseService = ref.read(databaseServiceProvider);
  final categoryData = await databaseService.getCategory(categoryId);

  if (categoryData == null) return null;

  return CategoryModel(
    id: categoryData['id'],
    name: categoryData['name'] ?? '',
    nameEn: categoryData['nameEn'] ?? '',
    description: categoryData['description'] ?? '',
    icon: categoryData['icon'] ?? 'category',
    color: categoryData['color'] ?? '#FF6B6B',
    difficulty: categoryData['difficulty'] ?? 'medium',
    isActive: categoryData['isActive'] ?? true,
    totalQuestions: categoryData['totalQuestions'] ?? 0,
    totalPlays: categoryData['totalPlays'] ?? 0,
    averageRating: (categoryData['averageRating'] ?? 0.0).toDouble(),
    totalRatings: categoryData['totalRatings'] ?? 0,
    createdAt: categoryData['createdAt']?.toDate() ?? DateTime.now(),
    updatedAt: categoryData['updatedAt']?.toDate() ?? DateTime.now(),
    createdBy: categoryData['createdBy'] ?? '',
  );
});

// Get questions by category (returns raw data)
final questionsByCategoryProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((
      ref,
      categoryId,
    ) async {
      final databaseService = ref.read(databaseServiceProvider);
      return databaseService.getQuestionsByCategory(categoryId);
    });

// Get question by ID
final questionProvider = FutureProvider.family<Map<String, dynamic>?, String>((
  ref,
  questionId,
) async {
  final databaseService = ref.read(databaseServiceProvider);
  return databaseService.getQuestion(questionId);
});

// ============================================================================
// PRACTICE GAME STATE (For offline practice)
// ============================================================================

class PracticeGameState {
  final CategoryModel? category;
  final List<Map<String, dynamic>> questions;
  final int currentQuestionIndex;
  final Map<int, String> userAnswers;
  final Map<int, bool> answersCorrectness;
  final Map<int, Duration> answerTimes;
  final int totalScore;
  final bool isGameActive;
  final bool isGameCompleted;
  final DateTime? gameStartTime;
  final DateTime? gameEndTime;

  const PracticeGameState({
    this.category,
    this.questions = const [],
    this.currentQuestionIndex = 0,
    this.userAnswers = const {},
    this.answersCorrectness = const {},
    this.answerTimes = const {},
    this.totalScore = 0,
    this.isGameActive = false,
    this.isGameCompleted = false,
    this.gameStartTime,
    this.gameEndTime,
  });

  PracticeGameState copyWith({
    CategoryModel? category,
    List<Map<String, dynamic>>? questions,
    int? currentQuestionIndex,
    Map<int, String>? userAnswers,
    Map<int, bool>? answersCorrectness,
    Map<int, Duration>? answerTimes,
    int? totalScore,
    bool? isGameActive,
    bool? isGameCompleted,
    DateTime? gameStartTime,
    DateTime? gameEndTime,
  }) {
    return PracticeGameState(
      category: category ?? this.category,
      questions: questions ?? this.questions,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      userAnswers: userAnswers ?? this.userAnswers,
      answersCorrectness: answersCorrectness ?? this.answersCorrectness,
      answerTimes: answerTimes ?? this.answerTimes,
      totalScore: totalScore ?? this.totalScore,
      isGameActive: isGameActive ?? this.isGameActive,
      isGameCompleted: isGameCompleted ?? this.isGameCompleted,
      gameStartTime: gameStartTime ?? this.gameStartTime,
      gameEndTime: gameEndTime ?? this.gameEndTime,
    );
  }

  // Get current question
  Map<String, dynamic>? get currentQuestion {
    if (currentQuestionIndex < questions.length) {
      return questions[currentQuestionIndex];
    }
    return null;
  }

  // Get total correct answers
  int get totalCorrectAnswers {
    return answersCorrectness.values.where((isCorrect) => isCorrect).length;
  }

  // Get accuracy percentage
  double get accuracy {
    if (userAnswers.isEmpty) return 0.0;
    return (totalCorrectAnswers / userAnswers.length) * 100;
  }

  // Get total game time
  Duration get totalGameTime {
    if (gameStartTime != null && gameEndTime != null) {
      return gameEndTime!.difference(gameStartTime!);
    }
    return Duration.zero;
  }

  // Check if there's a next question
  bool get hasNextQuestion {
    return currentQuestionIndex < questions.length - 1;
  }

  // Check if quiz is completed
  bool get isPracticeCompleted {
    return currentQuestionIndex >= questions.length;
  }

  // Get progress percentage
  double get progress {
    if (questions.isEmpty) return 0.0;
    return (currentQuestionIndex + 1) / questions.length;
  }
}

// ============================================================================
// PRACTICE GAME NOTIFIER
// ============================================================================

class PracticeGameNotifier extends StateNotifier<PracticeGameState> {
  final DatabaseService _databaseService;
  final Ref _ref;

  PracticeGameNotifier(this._databaseService, this._ref)
    : super(const PracticeGameState());

  // Initialize practice game with category
  Future<void> initializePracticeGame(String categoryId) async {
    try {
      // Get category data
      final categoryData = await _databaseService.getCategory(categoryId);
      if (categoryData == null) {
        throw Exception('Category not found');
      }

      final category = CategoryModel(
        id: categoryData['id'],
        name: categoryData['name'] ?? '',
        nameEn: categoryData['nameEn'] ?? '',
        description: categoryData['description'] ?? '',
        icon: categoryData['icon'] ?? 'category',
        color: categoryData['color'] ?? '#FF6B6B',
        difficulty: categoryData['difficulty'] ?? 'medium',
        isActive: categoryData['isActive'] ?? true,
        totalQuestions: categoryData['totalQuestions'] ?? 0,
        totalPlays: categoryData['totalPlays'] ?? 0,
        averageRating: (categoryData['averageRating'] ?? 0.0).toDouble(),
        totalRatings: categoryData['totalRatings'] ?? 0,
        createdAt: categoryData['createdAt']?.toDate() ?? DateTime.now(),
        updatedAt: categoryData['updatedAt']?.toDate() ?? DateTime.now(),
        createdBy: categoryData['createdBy'] ?? '',
      );

      // Get questions for category
      final questions = await _databaseService.getQuestionsByCategory(
        categoryId,
      );
      if (questions.isEmpty) {
        throw Exception('No questions found for this category');
      }

      // Shuffle questions for variety and take up to 15
      questions.shuffle();
      final practiceQuestions = questions.take(15).toList();

      state = state.copyWith(
        category: category,
        questions: practiceQuestions,
        currentQuestionIndex: 0,
        userAnswers: {},
        answersCorrectness: {},
        answerTimes: {},
        totalScore: 0,
        isGameActive: false,
        isGameCompleted: false,
        gameStartTime: null,
        gameEndTime: null,
      );
    } catch (e) {
      throw Exception('Failed to initialize practice game: $e');
    }
  }

  // Start practice game
  void startGame() {
    state = state.copyWith(isGameActive: true, gameStartTime: DateTime.now());
  }

  // Answer current question
  void answerQuestion(String answer, Duration timeTaken) {
    final currentQuestion = state.currentQuestion;
    if (currentQuestion == null) return;

    final correctAnswer = currentQuestion['correctAnswer'] as String? ?? '';
    final isCorrect =
        answer.toLowerCase().trim() == correctAnswer.toLowerCase().trim();

    // Calculate points with time bonus
    int points = 0;
    if (isCorrect) {
      points = currentQuestion['points'] as int? ?? 100;

      // Time bonus (similar to live game logic)
      final maxTime = 15; // Default time limit
      final timeRatio = timeTaken.inSeconds / maxTime;

      if (timeRatio <= 0.3) {
        points = (points * 1.5).round(); // Very fast - 50% bonus
      } else if (timeRatio <= 0.5) {
        points = (points * 1.25).round(); // Fast - 25% bonus
      } else if (timeRatio <= 0.8) {
        // Normal speed - full points
      } else {
        points = (points * 0.8).round(); // Slow - reduced points
      }
    }

    final newUserAnswers = Map<int, String>.from(state.userAnswers);
    newUserAnswers[state.currentQuestionIndex] = answer;

    final newAnswersCorrectness = Map<int, bool>.from(state.answersCorrectness);
    newAnswersCorrectness[state.currentQuestionIndex] = isCorrect;

    final newAnswerTimes = Map<int, Duration>.from(state.answerTimes);
    newAnswerTimes[state.currentQuestionIndex] = timeTaken;

    state = state.copyWith(
      userAnswers: newUserAnswers,
      answersCorrectness: newAnswersCorrectness,
      answerTimes: newAnswerTimes,
      totalScore: state.totalScore + points,
    );
  }

  // Move to next question
  void nextQuestion() {
    if (state.hasNextQuestion) {
      state = state.copyWith(
        currentQuestionIndex: state.currentQuestionIndex + 1,
      );
    } else {
      // Game completed
      completeGame();
    }
  }

  // Complete the game
  void completeGame() {
    state = state.copyWith(
      isGameActive: false,
      isGameCompleted: true,
      gameEndTime: DateTime.now(),
    );

    // Update user score in database
    _updateUserScore();
  }

  // Update user score in database
  Future<void> _updateUserScore() async {
    try {
      final authNotifier = _ref.read(authNotifierProvider.notifier);
      await authNotifier.updateUserScore(state.totalScore);

      // Update global leaderboard
      final currentUser = _ref.read(currentUserProvider);
      if (currentUser != null) {
        await _databaseService.updateGlobalLeaderboard(
          currentUser.uid,
          state.totalScore,
        );
      }
    } catch (e) {
      print('Error updating user score: $e');
    }
  }

  // Reset game
  void resetGame() {
    state = const PracticeGameState();
  }

  // Pause game
  void pauseGame() {
    state = state.copyWith(isGameActive: false);
  }

  // Resume game
  void resumeGame() {
    state = state.copyWith(isGameActive: true);
  }

  // Skip question
  void skipQuestion() {
    answerQuestion('', Duration.zero); // Empty answer with no time
    nextQuestion();
  }

  // Get question result
  Map<String, dynamic> getQuestionResult(int questionIndex) {
    final question = state.questions[questionIndex];
    final userAnswer = state.userAnswers[questionIndex] ?? '';
    final isCorrect = state.answersCorrectness[questionIndex] ?? false;
    final timeTaken = state.answerTimes[questionIndex] ?? Duration.zero;
    final correctAnswer = question['correctAnswer'] as String? ?? '';

    return {
      'question': question,
      'userAnswer': userAnswer,
      'correctAnswer': correctAnswer,
      'isCorrect': isCorrect,
      'timeTaken': timeTaken,
      'points': isCorrect ? (question['points'] as int? ?? 100) : 0,
    };
  }

  // Get game summary
  Map<String, dynamic> getGameSummary() {
    return {
      'category': state.category,
      'totalQuestions': state.questions.length,
      'correctAnswers': state.totalCorrectAnswers,
      'totalScore': state.totalScore,
      'accuracy': state.accuracy,
      'totalTime': state.totalGameTime,
      'averageTimePerQuestion':
          state.userAnswers.isNotEmpty
              ? Duration(
                milliseconds:
                    state.totalGameTime.inMilliseconds ~/
                    state.userAnswers.length,
              )
              : Duration.zero,
    };
  }
}

// ============================================================================
// ADMIN CATEGORY NOTIFIER
// ============================================================================

class AdminCategoryNotifier extends StateNotifier<AsyncValue<void>> {
  final DatabaseService _databaseService;

  AdminCategoryNotifier(this._databaseService)
    : super(const AsyncValue.data(null));

  // Create category
  Future<String> createCategory({
    required String name,
    required String nameEn,
    required String description,
    required String icon,
    required String color,
    required String difficulty,
  }) async {
    state = const AsyncValue.loading();

    try {
      // Import FirebaseAuth at the top and use it here
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('Admin not authenticated');
      }

      final categoryData = {
        'name': name,
        'nameEn': nameEn,
        'description': description,
        'icon': icon,
        'color': color,
        'difficulty': difficulty,
        'isActive': true,
        'totalQuestions': 0,
        'totalPlays': 0,
        'averageRating': 0.0,
        'totalRatings': 0,
        'createdBy': currentUser.uid,
      };

      final categoryId = await _databaseService.createCategory(categoryData);

      state = const AsyncValue.data(null);
      return categoryId;
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      rethrow;
    }
  }

  // Update category
  Future<void> updateCategory(
    String categoryId,
    Map<String, dynamic> updates,
  ) async {
    state = const AsyncValue.loading();

    try {
      await _databaseService.updateCategory(categoryId, updates);
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  // Create question
  Future<String> createQuestion({
    required String categoryId,
    required String question,
    required String questionEn,
    required List<String> options,
    required String correctAnswer,
    required String explanation,
    required String difficulty,
    required int points,
    required int timeLimit,
    required int order,
  }) async {
    try {
      // Import FirebaseAuth at the top and use it here
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('Admin not authenticated');
      }

      final questionData = {
        'categoryId': categoryId,
        'question': question,
        'questionEn': questionEn,
        'type': 'multiple_choice',
        'options': options,
        'correctAnswer': correctAnswer,
        'explanation': explanation,
        'difficulty': difficulty,
        'points': points,
        'timeLimit': timeLimit,
        'order': order,
        'isActive': true,
        'createdBy': currentUser.uid,
      };

      return await _databaseService.createQuestion(questionData);
    } catch (e) {
      rethrow;
    }
  }

  // Bulk create questions
  Future<List<String>> bulkCreateQuestions(
    List<Map<String, dynamic>> questionsData,
  ) async {
    state = const AsyncValue.loading();

    try {
      final questionIds = await _databaseService.bulkCreateQuestions(
        questionsData,
      );
      state = const AsyncValue.data(null);
      return questionIds;
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      rethrow;
    }
  }
}

// ============================================================================
// PROVIDER INSTANCES
// ============================================================================

// Practice game notifier provider
final practiceGameProvider =
    StateNotifierProvider<PracticeGameNotifier, PracticeGameState>((ref) {
      final databaseService = ref.read(databaseServiceProvider);
      return PracticeGameNotifier(databaseService, ref);
    });

// Admin category notifier provider
final adminCategoryNotifierProvider =
    StateNotifierProvider<AdminCategoryNotifier, AsyncValue<void>>((ref) {
      final databaseService = ref.read(databaseServiceProvider);
      return AdminCategoryNotifier(databaseService);
    });

// ============================================================================
// CONVENIENCE PROVIDERS
// ============================================================================

// Current practice question provider
final currentPracticeQuestionProvider = Provider<Map<String, dynamic>?>((ref) {
  final gameState = ref.watch(practiceGameProvider);
  return gameState.currentQuestion;
});

// Practice progress provider
final practiceProgressProvider = Provider<double>((ref) {
  final gameState = ref.watch(practiceGameProvider);
  return gameState.progress;
});

// Practice statistics provider
final practiceStatisticsProvider = Provider<Map<String, dynamic>>((ref) {
  final gameState = ref.watch(practiceGameProvider);
  return {
    'currentQuestion': gameState.currentQuestionIndex + 1,
    'totalQuestions': gameState.questions.length,
    'correctAnswers': gameState.totalCorrectAnswers,
    'score': gameState.totalScore,
    'accuracy': gameState.accuracy,
  };
});

// Is practice game active provider
final isPracticeGameActiveProvider = Provider<bool>((ref) {
  final gameState = ref.watch(practiceGameProvider);
  return gameState.isGameActive;
});

// Is practice game completed provider
final isPracticeGameCompletedProvider = Provider<bool>((ref) {
  final gameState = ref.watch(practiceGameProvider);
  return gameState.isGameCompleted;
});

// Active categories provider (categories with enough questions)
final activeCategoriesProvider = FutureProvider<List<CategoryModel>>((
  ref,
) async {
  final categories = await ref.watch(categoriesProvider.future);
  return categories
      .where((category) => category.isActive && category.totalQuestions >= 5)
      .toList();
});

// Featured categories provider
final featuredCategoriesProvider = FutureProvider<List<CategoryModel>>((
  ref,
) async {
  final categories = await ref.watch(categoriesProvider.future);
  // Sort by popularity and rating
  final featured = categories.where((category) => category.isActive).toList();
  featured.sort((a, b) {
    final scoreA = (a.totalPlays * 0.6) + (a.averageRating * 0.4);
    final scoreB = (b.totalPlays * 0.6) + (b.averageRating * 0.4);
    return scoreB.compareTo(scoreA);
  });
  return featured.take(6).toList();
});

// Popular categories provider
final popularCategoriesProvider = FutureProvider<List<CategoryModel>>((
  ref,
) async {
  final categories = await ref.watch(categoriesProvider.future);
  final popular =
      categories
          .where((category) => category.isPopular && category.isActive)
          .toList();
  popular.sort((a, b) => b.totalPlays.compareTo(a.totalPlays));
  return popular.take(10).toList();
});
