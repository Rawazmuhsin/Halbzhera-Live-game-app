import 'package:cloud_firestore/cloud_firestore.dart';

class GameResultModel {
  final String id;
  final String gameId;
  final String userId;
  final String? userDisplayName;
  final String? userEmail;
  final String? userPhotoUrl;
  final int score;
  final bool isWinner;
  final int? eliminatedAtQuestion;
  final DateTime? completedAt;

  GameResultModel({
    required this.id,
    required this.gameId,
    required this.userId,
    this.userDisplayName,
    this.userEmail,
    this.userPhotoUrl,
    required this.score,
    required this.isWinner,
    this.eliminatedAtQuestion,
    this.completedAt,
  });

  factory GameResultModel.fromMap(Map<String, dynamic> map, String id) {
    return GameResultModel(
      id: id,
      gameId: map['gameId'] ?? '',
      userId: map['userId'] ?? '',
      userDisplayName: map['userDisplayName'],
      userEmail: map['userEmail'],
      userPhotoUrl: map['userPhotoUrl'],
      score: map['score'] ?? 0,
      // For the winners collection, isWinner is always true
      isWinner: map['isWinner'] ?? true,
      eliminatedAtQuestion: map['eliminatedAtQuestion'],
      completedAt: (map['completedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'gameId': gameId,
      'userId': userId,
      'userDisplayName': userDisplayName,
      'userEmail': userEmail,
      'userPhotoUrl': userPhotoUrl,
      'score': score,
      'isWinner': isWinner,
      'eliminatedAtQuestion': eliminatedAtQuestion,
      'completedAt': FieldValue.serverTimestamp(),
    };
  }
}
