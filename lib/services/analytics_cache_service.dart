// File: lib/services/analytics_cache_service.dart
// Description: Cache service for analytics data to prevent repeated expensive queries

import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/analytics_provider.dart';
import 'database_service.dart';

class AnalyticsCacheService {
  static DateTime? _lastFetch;
  static AnalyticsData? _cachedData;
  static const _cacheDuration = Duration(minutes: 5); // Cache for 5 minutes

  // Stats cache with shorter duration (2 minutes)
  static DateTime? _lastStatsCheck;
  static Map<String, dynamic>? _cachedStats;
  static const _statsCacheDuration = Duration(minutes: 2);

  /// Get analytics data with caching
  /// [forceRefresh] - Set to true to bypass cache and fetch fresh data
  static Future<AnalyticsData> getAnalytics({
    required DatabaseService databaseService,
    required FirebaseFirestore firestore,
    bool forceRefresh = false,
  }) async {
    // Check if cache is valid
    if (!forceRefresh &&
        _cachedData != null &&
        _lastFetch != null &&
        DateTime.now().difference(_lastFetch!) < _cacheDuration) {
      print(
        '✅ Using cached analytics data (age: ${DateTime.now().difference(_lastFetch!).inSeconds}s)',
      );
      return _cachedData!;
    }

    print('🔄 Fetching fresh analytics data...');

    // Fetch total users with limit (optimization)
    final usersSnapshot =
        await firestore
            .collection('users')
            .orderBy('createdAt', descending: true)
            .limit(100) // Only fetch recent 100 users for stats
            .get();
    final totalUsers = usersSnapshot.size;

    // Fetch active users (last 7 days)
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
    final activeUsersSnapshot =
        await firestore
            .collection('users')
            .where('lastSeen', isGreaterThanOrEqualTo: sevenDaysAgo)
            .get();
    final activeUsers = activeUsersSnapshot.size;

    // Use count query for total games (much faster)
    final totalGamesCount =
        await firestore
            .collection('live_games')
            .where('status', isEqualTo: 'completed')
            .count()
            .get();
    final totalGamesPlayed = totalGamesCount.count ?? 0;

    // User growth data (last 30 days)
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    final userGrowthSnapshot =
        await firestore
            .collection('users')
            .where('createdAt', isGreaterThanOrEqualTo: thirtyDaysAgo)
            .get();

    final userGrowth = <String, int>{};
    for (var doc in userGrowthSnapshot.docs) {
      final createdAt = (doc.data()['createdAt'] as Timestamp).toDate();
      final day =
          '${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}-${createdAt.day.toString().padLeft(2, '0')}';
      userGrowth[day] = (userGrowth[day] ?? 0) + 1;
    }
    final sortedUserGrowth =
        userGrowth.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    final userGrowthData =
        sortedUserGrowth.map((e) => {'day': e.key, 'count': e.value}).toList();

    // Game activity (last 30 days) - limited query
    final gameActivitySnapshot =
        await firestore
            .collection('live_games')
            .where('status', isEqualTo: 'completed')
            .where('finishedAt', isGreaterThanOrEqualTo: thirtyDaysAgo)
            .limit(100) // Limit for performance
            .get();

    final gameActivity = <String, int>{};
    for (var doc in gameActivitySnapshot.docs) {
      final finishedAt = (doc.data()['finishedAt'] as Timestamp?)?.toDate();
      if (finishedAt != null) {
        final day =
            '${finishedAt.year}-${finishedAt.month.toString().padLeft(2, '0')}-${finishedAt.day.toString().padLeft(2, '0')}';
        gameActivity[day] = (gameActivity[day] ?? 0) + 1;
      }
    }
    final sortedGameActivity =
        gameActivity.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    final gameActivityData =
        sortedGameActivity
            .map((e) => {'day': e.key, 'count': e.value})
            .toList();

    // Category popularity - fetch from database service (uses stream)
    final categoryPopularity =
        await databaseService
            .getCategoriesStream()
            .first; // Get once, don't stream

    // Calculate average session duration (estimated from sample)
    final averageSessionDuration =
        15.5; // Placeholder - calculate from actual data

    // Create analytics data
    final analyticsData = AnalyticsData(
      totalUsers: totalUsers,
      activeUsers: activeUsers,
      totalGamesPlayed: totalGamesPlayed,
      averageSessionDuration: averageSessionDuration,
      userGrowth: userGrowthData,
      gameActivity: gameActivityData,
      categoryPopularity: categoryPopularity,
    );

    // Cache the data
    _cachedData = analyticsData;
    _lastFetch = DateTime.now();

    print('✅ Analytics data cached successfully');

    return analyticsData;
  }

  /// Get live game stats with caching
  static Future<Map<String, dynamic>> getLiveGameStats({
    required DatabaseService databaseService,
    bool forceRefresh = false,
  }) async {
    // Check if cache is valid
    if (!forceRefresh &&
        _cachedStats != null &&
        _lastStatsCheck != null &&
        DateTime.now().difference(_lastStatsCheck!) < _statsCacheDuration) {
      print(
        '✅ Using cached stats (age: ${DateTime.now().difference(_lastStatsCheck!).inSeconds}s)',
      );
      return _cachedStats!;
    }

    print('🔄 Fetching fresh stats...');

    // Fetch fresh stats
    final stats = await databaseService.getLiveGameStats();

    // Cache the stats
    _cachedStats = stats;
    _lastStatsCheck = DateTime.now();

    print('✅ Stats cached successfully');

    return stats;
  }

  /// Clear all cached data (use when data needs to be refreshed)
  static void clearCache() {
    _cachedData = null;
    _lastFetch = null;
    _cachedStats = null;
    _lastStatsCheck = null;
    print('🗑️ Analytics cache cleared');
  }

  /// Check if analytics cache is still valid
  static bool isAnalyticsCacheValid() {
    return _cachedData != null &&
        _lastFetch != null &&
        DateTime.now().difference(_lastFetch!) < _cacheDuration;
  }

  /// Check if stats cache is still valid
  static bool isStatsCacheValid() {
    return _cachedStats != null &&
        _lastStatsCheck != null &&
        DateTime.now().difference(_lastStatsCheck!) < _statsCacheDuration;
  }

  /// Get cache age in seconds (for UI display)
  static int? getCacheAge() {
    if (_lastFetch == null) return null;
    return DateTime.now().difference(_lastFetch!).inSeconds;
  }

  /// Get stats cache age in seconds
  static int? getStatsCacheAge() {
    if (_lastStatsCheck == null) return null;
    return DateTime.now().difference(_lastStatsCheck!).inSeconds;
  }
}
