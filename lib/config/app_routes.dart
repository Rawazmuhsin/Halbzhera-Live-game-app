import 'package:flutter/material.dart';
import '../screens/auth/auth_gate.dart';
import '../screens/admin/admin_home_screen.dart';
import '../screens/leaderboard/leaderboard_screen.dart';

class AppRoutes {
  static const String authGate = '/';
  static const String admin = '/admin';
  static const String leaderboard = '/leaderboard';
  static const String gameLeaderboard = '/game-leaderboard';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    // Extract any arguments if available
    final args = settings.arguments;

    switch (settings.name) {
      case authGate:
        return MaterialPageRoute(builder: (_) => const AuthGate());
      case admin:
        return MaterialPageRoute(builder: (_) => const AdminHomeScreen());
      case leaderboard:
        return MaterialPageRoute(builder: (_) => const LeaderboardScreen());
      case gameLeaderboard:
        // Extract the game ID from arguments
        if (args is Map<String, dynamic> && args.containsKey('gameId')) {
          final gameId = args['gameId'] as String;
          return MaterialPageRoute(
            builder: (_) => LeaderboardScreen(gameId: gameId),
          );
        }
        // Fallback to global leaderboard if no gameId provided
        return MaterialPageRoute(builder: (_) => const LeaderboardScreen());
      default:
        return MaterialPageRoute(
          builder:
              (_) =>
                  const Scaffold(body: Center(child: Text('Route not found'))),
        );
    }
  }
}
