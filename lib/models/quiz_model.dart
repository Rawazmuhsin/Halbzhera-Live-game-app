// File: lib/models/quiz_model.dart
// Description: Quiz data model

import 'package:cloud_firestore/cloud_firestore.dart';

enum QuizDifficulty { easy, medium, hard, mixed }

class QuizModel {
  final String id;
  final String title;
  final String description;
  final String category;
  final QuizDifficulty difficulty;
  final List<String> questionIds;
  final int totalQuestions;
  final int timeLimit; // in seconds per question
  final int totalTimeLimit; // total time for entire quiz
  final String? imageUrl;
  final String? thumbnailUrl;
  final bool isActive;
  final bool isFeatured;
  final int playCount;
  final double averageRating;
  final int totalRatings;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic> metadata;
  final List<String> tags;

  const QuizModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.difficulty,
    this.questionIds = const [],
    this.totalQuestions = 0,
    this.timeLimit = 15,
    this.totalTimeLimit = 300,
    this.imageUrl,
    this.thumbnailUrl,
    this.isActive = true,
    this.isFeatured = false,
    this.playCount = 0,
    this.averageRating = 0.0,
    this.totalRatings = 0,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.metadata = const {},
    this.tags = const [],
  });

  // Create from Firestore document
  factory QuizModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return QuizModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? '',
      difficulty: QuizDifficulty.values[data['difficulty'] ?? 0],
      questionIds: List<String>.from(data['questionIds'] ?? []),
      totalQuestions: data['totalQuestions'] ?? 0,
      timeLimit: data['timeLimit'] ?? 15,
      totalTimeLimit: data['totalTimeLimit'] ?? 300,
      imageUrl: data['imageUrl'],
      thumbnailUrl: data['thumbnailUrl'],
      isActive: data['isActive'] ?? true,
      isFeatured: data['isFeatured'] ?? false,
      playCount: data['playCount'] ?? 0,
      averageRating: (data['averageRating'] ?? 0.0).toDouble(),
      totalRatings: data['totalRatings'] ?? 0,
      createdBy: data['createdBy'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
      tags: List<String>.from(data['tags'] ?? []),
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'difficulty': difficulty.index,
      'questionIds': questionIds,
      'totalQuestions': totalQuestions,
      'timeLimit': timeLimit,
      'totalTimeLimit': totalTimeLimit,
      'imageUrl': imageUrl,
      'thumbnailUrl': thumbnailUrl,
      'isActive': isActive,
      'isFeatured': isFeatured,
      'playCount': playCount,
      'averageRating': averageRating,
      'totalRatings': totalRatings,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'metadata': metadata,
      'tags': tags,
    };
  }

  // Copy with method for updates
  QuizModel copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    QuizDifficulty? difficulty,
    List<String>? questionIds,
    int? totalQuestions,
    int? timeLimit,
    int? totalTimeLimit,
    String? imageUrl,
    String? thumbnailUrl,
    bool? isActive,
    bool? isFeatured,
    int? playCount,
    double? averageRating,
    int? totalRatings,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
    List<String>? tags,
  }) {
    return QuizModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      difficulty: difficulty ?? this.difficulty,
      questionIds: questionIds ?? this.questionIds,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      timeLimit: timeLimit ?? this.timeLimit,
      totalTimeLimit: totalTimeLimit ?? this.totalTimeLimit,
      imageUrl: imageUrl ?? this.imageUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      isActive: isActive ?? this.isActive,
      isFeatured: isFeatured ?? this.isFeatured,
      playCount: playCount ?? this.playCount,
      averageRating: averageRating ?? this.averageRating,
      totalRatings: totalRatings ?? this.totalRatings,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
      tags: tags ?? this.tags,
    );
  }

  // Get estimated completion time
  Duration get estimatedDuration {
    return Duration(seconds: totalQuestions * timeLimit);
  }

  // Get difficulty color
  String get difficultyColor {
    switch (difficulty) {
      case QuizDifficulty.easy:
        return '#4CAF50'; // Green
      case QuizDifficulty.medium:
        return '#FF9800'; // Orange
      case QuizDifficulty.hard:
        return '#F44336'; // Red
      case QuizDifficulty.mixed:
        return '#2196F3'; // Blue
    }
  }

  // Get difficulty text
  String get difficultyText {
    switch (difficulty) {
      case QuizDifficulty.easy:
        return 'ئاسان';
      case QuizDifficulty.medium:
        return 'مامناوەند';
      case QuizDifficulty.hard:
        return 'ئاڵۆز';
      case QuizDifficulty.mixed:
        return 'تێکەڵ';
    }
  }

  // Get category text in Kurdish
  String get categoryText {
    switch (category.toLowerCase()) {
      case 'history':
        return 'مێژوو';
      case 'science':
        return 'زانست';
      case 'technology':
        return 'تەکنۆلۆژیا';
      case 'sports':
        return 'وەرزش';
      case 'geography':
        return 'جوگرافیا';
      case 'literature':
        return 'ئەدەبیات';
      case 'mathematics':
        return 'بیرکاری';
      case 'religion':
        return 'ئایین';
      case 'culture':
        return 'کولتوور';
      case 'general':
        return 'گشتی';
      default:
        return category;
    }
  }

  // Get rating stars
  int get ratingStars {
    return averageRating.round();
  }

  // Check if quiz is popular
  bool get isPopular {
    return playCount > 100;
  }

  // Check if quiz is trending
  bool get isTrending {
    final daysSinceCreated = DateTime.now().difference(createdAt).inDays;
    return daysSinceCreated <= 7 && playCount > 50;
  }

  // Get completion percentage for a given score
  double getCompletionPercentage(int score, int maxPossibleScore) {
    if (maxPossibleScore == 0) return 0.0;
    return (score / maxPossibleScore) * 100;
  }

  // Add rating
  QuizModel addRating(double newRating) {
    final newTotalRatings = totalRatings + 1;
    final newAverageRating =
        ((averageRating * totalRatings) + newRating) / newTotalRatings;

    return copyWith(
      averageRating: newAverageRating,
      totalRatings: newTotalRatings,
    );
  }

  // Increment play count
  QuizModel incrementPlayCount() {
    return copyWith(playCount: playCount + 1);
  }

  @override
  String toString() {
    return 'QuizModel(id: $id, title: $title, category: $category)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is QuizModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
