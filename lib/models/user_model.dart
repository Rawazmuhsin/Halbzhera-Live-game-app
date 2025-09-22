// File: lib/models/user_model.dart
// Description: User data model

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

enum LoginProvider { google, facebook, anonymous }

class UserModel {
  final String uid;
  final String? email;
  final String? displayName;
  final String? photoURL;
  final LoginProvider provider;
  final int totalScore;
  final int gamesPlayed;
  final int gamesWon;
  final DateTime createdAt;
  final DateTime? firstLoginAt; // Only set on first registration
  final DateTime lastSeen;
  final bool isOnline;
  final Map<String, dynamic> preferences;

  const UserModel({
    required this.uid,
    this.email,
    this.displayName,
    this.photoURL,
    required this.provider,
    this.totalScore = 0,
    this.gamesPlayed = 0,
    this.gamesWon = 0,
    required this.createdAt,
    this.firstLoginAt,
    required this.lastSeen,
    this.isOnline = false,
    this.preferences = const {},
  });

  // Create from Firebase User
  factory UserModel.fromFirebaseUser(User user, {LoginProvider? provider}) {
    LoginProvider userProvider = provider ?? LoginProvider.anonymous;

    // Determine provider from user data
    if (user.providerData.isNotEmpty) {
      final providerId = user.providerData.first.providerId;
      if (providerId == 'google.com') {
        userProvider = LoginProvider.google;
      } else if (providerId == 'facebook.com') {
        userProvider = LoginProvider.facebook;
      }
    }

    return UserModel(
      uid: user.uid,
      email: user.email,
      displayName: user.displayName ?? 'Player ${user.uid.substring(0, 6)}',
      photoURL: user.photoURL,
      provider: userProvider,
      createdAt: DateTime.now(),
      // Don't set firstLoginAt here - it will be set by the database service
      lastSeen: DateTime.now(),
      isOnline: true,
    );
  }

  // Create from Firestore document
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return UserModel(
      uid: doc.id,
      email: data['email'],
      displayName: data['displayName'] ?? 'Player ${doc.id.substring(0, 6)}',
      photoURL: data['photoURL'],
      provider: LoginProvider.values[data['provider'] ?? 0],
      totalScore: data['totalScore'] ?? 0,
      gamesPlayed: data['gamesPlayed'] ?? 0,
      gamesWon: data['gamesWon'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      firstLoginAt: (data['firstLoginAt'] as Timestamp?)?.toDate(),
      lastSeen: (data['lastSeen'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isOnline: data['isOnline'] ?? false,
      preferences: Map<String, dynamic>.from(data['preferences'] ?? {}),
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    final data = {
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'provider': provider.index,
      'totalScore': totalScore,
      'gamesPlayed': gamesPlayed,
      'gamesWon': gamesWon,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastSeen': Timestamp.fromDate(lastSeen),
      'isOnline': isOnline,
      'preferences': preferences,
    };

    // Only include firstLoginAt if it's not null
    if (firstLoginAt != null) {
      data['firstLoginAt'] = Timestamp.fromDate(firstLoginAt!);
    }

    return data;
  }

  // Copy with method for updates
  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoURL,
    LoginProvider? provider,
    int? totalScore,
    int? gamesPlayed,
    int? gamesWon,
    DateTime? createdAt,
    DateTime? firstLoginAt,
    DateTime? lastSeen,
    bool? isOnline,
    Map<String, dynamic>? preferences,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      provider: provider ?? this.provider,
      totalScore: totalScore ?? this.totalScore,
      gamesPlayed: gamesPlayed ?? this.gamesPlayed,
      gamesWon: gamesWon ?? this.gamesWon,
      createdAt: createdAt ?? this.createdAt,
      firstLoginAt: firstLoginAt ?? this.firstLoginAt,
      lastSeen: lastSeen ?? this.lastSeen,
      isOnline: isOnline ?? this.isOnline,
      preferences: preferences ?? this.preferences,
    );
  }

  // Calculate win rate
  double get winRate {
    if (gamesPlayed == 0) return 0.0;
    return (gamesWon / gamesPlayed) * 100;
  }

  // Get average score per game
  double get averageScore {
    if (gamesPlayed == 0) return 0.0;
    return totalScore / gamesPlayed;
  }

  @override
  String toString() {
    return 'UserModel(uid: $uid, displayName: $displayName, email: $email)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel && other.uid == uid;
  }

  @override
  int get hashCode => uid.hashCode;
}
