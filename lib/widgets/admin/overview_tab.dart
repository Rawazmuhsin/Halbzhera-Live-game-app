// File: lib/widgets/admin/overview_tab.dart
// Description: Overview tab content widget

// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../utils/constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/live_game_provider.dart';
import '../../screens/admin/create_game_screen.dart';
import '../../screens/admin/add_questions_screen.dart';
import '../../screens/admin/send_notification_screen.dart';
import '../../widgets/common/loading_widget.dart';
import 'stat_card.dart';
import 'action_card.dart';
import 'recent_activity_card.dart';

class OverviewTab extends ConsumerWidget {
  const OverviewTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.paddingM),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight - AppDimensions.paddingM * 2,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatsSection(ref),
                const SizedBox(height: AppDimensions.paddingL),
                _buildQuickActionsSection(),
                const SizedBox(height: AppDimensions.paddingL),
                _buildRecentActivitySection(ref),
                const SizedBox(
                  height: AppDimensions.paddingL,
                ), // Extra bottom padding
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatsSection(WidgetRef ref) {
    final liveGameStatsAsync = ref.watch(liveGameStatsProvider);

    return liveGameStatsAsync.when(
      data:
          (stats) => LayoutBuilder(
            builder: (context, constraints) {
              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: AppDimensions.paddingM,
                crossAxisSpacing: AppDimensions.paddingM,
                childAspectRatio: constraints.maxWidth > 600 ? 1.8 : 1.3,
                children: [
                  StatCard(
                    title: 'کۆی بەکارهێنەران',
                    value: stats['totalUsers']?.toString() ?? '0',
                    icon: Icons.people,
                    color: AppColors.primaryTeal,
                    trend: '+15.2%',
                    onTap: () => _navigateToUsers(),
                  ),
                  StatCard(
                    title: 'یاری ئەمڕۆ',
                    value: stats['todayGames']?.toString() ?? '0',
                    icon: Icons.today,
                    color: AppColors.primaryRed,
                    trend: '+8.5%',
                    onTap: () => _navigateToTodaysGames(),
                  ),
                  StatCard(
                    title: 'بەشداربووان چالاک',
                    value: stats['activeParticipants']?.toString() ?? '0',
                    icon: Icons.group,
                    color: AppColors.accentYellow,
                    trend: '+12.3%',
                    onTap: () => _navigateToActiveUsers(),
                  ),
                  StatCard(
                    title: 'کۆی یاریەکان',
                    value: stats['totalGames']?.toString() ?? '0',
                    icon: Icons.sports_esports,
                    color: AppColors.success,
                    trend: '+25.8%',
                    onTap: () => _navigateToAllGames(),
                  ),
                ],
              );
            },
          ),
      loading:
          () => const LoadingWidget(
            message: 'بارکردنی ئامارەکان...',
            showMessage: true,
          ),
      error:
          (error, _) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 48, color: AppColors.error),
                const SizedBox(height: AppDimensions.paddingM),
                Text(
                  'هەڵەیەک ڕوویدا: $error',
                  style: const TextStyle(color: AppColors.error),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildQuickActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'کردارە خێراکان',
          style: TextStyle(
            color: AppColors.lightText,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppDimensions.paddingM),
        LayoutBuilder(
          builder: (context, constraints) {
            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: AppDimensions.paddingM,
              crossAxisSpacing: AppDimensions.paddingM,
              childAspectRatio: constraints.maxWidth > 600 ? 3.0 : 2.2,
              children: [
                ActionCard(
                  title: 'یاری نوێ دروستبکە',
                  icon: Icons.add_circle,
                  color: AppColors.primaryRed,
                  onTap: () => _navigateToCreateGame(context),
                ),
                ActionCard(
                  title: 'بەشی نوێ زیادبکە',
                  icon: Icons.category,
                  color: AppColors.primaryTeal,
                  onTap: () => _navigateToCreateCategory(context),
                ),
                ActionCard(
                  title: 'پرسیار زیادبکە',
                  icon: Icons.quiz,
                  color: AppColors.accentYellow,
                  onTap: () => _navigateToAddQuestions(context),
                ),
                ActionCard(
                  title: 'ناردنی ئاگاداری',
                  icon: Icons.notifications_active,
                  color: Colors.orange,
                  onTap: () => _navigateToSendNotification(context),
                ),
                ActionCard(
                  title: 'یاری زیندوو ببینە',
                  icon: Icons.live_tv,
                  color: AppColors.success,
                  onTap: () => _navigateToLiveMonitor(context),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildRecentActivitySection(WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'چالاکی دواییە',
              style: TextStyle(
                color: AppColors.lightText,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: _navigateToFullActivity,
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
            final upcomingGamesAsync = ref.watch(upcomingGamesProvider);

            return upcomingGamesAsync.when(
              data:
                  (games) => Column(
                    children:
                        games
                            .take(5)
                            .map(
                              (game) => RecentActivityCard(
                                title: game.title,
                                subtitle:
                                    'نەخشەکراو بۆ ${_formatDateTime(game.scheduledTime)}',
                                icon: Icons.schedule,
                                color: AppColors.primaryTeal,
                                onTap: () => _navigateToGameDetails(game.id),
                              ),
                            )
                            .toList(),
                  ),
              loading: () => const LoadingWidget(),
              error:
                  (error, _) => Text(
                    'هەڵەیەک ڕوویدا: $error',
                    style: const TextStyle(color: AppColors.error),
                  ),
            );
          },
        ),
      ],
    );
  }

  // Navigation methods
  void _navigateToUsers() {
    // Navigate to users management
    print('Navigate to users');
  }

  void _navigateToTodaysGames() {
    // Navigate to today's games
    print('Navigate to today\'s games');
  }

  void _navigateToActiveUsers() {
    // Navigate to active users
    print('Navigate to active users');
  }

  void _navigateToAllGames() {
    // Navigate to all games
    print('Navigate to all games');
  }

  void _navigateToCreateGame(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateGameScreen()),
    );
  }

  void _navigateToCreateCategory(BuildContext context) {
    // Navigate to create category page
    print('Navigate to create category');
  }

  void _navigateToAddQuestions(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddQuestionsScreen()),
    );
  }

  void _navigateToLiveMonitor(BuildContext context) {
    // Navigate to live game monitor
    print('Navigate to live monitor');
  }

  void _navigateToSendNotification(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SendNotificationScreen()),
    );
  }

  void _navigateToFullActivity() {
    // Navigate to full activity page
    print('Navigate to full activity');
  }

  void _navigateToGameDetails(String gameId) {
    // Navigate to game details
    print('Navigate to game details: $gameId');
  }

  String _formatDateTime(DateTime dateTime) {
    // Format date time in Kurdish
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} - ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
