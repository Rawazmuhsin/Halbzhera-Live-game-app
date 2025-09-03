// ignore_for_file: avoid_print

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/game_result_model.dart';
import '../config/firebase_config.dart';
import 'database_service.dart';

extension GameResultOperations on DatabaseService {
  // Save game result (creates the game_results collection automatically)
  Future<void> saveGameResult({
    required String gameId,
    required String userId,
    required int score,
    required bool isWinner,
    int? eliminatedAtQuestion,
  }) async {
    try {
      print(
        'Saving game result for user $userId in game $gameId, isWinner: $isWinner',
      );

      // Get user data from users collection
      final userDoc = await FirebaseConfig.getUserDoc(userId).get();

      final userData = userDoc.data() as Map<String, dynamic>? ?? {};
      final userName = userData['displayName'] ?? 'Unknown User';
      final userEmail = userData['email'] ?? '';
      final userPhotoUrl = userData['photoURL'];

      print('User data retrieved: name=$userName, email=$userEmail');

      // Create result document in game_results collection
      final gameResultRef = await FirebaseFirestore.instance
          .collection('game_results')
          .add({
            'gameId': gameId,
            'userId': userId,
            'userDisplayName': userName,
            'userEmail': userEmail,
            'userPhotoUrl': userPhotoUrl,
            'score': score,
            'isWinner': isWinner,
            'eliminatedAtQuestion': eliminatedAtQuestion,
            'completedAt': FieldValue.serverTimestamp(),
          });

      print('Game result saved with ID: ${gameResultRef.id}');

      // If user is a winner, also add to the winners collection
      if (isWinner) {
        // Use a Timestamp for more consistent results
        final now = Timestamp.now();

        final winnerRef = await FirebaseFirestore.instance
            .collection('winners')
            .add({
              'gameId': gameId,
              'userId': userId,
              'userDisplayName': userName,
              'userEmail': userEmail,
              'userPhotoUrl': userPhotoUrl,
              'score': score,
              'completedAt': now,
            });

        print(
          'Winner saved successfully with ID: ${winnerRef.id} for user $userId in game $gameId',
        );
        print('Winner data: name=$userName, email=$userEmail');
      }

      // Update user statistics
      await FirebaseConfig.getUserDoc(userId).update({
        'totalGamesPlayed': FieldValue.increment(1),
        'gamesWon':
            isWinner ? FieldValue.increment(1) : FieldValue.increment(0),
        'totalScore': FieldValue.increment(score),
      });

      print('Game result saved successfully for user $userId in game $gameId');
    } catch (e) {
      print('Error saving game result: $e');
      rethrow;
    }
  }

  // Get winners for a specific game - stream version
  Stream<List<GameResultModel>> getGameWinnersStream(String gameId) {
    print('Setting up winners stream for game: $gameId');

    // Create a stream controller to handle both collections
    final controller = StreamController<List<GameResultModel>>();

    // First try to get all winners for this game (no ordering in query)
    final winnersSubscription = FirebaseFirestore.instance
        .collection('winners')
        .where('gameId', isEqualTo: gameId)
        .snapshots()
        .listen(
          (snapshot) {
            print(
              'Winners stream update: ${snapshot.docs.length} documents from winners collection',
            );
            if (snapshot.docs.isNotEmpty) {
              final results =
                  snapshot.docs.map((doc) {
                    final data = doc.data();
                    print(
                      'Winner data from stream: ${doc.id} - Display Name: ${data['userDisplayName']}',
                    );
                    return GameResultModel.fromMap(data, doc.id);
                  }).toList();

              // Sort by completedAt in memory to get most recent first
              results.sort(
                (a, b) => (b.completedAt ?? DateTime.now()).compareTo(
                  a.completedAt ?? DateTime.now(),
                ),
              );

              controller.add(results);
            } else {
              // If no results in winners collection, check game_results
              print('No winners found in stream, will check game_results');
              FirebaseFirestore.instance
                  .collection('game_results')
                  .where('gameId', isEqualTo: gameId)
                  .where('isWinner', isEqualTo: true)
                  .get()
                  .then((fallbackSnapshot) {
                    final fallbackResults =
                        fallbackSnapshot.docs.map((doc) {
                          final data = doc.data();
                          print(
                            'Fallback winner data from stream: ${doc.id} - Display Name: ${data['userDisplayName']}',
                          );
                          return GameResultModel.fromMap(data, doc.id);
                        }).toList();

                    if (fallbackResults.isNotEmpty) {
                      // Sort by completedAt in memory
                      fallbackResults.sort(
                        (a, b) => (b.completedAt ?? DateTime.now()).compareTo(
                          a.completedAt ?? DateTime.now(),
                        ),
                      );

                      print('Found ${fallbackResults.length} fallback winners');
                      controller.add(fallbackResults);

                      // Auto-migrate these to the winners collection
                      _asyncMigrateSpecificWinners(fallbackResults);
                    } else {
                      // No winners found in either collection, add empty list
                      controller.add([]);
                    }
                  })
                  .catchError((e) {
                    print('Error checking fallback winners: $e');
                    // In case of error, add empty list to avoid hanging
                    controller.add([]);
                    return null;
                  });
            }
          },
          onError: (e) {
            print('Error in winners stream: $e');
            controller.addError(e);
          },
        );

    // When the stream is canceled, clean up subscriptions
    controller.onCancel = () {
      winnersSubscription.cancel();
    };

    return controller.stream;
  }

