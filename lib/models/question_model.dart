// File: lib/models/question_model.dart
// Description: Question data model

import 'package:cloud_firestore/cloud_firestore.dart';

enum QuestionType { multipleChoice, trueFalse, fillInTheBlank }

enum QuestionDifficulty { easy, medium, hard }

class QuestionModel {
  final String id;
  final String quizId;
  final String question;
  final QuestionType type;
  final List<String> options;
  final String correctAnswer;
  final String? explanation;
  final String category;
  final QuestionDifficulty difficulty;
  final int points;
  final int timeLimit; // in seconds
  final int order;
  final String? imageUrl;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic> metadata;

  const QuestionModel({
    required this.id,
    required this.quizId,
    required this.question,
    required this.type,
    required this.options,
    required this.correctAnswer,
    this.explanation,
    required this.category,
    required this.difficulty,
    this.points = 10,
    this.timeLimit = 15,
    this.order = 0,
    this.imageUrl,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.metadata = const {},
  });

  // Create from Firestore document
  factory QuestionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return QuestionModel(
      id: doc.id,
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
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'quizId': quizId,
      'question': question,
      'type': type.index,
      'options': options,
      'correctAnswer': correctAnswer,
      'explanation': explanation,
      'category': category,
      'difficulty': difficulty.index,
      'points': points,
      'timeLimit': timeLimit,
      'order': order,
      'imageUrl': imageUrl,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'metadata': metadata,
    };
  }

  // Copy with method for updates
  QuestionModel copyWith({
    String? id,
    String? quizId,
    String? question,
    QuestionType? type,
    List<String>? options,
    String? correctAnswer,
    String? explanation,
    String? category,
    QuestionDifficulty? difficulty,
    int? points,
    int? timeLimit,
    int? order,
    String? imageUrl,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return QuestionModel(
      id: id ?? this.id,
      quizId: quizId ?? this.quizId,
      question: question ?? this.question,
      type: type ?? this.type,
      options: options ?? this.options,
      correctAnswer: correctAnswer ?? this.correctAnswer,
      explanation: explanation ?? this.explanation,
      category: category ?? this.category,
      difficulty: difficulty ?? this.difficulty,
      points: points ?? this.points,
      timeLimit: timeLimit ?? this.timeLimit,
      order: order ?? this.order,
      imageUrl: imageUrl ?? this.imageUrl,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  // Check if answer is correct
  bool isCorrect(String answer) {
    return answer.toLowerCase().trim() == correctAnswer.toLowerCase().trim();
  }

  // Get points based on time taken (speed bonus)
  int getPointsWithTimeBonus(Duration timeTaken) {
    final maxTime = Duration(seconds: timeLimit);
    final timeRatio = timeTaken.inMilliseconds / maxTime.inMilliseconds;

    if (timeRatio <= 0.3) {
      // Very fast - 50% bonus
      return (points * 1.5).round();
    } else if (timeRatio <= 0.5) {
      // Fast - 25% bonus
      return (points * 1.25).round();
    } else if (timeRatio <= 0.8) {
      // Normal speed - full points
      return points;
    } else {
      // Slow - reduced points
      return (points * 0.8).round();
    }
  }

  // Get difficulty color
  String get difficultyColor {
    switch (difficulty) {
      case QuestionDifficulty.easy:
        return '#4CAF50'; // Green
      case QuestionDifficulty.medium:
        return '#FF9800'; // Orange
      case QuestionDifficulty.hard:
        return '#F44336'; // Red
    }
  }

  // Get difficulty text
  String get difficultyText {
    switch (difficulty) {
      case QuestionDifficulty.easy:
        return 'ئاسان';
      case QuestionDifficulty.medium:
        return 'مامناوەند';
      case QuestionDifficulty.hard:
        return 'ئاڵۆز';
    }
  }

  // Get type text
  String get typeText {
    switch (type) {
      case QuestionType.multipleChoice:
        return 'هەڵبژاردەی فرە';
      case QuestionType.trueFalse:
        return 'ڕاست/هەڵە';
      case QuestionType.fillInTheBlank:
        return 'پڕکردنەوەی بۆشاڵی';
    }
  }

  @override
  String toString() {
    return 'QuestionModel(id: $id, question: $question, type: $type)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is QuestionModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
