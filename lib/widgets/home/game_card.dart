// File: lib/widgets/home/game_card.dart
// Description: Individual game card with lobby navigation

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../utils/constants.dart';
import '../../models/scheduled_game_model.dart';
import '../../providers/joined_user_provider.dart';
import '../../providers/auth_provider.dart';
import '../../screens/games/lobby_screen.dart';
import 'game_category_badge.dart';
import 'game_title.dart';
import 'game_description.dart';
import 'game_details.dart';
import 'join_game_button.dart';

class GameCard extends ConsumerWidget {
  final ScheduledGameModel game;

  const GameCard({super.key, required this.game});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasJoinedAsync = ref.watch(hasUserJoinedGameProvider(game.id));
    final isLoading = ref.watch(joinGameLoadingProvider);

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
          hasJoinedAsync.when(
            data: (hasJoined) {
              if (hasJoined) {
                return _buildJoinedButtons(context, ref);
              } else {
                return JoinGameButton(
                  onPressed: isLoading ? null : () => _joinGame(context, ref),
                  text: 'بەشداری بکە',
                );
              }
            },
            loading:
                () => const JoinGameButton(onPressed: null, text: 'بارکردن...'),
            error:
                (_, __) => JoinGameButton(
                  onPressed: isLoading ? null : () => _joinGame(context, ref),
                  text: 'بەشداری بکە',
                ),
          ),
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

  void _joinGame(BuildContext context, WidgetRef ref) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تکایە سەرەتا چوارچێوەکە بکەرەوە'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Check if user is guest (anonymous) and needs account number
    String? guestAccountNumber;
    if (currentUser.isAnonymous) {
      guestAccountNumber = await _showGuestAccountDialog(context);
      if (guestAccountNumber == null || guestAccountNumber.isEmpty) {
        return; // User cancelled or didn't provide account number
      }
    }

    try {
      final joinId = await ref
          .read(joinedUserNotifierProvider.notifier)
          .joinGame(gameId: game.id, guestAccountNumber: guestAccountNumber);

      if (joinId != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('بە سەرکەوتووی بەشداری یاریی "${game.name}" کرد'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('هەڵە لە بەشداری کردن: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Widget _buildJoinedButtons(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final gameTime = game.scheduledTime;
    final timeDifference = gameTime.difference(now);

    // Check if game has started (scheduled time has passed)
    final hasGameStarted = timeDifference.inSeconds <= 0;

    return Column(
      children: [
        // Lobby Button - Always available if user joined
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => _navigateToLobby(context, hasGameStarted),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  hasGameStarted
                      ? AppColors
                          .primaryRed // Red if game started (active lobby)
                      : AppColors
                          .primaryTeal, // Teal if waiting (preview lobby)
              foregroundColor: AppColors.white,
              padding: const EdgeInsets.symmetric(
                vertical: AppDimensions.paddingM,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusL),
              ),
              elevation: 4,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  hasGameStarted ? Icons.play_arrow : Icons.people,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  hasGameStarted
                      ? 'چوونە ناو لۆبی' // Active lobby (1-minute countdown)
                      : 'بینینی لۆبی', // Preview lobby (waiting state)
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: AppDimensions.paddingM),

        // Leave Game Button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => _leaveGame(context, ref),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.error),
              foregroundColor: AppColors.error,
              padding: const EdgeInsets.symmetric(
                vertical: AppDimensions.paddingM,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusL),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.exit_to_app, size: 20),
                SizedBox(width: 8),
                Text(
                  'جێهێشتنی یاری',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _navigateToLobby(BuildContext context, bool hasGameStarted) {
    // Always allow lobby access for joined users
    // The lobby screen itself will handle the different states

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => LobbyScreen(
              game: game,
              isPreviewMode: !hasGameStarted, // Preview if game hasn't started
            ),
      ),
    );
  }

  void _leaveGame(BuildContext context, WidgetRef ref) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.surface2,
          title: const Text(
            'جێهێشتنی یاری',
            style: TextStyle(color: AppColors.lightText),
          ),
          content: Text(
            'دڵنیایت لە جێهێشتنی یاریی "${game.name}"؟',
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
                'جێهێشتن',
                style: TextStyle(color: AppColors.white),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        final success = await ref
            .read(joinedUserNotifierProvider.notifier)
            .leaveGame(game.id);

        if (success && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('بە سەرکەوتووی یاریی "${game.name}" جێهێشت'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('هەڵە لە جێهێشتنی یاری: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  Future<String?> _showGuestAccountDialog(BuildContext context) async {
    final controller = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.surface2,
          title: const Text(
            'ژمارەی هەژمار',
            style: TextStyle(color: AppColors.lightText),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'تکایە ژمارەی هەژمارت بنووسە:',
                style: TextStyle(color: AppColors.mediumText),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                style: const TextStyle(color: AppColors.lightText),
                decoration: InputDecoration(
                  hintText: 'ژمارەی هەژمار',
                  hintStyle: TextStyle(color: AppColors.mediumText),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.border1),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.border1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.primaryRed),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(null),
              child: const Text(
                'پاشگەزبوونەوە',
                style: TextStyle(color: AppColors.mediumText),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final accountNumber = controller.text.trim();
                Navigator.of(dialogContext).pop(accountNumber);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryRed,
              ),
              child: const Text(
                'دووپاتکردنەوە',
                style: TextStyle(color: AppColors.white),
              ),
            ),
          ],
        );
      },
    );
  }
}