  // Get all results for a specific game (for admin/stats)
  Stream<List<GameResultModel>> getGameResultsStream(
    String gameId, {
    int limit = 50,
  }) {
    // First try to get from winners collection
    return FirebaseFirestore.instance
        .collection('winners')
        .where('gameId', isEqualTo: gameId)
        .orderBy('completedAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          final results =
              snapshot.docs
                  .map((doc) => GameResultModel.fromMap(doc.data(), doc.id))
                  .toList();

          print('Live winners stream returned ${results.length} results');
          return results;
        })
        .handleError((error) {
          print(
            'Error in winners stream: $error, falling back to game_results',
          );
          // Return an empty list so the stream continues
          return <GameResultModel>[];
        })
        .asyncMap((results) async {
          // If we got results from winners collection, return them
          if (results.isNotEmpty) {
            return results;
          }

          // Otherwise, try game_results as fallback
          print('No results in winners stream, checking game_results');
          final fallbackSnapshot =
              await FirebaseFirestore.instance
                  .collection('game_results')
                  .where('gameId', isEqualTo: gameId)
                  .where('isWinner', isEqualTo: true)
                  .orderBy('completedAt', descending: true)
                  .limit(limit)
                  .get();

          final fallbackResults =
              fallbackSnapshot.docs
                  .map((doc) => GameResultModel.fromMap(doc.data(), doc.id))
                  .toList();

          print(
            'Fallback game_results returned ${fallbackResults.length} winners',
          );

          // Auto-migrate winners from fallback for future queries
          if (fallbackResults.isNotEmpty) {
            _asyncMigrateSpecificWinners(fallbackResults);
          }

          return fallbackResults;
        });
  }

  // Get all game results (non-stream version)
  Future<List<GameResultModel>> getGameResults({
    required String gameId,
    int limit = 50,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      print(
        'Fetching winners for game: $gameId (limit: $limit, pagination: ${startAfter != null})',
      );

      // Build query with pagination
      Query winnersQuery = FirebaseFirestore.instance
          .collection('winners')
          .where('gameId', isEqualTo: gameId)
          .orderBy('completedAt', descending: true)
          .limit(limit);

      // Apply pagination if startAfter is provided
      if (startAfter != null) {
        winnersQuery = winnersQuery.startAfterDocument(startAfter);
      }

      // Execute query
      final winnersSnapshot = await winnersQuery.get();

      print('Query returned ${winnersSnapshot.docs.length} winner documents');

      if (winnersSnapshot.docs.isNotEmpty) {
        final results =
            winnersSnapshot.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              print(
                'Winner data: ${doc.id} - Display Name: ${data['userDisplayName']}, Email: ${data['userEmail']}',
              );
              return GameResultModel.fromMap(data, doc.id);
            }).toList();

        print('Processed ${results.length} winners for game $gameId');
        return results;
      }

      // As a fallback, check game_results collection if no winners were found
      print(
        'No winners found in winners collection, checking game_results as fallback',
      );

      // Build fallback query with pagination
      Query fallbackQuery = FirebaseFirestore.instance
          .collection('game_results')
          .where('gameId', isEqualTo: gameId)
          .where('isWinner', isEqualTo: true)
          .orderBy('completedAt', descending: true)
          .limit(limit);

      // Apply pagination if startAfter is provided
      if (startAfter != null) {
        fallbackQuery = fallbackQuery.startAfterDocument(startAfter);
      }

      final fallbackSnapshot = await fallbackQuery.get();

      final fallbackResults =
          fallbackSnapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            print(
              'Fallback winner data: ${doc.id} - Display Name: ${data['userDisplayName']}, Email: ${data['userEmail']}',
            );
            return GameResultModel.fromMap(data, doc.id);
          }).toList();

      print(
        'Found ${fallbackResults.length} winners for game $gameId in fallback game_results',
      );

      if (fallbackResults.isNotEmpty) {
        // Auto-migrate these to the winners collection for future use
        _asyncMigrateSpecificWinners(fallbackResults);
        return fallbackResults;
      }

      return [];
    } catch (e) {
      print('Error getting game results: $e');
      return [];
    }
  }

  // Get top winners across all games for the leaderboard
  Future<List<Map<String, dynamic>>> getTopWinners({int limit = 10}) async {
    try {
      print('Fetching top $limit winners across all games');

      // Query all winners
      final winnersSnapshot =
          await FirebaseFirestore.instance
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
      leaderboard.sort((a, b) {
        final gamesComparison = (b['gamesWon'] as int).compareTo(
          a['gamesWon'] as int,
        );
        if (gamesComparison != 0) return gamesComparison;
        return (b['totalScore'] as int).compareTo(a['totalScore'] as int);
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

      // Query winners for this specific game
      final winnersSnapshot =
          await FirebaseFirestore.instance
              .collection('winners')
              .where('gameId', isEqualTo: gameId)
              .orderBy('score', descending: true) // Sort by score
              .limit(limit)
              .get();

      if (winnersSnapshot.docs.isEmpty) {
        print('No winners found for game $gameId');
        return [];
      }

      // Convert to list of maps with simplified structure
      return winnersSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'userId': data['userId'],
          'displayName': data['userDisplayName'] ?? 'Unknown User',
          'photoUrl': data['userPhotoUrl'],
          'score': data['score'] ?? 0,
          'completedAt': data['completedAt'],
        };
      }).toList();
    } catch (e) {
      print('Error getting top winners for game: $e');
      return [];
    }
  }

  // Helper method to asynchronously migrate specific winners to the winners collection
  Future<void> _asyncMigrateSpecificWinners(
    List<GameResultModel> winners,
  ) async {
    try {
      print('Auto-migrating ${winners.length} winners to winners collection');
      for (final winner in winners) {
        await FirebaseFirestore.instance.collection('winners').add({
          'gameId': winner.gameId,
          'userId': winner.userId,
          'userDisplayName': winner.userDisplayName ?? 'Unknown User',
          'userEmail': winner.userEmail ?? '',
          'userPhotoUrl': winner.userPhotoUrl,
          'score': winner.score,
          'completedAt':
              winner.completedAt != null
                  ? Timestamp.fromDate(winner.completedAt!)
                  : FieldValue.serverTimestamp(),
        });
      }
      print('Auto-migration complete');
    } catch (e) {
      print('Error in auto-migration: $e');
      // Don't throw as this is a background task
    }
  }

  // Get all winners across all games (for admin)
  Future<List<GameResultModel>> getAllGameWinners() async {
    try {
      print('Fetching all winners');

      // Use the winners collection as the primary source
      final winnersSnapshot =
          await FirebaseFirestore.instance
              .collection('winners')
              .orderBy('completedAt', descending: true)
              .get();

      final results =
          winnersSnapshot.docs.map((doc) {
            final data = doc.data();
            print(
              'Admin winner data: ${doc.id} - Display Name: ${data['userDisplayName']}, Email: ${data['userEmail']}',
            );
            return GameResultModel.fromMap(data, doc.id);
          }).toList();

      print('Found ${results.length} total winners in winners collection');

      // If we have a reasonable number of winners, also check game_results for any missing ones
      // but only if winners collection is small (suggesting it might be incomplete)
      if (results.length < 10) {
        print(
          'Found fewer than 10 winners, checking game_results for missing winners',
        );

        // Keep track of already found userIds to avoid duplicates
        final existingUserGamePairs =
            results.map((r) => '${r.userId}_${r.gameId}').toSet();

        try {
          // Try a simpler query without the orderBy that would require a composite index
          final gameResultsSnapshot =
              await FirebaseFirestore.instance
                  .collection('game_results')
                  .where('isWinner', isEqualTo: true)
                  .limit(50) // Limit to a reasonable number
                  .get();

          for (final doc in gameResultsSnapshot.docs) {
            final data = doc.data();
            final userId = data['userId'] as String? ?? '';
            final gameId = data['gameId'] as String? ?? '';
            final pairKey = '${userId}_$gameId';

            // Only add if this user+game combo is not already in results and has valid IDs
            if (!existingUserGamePairs.contains(pairKey) &&
                userId.isNotEmpty &&
                gameId.isNotEmpty) {
              print(
                'Found missing winner in game_results: $userId for game $gameId',
              );
              results.add(GameResultModel.fromMap(data, doc.id));

              // Add to our tracking set to avoid duplicates
              existingUserGamePairs.add(pairKey);
            }
          }
        } catch (queryError) {
          print('Error querying game_results: $queryError');
          // Continue with the results we have from winners collection
        }

        // Sort by completedAt (descending)
        if (results.isNotEmpty) {
          results.sort(
            (a, b) => (b.completedAt ?? DateTime.now()).compareTo(
              a.completedAt ?? DateTime.now(),
            ),
          );
        }

        // Consider migrating these winners
        if (results.length > winnersSnapshot.docs.length) {
          print(
            'Found ${results.length - winnersSnapshot.docs.length} additional winners in game_results',
          );
        }
      }

      return results;
    } catch (e) {
      print('Error getting all game winners: $e');
      return [];
    }
  }

  // Schedule migration of missing winners for background processing
  Future<void> _scheduleMigrationOfMissingWinners() async {
    // We'll create a background task indicator in Firestore
    try {
      await FirebaseFirestore.instance.collection('system_tasks').add({
        'task': 'migrate_missing_winners',
        'status': 'scheduled',
        'scheduledAt': FieldValue.serverTimestamp(),
      });
      print('Scheduled migration of missing winners');
    } catch (e) {
      print('Error scheduling migration: $e');
    }
  }

  // Get game details by game ID
  Future<Map<String, dynamic>?> getGameDetails(String gameId) async {
    try {
      // First try to get from live_games collection
      var doc =
          await FirebaseFirestore.instance
              .collection('live_games')
              .doc(gameId)
              .get();

      if (doc.exists) {
        return doc.data();
      }

      // If not found, try scheduled_games collection
      doc =
          await FirebaseFirestore.instance
              .collection('scheduled_games')
              .doc(gameId)
              .get();

      if (doc.exists) {
        return doc.data();
      }

      return null;
    } catch (e) {
      print('Error getting game details: $e');
      return null;
    }
  }

  // Delete a game result
  Future<void> deleteGameResult(String resultId) async {
    try {
      await FirebaseFirestore.instance
          .collection('game_results')
          .doc(resultId)
          .delete();
      print('Game result deleted successfully: $resultId');
    } catch (e) {
      print('Error deleting game result: $e');
      rethrow;
    }
  }

  // Delete a winner
  Future<void> deleteWinner(String winnerId) async {
    try {
      await FirebaseFirestore.instance
          .collection('winners')
          .doc(winnerId)
          .delete();
      print('Winner deleted successfully: $winnerId');
    } catch (e) {
      print('Error deleting winner: $e');
      rethrow;
    }
  }

  // Update a winner's details
  Future<void> updateWinner(String winnerId, Map<String, dynamic> data) async {
    try {
      await FirebaseFirestore.instance
          .collection('winners')
          .doc(winnerId)
          .update(data);
      print('Winner updated successfully: $winnerId');
    } catch (e) {
      print('Error updating winner: $e');
      rethrow;
    }
  }

  // Migrate existing winners from game_results to winners collection
  // This can be used once to populate the winners collection with existing data
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

        // Create a new document in winners collection with the same data
        // Remove eliminatedAtQuestion field which doesn't apply to winners
        data.remove('eliminatedAtQuestion');

        // Always set isWinner to true (redundant but included for consistency)
        data['isWinner'] = true;

        final winnersRef =
            FirebaseFirestore.instance.collection('winners').doc();
        batch.set(winnersRef, data);
        migratedCount++;
      }

      // Commit the batch
      await batch.commit();
      print(
        'Successfully migrated $migratedCount winners to winners collection',
      );
    } catch (e) {
      print('Error migrating winners: $e');
      rethrow;
    }
  }
}
