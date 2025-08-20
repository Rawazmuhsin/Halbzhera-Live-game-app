import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/category_model.dart';
import '../services/database_service.dart';

final databaseServiceProvider = Provider<DatabaseService>(
  (ref) => DatabaseService(),
);

class AnalyticsData {
  final int totalUsers;
  final int activeUsers;
  final int totalGamesPlayed;
  final double averageSessionDuration;
  final List<Map<String, dynamic>> userGrowth;
  final List<Map<String, dynamic>> gameActivity;
  final List<CategoryModel> categoryPopularity;

  AnalyticsData({
    required this.totalUsers,
    required this.activeUsers,
    required this.totalGamesPlayed,
    required this.averageSessionDuration,
    required this.userGrowth,
    required this.gameActivity,
    required this.categoryPopularity,
  });
}

final analyticsProvider = FutureProvider<AnalyticsData>((ref) async {
  final databaseService = ref.read(databaseServiceProvider);
  final firestore = FirebaseFirestore.instance;

  // Fetch total users
  final usersSnapshot = await firestore.collection('users').get();
  final totalUsers = usersSnapshot.size;

  // Fetch active users (e.g., active in the last 7 days)
  final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
  final activeUsersSnapshot =
      await firestore
          .collection('users')
          .where('lastSeen', isGreaterThanOrEqualTo: sevenDaysAgo)
          .get();
  final activeUsers = activeUsersSnapshot.size;

  // Fetch total games played from live games history
  final gamesSnapshot =
      await firestore
          .collection('live_games')
          .where('status', isEqualTo: 'completed')
          .get();
  final totalGamesPlayed = gamesSnapshot.size;

  // User growth data (new users per day for the last 30 days)
  final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
  final userGrowthSnapshot =
      await firestore
          .collection('users')
          .where('createdAt', isGreaterThanOrEqualTo: thirtyDaysAgo)
          .get();
  final userGrowth = <String, int>{};
  for (var doc in userGrowthSnapshot.docs) {
    final createdAt = (doc.data()['createdAt'] as Timestamp).toDate();
    // Format date consistently as YYYY-MM-DD
    final day =
        '${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}-${createdAt.day.toString().padLeft(2, '0')}';
    userGrowth[day] = (userGrowth[day] ?? 0) + 1;
  }
  final sortedUserGrowth =
      userGrowth.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
  final userGrowthData =
      sortedUserGrowth.map((e) => {'day': e.key, 'count': e.value}).toList();

  // Game activity (games played per day for the last 30 days)
  final gameActivitySnapshot =
      await firestore
          .collection('live_games')
          .where('status', isEqualTo: 'completed')
          .where('finishedAt', isGreaterThanOrEqualTo: thirtyDaysAgo)
          .get();
  final gameActivity = <String, int>{};
  for (var doc in gameActivitySnapshot.docs) {
    final endTimeStamp = doc.data()['finishedAt'] as Timestamp?;
    if (endTimeStamp != null) {
      final endTime = endTimeStamp.toDate();
      // Format date consistently as YYYY-MM-DD
      final day =
          '${endTime.year}-${endTime.month.toString().padLeft(2, '0')}-${endTime.day.toString().padLeft(2, '0')}';
      gameActivity[day] = (gameActivity[day] ?? 0) + 1;
    }
  }
  final sortedGameActivity =
      gameActivity.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
  final gameActivityData =
      sortedGameActivity.map((e) => {'day': e.key, 'count': e.value}).toList();

  // Category popularity
  final categoriesData = await databaseService.getCategories();
  final categories =
      categoriesData.map((data) => CategoryModel.fromMap(data)).toList();
  categories.sort((a, b) => b.totalPlays.compareTo(a.totalPlays));
  final categoryPopularity = categories.take(5).toList();

  return AnalyticsData(
    totalUsers: totalUsers,
    activeUsers: activeUsers,
    totalGamesPlayed: totalGamesPlayed,
    averageSessionDuration: 25.5, // Placeholder
    userGrowth: userGrowthData,
    gameActivity: gameActivityData,
    categoryPopularity: categoryPopularity,
  );
});
