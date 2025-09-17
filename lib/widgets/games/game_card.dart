// File: lib/widgets/games/game_card.dart
// Description: Card widget for displaying game sections in the main app

// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/scheduled_game_model.dart';
import '../../providers/question_provider.dart';

class GameCard extends ConsumerWidget {
  final ScheduledGameModel game;
  final VoidCallback onTap;

  const GameCard({super.key, required this.game, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final questionCountAsync = ref.watch(
      totalQuestionCountProvider(game.categoryName),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.primary.withOpacity(0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.shadowColor.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.gamepad,
                        color: theme.colorScheme.secondary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(game.name, style: theme.textTheme.titleLarge),
                          if (game.description.isNotEmpty)
                            Text(
                              game.description,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(
                                  0.7,
                                ),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    questionCountAsync.when(
                      data:
                          (count) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  count >= 10
                                      ? theme.colorScheme.tertiary.withOpacity(
                                        0.2,
                                      )
                                      : theme.colorScheme.error.withOpacity(
                                        0.2,
                                      ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$count پرسیار',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color:
                                    count >= 10
                                        ? theme.colorScheme.tertiary
                                        : theme.colorScheme.error,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      loading:
                          () => SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                theme.colorScheme.secondary,
                              ),
                            ),
                          ),
                      error:
                          (_, __) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.error.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '0 پرسیار',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.error,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Game info
                Row(
                  children: [
                    _buildInfoItem(
                      Icons.stars,
                      'خەڵات',
                      game.prize.isNotEmpty ? game.prize : 'نادیار',
                      Colors.amber,
                    ),
                    const SizedBox(width: 20),
                    _buildInfoItem(
                      Icons.timer,
                      'کات',
                      '${game.duration} خولەک',
                      Colors.blue,
                    ),
                    const SizedBox(width: 20),
                    _buildInfoItem(
                      Icons.people,
                      'یارێزان',
                      '${game.maxParticipants}',
                      Colors.green,
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Status and scheduled time
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(game.status).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        game.statusText,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: _getStatusColor(game.status),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Text(
                      _formatDateTime(game.scheduledTime),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant.withOpacity(
                          0.6,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Action hint
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: theme.colorScheme.primary.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.touch_app,
                        color: theme.colorScheme.primary,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'کلیک بکە بۆ بینینی پرسیارەکان',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Builder(
      builder: (context) {
        final theme = Theme.of(context);
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 4),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: color.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Color _getStatusColor(GameStatus status) {
    // Since we can't directly access the context here, we'll use fixed colors
    // that match our theme colors
    switch (status) {
      case GameStatus.scheduled:
        return Colors.blue; // primary
      case GameStatus.live:
        return Colors.orange; // tertiary
      case GameStatus.completed:
        return Colors.grey; // onSurfaceVariant
      case GameStatus.cancelled:
        return Colors.red; // error
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = dateTime.difference(now);

    if (difference.inDays > 0) {
      return '${difference.inDays} ڕۆژ ماوە';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} کاتژمێر ماوە';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} خولەک ماوە';
    } else if (difference.inSeconds > 0) {
      return 'دەست پێ دەکات';
    } else {
      return 'تەواوبوو';
    }
  }
}
