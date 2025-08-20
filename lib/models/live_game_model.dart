// File: lib/models/live_game_model.dart
// Description: Live multiplayer game data model

import 'package:cloud_firestore/cloud_firestore.dart';

enum LiveGameStatus { scheduled, waiting, live, finished, cancelled }

class LiveGameModel {
  final String id;
  final String title;
  final String category;
  final DateTime scheduledTime;
  final LiveGameStatus status;
  final int currentQuestion;
  final int totalQuestions;
  final int timePerQuestion; // seconds
  final List<String> questions; // question IDs
  final Map<String, dynamic> participants;
  final DateTime? startedAt;
  final DateTime? finishedAt;
  final String createdBy;
  final DateTime createdAt;
  final DateTime? currentQuestionStartTime;
  final String? winnerId; // NEW: Winner of the game
  final String? endReason; // NEW: How the game ended

  const LiveGameModel({
    required this.id,
    required this.title,
    required this.category,
    required this.scheduledTime,
    this.status = LiveGameStatus.scheduled,
    this.currentQuestion = 0,
    this.totalQuestions = 15,
    this.timePerQuestion = 10,
    this.questions = const [],
    this.participants = const {},
    this.startedAt,
    this.finishedAt,
    required this.createdBy,
    required this.createdAt,
    this.currentQuestionStartTime,
    this.winnerId, // NEW
    this.endReason, // NEW
  });

