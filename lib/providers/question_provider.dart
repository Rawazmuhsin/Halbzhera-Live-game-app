// File: lib/providers/question_provider.dart
// Description: Question management provider with Riverpod

// ignore_for_file: avoid_print

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/question_model.dart';
import '../models/category_model.dart';
import '../models/scheduled_game_model.dart';
import '../config/firebase_config.dart';
import '../services/database_service.dart';
import 'auth_provider.dart';

// ============================================================================
// QUESTION PROVIDERS
// ============================================================================

// Categories stream provider
final categoriesProvider = StreamProvider<List<CategoryModel>>((ref) {
  final databaseService = ref.read(databaseServiceProvider);
  return databaseService.getCategoriesStream();
});

// Questions by category provider
final questionsByCategoryProvider =
    StreamProvider.family<List<QuestionModel>, String>((ref, categoryId) {
      final databaseService = ref.read(databaseServiceProvider);
      return databaseService.getQuestionsByCategoryStream(categoryId);
    });

// Question count by category provider
final questionCountByCategoryProvider = Provider.family<int, String>((
  ref,
  categoryId,
) {
  final questionsAsync = ref.watch(questionsByCategoryProvider(categoryId));
  return questionsAsync.when(
    data: (questions) => questions.length,
    loading: () => 0,
    error: (_, __) => 0,
  );
});

// Real-time question count provider (counts actual documents)
final realTimeQuestionCountProvider = FutureProvider.family<int, String>((
  ref,
  categoryName,
) async {
  // Get questions from last 24 hours for this category
  final yesterday = DateTime.now().subtract(const Duration(hours: 24));

  try {
    final snapshot =
        await FirebaseConfig.questions
            .where('category', isEqualTo: categoryName)
            .where('isActive', isEqualTo: true)
            .where('createdAt', isGreaterThan: Timestamp.fromDate(yesterday))
            .get();

    return snapshot.docs.length;
  } catch (e) {
    print('Error counting questions: $e');
    return 0;
  }
});

// Total question count provider (all questions for category)
final totalQuestionCountProvider = FutureProvider.family<int, String>((
  ref,
  categoryName,
) async {
  try {
    final snapshot =
        await FirebaseConfig.questions
            .where('category', isEqualTo: categoryName)
            .where('isActive', isEqualTo: true)
            .get();

    return snapshot.docs.length;
  } catch (e) {
    print('Error counting total questions: $e');
    return 0;
  }
});

// All questions provider (for admin)
final allQuestionsProvider = StreamProvider<List<QuestionModel>>((ref) {
  final databaseService = ref.read(databaseServiceProvider);
  return databaseService.getAllQuestionsStream();
});

// Question statistics provider
final questionStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final databaseService = ref.read(databaseServiceProvider);
  return databaseService.getQuestionStatistics();
});

// ============================================================================
// QUESTION STATE MANAGEMENT
// ============================================================================

class QuestionState {
  final List<QuestionModel> questions;
  final List<CategoryModel> categories;
  final String? selectedCategoryId;
  final bool isLoading;
  final String? error;

  const QuestionState({
    this.questions = const [],
    this.categories = const [],
    this.selectedCategoryId,
    this.isLoading = false,
    this.error,
  });

