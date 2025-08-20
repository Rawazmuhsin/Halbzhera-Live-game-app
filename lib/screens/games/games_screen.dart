// File: lib/screens/games/games_screen.dart
// Description: Main games screen for users to view available game sections

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/scheduled_game_model.dart';
import '../../providers/scheduled_game_provider.dart';
import '../../widgets/games/game_card.dart';
import '../../widgets/common/gradient_background.dart';
import '../admin/section_questions_screen.dart';

class GamesScreen extends ConsumerWidget {
  const GamesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final upcomingGamesAsync = ref.watch(upcomingScheduledGamesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        elevation: 0,
        title: const Text(
          'یاری داهاتووەکان',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: GradientBackground(
        child: SafeArea(
          child: upcomingGamesAsync.when(
            data: (games) {
              if (games.isEmpty) {
                return _buildEmptyState();
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header section
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'بەشە بەردەستەکان',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'کلیک بکە لەسەر هەر بەشێک بۆ بینینی وردەکارییەکان',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Games list
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: games.length,
                      itemBuilder: (context, index) {
                        final game = games[index];
                        return GameCard(
                          game: game,
                          onTap: () => _navigateToGameDetails(context, game),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
            loading:
                () => const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                  ),
                ),
            error:
                (error, stackTrace) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.red[300],
                        size: 64,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'هەڵەیەک ڕوویدا',
                        style: TextStyle(
                          color: Colors.red[300],
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'تکایە دووبارە هەوڵ بدە',
                        style: TextStyle(color: Colors.grey[400], fontSize: 14),
                      ),
                    ],
                  ),
                ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.gamepad_outlined, color: Colors.grey[600], size: 80),
          const SizedBox(height: 24),
          Text(
            'هیچ یارییەک نەدۆزرایەوە',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'تکایە دواتر گەڕێوە',
            style: TextStyle(color: Colors.grey[500], fontSize: 16),
          ),
        ],
      ),
    );
  }

  void _navigateToGameDetails(BuildContext context, ScheduledGameModel game) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SectionQuestionsScreen(gameSection: game),
      ),
    );
  }
}
