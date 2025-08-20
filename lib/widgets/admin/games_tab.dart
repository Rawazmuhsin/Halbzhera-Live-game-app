// File: lib/widgets/admin/games_tab.dart
// Description: Games tab content widget

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../utils/constants.dart';
import '../../providers/live_game_provider.dart';
import '../../providers/quiz_provider.dart';
import '../../providers/scheduled_game_provider.dart';
import '../../widgets/common/loading_widget.dart';
import '../../models/live_game_model.dart';
import '../../models/scheduled_game_model.dart';
import '../../screens/admin/create_game_screen.dart';

class GamesTab extends ConsumerWidget {
  const GamesTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGameActions(context),
          const SizedBox(height: AppDimensions.paddingL),
          _buildCurrentLiveGame(ref),
          const SizedBox(height: AppDimensions.paddingL),
          _buildUpcomingGames(ref),
          const SizedBox(height: AppDimensions.paddingL),
          _buildGameCategories(ref),
        ],
      ),
    );
  }

  Widget _buildGameActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'بەڕێوەبردنی یاریەکان',
          style: TextStyle(
            color: AppColors.lightText,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppDimensions.paddingM),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _navigateToCreateGame(context),
                icon: const Icon(Icons.add),
                label: const Text('یاری نوێ دروستبکە'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryRed,
                  padding: const EdgeInsets.all(AppDimensions.paddingM),
                ),
              ),
            ),
            const SizedBox(width: AppDimensions.paddingM),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _navigateToCreateCategory,
                icon: const Icon(Icons.category),
                label: const Text('بەشی نوێ زیادبکە'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryTeal,
                  padding: const EdgeInsets.all(AppDimensions.paddingM),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCurrentLiveGame(WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'یاری زیندووی چالاک',
          style: TextStyle(
            color: AppColors.lightText,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppDimensions.paddingM),
        Consumer(
          builder: (context, ref, child) {
            final currentGameAsync = ref.watch(currentLiveGameProvider);

            return currentGameAsync.when(
              data: (game) {
                if (game == null) {
                  return _buildNoLiveGameCard(context);
                }
                return _buildLiveGameCard(game);
              },
              loading: () => const LoadingWidget(),
              error: (error, _) => _buildErrorCard('هەڵەیەک ڕوویدا: $error'),
            );
          },
        ),
      ],
    );
  }

  Widget _buildNoLiveGameCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        border: Border.all(color: AppColors.border1),
      ),
      child: Column(
        children: [
          Icon(Icons.games, size: 48, color: AppColors.mediumText),
          const SizedBox(height: AppDimensions.paddingM),
          const Text(
            'هیچ یاری زیندووی چالاک نییە',
            style: TextStyle(color: AppColors.mediumText, fontSize: 16),
          ),
          const SizedBox(height: AppDimensions.paddingM),
          ElevatedButton(
            onPressed: () => _navigateToCreateGame(context),
            child: const Text('یاری نوێ دروستبکە'),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveGameCard(LiveGameModel game) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryRed, AppColors.primaryRed.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryRed.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.live_tv,
                  color: AppColors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppDimensions.paddingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'یاری زیندوو چالاک',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      game.title,
                      style: TextStyle(
                        color: AppColors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: _navigateToLiveMonitor,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.white,
                  foregroundColor: AppColors.primaryRed,
                ),
                child: const Text('بینین'),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.paddingM),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildGameStat(
                'بەشداربووان',
                game.participantCount.toString(),
                Icons.people,
              ),
              _buildGameStat(
                'پرسیار',
                '${game.currentQuestion + 1}/${game.totalQuestions}',
                Icons.quiz,
              ),
              _buildGameStat('دۆخ', game.statusText, Icons.play_circle),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGameStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppColors.white, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: AppColors.white.withOpacity(0.8),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildUpcomingGames(WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'یاری داهاتووەکان',
              style: TextStyle(
                color: AppColors.lightText,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: _navigateToAllGames,
              child: const Text(
                'هەموو ببینە',
                style: TextStyle(color: AppColors.primaryRed),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.paddingM),
        Consumer(
          builder: (context, ref, child) {
            final upcomingGamesAsync = ref.watch(
              upcomingScheduledGamesProvider,
            );

            return upcomingGamesAsync.when(
              data: (games) {
                if (games.isEmpty) {
                  return _buildEmptyUpcomingGames();
                }

                return Column(
                  children:
                      games
                          .take(3)
                          .map(
                            (game) =>
                                _buildUpcomingScheduledGameCard(context, game),
                          )
                          .toList(),
                );
              },
              loading: () => const LoadingWidget(),
              error: (error, _) => _buildErrorCard('هەڵەیەک ڕوویدا: $error'),
            );
          },
        ),
      ],
    );
  }

  Widget _buildUpcomingScheduledGameCard(
    BuildContext context,
    ScheduledGameModel game,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingS),
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: AppColors.border1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryTeal.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.schedule,
              color: AppColors.primaryTeal,
              size: 20,
            ),
          ),
          const SizedBox(width: AppDimensions.paddingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  game.name,
                  style: const TextStyle(
                    color: AppColors.lightText,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'نەخشەکراو بۆ ${_formatDateTime(game.scheduledTime)}',
                  style: const TextStyle(
                    color: AppColors.mediumText,
                    fontSize: 14,
                  ),
                ),
                if (game.prize.isNotEmpty)
                  Text(
                    'خەڵات: ${game.prize}',
                    style: const TextStyle(
                      color: AppColors.accentYellow,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
          Column(
            children: [
              Text(
                game.statusText,
                style: TextStyle(
                  color: _getStatusColor(game.status),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: AppColors.mediumText),
                color: AppColors.surface3,
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => CreateGameScreen(gameToEdit: game),
                        ),
                      );
                      break;
                    case 'start':
                      debugPrint('Start game: ${game.name}');
                      break;
                    case 'delete':
                      debugPrint('Delete game: ${game.name}');
                      break;
                  }
                },
                itemBuilder:
                    (popupContext) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(
                              Icons.edit,
                              color: AppColors.lightText,
                              size: 16,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'دەستکاری',
                              style: TextStyle(color: AppColors.lightText),
                            ),
                          ],
                        ),
                      ),
                      if (game.canStart)
                        const PopupMenuItem(
                          value: 'start',
                          child: Row(
                            children: [
                              Icon(
                                Icons.play_arrow,
                                color: AppColors.success,
                                size: 16,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'دەستپێکردن',
                                style: TextStyle(color: AppColors.success),
                              ),
                            ],
                          ),
                        ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete,
                              color: AppColors.error,
                              size: 16,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'سڕینەوە',
                              style: TextStyle(color: AppColors.error),
                            ),
                          ],
                        ),
                      ),
                    ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyUpcomingGames() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: AppColors.border1),
      ),
      child: Column(
        children: [
          Icon(Icons.event_note, size: 32, color: AppColors.mediumText),
          const SizedBox(height: AppDimensions.paddingS),
          const Text(
            'هیچ یاری نەخشەکراوێک نییە',
            style: TextStyle(color: AppColors.mediumText, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildGameCategories(WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'بەشەکانی یاری',
              style: TextStyle(
                color: AppColors.lightText,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: _navigateToManageCategories,
              child: const Text(
                'بەڕێوەبردن',
                style: TextStyle(color: AppColors.primaryRed),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.paddingM),
        Consumer(
          builder: (context, ref, child) {
            final categoriesAsync = ref.watch(categoriesProvider);

            return categoriesAsync.when(
              data: (categories) {
                if (categories.isEmpty) {
                  return _buildEmptyCategories();
                }
                return Wrap(
                  spacing: AppDimensions.paddingS,
                  runSpacing: AppDimensions.paddingS,
                  children:
                      categories
                          .map(
                            (category) => Chip(
                              label: Text(category.name),
                              backgroundColor: AppColors.surface3,
                              labelStyle: const TextStyle(
                                color: AppColors.lightText,
                              ),
                              side: BorderSide(color: AppColors.border1),
                            ),
                          )
                          .toList(),
                );
              },
              loading: () => const LoadingWidget(),
              error: (error, _) => _buildErrorCard('هەڵەیەک ڕوویدا: $error'),
            );
          },
        ),
      ],
    );
  }

  Widget _buildEmptyCategories() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: AppColors.border1),
      ),
      child: const Center(
        child: Column(
          children: [
            Icon(
              Icons.category_outlined,
              size: 32,
              color: AppColors.mediumText,
            ),
            SizedBox(height: AppDimensions.paddingS),
            Text(
              'هیچ بەشێک نەدۆزرایەوە',
              style: TextStyle(color: AppColors.mediumText, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: AppColors.error.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error),
          const SizedBox(width: AppDimensions.paddingM),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    // Placeholder implementation
    return '${dt.year}/${dt.month}/${dt.day} - ${dt.hour}:${dt.minute}';
  }

  Color _getStatusColor(GameStatus status) {
    switch (status) {
      case GameStatus.scheduled:
        return AppColors.primaryTeal;
      case GameStatus.live:
        return AppColors.success;
      case GameStatus.completed:
        return AppColors.mediumText;
      case GameStatus.cancelled:
        return AppColors.error;
    }
  }

  void _navigateToCreateGame(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateGameScreen()),
    );
  }

  void _navigateToCreateCategory() {
    // Placeholder implementation for navigation
    debugPrint('Navigate to create category');
  }

  void _navigateToLiveMonitor() {
    // Placeholder implementation for navigation
    debugPrint('Navigate to live monitor');
  }

  void _navigateToAllGames() {
    // Placeholder implementation for navigation
    debugPrint('Navigate to all games');
  }

  void _navigateToManageCategories() {
    // Placeholder implementation for navigation
    debugPrint('Navigate to manage categories');
  }
}
