// File: lib/models/joined_user_model.dart
// Description: Model for joined users in games

import 'package:cloud_firestore/cloud_firestore.dart';

class JoinedUserModel {
  final String id;
  final String gameId;
  final String userId;
  final String userEmail;
  final String? userDisplayName;
  final String? userPhotoUrl;
  final String accountType; // 'guest' or 'registered'
  final String? guestAccountNumber; // Only for guest users
  final DateTime joinedAt;
  final bool isActive;

  JoinedUserModel({
    required this.id,
    required this.gameId,
    required this.userId,
    required this.userEmail,
    this.userDisplayName,
    this.userPhotoUrl,
    required this.accountType,
    this.guestAccountNumber,
    required this.joinedAt,
    this.isActive = true,
  });

  // Create from Firestore document
  factory JoinedUserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return JoinedUserModel(
      id: doc.id,
      gameId: data['gameId'] ?? '',
      userId: data['userId'] ?? '',
      userEmail: data['userEmail'] ?? '',
      userDisplayName: data['userDisplayName'],
      userPhotoUrl: data['userPhotoUrl'],
      accountType: data['accountType'] ?? 'registered',
      guestAccountNumber: data['guestAccountNumber'],
      joinedAt: (data['joinedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: data['isActive'] ?? true,
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'gameId': gameId,
      'userId': userId,
      'userEmail': userEmail,
      'userDisplayName': userDisplayName,
      'userPhotoUrl': userPhotoUrl,
      'accountType': accountType,
      'guestAccountNumber': guestAccountNumber,
      'joinedAt': Timestamp.fromDate(joinedAt),
      'isActive': isActive,
    };
  }

  // Create a copy with updated fields
  JoinedUserModel copyWith({
    String? id,
    String? gameId,
    String? userId,
    String? userEmail,
    String? userDisplayName,
    String? userPhotoUrl,
    String? accountType,
    String? guestAccountNumber,
    DateTime? joinedAt,
    bool? isActive,
  }) {
    return JoinedUserModel(
      id: id ?? this.id,
      gameId: gameId ?? this.gameId,
      userId: userId ?? this.userId,
      userEmail: userEmail ?? this.userEmail,
      userDisplayName: userDisplayName ?? this.userDisplayName,
      userPhotoUrl: userPhotoUrl ?? this.userPhotoUrl,
      accountType: accountType ?? this.accountType,
      guestAccountNumber: guestAccountNumber ?? this.guestAccountNumber,
      joinedAt: joinedAt ?? this.joinedAt,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  String toString() {
    return 'JoinedUserModel(id: $id, gameId: $gameId, userId: $userId, userEmail: $userEmail, accountType: $accountType)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is JoinedUserModel &&
        other.id == id &&
        other.gameId == gameId &&
        other.userId == userId;
  }

  @override
  int get hashCode {
    return id.hashCode ^ gameId.hashCode ^ userId.hashCode;
  }
}
