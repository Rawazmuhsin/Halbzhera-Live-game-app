// File: lib/widgets/lobby/lobby_header.dart
// Description: Lobby screen header with game info and leave button

// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import '../../models/scheduled_game_model.dart';

class LobbyHeader extends StatelessWidget implements PreferredSizeWidget {
  final ScheduledGameModel game;
  final VoidCallback onLeave;
  final bool isPreviewMode; // Add this parameter

  const LobbyHeader({
    super.key,
    required this.game,
    required this.onLeave,
    this.isPreviewMode = false, // Default to false (active mode)
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.surface2,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        game.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.lightText,
                        ),
                      ),
                    ),
                    // Show preview indicator if in preview mode
                    if (isPreviewMode)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDimensions.paddingS,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accentYellow.withOpacity(0.2),
                          border: Border.all(
                            color: AppColors.accentYellow.withOpacity(0.5),
                          ),
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusS,
                          ),
                        ),
                        child: const Text(
                          'پێشبینین',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.accentYellow,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.paddingM,
                    vertical: AppDimensions.paddingS,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primaryTeal,
                        AppColors.primaryTeal.withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                  ),
                  child: Text(
                    game.categoryName,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: AppDimensions.paddingM),
          child: ElevatedButton(
            onPressed: onLeave,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusL),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.paddingL,
                vertical: AppDimensions.paddingM,
              ),
            ),
            child: Text(
              isPreviewMode ? 'گەڕانەوە' : 'جێهێشتن',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
