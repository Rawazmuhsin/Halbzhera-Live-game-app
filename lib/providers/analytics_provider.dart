import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/category_model.dart';
import '../services/database_service.dart';
import '../services/analytics_cache_service.dart';

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

// Analytics provider with caching (caches for 5 minutes)
final analyticsProvider = FutureProvider<AnalyticsData>((ref) async {
  final databaseService = ref.read(databaseServiceProvider);
  final firestore = FirebaseFirestore.instance;

  // Use cached analytics with 5-minute cache duration
  return AnalyticsCacheService.getAnalytics(
    databaseService: databaseService,
    firestore: firestore,
    forceRefresh: false, // Set to true to force refresh
  );
});

// Provider to force refresh analytics (bypasses cache)
final refreshAnalyticsProvider = FutureProvider<AnalyticsData>((ref) async {
  final databaseService = ref.read(databaseServiceProvider);
  final firestore = FirebaseFirestore.instance;

  return AnalyticsCacheService.getAnalytics(
    databaseService: databaseService,
    firestore: firestore,
    forceRefresh: true, // Always fetch fresh data
  );
});
