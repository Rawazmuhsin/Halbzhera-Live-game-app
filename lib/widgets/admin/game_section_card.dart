// File: lib/widgets/admin/game_section_card.dart
// Description: Card widget for displaying game section with question status

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../utils/constants.dart';
import '../../models/scheduled_game_model.dart';
import '../../providers/question_provider.dart';

class GameSectionCard extends ConsumerWidget {
  final ScheduledGameModel game;
  final VoidCallback onAddQuestions;
  final VoidCallback? onViewQuestions;

  const GameSectionCard({
    super.key,
    required this.game,
    required this.onAddQuestions,
    this.onViewQuestions,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get total question count for this category
    final questionCountAsync = ref.watch(
      totalQuestionCountProvider(game.categoryName),
    );

    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        border: Border.all(color: AppColors.border1),
        boxShadow: [
          BoxShadow(
            color: AppColors.surface1.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: questionCountAsync.when(
        data: (questionCount) => _buildCardContent(context, questionCount),
        loading: () => _buildCardContent(context, 0),
        error: (error, stack) => _buildCardContent(context, 0),
      ),
    );
  }

  Widget _buildCardContent(BuildContext context, int questionCount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppDimensions.paddingS),
              decoration: BoxDecoration(
                color: AppColors.primaryTeal.withOpacity(0.2),
                borderRadius: BorderRadius.circular(AppDimensions.radiusS),
              ),
              child: const Icon(
                Icons.games,
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
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    game.categoryName,
                    style: const TextStyle(
                      color: AppColors.mediumText,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            _buildStatusBadge(questionCount),
          ],
        ),

        const SizedBox(height: AppDimensions.paddingM),

        // Description
        Text(
          game.description,
          style: const TextStyle(color: AppColors.mediumText, fontSize: 14),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),

        const SizedBox(height: AppDimensions.paddingM),

        // Game details
        Row(
          children: [
            _buildDetailChip(
              icon: Icons.timer,
              label: '${game.duration} خولەک',
              color: AppColors.info,
            ),
            const SizedBox(width: AppDimensions.paddingS),
            _buildDetailChip(
              icon: Icons.people,
              label: '${game.maxParticipants} کەس',
              color: AppColors.primaryRed,
            ),
            const SizedBox(width: AppDimensions.paddingS),
            _buildDetailChip(
              icon: Icons.quiz,
              label: '${game.questionsCount} پرسیار',
              color: AppColors.primaryTeal,
            ),
          ],
        ),

        const SizedBox(height: AppDimensions.paddingM),

        // Question progress
        _buildQuestionProgress(questionCount, game.questionsCount),

        const SizedBox(height: AppDimensions.paddingM),

        // Action buttons
        Row(
          children: [
            // View Questions Button
            if (questionCount > 0)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onViewQuestions,
                  icon: const Icon(Icons.list_alt),
                  label: const Text('بینینی پرسیارەکان'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryTeal,
                    side: const BorderSide(color: AppColors.primaryTeal),
                    padding: const EdgeInsets.all(AppDimensions.paddingM),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusM,
                      ),
                    ),
                  ),
                ),
              ),
            if (questionCount > 0)
              const SizedBox(width: AppDimensions.paddingS),
            // Add Questions Button
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onAddQuestions,
                icon: const Icon(Icons.add_circle_outline),
                label: Text(
                  questionCount > 0 ? 'زیادکردنی پرسیار' : 'پرسیار زیادکردن',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryTeal,
                  padding: const EdgeInsets.all(AppDimensions.paddingM),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusBadge(int questionCount) {
    Color badgeColor;
    String statusText;
    IconData statusIcon;

    if (questionCount >= 15) {
      badgeColor = AppColors.success;
      statusText = 'تەواو';
      statusIcon = Icons.check_circle;
    } else if (questionCount >= 10) {
      badgeColor = AppColors.warning;
      statusText = 'کەم';
      statusIcon = Icons.warning;
    } else {
      badgeColor = AppColors.error;
      statusText = 'ناتەواو';
      statusIcon = Icons.error;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingS,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
        border: Border.all(color: badgeColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusIcon, color: badgeColor, size: 14),
          const SizedBox(width: 4),
          Text(
            statusText,
            style: TextStyle(
              color: badgeColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingS,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionProgress(int questionCount, int requiredQuestions) {
    final progress = questionCount / requiredQuestions;
    final progressClamped = progress.clamp(0.0, 1.0);

    Color progressColor;
    if (questionCount >= 15) {
      progressColor = AppColors.success;
    } else if (questionCount >= 10) {
      progressColor = AppColors.warning;
    } else {
      progressColor = AppColors.error;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'پێشکەوتنی پرسیارەکان',
              style: TextStyle(
                color: AppColors.lightText,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '$questionCount/$requiredQuestions',
              style: TextStyle(
                color: progressColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.paddingS),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppDimensions.radiusS),
          child: LinearProgressIndicator(
            value: progressClamped,
            backgroundColor: AppColors.surface3,
            valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            minHeight: 8,
          ),
        ),
        const SizedBox(height: 4),
        if (questionCount < 10)
          Text(
            'کەمتر ${10 - questionCount} پرسیار بۆ کەمترین ژمارە',
            style: const TextStyle(color: AppColors.error, fontSize: 12),
          )
        else if (questionCount < 15)
          Text(
            'کەمتر ${15 - questionCount} پرسیار بۆ تەواوکردن',
            style: const TextStyle(color: AppColors.warning, fontSize: 12),
          )
        else
          const Text(
            'ئامادەیە بۆ یاری!',
            style: TextStyle(color: AppColors.success, fontSize: 12),
          ),
      ],
    );
  }
}