  QuestionState copyWith({
    List<QuestionModel>? questions,
    List<CategoryModel>? categories,
    String? selectedCategoryId,
    bool? isLoading,
    String? error,
  }) {
    return QuestionState(
      questions: questions ?? this.questions,
      categories: categories ?? this.categories,
      selectedCategoryId: selectedCategoryId ?? this.selectedCategoryId,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }

  // Get questions for selected category
  List<QuestionModel> get selectedCategoryQuestions {
    if (selectedCategoryId == null) return [];
    return questions.where((q) => q.category == selectedCategoryId).toList();
  }

  // Get category by ID
  CategoryModel? getCategoryById(String id) {
    try {
      return categories.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }

  // Check if category has enough questions for live game
  bool categoryHasEnoughQuestions(String categoryId, {int required = 15}) {
    final categoryQuestions =
        questions.where((q) => q.category == categoryId).length;
    return categoryQuestions >= required;
  }
}

// ============================================================================
// QUESTION NOTIFIER
// ============================================================================

class QuestionNotifier extends StateNotifier<QuestionState> {
  final DatabaseService _databaseService;
  final Ref _ref;

  QuestionNotifier(this._databaseService, this._ref)
    : super(const QuestionState()) {
    _initialize();
  }

  void _initialize() {
    // Load categories
    _ref.listen(categoriesProvider, (previous, next) {
      next.when(
        data: (categories) => state = state.copyWith(categories: categories),
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

  // Set selected category
  void selectCategory(String categoryId) {
    state = state.copyWith(selectedCategoryId: categoryId);
    _loadQuestionsForCategory(categoryId);
  }

  // Load questions for specific category
  void _loadQuestionsForCategory(String categoryId) {
    _ref.listen(questionsByCategoryProvider(categoryId), (previous, next) {
      next.when(
        data:
            (questions) =>
                state = state.copyWith(questions: questions, isLoading: false),
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

  // Create new question
  Future<String> createQuestion({
    required String question,
    required QuestionType type,
    required List<String> options,
    required String correctAnswer,
    String? explanation,
    required String categoryId,
    required QuestionDifficulty difficulty,
    int points = 100,
    int timeLimit = 15,
    String? imageUrl,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final questionModel = QuestionModel(
        id: '', // Will be set by Firestore
        quizId: '', // For live games, this can be empty
        question: question,
        type: type,
        options: options,
        correctAnswer: correctAnswer,
        explanation: explanation,
        category: categoryId,
        difficulty: difficulty,
        points: points,
        timeLimit: timeLimit,
        imageUrl: imageUrl,
        order: 0, // Will be set automatically
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final questionId = await _databaseService.createQuestion(
        questionModel.toFirestore(),
      );

      // Update category question count
      await _updateCategoryQuestionCount(categoryId);

      state = state.copyWith(isLoading: false);
      return questionId;
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      rethrow;
    }
  }

  // Bulk create questions
  Future<List<String>> bulkCreateQuestions(
    String categoryId,
    List<Map<String, dynamic>> questionsData,
  ) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      // Add category to each question
      final questionsWithCategory =
          questionsData
              .map(
                (data) => {
                  ...data,
                  'category': categoryId,
                  'createdAt': FieldValue.serverTimestamp(),
                  'updatedAt': FieldValue.serverTimestamp(),
                  'isActive': true,
                },
              )
              .toList();

      final questionIds = await _databaseService.bulkCreateQuestions(
        questionsWithCategory,
      );

      // Update category question count
      await _updateCategoryQuestionCount(categoryId);

      state = state.copyWith(isLoading: false);
      return questionIds;
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      rethrow;
    }
  }

  // Update question
  Future<void> updateQuestion(
    String questionId,
    Map<String, dynamic> data,
  ) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      await _databaseService.updateQuestion(questionId, {
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      rethrow;
    }
  }

  // Delete question
  Future<void> deleteQuestion(String questionId, String categoryId) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      await _databaseService.deleteQuestion(questionId);

      // Update category question count
      await _updateCategoryQuestionCount(categoryId);

      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      rethrow;
    }
  }

  // Update category question count
  Future<void> _updateCategoryQuestionCount(String categoryId) async {
    try {
      final questions = await _databaseService.getQuestionsByCategory(
        categoryId,
      );
      await _databaseService.updateCategory(categoryId, {
        'totalQuestions': questions.length,
      });
    } catch (e) {
      print('Error updating category question count: $e');
    }
  }

  // Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  // Reset state
  void reset() {
    state = const QuestionState();
  }
}

// ============================================================================
// PROVIDER INSTANCES
// ============================================================================

// Question notifier provider
final questionNotifierProvider =
    StateNotifierProvider<QuestionNotifier, QuestionState>((ref) {
      final databaseService = ref.read(databaseServiceProvider);
      return QuestionNotifier(databaseService, ref);
    });

// ============================================================================
// CONVENIENCE PROVIDERS
// ============================================================================

// Selected category provider
final selectedCategoryProvider = Provider<CategoryModel?>((ref) {
  final questionState = ref.watch(questionNotifierProvider);
  if (questionState.selectedCategoryId == null) return null;
  return questionState.getCategoryById(questionState.selectedCategoryId!);
});

// Selected category questions provider
final selectedCategoryQuestionsProvider = Provider<List<QuestionModel>>((ref) {
  final questionState = ref.watch(questionNotifierProvider);
  return questionState.selectedCategoryQuestions;
});

// Can create live game provider (checks if category has enough questions)
final canCreateLiveGameProvider = Provider.family<bool, String>((
  ref,
  categoryId,
) {
  final questionState = ref.watch(questionNotifierProvider);
  return questionState.categoryHasEnoughQuestions(categoryId);
});

// Question difficulties provider
final questionDifficultiesProvider = Provider<List<QuestionDifficulty>>((ref) {
  return QuestionDifficulty.values;
});

// Question types provider
final questionTypesProvider = Provider<List<QuestionType>>((ref) {
  return QuestionType.values;
});

// Scheduled games stream provider
final scheduledGamesStreamProvider = StreamProvider<List<ScheduledGameModel>>((
  ref,
) {
  final databaseService = ref.read(databaseServiceProvider);
  return databaseService.getScheduledGamesStream();
});
