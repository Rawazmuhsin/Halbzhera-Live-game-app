// File: lib/config/firebase_config.dart
// Description: Updated Firebase configuration with live game collections

// ignore_for_file: avoid_print

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../firebase_options.dart';

class FirebaseConfig {
  static FirebaseAuth get auth => FirebaseAuth.instance;
  static FirebaseFirestore get firestore => FirebaseFirestore.instance;

  // Collection references
  static CollectionReference get users => firestore.collection('users');
  static CollectionReference get categories =>
      firestore.collection('categories');
  static CollectionReference get questions => firestore.collection('questions');
  static CollectionReference get liveGames =>
      firestore.collection('live_games');
  static CollectionReference get liveAnswers =>
      firestore.collection('live_answers');
  static CollectionReference get gameSchedule =>
      firestore.collection('game_schedule');
  static CollectionReference get leaderboard =>
      firestore.collection('leaderboard');

  // Legacy collections (for backward compatibility)
  static CollectionReference get quizzes => firestore.collection('quizzes');
  static CollectionReference get rooms => firestore.collection('rooms');
  static CollectionReference get scores => firestore.collection('scores');

  // Initialize Firebase
  static Future<void> initialize() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // Configure Firestore settings with optimized cache
      firestore.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: 50 * 1024 * 1024, // 50MB cache instead of unlimited
      );

      print('✅ Firebase initialized successfully!');
    } catch (e) {
      print('❌ Error initializing Firebase: $e');
      rethrow;
    }
  }

  // Helper method to get user document reference
  static DocumentReference getUserDoc(String uid) {
    return users.doc(uid);
  }

  // Helper method to get category document reference
  static DocumentReference getCategoryDoc(String categoryId) {
    return categories.doc(categoryId);
  }

  // Helper method to get question document reference
  static DocumentReference getQuestionDoc(String questionId) {
    return questions.doc(questionId);
  }

  // Helper method to get live game document reference
  static DocumentReference getLiveGameDoc(String gameId) {
    return liveGames.doc(gameId);
  }

  // Helper method to get live answer document reference
  static DocumentReference getLiveAnswerDoc(String gameId, String userId) {
    return liveAnswers.doc('${gameId}_$userId');
  }

  // Helper method to get game schedule document reference
  static DocumentReference getGameScheduleDoc(String scheduleId) {
    return gameSchedule.doc(scheduleId);
  }

  // Helper method to get leaderboard document reference
  static DocumentReference getLeaderboardDoc(String userId) {
    return leaderboard.doc(userId);
  }

  // Legacy helper methods (for backward compatibility)
  static DocumentReference getRoomDoc(String roomId) {
    return rooms.doc(roomId);
  }

  static DocumentReference getQuizDoc(String quizId) {
    return quizzes.doc(quizId);
  }

  // Generate unique game ID based on date and time
  static String generateGameId(DateTime scheduledTime) {
    return 'game_${scheduledTime.year}_${scheduledTime.month.toString().padLeft(2, '0')}_${scheduledTime.day.toString().padLeft(2, '0')}_${scheduledTime.hour.toString().padLeft(2, '0')}_${scheduledTime.minute.toString().padLeft(2, '0')}';
  }

  // Generate live answer document ID
  static String generateLiveAnswerId(String gameId, String userId) {
    return '${gameId}_$userId';
  }
}
