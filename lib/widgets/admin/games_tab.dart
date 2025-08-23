// File: lib/widgets/admin/games_tab.dart
// Description: Games tab content widget

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../utils/constants.dart';
import '../../providers/live_game_provider.dart';
import '../../providers/quiz_provider.dart';
import '../../providers/scheduled_game_provider.dart';
import '../../providers/joined_user_provider.dart';
import '../../widgets/common/loading_widget.dart';
import '../../models/live_game_model.dart';
import '../../models/scheduled_game_model.dart';
import '../../screens/admin/create_game_screen.dart';
import '../../screens/admin/add_questions_screen.dart';
import '../../screens/admin/section_questions_screen.dart';

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
                onPressed: () => _navigateToAddQuestions(context),
                icon: const Icon(Icons.quiz_outlined),
                label: const Text('پرسیار زیادکردن'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentYellow,
                  foregroundColor: AppColors.darkText,
                  padding: const EdgeInsets.all(AppDimensions.paddingM),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.paddingM),
        SizedBox(
          width: double.infinity,
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
                            (game) => _buildUpcomingScheduledGameCard(
                              context,
                              ref,
                              game,
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

  Widget _buildUpcomingScheduledGameCard(
    BuildContext context,
    WidgetRef ref,
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
                onSelected: (value) async {
                  switch (value) {
                    case 'view_questions':
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) =>
                                  SectionQuestionsScreen(gameSection: game),
                        ),
                      );
                      break;
                    case 'view_participants':
                      await _showParticipantsDialog(context, ref, game);
                      break;
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
                      await _deleteGame(context, ref, game);
                      break;
                  }
                },
                itemBuilder:
                    (popupContext) => [
                      const PopupMenuItem(
                        value: 'view_questions',
                        child: Row(
                          children: [
                            Icon(
                              Icons.quiz,
                              color: AppColors.primaryTeal,
                              size: 16,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'بینینی پرسیارەکان',
                              style: TextStyle(color: AppColors.lightText),
                            ),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'view_participants',
                        child: Row(
                          children: [
                            Icon(
                              Icons.people,
                              color: AppColors.accentYellow,
                              size: 16,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'بینینی بەشداربووان',
                              style: TextStyle(color: AppColors.lightText),
                            ),
                          ],
                        ),
                      ),
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

  void _navigateToAddQuestions(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddQuestionsScreen()),
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

  Future<void> _deleteGame(
    BuildContext context,
    WidgetRef ref,
    ScheduledGameModel game,
  ) async {
    // Show confirmation dialog
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.surface2,
          title: const Text(
            'سڕینەوەی یاری',
            style: TextStyle(color: AppColors.lightText),
          ),
          content: Text(
            'دڵنیایت لە سڕینەوەی یاریی "${game.name}"؟\nئەم کردارە گەڕانەوەی نییە.',
            style: const TextStyle(color: AppColors.mediumText),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text(
                'پاشگەزبوونەوە',
                style: TextStyle(color: AppColors.mediumText),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              child: const Text(
                'سڕینەوە',
                style: TextStyle(color: AppColors.white),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        // Show loading
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('سڕینەوەی یاری...'),
              backgroundColor: AppColors.primaryTeal,
            ),
          );
        }

        // Delete the game using the provider
        final success = await ref
            .read(scheduledGameNotifierProvider.notifier)
            .deleteGame(game.id);

        if (context.mounted) {
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('یاریی "${game.name}" بە سەرکەوتووی سڕایەوە'),
                backgroundColor: AppColors.success,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('هەڵەیەک ڕوویدا لە سڕینەوەی یاری'),
                backgroundColor: AppColors.error,
              ),
            );
          }
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('هەڵەیەک ڕوویدا: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _showParticipantsDialog(
    BuildContext context,
    WidgetRef ref,
    ScheduledGameModel game,
  ) async {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: AppColors.surface2,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.7,
            padding: const EdgeInsets.all(AppDimensions.paddingL),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'بەشداربووانی ${game.name}',
                      style: const TextStyle(
                        color: AppColors.lightText,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      icon: const Icon(Icons.close, color: AppColors.lightText),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.paddingM),
                Expanded(
                  child: Consumer(
                    builder: (context, ref, child) {
                      final joinedUsersAsync = ref.watch(
                        joinedUsersProvider(game.id),
                      );

                      return joinedUsersAsync.when(
                        data: (joinedUsers) {
                          if (joinedUsers.isEmpty) {
                            return const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.people_outline,
                                    size: 64,
                                    color: AppColors.mediumText,
                                  ),
                                  SizedBox(height: AppDimensions.paddingM),
                                  Text(
                                    'هیچ بەشداربووێک نییە',
                                    style: TextStyle(
                                      color: AppColors.mediumText,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          return ListView.builder(
                            itemCount: joinedUsers.length,
                            itemBuilder: (context, index) {
                              if (index < 0 || index >= joinedUsers.length) {
                                return const SizedBox.shrink(); // Safeguard against invalid indices
                              }

                              final joinedUser = joinedUsers[index];
                              return Container(
                                margin: const EdgeInsets.only(
                                  bottom: AppDimensions.paddingS,
                                ),
                                padding: const EdgeInsets.all(
                                  AppDimensions.paddingM,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.surface3,
                                  borderRadius: BorderRadius.circular(
                                    AppDimensions.radiusM,
                                  ),
                                  border: Border.all(color: AppColors.border1),
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundColor: AppColors.primaryRed,
                                      backgroundImage:
                                          joinedUser.userPhotoUrl != null
                                              ? NetworkImage(
                                                joinedUser.userPhotoUrl!,
                                              )
                                              : null,
                                      child:
                                          (joinedUser.userDisplayName != null &&
                                                  joinedUser
                                                      .userDisplayName!
                                                      .isNotEmpty)
                                              ? Text(
                                                joinedUser.userDisplayName!
                                                    .substring(0, 1)
                                                    .toUpperCase(),
                                                style: const TextStyle(
                                                  color: AppColors.white,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              )
                                              : (joinedUser.userEmail.isNotEmpty
                                                  ? Text(
                                                    joinedUser.userEmail
                                                        .substring(0, 1)
                                                        .toUpperCase(),
                                                    style: const TextStyle(
                                                      color: AppColors.white,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  )
                                                  : Text(
                                                    '?',
                                                    style: const TextStyle(
                                                      color: AppColors.white,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  )),
                                    ),
                                    const SizedBox(
                                      width: AppDimensions.paddingM,
                                    ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            joinedUser.userDisplayName ??
                                                joinedUser.userEmail,
                                            style: const TextStyle(
                                              color: AppColors.lightText,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          if (joinedUser.userDisplayName !=
                                              null)
                                            Text(
                                              joinedUser.userEmail,
                                              style: const TextStyle(
                                                color: AppColors.mediumText,
                                                fontSize: 12,
                                              ),
                                            ),
                                          if (joinedUser.accountType ==
                                                  'guest' &&
                                              joinedUser.guestAccountNumber !=
                                                  null)
                                            Text(
                                              'ژمارەی هەژمار: ${joinedUser.guestAccountNumber}',
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
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color:
                                                joinedUser.accountType ==
                                                        'guest'
                                                    ? AppColors.accentYellow
                                                        .withOpacity(0.2)
                                                    : AppColors.primaryTeal
                                                        .withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: Text(
                                            joinedUser.accountType == 'guest'
                                                ? 'میوان'
                                                : 'تۆمارکراو',
                                            style: TextStyle(
                                              color:
                                                  joinedUser.accountType ==
                                                          'guest'
                                                      ? AppColors.accentYellow
                                                      : AppColors.primaryTeal,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${joinedUser.joinedAt.day}/${joinedUser.joinedAt.month}',
                                          style: const TextStyle(
                                            color: AppColors.mediumText,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                        loading:
                            () => const Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.primaryRed,
                                ),
                              ),
                            ),
                        error:
                            (error, _) => Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.error_outline,
                                    size: 48,
                                    color: AppColors.error,
                                  ),
                                  const SizedBox(
                                    height: AppDimensions.paddingM,
                                  ),
                                  Text(
                                    'هەڵەیەک ڕوویدا: $error',
                                    style: const TextStyle(
                                      color: AppColors.error,
                                      fontSize: 14,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
