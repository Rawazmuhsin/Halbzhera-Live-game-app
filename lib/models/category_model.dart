// File: lib/models/category_model.dart
// Description: Category data model for game sections

import 'package:cloud_firestore/cloud_firestore.dart';

class CategoryModel {
  final String id;
  final String name; // Kurdish name
  final String nameEn; // English name (optional)
  final String description;
  final String icon; // icon identifier
  final String color; // hex color code
  final String difficulty; // easy, medium, hard
  final bool isActive;
  final int totalQuestions;
  final int totalPlays;
  final double averageRating;
  final int totalRatings;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;

  const CategoryModel({
    required this.id,
    required this.name,
    this.nameEn = '',
    required this.description,
    this.icon = 'category',
    this.color = '#FF6B6B',
    this.difficulty = 'medium',
    this.isActive = true,
    this.totalQuestions = 0,
    this.totalPlays = 0,
    this.averageRating = 0.0,
    this.totalRatings = 0,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
  });

  // Create from map
  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      nameEn: map['nameEn'] ?? '',
      description: map['description'] ?? '',
      icon: map['icon'] ?? 'category',
      color: map['color'] ?? '#FF6B6B',
      difficulty: map['difficulty'] ?? 'medium',
      isActive: map['isActive'] ?? true,
      totalQuestions: map['totalQuestions'] ?? 0,
      totalPlays: map['totalPlays'] ?? 0,
      averageRating: (map['averageRating'] ?? 0.0).toDouble(),
      totalRatings: map['totalRatings'] ?? 0,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: map['createdBy'] ?? '',
    );
  }

  // Create from Firestore document
  factory CategoryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return CategoryModel(
      id: doc.id,
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
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: data['createdBy'] ?? '',
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'nameEn': nameEn,
      'description': description,
      'icon': icon,
      'color': color,
      'difficulty': difficulty,
      'isActive': isActive,
      'totalQuestions': totalQuestions,
      'totalPlays': totalPlays,
      'averageRating': averageRating,
      'totalRatings': totalRatings,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'createdBy': createdBy,
    };
  }

  // Copy with method for updates
  CategoryModel copyWith({
    String? id,
    String? name,
    String? nameEn,
    String? description,
    String? icon,
    String? color,
    String? difficulty,
    bool? isActive,
    int? totalQuestions,
    int? totalPlays,
    double? averageRating,
    int? totalRatings,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      nameEn: nameEn ?? this.nameEn,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      difficulty: difficulty ?? this.difficulty,
      isActive: isActive ?? this.isActive,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      totalPlays: totalPlays ?? this.totalPlays,
      averageRating: averageRating ?? this.averageRating,
      totalRatings: totalRatings ?? this.totalRatings,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  // Get difficulty text in Kurdish
  String get difficultyTextKurdish {
    switch (difficulty) {
      case 'easy':
        return 'ئاسان';
      case 'medium':
        return 'مامناوەند';
      case 'hard':
        return 'ئاڵۆز';
      default:
        return difficulty;
    }
  }

  // Get rating stars (1-5)
  int get ratingStars {
    return averageRating.round().clamp(1, 5);
  }

  // Check if category is popular
  bool get isPopular {
    return totalPlays > 100;
  }

  // Check if category has enough questions for live game
  bool get hasEnoughQuestionsForLiveGame {
    return totalQuestions >= 15;
  }

  // Get completion rate (if you track this)
  double get completionRate {
    if (totalPlays == 0) return 0.0;
    // This would require additional tracking
    return 75.0; // Placeholder
  }

  @override
  String toString() {
    return 'CategoryModel(id: $id, name: $name, totalQuestions: $totalQuestions)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CategoryModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
