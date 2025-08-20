// File: lib/models/scheduled_game_model.dart
// Description: Model for scheduled games in the admin panel

import 'package:cloud_firestore/cloud_firestore.dart';

enum GameStatus { scheduled, live, completed, cancelled }

class ScheduledGameModel {
  final String id;
  final String name;
  final String description;
  final DateTime scheduledTime;
  final String prize;
  final String categoryId;
  final String categoryName;
  final int duration; // in minutes
  final int maxParticipants;
  final int questionsCount;
  final GameStatus status;
  final String createdBy;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<String> tags;
  final Map<String, dynamic> gameSettings;

  ScheduledGameModel({
    required this.id,
    required this.name,
    required this.description,
    required this.scheduledTime,
    required this.prize,
    required this.categoryId,
    required this.categoryName,
    required this.duration,
    required this.maxParticipants,
    required this.questionsCount,
    required this.status,
    required this.createdBy,
    required this.createdAt,
    this.updatedAt,
    this.tags = const [],
    this.gameSettings = const {},
  });

  // Create from Firestore document
  factory ScheduledGameModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return ScheduledGameModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      scheduledTime: (data['scheduledTime'] as Timestamp).toDate(),
      prize: data['prize'] ?? '',
      categoryId: data['categoryId'] ?? '',
      categoryName: data['categoryName'] ?? '',
      duration: data['duration'] ?? 30,
      maxParticipants: data['maxParticipants'] ?? 100,
      questionsCount: data['questionsCount'] ?? 10,
      status: GameStatus.values[data['status'] ?? 0],
      createdBy: data['createdBy'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt:
          data['updatedAt'] != null
              ? (data['updatedAt'] as Timestamp).toDate()
              : null,
      tags: List<String>.from(data['tags'] ?? []),
      gameSettings: Map<String, dynamic>.from(data['gameSettings'] ?? {}),
    );
  }

  // Convert to map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'scheduledTime': Timestamp.fromDate(scheduledTime),
      'prize': prize,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'duration': duration,
      'maxParticipants': maxParticipants,
      'questionsCount': questionsCount,
      'status': status.index,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'tags': tags,
      'gameSettings': gameSettings,
    };
  }

  // Copy with method for updates
  ScheduledGameModel copyWith({
    String? id,
    String? name,
    String? description,
    DateTime? scheduledTime,
    String? prize,
    String? categoryId,
    String? categoryName,
    int? duration,
    int? maxParticipants,
    int? questionsCount,
    GameStatus? status,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? tags,
    Map<String, dynamic>? gameSettings,
  }) {
    return ScheduledGameModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      prize: prize ?? this.prize,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      duration: duration ?? this.duration,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      questionsCount: questionsCount ?? this.questionsCount,
      status: status ?? this.status,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      tags: tags ?? this.tags,
      gameSettings: gameSettings ?? this.gameSettings,
    );
  }

  // Helper getters
  String get statusText {
    switch (status) {
      case GameStatus.scheduled:
        return 'نەخشەکراو';
      case GameStatus.live:
        return 'زیندوو';
      case GameStatus.completed:
        return 'تەواوبوو';
      case GameStatus.cancelled:
        return 'هەڵوەشاندراوە';
    }
  }

  bool get isScheduled => status == GameStatus.scheduled;
  bool get isLive => status == GameStatus.live;
  bool get isCompleted => status == GameStatus.completed;
  bool get isCancelled => status == GameStatus.cancelled;

  // Check if game can be started
  bool get canStart {
    final now = DateTime.now();
    final timeDiff = scheduledTime.difference(now).inMinutes;
    return isScheduled &&
        timeDiff <= 5 &&
        timeDiff >= -5; // 5 minutes tolerance
  }

  // Check if game should start automatically
  bool get shouldAutoStart {
    final now = DateTime.now();
    return isScheduled && now.isAfter(scheduledTime);
  }

  // Time until game starts
  Duration get timeUntilStart {
    final now = DateTime.now();
    if (now.isAfter(scheduledTime)) {
      return Duration.zero;
    }
    return scheduledTime.difference(now);
  }

  // Formatted time until start
  String get timeUntilStartText {
    final duration = timeUntilStart;
    if (duration.isNegative || duration == Duration.zero) {
      return 'ئێستا';
    }

    final days = duration.inDays;
    final hours = duration.inHours % 24;
    final minutes = duration.inMinutes % 60;

    if (days > 0) {
      return '$days ڕۆژ $hours کاتژمێر';
    } else if (hours > 0) {
      return '$hours کاتژمێر $minutes خولەک';
    } else {
      return '$minutes خولەک';
    }
  }

  @override
  String toString() {
    return 'ScheduledGameModel(id: $id, name: $name, scheduledTime: $scheduledTime, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ScheduledGameModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
