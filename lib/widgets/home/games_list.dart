// File: lib/widgets/home/games_list.dart
// Description: List of upcoming games

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../utils/constants.dart';
import '../../providers/scheduled_game_provider.dart';
import 'game_card.dart';
import 'no_games_message.dart';

class GamesList extends ConsumerWidget {
  const GamesList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final upcomingGamesAsync = ref.watch(upcomingScheduledGamesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'یاریەکانی ئامادە',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.lightText,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppDimensions.paddingL),
        upcomingGamesAsync.when(
          data: (upcomingGames) {
            if (upcomingGames.isEmpty) {
              return const NoGamesMessage();
            }
            return Column(
              children: List.generate(
                upcomingGames.length,
                (index) => Padding(
                  padding: const EdgeInsets.only(
                    bottom: AppDimensions.paddingL,
                  ),
                  child: GameCard(game: upcomingGames[index]),
                ),
              ),
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(AppDimensions.paddingXL),
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryRed),
              ),
            ),
          ),
          error: (error, stack) => Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppDimensions.paddingXL),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
              border: Border.all(
                color: AppColors.error.withOpacity(0.2),
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: AppColors.error,
                ),
                const SizedBox(height: AppDimensions.paddingM),
                Text(
                  'هەڵەیەک ڕوویدا لە بارکردنی یارییەکان',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.error,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppDimensions.paddingS),
                Text(
                  'تکایە دواتر هەوڵبدەوە',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.mediumText,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