  // Create from Firestore document
  factory LiveGameModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return LiveGameModel(
      id: doc.id,
      title: data['title'] ?? '',
      category: data['category'] ?? '',
      scheduledTime:
          (data['scheduledTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: LiveGameStatus.values[data['status'] ?? 0],
      currentQuestion: data['currentQuestion'] ?? 0,
      totalQuestions: data['totalQuestions'] ?? 15,
      timePerQuestion: data['timePerQuestion'] ?? 10,
      questions: List<String>.from(data['questions'] ?? []),
      participants: Map<String, dynamic>.from(data['participants'] ?? {}),
      startedAt: (data['startedAt'] as Timestamp?)?.toDate(),
      finishedAt: (data['finishedAt'] as Timestamp?)?.toDate(),
      createdBy: data['createdBy'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      currentQuestionStartTime:
          (data['currentQuestionStartTime'] as Timestamp?)?.toDate(),
      winnerId: data['winnerId'], // NEW
      endReason: data['endReason'], // NEW
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'category': category,
      'scheduledTime': Timestamp.fromDate(scheduledTime),
      'status': status.index,
      'currentQuestion': currentQuestion,
      'totalQuestions': totalQuestions,
      'timePerQuestion': timePerQuestion,
      'questions': questions,
      'participants': participants,
      'startedAt': startedAt != null ? Timestamp.fromDate(startedAt!) : null,
      'finishedAt': finishedAt != null ? Timestamp.fromDate(finishedAt!) : null,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'currentQuestionStartTime':
          currentQuestionStartTime != null
              ? Timestamp.fromDate(currentQuestionStartTime!)
              : null,
      'winnerId': winnerId, // NEW
      'endReason': endReason, // NEW
    };
  }

  // Copy with method for updates
  LiveGameModel copyWith({
    String? id,
    String? title,
    String? category,
    DateTime? scheduledTime,
    LiveGameStatus? status,
    int? currentQuestion,
    int? totalQuestions,
    int? timePerQuestion,
    List<String>? questions,
    Map<String, dynamic>? participants,
    DateTime? startedAt,
    DateTime? finishedAt,
    String? createdBy,
    DateTime? createdAt,
    DateTime? currentQuestionStartTime,
    String? winnerId, // NEW
    String? endReason, // NEW
  }) {
    return LiveGameModel(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      status: status ?? this.status,
      currentQuestion: currentQuestion ?? this.currentQuestion,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      timePerQuestion: timePerQuestion ?? this.timePerQuestion,
      questions: questions ?? this.questions,
      participants: participants ?? this.participants,
      startedAt: startedAt ?? this.startedAt,
      finishedAt: finishedAt ?? this.finishedAt,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      currentQuestionStartTime:
          currentQuestionStartTime ?? this.currentQuestionStartTime,
      winnerId: winnerId ?? this.winnerId, // NEW
      endReason: endReason ?? this.endReason, // NEW
    );
  }

  // Get participant count
  int get participantCount => participants.length;

  // Check if user is participant
  bool isParticipant(String userId) => participants.containsKey(userId);

  // Get time remaining for current question
  Duration? get timeRemainingForQuestion {
    if (currentQuestionStartTime == null || status != LiveGameStatus.live) {
      return null;
    }

    final elapsed = DateTime.now().difference(currentQuestionStartTime!);
    final remaining = Duration(seconds: timePerQuestion) - elapsed;

    return remaining.isNegative ? Duration.zero : remaining;
  }

  // Check if game is active (live or waiting)
  bool get isActive =>
      status == LiveGameStatus.live || status == LiveGameStatus.waiting;

  // Check if game can be joined
  bool get canJoin =>
      status == LiveGameStatus.scheduled || status == LiveGameStatus.waiting;

  // Get status text in Kurdish
  String get statusText {
    switch (status) {
      case LiveGameStatus.scheduled:
        return 'نەخشەکراو';
      case LiveGameStatus.waiting:
        return 'چاوەڕوانی';
      case LiveGameStatus.live:
        return 'زیندوو';
      case LiveGameStatus.finished:
        return 'تەواوبوو';
      case LiveGameStatus.cancelled:
        return 'هەڵوەشاوە';
    }
  }

  // Get current question model
  String? get currentQuestionId {
    if (currentQuestion < questions.length) {
      return questions[currentQuestion];
    }
    return null;
  }

  // Check if game is finished
  bool get isFinished =>
      currentQuestion >= totalQuestions || status == LiveGameStatus.finished;

  @override
  String toString() {
    return 'LiveGameModel(id: $id, title: $title, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LiveGameModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

// Live answer model for real-time leaderboard
class LiveAnswerModel {
  final String gameId;
  final String userId;
  final String displayName;
  final String? photoURL;
  final Map<String, dynamic> answers; // question index -> answer data
  final int totalScore;
  final int correctAnswers;
  final int rank;
  final bool isActive;
  final bool isEliminated; // NEW: Track elimination status
  final int? eliminatedAtQuestion; // NEW: Which question eliminated on
  final String? eliminationReason; // NEW: Reason for elimination
  final DateTime lastAnswerAt;

  const LiveAnswerModel({
    required this.gameId,
    required this.userId,
    required this.displayName,
    this.photoURL,
    this.answers = const {},
    this.totalScore = 0,
    this.correctAnswers = 0,
    this.rank = 0,
    this.isActive = true,
    this.isEliminated = false, // NEW
    this.eliminatedAtQuestion, // NEW
    this.eliminationReason, // NEW
    required this.lastAnswerAt,
  });

  // Create from Firestore document
  factory LiveAnswerModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return LiveAnswerModel(
      gameId: data['gameId'] ?? '',
      userId: data['userId'] ?? '',
      displayName: data['displayName'] ?? '',
      photoURL: data['photoURL'],
      answers: Map<String, dynamic>.from(data['answers'] ?? {}),
      totalScore: data['totalScore'] ?? 0,
      correctAnswers: data['correctAnswers'] ?? 0,
      rank: data['rank'] ?? 0,
      isActive: data['isActive'] ?? true,
      isEliminated: data['isEliminated'] ?? false, // NEW
      eliminatedAtQuestion: data['eliminatedAtQuestion'], // NEW
      eliminationReason: data['eliminationReason'], // NEW
      lastAnswerAt:
          (data['lastAnswerAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'gameId': gameId,
      'userId': userId,
      'displayName': displayName,
      'photoURL': photoURL,
      'answers': answers,
      'totalScore': totalScore,
      'correctAnswers': correctAnswers,
      'rank': rank,
      'isActive': isActive,
      'isEliminated': isEliminated, // NEW
      'eliminatedAtQuestion': eliminatedAtQuestion, // NEW
      'eliminationReason': eliminationReason, // NEW
      'lastAnswerAt': Timestamp.fromDate(lastAnswerAt),
    };
  }

  // Copy with method for updates
  LiveAnswerModel copyWith({
    String? gameId,
    String? userId,
    String? displayName,
    String? photoURL,
    Map<String, dynamic>? answers,
    int? totalScore,
    int? correctAnswers,
    int? rank,
    bool? isActive,
    bool? isEliminated, // NEW
    int? eliminatedAtQuestion, // NEW
    String? eliminationReason, // NEW
    DateTime? lastAnswerAt,
  }) {
    return LiveAnswerModel(
      gameId: gameId ?? this.gameId,
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      answers: answers ?? this.answers,
      totalScore: totalScore ?? this.totalScore,
      correctAnswers: correctAnswers ?? this.correctAnswers,
      rank: rank ?? this.rank,
      isActive: isActive ?? this.isActive,
      isEliminated: isEliminated ?? this.isEliminated, // NEW
      eliminatedAtQuestion:
          eliminatedAtQuestion ?? this.eliminatedAtQuestion, // NEW
      eliminationReason: eliminationReason ?? this.eliminationReason, // NEW
      lastAnswerAt: lastAnswerAt ?? this.lastAnswerAt,
    );
  }

  // Get answer for specific question
  Map<String, dynamic>? getAnswerForQuestion(int questionIndex) {
    return answers[questionIndex.toString()];
  }

  // Check if answered specific question
  bool hasAnsweredQuestion(int questionIndex) {
    return answers.containsKey(questionIndex.toString());
  }

  // Calculate accuracy percentage
  double get accuracy {
    if (answers.isEmpty) return 0.0;
    return (correctAnswers / answers.length) * 100;
  }

  // Check if user is still in the game (not eliminated)
  bool get isStillPlaying => isActive && !isEliminated;

  // Get elimination message in Kurdish
  String get eliminationMessage {
    switch (eliminationReason) {
      case 'wrong_answer':
        return 'وەڵامی هەڵە - دەرکراویت!';
      case 'timeout':
        return 'کاتت تەواوبوو - دەرکراویت!';
      case 'connection_lost':
        return 'پەیوەندی بڕا - دەرکراویت!';
      default:
        return 'دەرکراویت لە یاریەکە!';
    }
  }

  @override
  String toString() {
    return 'LiveAnswerModel(userId: $userId, totalScore: $totalScore, rank: $rank, isEliminated: $isEliminated)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LiveAnswerModel &&
        other.gameId == gameId &&
        other.userId == userId;
  }

  @override
  int get hashCode => '$gameId$userId'.hashCode;
}

// Game schedule model for recurring games
class GameScheduleModel {
  final String id;
  final int dayOfWeek; // 0=Sunday, 1=Monday, etc.
  final String time; // "21:00" format
  final String category;
  final String title;
  final String description;
  final bool isActive;
  final DateTime createdAt;

  const GameScheduleModel({
    required this.id,
    required this.dayOfWeek,
    required this.time,
    required this.category,
    required this.title,
    required this.description,
    this.isActive = true,
    required this.createdAt,
  });

  // Create from Firestore document
  factory GameScheduleModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return GameScheduleModel(
      id: doc.id,
      dayOfWeek: data['dayOfWeek'] ?? 0,
      time: data['time'] ?? '',
      category: data['category'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'dayOfWeek': dayOfWeek,
      'time': time,
      'category': category,
      'title': title,
      'description': description,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // Copy with method for updates
  GameScheduleModel copyWith({
    String? id,
    int? dayOfWeek,
    String? time,
    String? category,
    String? title,
    String? description,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return GameScheduleModel(
      id: id ?? this.id,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      time: time ?? this.time,
      category: category ?? this.category,
      title: title ?? this.title,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Get day name in Kurdish
  String get dayNameKurdish {
    const days = [
      'یەکشەممە',
      'دووشەممە',
      'سێشەممە',
      'چوارشەممە',
      'پێنجشەممە',
      'هەینی',
      'شەممە',
    ];
    return days[dayOfWeek];
  }

  // Get next scheduled date
  DateTime get nextScheduledDate {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Parse time
    final timeParts = time.split(':');
    final hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);

    // Find next occurrence
    for (int i = 0; i < 7; i++) {
      final date = today.add(Duration(days: i));
      if (date.weekday % 7 == dayOfWeek) {
        final scheduledDateTime = DateTime(
          date.year,
          date.month,
          date.day,
          hour,
          minute,
        );
        if (scheduledDateTime.isAfter(now)) {
          return scheduledDateTime;
        }
      }
    }

    // If not found this week, get next week
    final daysUntilNext = (dayOfWeek - now.weekday % 7 + 7) % 7;
    final nextDate = today.add(Duration(days: daysUntilNext + 7));
    return DateTime(nextDate.year, nextDate.month, nextDate.day, hour, minute);
  }

  @override
  String toString() {
    return 'GameScheduleModel(id: $id, title: $title, time: $dayNameKurdish $time)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GameScheduleModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
