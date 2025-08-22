// File: lib/widgets/home/game_card.dart
// Description: Individual game card

import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import '../../models/scheduled_game_model.dart'; // Use your existing model
import 'game_category_badge.dart';
import 'game_title.dart';
import 'game_description.dart';
import 'game_details.dart';
import 'join_game_button.dart';

class GameCard extends StatelessWidget {
  final ScheduledGameModel game;

  const GameCard({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingXL),
      decoration: BoxDecoration(
        color: AppColors.surface2.withOpacity(0.6),
        borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
        border: Border.all(color: AppColors.border1.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GameCategoryBadge(
            category: game.categoryName,
            color: _getCategoryColor(game.categoryName),
          ),
          const SizedBox(height: AppDimensions.paddingM),
          GameTitle(title: game.name),
          const SizedBox(height: AppDimensions.paddingS),
          GameDescription(description: game.description),
          const SizedBox(height: AppDimensions.paddingL),
          GameDetails(
            timeToStart: _getTimeToStart(game.scheduledTime),
            prize: game.prize,
          ),
          const SizedBox(height: AppDimensions.paddingL),
          JoinGameButton(onPressed: () => _joinGame(context)),
        ],
      ),
    );
  }

  String _getTimeToStart(DateTime scheduledTime) {
    final now = DateTime.now();
    final difference = scheduledTime.difference(now);

    if (difference.inDays > 0) {
      return '${difference.inDays} ڕۆژ';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} کاتژمێر';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} خولەک';
    } else {
      return 'ئێستا';
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'مێژوو':
        return AppColors.primaryTeal;
      case 'زانست':
        return AppColors.accentYellow;
      case 'ئەدەبیات':
        return AppColors.primaryRed;
      case 'جوگرافیا':
        return AppColors.primaryTeal;
      default:
        return AppColors.primaryRed;
    }
  }

  void _joinGame(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('بەشداری کردن لە یاری: ${game.name}'),
        backgroundColor: AppColors.primaryRed,
      ),
    );
  }
}
