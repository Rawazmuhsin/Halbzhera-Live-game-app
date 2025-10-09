// File: lib/services/database_service.dart
// Description: Updated Firestore database service with live game functionality

// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/firebase_config.dart';
import '../models/user_model.dart';
import '../models/live_game_model.dart';
import '../models/scheduled_game_model.dart';
import '../models/question_model.dart';
import '../models/category_model.dart';
import '../models/joined_user_model.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseConfig.firestore;

  // ============================================================================
  // USER OPERATIONS (Same as before)
  // ============================================================================

  // Create or update user
  Future<void> createOrUpdateUser(UserModel user) async {
    try {
      // Check if user already exists
      final existingDoc = await FirebaseConfig.getUserDoc(user.uid).get();

      if (existingDoc.exists) {
        // User exists - update only necessary fields without touching firstLoginAt
        await FirebaseConfig.getUserDoc(user.uid).update({
          'email': user.email,
          'displayName': user.displayName,
          'photoURL': user.photoURL,
          'provider': user.provider.index,
          'lastSeen': FieldValue.serverTimestamp(),
          'isOnline': user.isOnline,
          // Don't update createdAt or firstLoginAt for existing users
        });
      } else {
        // New user - set both createdAt and firstLoginAt to current time
        final now = DateTime.now();
        final userWithFirstLogin = user.copyWith(
          createdAt: now,
          firstLoginAt: now,
        );
        await FirebaseConfig.getUserDoc(user.uid).set(
          userWithFirstLogin.toFirestore(),
          SetOptions(merge: false), // Don't merge for new users
        );
      }
    } catch (e) {
      throw Exception('Failed to create/update user: $e');
    }
  }

  // Get user by ID
  Future<UserModel?> getUser(String uid) async {
    try {
      final doc = await FirebaseConfig.getUserDoc(uid).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user: $e');
    }
  }

  // Get user stream
  Stream<UserModel?> getUserStream(String uid) {
    return FirebaseConfig.getUserDoc(uid).snapshots().map((doc) {
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    });
  }

  // Update user online status
  Future<void> updateUserOnlineStatus(String uid, bool isOnline) async {
    try {
      // Check if document exists first
      final docSnapshot = await FirebaseConfig.getUserDoc(uid).get();

      if (docSnapshot.exists) {
        await FirebaseConfig.getUserDoc(uid).update({
          'isOnline': isOnline,
          'lastSeen': FieldValue.serverTimestamp(),
        });
      } else {
        // Document doesn't exist, skip the update silently
        print('User document $uid not found, skipping online status update');
      }
    } catch (e) {
      // Log the error but don't throw to prevent sign-out failures
      print('Failed to update online status for $uid: $e');
    }
  }

  // Update user score
  Future<void> updateUserScore(String uid, int scoreToAdd) async {
    try {
      // Check if document exists first
      final docSnapshot = await FirebaseConfig.getUserDoc(uid).get();

      if (docSnapshot.exists) {
        await FirebaseConfig.getUserDoc(uid).update({
          'totalScore': FieldValue.increment(scoreToAdd),
          'gamesPlayed': FieldValue.increment(1),
          'lastSeen': FieldValue.serverTimestamp(),
        });
      } else {
        print('User document $uid not found, skipping score update');
      }
    } catch (e) {
      throw Exception('Failed to update user score: $e');
    }
  }

  // Update user win count (separate method for better tracking)
  Future<void> updateUserWinCount(String uid) async {
    try {
      final docSnapshot = await FirebaseConfig.getUserDoc(uid).get();

      if (docSnapshot.exists) {
        await FirebaseConfig.getUserDoc(uid).update({
          'gamesWon': FieldValue.increment(1),
          'lastSeen': FieldValue.serverTimestamp(),
        });
      } else {
        print('User document $uid not found, skipping win count update');
      }
    } catch (e) {
      throw Exception('Failed to update user win count: $e');
    }
  }

  // ============================================================================
  // LIVE GAME OPERATIONS
  // ============================================================================

  // Create a new live game
  Future<String> createLiveGame(LiveGameModel game) async {
    try {
      final gameId = FirebaseConfig.generateGameId(game.scheduledTime);
      final gameWithId = game.copyWith(id: gameId);

      await FirebaseConfig.getLiveGameDoc(gameId).set(gameWithId.toFirestore());
      return gameId;
    } catch (e) {
      throw Exception('Failed to create live game: $e');
    }
  }

  // Get live game by ID
  Future<LiveGameModel?> getLiveGame(String gameId) async {
    try {
      final doc = await FirebaseConfig.getLiveGameDoc(gameId).get();
      if (doc.exists) {
        return LiveGameModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get live game: $e');
    }
  }

  // Get current live game
  Stream<LiveGameModel?> getCurrentLiveGameStream() {
    return FirebaseConfig.liveGames
        .where('status', isEqualTo: LiveGameStatus.live.index)
        .limit(1)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.isNotEmpty
                  ? LiveGameModel.fromFirestore(snapshot.docs.first)
                  : null,
        );
  }

  // Get upcoming live games
  Stream<List<LiveGameModel>> getUpcomingGamesStream() {
    return FirebaseConfig.liveGames
        .where('scheduledTime', isGreaterThan: Timestamp.now())
        .where(
          'status',
          whereIn: [
            LiveGameStatus.scheduled.index,
            LiveGameStatus.waiting.index,
          ],
        )
        .orderBy('scheduledTime')
        .limit(10)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => LiveGameModel.fromFirestore(doc))
                  .toList(),
        );
  }

  // Get live game stream
  Stream<LiveGameModel?> getLiveGameStream(String gameId) {
    return FirebaseConfig.getLiveGameDoc(gameId).snapshots().map((doc) {
      if (doc.exists) {
        return LiveGameModel.fromFirestore(doc);
      }
      return null;
    });
  }

  // Join live game
  Future<void> joinLiveGame(String gameId, UserModel user) async {
    try {
      await FirebaseConfig.getLiveGameDoc(gameId).update({
        'participants.${user.uid}': {
          'displayName': user.displayName,
          'photoURL': user.photoURL,
          'joinedAt': FieldValue.serverTimestamp(),
          'isActive': true,
        },
      });

      // Create live answer document for the user
      final liveAnswer = LiveAnswerModel(
        gameId: gameId,
        userId: user.uid,
        displayName: user.displayName ?? 'Player',
        photoURL: user.photoURL,
        lastAnswerAt: DateTime.now(),
      );

      await FirebaseConfig.getLiveAnswerDoc(
        gameId,
        user.uid,
      ).set(liveAnswer.toFirestore());
    } catch (e) {
      throw Exception('Failed to join live game: $e');
    }
  }

  // Leave live game
  Future<void> leaveLiveGame(String gameId, String userId) async {
    try {
      await FirebaseConfig.getLiveGameDoc(
        gameId,
      ).update({'participants.$userId': FieldValue.delete()});

      await FirebaseConfig.getLiveAnswerDoc(
        gameId,
        userId,
      ).update({'isActive': false});
    } catch (e) {
      throw Exception('Failed to leave live game: $e');
    }
  }

  // Start live game
  Future<void> startLiveGame(String gameId) async {
    try {
      await FirebaseConfig.getLiveGameDoc(gameId).update({
        'status': LiveGameStatus.live.index,
        'startedAt': FieldValue.serverTimestamp(),
        'currentQuestion': 0,
        'currentQuestionStartTime': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to start live game: $e');
    }
  }

  // Move to next question
  Future<void> moveToNextQuestion(String gameId, int nextQuestionIndex) async {
    try {
      await FirebaseConfig.getLiveGameDoc(gameId).update({
        'currentQuestion': nextQuestionIndex,
        'currentQuestionStartTime': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to move to next question: $e');
    }
  }

  // Finish live game
  Future<void> finishLiveGame(String gameId) async {
    try {
      await FirebaseConfig.getLiveGameDoc(gameId).update({
        'status': LiveGameStatus.finished.index,
        'finishedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to finish live game: $e');
    }
  }

  // ============================================================================
  // LIVE ANSWER OPERATIONS
  // ============================================================================

  // Submit answer for live game with elimination logic
  Future<bool> submitLiveAnswerWithElimination({
    required String gameId,
    required String userId,
    required int questionIndex,
    required String answer,
    required String questionId,
  }) async {
    try {
      // 1. Get the correct answer from question
      final question = await getQuestion(questionId);
      if (question == null) {
        throw Exception('Question not found');
      }

      final correctAnswer = question['correctAnswer'] as String? ?? '';
      final isCorrect =
          answer.toLowerCase().trim() == correctAnswer.toLowerCase().trim();
      final points = question['points'] as int? ?? 10;

      // 2. Calculate time taken (you might want to pass this as parameter)
      final timeTaken =
          10.0; // Default, should be calculated from question start time

      // 3. Submit the answer
      final answerData = {
        'answer': answer,
        'isCorrect': isCorrect,
        'submittedAt': FieldValue.serverTimestamp(),
        'timeTaken': timeTaken,
        'points': isCorrect ? points : 0,
      };

      await FirebaseConfig.getLiveAnswerDoc(gameId, userId).update({
        'answers.$questionIndex': answerData,
        'totalScore': FieldValue.increment(isCorrect ? points : 0),
        'correctAnswers':
            isCorrect ? FieldValue.increment(1) : FieldValue.increment(0),
        'lastAnswerAt': FieldValue.serverTimestamp(),
      });

      // 4. If wrong answer, eliminate user
      if (!isCorrect) {
        await eliminateUser(gameId, userId, questionIndex, 'wrong_answer');
      }

      // 5. Check if game should end
      await checkAndEndGame(gameId);

      return isCorrect;
    } catch (e) {
      throw Exception('Failed to submit live answer: $e');
    }
  }

  // Eliminate user from live game
  Future<void> eliminateUser(
    String gameId,
    String userId,
    int questionIndex,
    String reason,
  ) async {
    try {
      await FirebaseConfig.getLiveAnswerDoc(gameId, userId).update({
        'isEliminated': true,
        'eliminatedAtQuestion': questionIndex,
        'eliminationReason': reason,
        'isActive': false,
      });

      print(
        'User $userId eliminated from game $gameId at question $questionIndex',
      );
    } catch (e) {
      throw Exception('Failed to eliminate user: $e');
    }
  }

  // Get active (non-eliminated) players in game
  Future<List<LiveAnswerModel>> getActivePlayersInGame(String gameId) async {
    try {
      final snapshot =
          await FirebaseConfig.liveAnswers
              .where('gameId', isEqualTo: gameId)
              .where('isEliminated', isEqualTo: false)
              .where('isActive', isEqualTo: true)
              .get();

      return snapshot.docs
          .map((doc) => LiveAnswerModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get active players: $e');
    }
  }

  // Get eliminated players in game
  Future<List<LiveAnswerModel>> getEliminatedPlayersInGame(
    String gameId,
  ) async {
    try {
      final snapshot =
          await FirebaseConfig.liveAnswers
              .where('gameId', isEqualTo: gameId)
              .where('isEliminated', isEqualTo: true)
              .orderBy('eliminatedAtQuestion')
              .get();

      return snapshot.docs
          .map((doc) => LiveAnswerModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get eliminated players: $e');
    }
  }

  // Check if game should end and end it if necessary
  Future<void> checkAndEndGame(String gameId) async {
    try {
      final activePlayers = await getActivePlayersInGame(gameId);

      // End game if 1 or fewer players remain
      if (activePlayers.length <= 1) {
        if (activePlayers.isNotEmpty) {
          // We have a winner
          await endGameWithWinner(gameId, activePlayers.first.userId);
        } else {
          // No winners (everyone eliminated)
          await endGameWithNoWinner(gameId);
        }
      }
    } catch (e) {
      print('Error checking game end condition: $e');
    }
  }

  // End game with a winner
  Future<void> endGameWithWinner(String gameId, String winnerId) async {
    try {
      await FirebaseConfig.getLiveGameDoc(gameId).update({
        'status': LiveGameStatus.finished.index,
        'finishedAt': FieldValue.serverTimestamp(),
        'winnerId': winnerId,
        'endReason': 'winner_found',
      });

      // Update winner's score and stats with bonus points for winning
      await updateUserScore(winnerId, 500); // Bonus points for winning
      await updateUserWinCount(winnerId); // Increment win count

      print('Game $gameId ended with winner: $winnerId');
    } catch (e) {
      throw Exception('Failed to end game with winner: $e');
    }
  }

  // End game with no winner (everyone eliminated)
  Future<void> endGameWithNoWinner(String gameId) async {
    try {
      await FirebaseConfig.getLiveGameDoc(gameId).update({
        'status': LiveGameStatus.finished.index,
        'finishedAt': FieldValue.serverTimestamp(),
        'winnerId': null,
        'endReason': 'no_survivors',
      });

      print('Game $gameId ended with no winner');
    } catch (e) {
      throw Exception('Failed to end game with no winner: $e');
    }
  }

  // Eliminate user due to timeout
  Future<void> eliminateUserTimeout(
    String gameId,
    String userId,
    int questionIndex,
  ) async {
    await eliminateUser(gameId, userId, questionIndex, 'timeout');
  }

  // Get game statistics including elimination data
  Future<Map<String, dynamic>> getGameEliminationStats(String gameId) async {
    try {
      final allAnswers =
          await FirebaseConfig.liveAnswers
              .where('gameId', isEqualTo: gameId)
              .get();

      final players =
          allAnswers.docs
              .map((doc) => LiveAnswerModel.fromFirestore(doc))
              .toList();

      final activePlayers = players.where((p) => !p.isEliminated).length;
      final eliminatedPlayers = players.where((p) => p.isEliminated).length;
      final totalPlayers = players.length;

      // Group eliminations by question
      final eliminationsByQuestion = <int, int>{};
      for (final player in players.where((p) => p.isEliminated)) {
        final questionIndex = player.eliminatedAtQuestion ?? 0;
        eliminationsByQuestion[questionIndex] =
            (eliminationsByQuestion[questionIndex] ?? 0) + 1;
      }

      return {
        'totalPlayers': totalPlayers,
        'activePlayers': activePlayers,
        'eliminatedPlayers': eliminatedPlayers,
        'eliminationsByQuestion': eliminationsByQuestion,
        'survivalRate':
            totalPlayers > 0 ? (activePlayers / totalPlayers) * 100 : 0.0,
      };
    } catch (e) {
      throw Exception('Failed to get game elimination stats: $e');
    }
  }

  // Check if user is eliminated in specific game
  Future<bool> isUserEliminated(String gameId, String userId) async {
    try {
      final doc = await FirebaseConfig.getLiveAnswerDoc(gameId, userId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return data['isEliminated'] ?? false;
      }
      return false;
    } catch (e) {
      print('Error checking if user is eliminated: $e');
      return false;
    }
  }

  // Get live leaderboard (only active players)
  Stream<List<LiveAnswerModel>> getLiveLeaderboardStream(String gameId) {
    return FirebaseConfig.liveAnswers
        .where('gameId', isEqualTo: gameId)
        .where('isEliminated', isEqualTo: false) // Only non-eliminated players
        .where('isActive', isEqualTo: true)
        .orderBy('totalScore', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => LiveAnswerModel.fromFirestore(doc))
                  .toList(),
        );
  }

  // Get all players leaderboard (including eliminated)
  Stream<List<LiveAnswerModel>> getAllPlayersLeaderboardStream(String gameId) {
    return FirebaseConfig.liveAnswers
        .where('gameId', isEqualTo: gameId)
        .orderBy('totalScore', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => LiveAnswerModel.fromFirestore(doc))
                  .toList(),
        );
  }

  // Get user's live answer
  Stream<LiveAnswerModel?> getUserLiveAnswerStream(
    String gameId,
    String userId,
  ) {
    return FirebaseConfig.getLiveAnswerDoc(gameId, userId).snapshots().map((
      doc,
    ) {
      if (doc.exists) {
        return LiveAnswerModel.fromFirestore(doc);
      }
      return null;
    });
  }

  // ============================================================================
  // GAME SCHEDULE OPERATIONS
  // ============================================================================

  // Create game schedule
  Future<String> createGameSchedule(GameScheduleModel schedule) async {
    try {
      final docRef = await FirebaseConfig.gameSchedule.add(
        schedule.toFirestore(),
      );
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create game schedule: $e');
    }
  }

  // Get all game schedules
  Future<List<GameScheduleModel>> getGameSchedules() async {
    try {
      final snapshot =
          await FirebaseConfig.gameSchedule
              .where('isActive', isEqualTo: true)
              .orderBy('dayOfWeek')
              .orderBy('time')
              .get();

      return snapshot.docs
          .map((doc) => GameScheduleModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get game schedules: $e');
    }
  }

  // Update game schedule
  Future<void> updateGameSchedule(
    String scheduleId,
    Map<String, dynamic> data,
  ) async {
    try {
      await FirebaseConfig.getGameScheduleDoc(scheduleId).update(data);
    } catch (e) {
      throw Exception('Failed to update game schedule: $e');
    }
  }

  // Delete game schedule
  Future<void> deleteGameSchedule(String scheduleId) async {
    try {
      await FirebaseConfig.getGameScheduleDoc(scheduleId).delete();
    } catch (e) {
      throw Exception('Failed to delete game schedule: $e');
    }
  }

  // ============================================================================
  // CATEGORY OPERATIONS
  // ============================================================================

  // Create category
  Future<String> createCategory(Map<String, dynamic> categoryData) async {
    try {
      final docRef = await FirebaseConfig.categories.add({
        ...categoryData,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create category: $e');
    }
  }

  // Get categories
  Future<List<Map<String, dynamic>>> getCategories() async {
    try {
      final snapshot =
          await FirebaseConfig.categories
              .where('isActive', isEqualTo: true)
              .orderBy('name')
              .get();

      return snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
          .toList();
    } catch (e) {
      throw Exception('Failed to get categories: $e');
    }
  }

  // Get category by ID
  Future<Map<String, dynamic>?> getCategory(String categoryId) async {
    try {
      final doc = await FirebaseConfig.getCategoryDoc(categoryId).get();
      if (doc.exists) {
        return {'id': doc.id, ...doc.data() as Map<String, dynamic>};
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get category: $e');
    }
  }

  // Update category
  Future<void> updateCategory(
    String categoryId,
    Map<String, dynamic> data,
  ) async {
    try {
      await FirebaseConfig.getCategoryDoc(
        categoryId,
      ).update({...data, 'updatedAt': FieldValue.serverTimestamp()});
    } catch (e) {
      throw Exception('Failed to update category: $e');
    }
  }

  // ============================================================================
  // QUESTION OPERATIONS
  // ============================================================================

  // Create question
  Future<String> createQuestion(Map<String, dynamic> questionData) async {
    try {
      final docRef = await FirebaseConfig.questions.add({
        ...questionData,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create question: $e');
    }
  }

  // Get questions by category
  Future<List<Map<String, dynamic>>> getQuestionsByCategory(
    String categoryId,
  ) async {
    try {
      final snapshot =
          await FirebaseConfig.questions
              .where('categoryId', isEqualTo: categoryId)
              .where('isActive', isEqualTo: true)
              .orderBy('order')
              .get();

      return snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
          .toList();
    } catch (e) {
      throw Exception('Failed to get questions by category: $e');
    }
  }

  // Get random questions for live game
  Future<List<String>> getRandomQuestionsForLiveGame(
    String categoryId,
    int count,
  ) async {
    try {
      final snapshot =
          await FirebaseConfig.questions
              .where('categoryId', isEqualTo: categoryId)
              .where('isActive', isEqualTo: true)
              .get();

      if (snapshot.docs.length < count) {
        throw Exception('Not enough questions in category for live game');
      }

      // Shuffle and take required count
      final allQuestions = snapshot.docs.map((doc) => doc.id).toList();
      allQuestions.shuffle();
      return allQuestions.take(count).toList();
    } catch (e) {
      throw Exception('Failed to get random questions: $e');
    }
  }

  // Get question by ID
  Future<Map<String, dynamic>?> getQuestion(String questionId) async {
    try {
      final doc = await FirebaseConfig.getQuestionDoc(questionId).get();
      if (doc.exists) {
        return {'id': doc.id, ...doc.data() as Map<String, dynamic>};
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get question: $e');
    }
  }

  // Update question
  Future<void> updateQuestion(
    String questionId,
    Map<String, dynamic> data,
  ) async {
    try {
      await FirebaseConfig.getQuestionDoc(
        questionId,
      ).update({...data, 'updatedAt': FieldValue.serverTimestamp()});
    } catch (e) {
      throw Exception('Failed to update question: $e');
    }
  }

  // Bulk create questions
  Future<List<String>> bulkCreateQuestions(
    List<Map<String, dynamic>> questionsData,
  ) async {
    try {
      final batch = _firestore.batch();
      final questionIds = <String>[];

      for (final questionData in questionsData) {
        final docRef = FirebaseConfig.questions.doc();
        questionIds.add(docRef.id);

        batch.set(docRef, {
          ...questionData,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
      return questionIds;
    } catch (e) {
      throw Exception('Failed to bulk create questions: $e');
    }
  }

  // ============================================================================
  // LEADERBOARD OPERATIONS
  // ============================================================================

  // Update global leaderboard
  Future<void> updateGlobalLeaderboard(String userId, int scoreToAdd) async {
    try {
      await FirebaseConfig.getLeaderboardDoc(userId).set({
        'userId': userId,
        'totalScore': FieldValue.increment(scoreToAdd),
        'gamesPlayed': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to update leaderboard: $e');
    }
  }

  // Get global leaderboard
  Future<List<UserModel>> getLeaderboard({int limit = 10}) async {
    try {
      final querySnapshot =
          await FirebaseConfig.users
              .orderBy('totalScore', descending: true)
              .limit(limit)
              .get();

      return querySnapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get leaderboard: $e');
    }
  }

  // ============================================================================
  // ADMIN OPERATIONS
  // ============================================================================

  // Get all users for admin
  Future<List<UserModel>> getAllUsers({int limit = 100}) async {
    try {
      final snapshot =
          await FirebaseConfig.users
              .orderBy('createdAt', descending: true)
              .limit(limit)
              .get();

      return snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Failed to get all users: $e');
    }
  }

  // Get users with pagination
  Stream<List<UserModel>> getUsersPaginated({
    int limit = 20,
    DocumentSnapshot? lastDoc,
  }) {
    Query query = FirebaseConfig.users
        .orderBy('createdAt', descending: true)
        .limit(limit);

    if (lastDoc != null) {
      query = query.startAfterDocument(lastDoc);
    }

    return query.snapshots().map(
      (snapshot) =>
          snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList(),
    );
  }

  // Get live game statistics
  Future<Map<String, dynamic>> getLiveGameStats() async {
    try {
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final todayEnd = todayStart.add(const Duration(days: 1));

      // Get today's games
      final todayGames =
          await FirebaseConfig.liveGames
              .where(
                'scheduledTime',
                isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart),
              )
              .where('scheduledTime', isLessThan: Timestamp.fromDate(todayEnd))
              .get();

      // Get total games
      final totalGames = await FirebaseConfig.liveGames.get();

      // Get active participants
      final activeAnswers =
          await FirebaseConfig.liveAnswers
              .where('isActive', isEqualTo: true)
              .get();

      return {
        'todayGames': todayGames.docs.length,
        'totalGames': totalGames.docs.length,
        'activeParticipants': activeAnswers.docs.length,
        'totalUsers': (await FirebaseConfig.users.get()).docs.length,
      };
    } catch (e) {
      throw Exception('Failed to get live game stats: $e');
    }
  }

  // ============================================================================
  // UTILITY METHODS
  // ============================================================================

  // Migrate user data to fix field name inconsistencies
  // This should only run ONCE per app installation
  Future<void> migrateUserDataFields() async {
    try {
      // Check if migration already ran using SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final migrationKey = 'user_data_migration_v1_completed';
      final alreadyMigrated = prefs.getBool(migrationKey) ?? false;

      if (alreadyMigrated) {
        print('✅ User data migration already completed, skipping...');
        return;
      }

      print('Starting user data migration...');

      // Get all users
      final usersSnapshot = await FirebaseConfig.users.get();
      final batch = _firestore.batch();
      int migratedCount = 0;

      for (final userDoc in usersSnapshot.docs) {
        final data = userDoc.data() as Map<String, dynamic>;
        bool needsUpdate = false;
        Map<String, dynamic> updates = {};

        // Check if user has totalGamesPlayed instead of gamesPlayed
        if (data.containsKey('totalGamesPlayed') &&
            !data.containsKey('gamesPlayed')) {
          updates['gamesPlayed'] = data['totalGamesPlayed'];
          needsUpdate = true;
        }

        // Ensure all required fields exist with default values
        if (!data.containsKey('gamesPlayed')) {
          updates['gamesPlayed'] = 0;
          needsUpdate = true;
        }
        if (!data.containsKey('gamesWon')) {
          updates['gamesWon'] = 0;
          needsUpdate = true;
        }
        if (!data.containsKey('totalScore')) {
          updates['totalScore'] = 0;
          needsUpdate = true;
        }

        // Migrate firstLoginAt field - use createdAt if firstLoginAt doesn't exist
        if (!data.containsKey('firstLoginAt') &&
            data.containsKey('createdAt')) {
          updates['firstLoginAt'] = data['createdAt'];
          needsUpdate = true;
        }

        if (needsUpdate) {
          batch.update(userDoc.reference, updates);
          migratedCount++;
        }
      }

      if (migratedCount > 0) {
        await batch.commit();
        print('✅ Migrated $migratedCount user records');
      } else {
        print('✅ No user records needed migration');
      }

      // Mark migration as completed
      await prefs.setBool(migrationKey, true);
      print('✅ User data migration marked as completed');
    } catch (e) {
      print('❌ Error during user data migration: $e');
      // Don't throw - let the app continue even if migration fails
    }
  }

  // Delete user
  Future<void> deleteUser(String uid) async {
    try {
      await FirebaseConfig.getUserDoc(uid).delete();
    } catch (e) {
      throw Exception('Failed to delete user: $e');
    }
  }

  // Get user's game history
  Future<List<Map<String, dynamic>>> getUserGameHistory(
    String userId, {
    int limit = 20,
  }) async {
    try {
      final snapshot =
          await FirebaseConfig.liveAnswers
              .where('userId', isEqualTo: userId)
              .orderBy('lastAnswerAt', descending: true)
              .limit(limit)
              .get();

      return snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
          .toList();
    } catch (e) {
      throw Exception('Failed to get user game history: $e');
    }
  }

  // Batch update multiple documents
  Future<void> batchUpdate(List<Map<String, dynamic>> updates) async {
    try {
      final batch = _firestore.batch();

      for (final update in updates) {
        final docRef = _firestore.doc(update['path']);
        batch.update(docRef, update['data']);
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to perform batch update: $e');
    }
  }

  // Clean up old games (admin utility)
  Future<void> cleanupOldGames({int daysOld = 30}) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));

      final oldGames =
          await FirebaseConfig.liveGames
              .where('finishedAt', isLessThan: Timestamp.fromDate(cutoffDate))
              .get();

      final batch = _firestore.batch();

      for (final doc in oldGames.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to cleanup old games: $e');
    }
  }

  // ============================================================================
  // SCHEDULED GAMES OPERATIONS
  // ============================================================================

  // Create scheduled game
  Future<String> createScheduledGame(ScheduledGameModel game) async {
    try {
      final docRef = _firestore.collection('scheduled_games').doc();
      final gameWithId = game.copyWith(id: docRef.id);

      await docRef.set(gameWithId.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create scheduled game: $e');
    }
  }

  // Update scheduled game
  Future<void> updateScheduledGame(ScheduledGameModel game) async {
    try {
      await _firestore
          .collection('scheduled_games')
          .doc(game.id)
          .update(game.toMap());
    } catch (e) {
      throw Exception('Failed to update scheduled game: $e');
    }
  }

  // Get scheduled game by ID
  Future<ScheduledGameModel?> getScheduledGame(String gameId) async {
    try {
      final doc =
          await _firestore.collection('scheduled_games').doc(gameId).get();

      if (doc.exists) {
        return ScheduledGameModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get scheduled game: $e');
    }
  }

  // Get all scheduled games
  Stream<List<ScheduledGameModel>> getScheduledGamesStream() {
    return _firestore
        .collection('scheduled_games')
        .orderBy('scheduledTime')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => ScheduledGameModel.fromFirestore(doc))
                  .toList(),
        );
  }

  // Get upcoming scheduled games
  Stream<List<ScheduledGameModel>> getUpcomingScheduledGamesStream({
    int limit = 5,
  }) {
    return _firestore
        .collection('scheduled_games')
        .where('status', isEqualTo: GameStatus.scheduled.index)
        .orderBy('scheduledTime')
        .limit(limit) // Limit for better performance
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => ScheduledGameModel.fromFirestore(doc))
                  .where((game) => game.scheduledTime.isAfter(DateTime.now()))
                  .toList(),
        );
  }

  // Get scheduled games by category
  Stream<List<ScheduledGameModel>> getScheduledGamesByCategoryStream(
    String categoryId,
  ) {
    return _firestore
        .collection('scheduled_games')
        .where('categoryId', isEqualTo: categoryId)
        .orderBy('scheduledTime')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => ScheduledGameModel.fromFirestore(doc))
                  .toList(),
        );
  }

  // Delete scheduled game
  Future<void> deleteScheduledGame(String gameId) async {
    try {
      await _firestore.collection('scheduled_games').doc(gameId).delete();
    } catch (e) {
      throw Exception('Failed to delete scheduled game: $e');
    }
  }

  // Update game status
  Future<void> updateGameStatus(String gameId, GameStatus status) async {
    try {
      await _firestore.collection('scheduled_games').doc(gameId).update({
        'status': status.index,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Failed to update game status: $e');
    }
  }

  // Start scheduled game (convert to live game)
  Future<String> startScheduledGame(String scheduledGameId) async {
    try {
      final scheduledGame = await getScheduledGame(scheduledGameId);
      if (scheduledGame == null) {
        throw Exception('Scheduled game not found');
      }

      // Create live game from scheduled game
      final liveGame = LiveGameModel(
        id: '', // Will be set by createLiveGame
        title: scheduledGame.name,
        category: scheduledGame.categoryName,
        scheduledTime: scheduledGame.scheduledTime,
        status: LiveGameStatus.waiting,
        totalQuestions: scheduledGame.questionsCount,
        currentQuestion: 0,
        timePerQuestion: 10, // Default 10 seconds per question
        questions: [], // Questions will be loaded separately
        participants: {},
        createdBy: scheduledGame.createdBy,
        createdAt: DateTime.now(),
      );

      // Create the live game
      final liveGameId = await createLiveGame(liveGame);

      // Update scheduled game status to live
      await updateGameStatus(scheduledGameId, GameStatus.live);

      return liveGameId;
    } catch (e) {
      throw Exception('Failed to start scheduled game: $e');
    }
  }

  // Get games ready to start
  Future<List<ScheduledGameModel>> getGamesReadyToStart() async {
    try {
      final now = DateTime.now();
      final fiveMinutesAgo = now.subtract(const Duration(minutes: 5));

      final snapshot =
          await _firestore
              .collection('scheduled_games')
              .where('status', isEqualTo: GameStatus.scheduled.index)
              .where(
                'scheduledTime',
                isLessThanOrEqualTo: Timestamp.fromDate(now),
              )
              .where(
                'scheduledTime',
                isGreaterThanOrEqualTo: Timestamp.fromDate(fiveMinutesAgo),
              )
              .get();

      return snapshot.docs
          .map((doc) => ScheduledGameModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get games ready to start: $e');
    }
  }

  // ============================================================================
  // QUESTION STREAM OPERATIONS
  // ============================================================================

  // Get categories stream
  Stream<List<CategoryModel>> getCategoriesStream() {
    return FirebaseConfig.categories
        .where('isActive', isEqualTo: true)
        .orderBy('name')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => CategoryModel.fromFirestore(doc))
                  .toList(),
        );
  }

  // Get questions by category stream
  Stream<List<QuestionModel>> getQuestionsByCategoryStream(String categoryId) {
    return FirebaseConfig.questions
        .where('category', isEqualTo: categoryId)
        .where('isActive', isEqualTo: true)
        // .orderBy('order') // Temporarily commented out until index is built
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => QuestionModel.fromFirestore(doc))
                  .toList()
                ..sort(
                  (a, b) => a.order.compareTo(b.order),
                ), // Sort in memory instead
        );
  }

  // Get all questions stream (for admin)
  Stream<List<QuestionModel>> getAllQuestionsStream() {
    return FirebaseConfig.questions
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => QuestionModel.fromFirestore(doc))
                  .toList(),
        );
  }

  // Get question statistics
  Future<Map<String, dynamic>> getQuestionStatistics() async {
    try {
      final questionsSnapshot =
          await FirebaseConfig.questions
              .where('isActive', isEqualTo: true)
              .get();

      final categoriesSnapshot =
          await FirebaseConfig.categories
              .where('isActive', isEqualTo: true)
              .get();

      final totalQuestions = questionsSnapshot.docs.length;
      final totalCategories = categoriesSnapshot.docs.length;

      // Count questions by difficulty
      int easyCount = 0;
      int mediumCount = 0;
      int hardCount = 0;

      for (final doc in questionsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final difficulty = data['difficulty'] ?? 0;
        switch (difficulty) {
          case 0:
            easyCount++;
            break;
          case 1:
            mediumCount++;
            break;
          case 2:
            hardCount++;
            break;
        }
      }

      // Count questions by type
      int multipleChoiceCount = 0;
      int trueFalseCount = 0;
      int fillInBlankCount = 0;

      for (final doc in questionsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final type = data['type'] ?? 0;
        switch (type) {
          case 0:
            multipleChoiceCount++;
            break;
          case 1:
            trueFalseCount++;
            break;
          case 2:
            fillInBlankCount++;
            break;
        }
      }

      return {
        'totalQuestions': totalQuestions,
        'totalCategories': totalCategories,
        'byDifficulty': {
          'easy': easyCount,
          'medium': mediumCount,
          'hard': hardCount,
        },
        'byType': {
          'multipleChoice': multipleChoiceCount,
          'trueFalse': trueFalseCount,
          'fillInBlank': fillInBlankCount,
        },
      };
    } catch (e) {
      throw Exception('Failed to get question statistics: $e');
    }
  }

  // Delete question (hard delete - permanently removes from database)
  Future<void> deleteQuestion(String questionId) async {
    try {
      await FirebaseConfig.getQuestionDoc(questionId).delete();
    } catch (e) {
      throw Exception('Failed to delete question: $e');
    }
  }

  // ============================================================================
  // JOINED USERS METHODS
  // ============================================================================

  // Add user to joined_users collection when they join a game
  Future<String> joinGame({
    required String gameId,
    required String userId,
    required String userEmail,
    String? userDisplayName,
    String? userPhotoUrl,
    required String accountType,
    String? guestAccountNumber,
  }) async {
    try {
      // Check if user already joined this game
      final existingJoin =
          await _firestore
              .collection('joined_users')
              .where('gameId', isEqualTo: gameId)
              .where('userId', isEqualTo: userId)
              .where('isActive', isEqualTo: true)
              .get();

      if (existingJoin.docs.isNotEmpty) {
        throw Exception('کاربەر پێشتر بەشداری ئەم یارییە کردووە');
      }

      // Create joined user document
      final joinedUserData = {
        'gameId': gameId,
        'userId': userId,
        'userEmail': userEmail,
        'userDisplayName': userDisplayName,
        'userPhotoUrl': userPhotoUrl,
        'accountType': accountType,
        'guestAccountNumber': guestAccountNumber,
        'joinedAt': Timestamp.now(),
        'isActive': true,
      };

      final docRef = await _firestore
          .collection('joined_users')
          .add(joinedUserData);

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to join game: $e');
    }
  }

  // Get joined users for a specific game
  Stream<List<JoinedUserModel>> getJoinedUsersStream(String gameId) {
    return _firestore
        .collection('joined_users')
        .where('gameId', isEqualTo: gameId)
        .where('isActive', isEqualTo: true)
        .orderBy('joinedAt', descending: false)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => JoinedUserModel.fromFirestore(doc))
                  .toList(),
        );
  }

  // Get all games joined by a specific user
  Stream<List<JoinedUserModel>> getUserJoinedGamesStream(
    String userId, {
    int limit = 10,
  }) {
    return _firestore
        .collection('joined_users')
        .where('userId', isEqualTo: userId)
        .where('isActive', isEqualTo: true)
        .orderBy('joinedAt', descending: true)
        .limit(limit) // Limit results for better performance
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => JoinedUserModel.fromFirestore(doc))
                  .toList(),
        );
  }

  // Check if user has joined a specific game
  Future<bool> hasUserJoinedGame(String gameId, String userId) async {
    try {
      final result =
          await _firestore
              .collection('joined_users')
              .where('gameId', isEqualTo: gameId)
              .where('userId', isEqualTo: userId)
              .where('isActive', isEqualTo: true)
              .get();

      return result.docs.isNotEmpty;
    } catch (e) {
      throw Exception('Failed to check if user joined game: $e');
    }
  }

  // Remove user from game (set isActive to false)
  Future<void> leaveGame(String gameId, String userId) async {
    try {
      final joinedUserDocs =
          await _firestore
              .collection('joined_users')
              .where('gameId', isEqualTo: gameId)
              .where('userId', isEqualTo: userId)
              .where('isActive', isEqualTo: true)
              .get();

      for (final doc in joinedUserDocs.docs) {
        await doc.reference.update({
          'isActive': false,
          'leftAt': Timestamp.now(),
        });
      }
    } catch (e) {
      throw Exception('Failed to leave game: $e');
    }
  }

  // Get count of joined users for a game
  Future<int> getJoinedUserCount(String gameId) async {
    try {
      final result =
          await _firestore
              .collection('joined_users')
              .where('gameId', isEqualTo: gameId)
              .where('isActive', isEqualTo: true)
              .get();

      return result.docs.length;
    } catch (e) {
      throw Exception('Failed to get joined user count: $e');
    }
  }

  // Migrate existing winners from game_results to winners collection
  Future<void> migrateExistingWinners() async {
    try {
      // Get all winners from game_results collection
      final snapshot =
          await FirebaseFirestore.instance
              .collection('game_results')
              .where('isWinner', isEqualTo: true)
              .get();

      print('Found ${snapshot.docs.length} existing winners to migrate');

      // Batch write to winners collection
      final batch = FirebaseFirestore.instance.batch();
      int migratedCount = 0;

      for (final doc in snapshot.docs) {
        final data = doc.data();

        // Check if this winner already exists in the winners collection
        final existingWinnerQuery =
            await FirebaseFirestore.instance
                .collection('winners')
                .where('gameId', isEqualTo: data['gameId'])
                .where('userId', isEqualTo: data['userId'])
                .get();

        if (existingWinnerQuery.docs.isEmpty) {
          // Create a new document in winners collection with the same data
          // Remove eliminatedAtQuestion field which doesn't apply to winners
          final winnerData = Map<String, dynamic>.from(data);
          winnerData.remove('eliminatedAtQuestion');
          winnerData.remove('isWinner'); // Not needed in winners collection

          final winnersRef =
              FirebaseFirestore.instance.collection('winners').doc();
          batch.set(winnersRef, winnerData);
          migratedCount++;
        }
      }

      if (migratedCount > 0) {
        // Commit the batch
        await batch.commit();
        print(
          'Successfully migrated $migratedCount winners to winners collection',
        );
      } else {
        print('No new winners to migrate');
      }
    } catch (e) {
      print('Error migrating winners: $e');
      rethrow;
    }
  }

  // ============================================================================
  // LEADERBOARD OPERATIONS
  // ============================================================================

  // Get top winners across all games for the leaderboard
  Future<List<Map<String, dynamic>>> getTopWinners({int limit = 10}) async {
    try {
      print('Fetching top $limit winners across all games');

      // Query all winners
      final winnersSnapshot =
          await _firestore
              .collection('winners')
              .orderBy('completedAt', descending: true)
              .limit(100) // Get more than we need for aggregation
              .get();

      if (winnersSnapshot.docs.isEmpty) {
        print('No winners found in the database');
        return [];
      }

      // Group winners by userId and aggregate their stats
      final Map<String, Map<String, dynamic>> userStats = {};

      for (final doc in winnersSnapshot.docs) {
        final data = doc.data();
        final userId = data['userId'] as String;

        if (!userStats.containsKey(userId)) {
          userStats[userId] = {
            'userId': userId,
            'displayName': data['userDisplayName'] ?? 'Unknown User',
            'photoUrl': data['userPhotoUrl'],
            'email': data['userEmail'],
            'gamesWon': 0,
            'totalScore': 0,
            'lastWin': data['completedAt'],
          };
        }

        userStats[userId]!['gamesWon'] =
            (userStats[userId]!['gamesWon'] as int) + 1;
        userStats[userId]!['totalScore'] =
            (userStats[userId]!['totalScore'] as int) +
            (data['score'] as int? ?? 0);

        // Update last win time if this is more recent
        final currentLastWin = userStats[userId]!['lastWin'];
        final thisWin = data['completedAt'];
        if (thisWin != null &&
            (currentLastWin == null ||
                (thisWin is Timestamp &&
                    currentLastWin is Timestamp &&
                    thisWin.compareTo(currentLastWin) > 0))) {
          userStats[userId]!['lastWin'] = thisWin;
        }
      }

      // Convert to list, sort by games won (descending) then total score
      final List<Map<String, dynamic>> leaderboard = userStats.values.toList();

      // Convert totalScore to score for consistency in the UI
      for (final user in leaderboard) {
        user['score'] = user['totalScore'];
      }

      leaderboard.sort((a, b) {
        final gamesComparison = (b['gamesWon'] as int).compareTo(
          a['gamesWon'] as int,
        );
        if (gamesComparison != 0) return gamesComparison;
        return (b['score'] as int).compareTo(a['score'] as int);
      });

      // Return top N users
      return leaderboard.take(limit).toList();
    } catch (e) {
      print('Error getting top winners: $e');
      return [];
    }
  }

  // Get top winners for a specific game
  Future<List<Map<String, dynamic>>> getGameTopWinners({
    required String gameId,
    int limit = 10,
  }) async {
    try {
      print('Fetching top $limit winners for game $gameId');

      // Query winners for this specific game - fetch all and sort in memory to avoid index requirements
      final winnersSnapshot =
          await _firestore
              .collection('winners')
              .where('gameId', isEqualTo: gameId)
              .limit(100) // Get a reasonable number to sort locally
              .get();

      if (winnersSnapshot.docs.isEmpty) {
        print('No winners found for game $gameId');
        return [];
      }

      // Convert to list of maps with simplified structure
      List<Map<String, dynamic>> results =
          winnersSnapshot.docs.map((doc) {
            final data = doc.data();
            return {
              'userId': data['userId'],
              'displayName': data['userDisplayName'] ?? 'Unknown User',
              'photoUrl': data['userPhotoUrl'],
              'score': data['score'] ?? 0,
              'completedAt': data['completedAt'],
            };
          }).toList();

      // Sort by score in memory
      results.sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));

      // Return just the top 'limit' entries
      return results.take(limit).toList();
    } catch (e) {
      print('Error getting top winners for game: $e');
      return [];
    }
  }
}
