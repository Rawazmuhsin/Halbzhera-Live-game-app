// File: lib/screens/admin/add_questions_screen.dart
// Description: Screen for selecting game section and adding questions

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../utils/constants.dart';
import '../../models/scheduled_game_model.dart';
import '../../providers/question_provider.dart';
import '../../widgets/common/gradient_background.dart';
import '../../widgets/admin/game_section_card.dart';
import 'create_question_screen.dart';
import 'section_questions_screen.dart';

class AddQuestionsScreen extends ConsumerWidget {
  const AddQuestionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheduledGamesAsync = ref.watch(scheduledGamesStreamProvider);

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            'پرسیار زیادکردن',
            style: TextStyle(color: AppColors.lightText),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.lightText),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header section
              Container(
                padding: const EdgeInsets.all(AppDimensions.paddingL),
                decoration: BoxDecoration(
                  color: AppColors.surface2,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                  border: Border.all(color: AppColors.border1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.quiz,
                          color: AppColors.primaryTeal,
                          size: 28,
                        ),
                        const SizedBox(width: AppDimensions.paddingM),
                        const Expanded(
                          child: Text(
                            'بەشێک هەڵبژێرە بۆ زیادکردنی پرسیار',
                            style: TextStyle(
                              color: AppColors.lightText,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.paddingM),
                    const Text(
                      'بۆ هەر بەشێک کەمتر ١٠ پرسیار و زۆرتر ١٥ پرسیار پێویستە تا یاری دروست بکرێت',
                      style: TextStyle(
                        color: AppColors.mediumText,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimensions.paddingL),

              // Games list
              Expanded(
                child: scheduledGamesAsync.when(
                  data: (games) {
                    if (games.isEmpty) {
                      return _buildEmptyState(context);
                    }

                    return ListView.builder(
                      itemCount: games.length,
                      itemBuilder: (context, index) {
                        final game = games[index];
                        return Padding(
                          padding: const EdgeInsets.only(
                            bottom: AppDimensions.paddingM,
                          ),
                          child: GameSectionCard(
                            game: game,
                            onAddQuestions:
                                () => _navigateToAddQuestions(context, game),
                            onViewQuestions:
                                () => _navigateToViewQuestions(context, game),
                          ),
                        );
                      },
                    );
                  },
                  loading:
                      () => const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primaryTeal,
                        ),
                      ),
                  error:
                      (error, stack) => Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: AppColors.error,
                              size: 48,
                            ),
                            const SizedBox(height: AppDimensions.paddingM),
                            Text(
                              'هەڵە: $error',
                              style: const TextStyle(color: AppColors.error),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: AppDimensions.paddingM),
                            ElevatedButton(
                              onPressed:
                                  () =>
                                      ref.refresh(scheduledGamesStreamProvider),
                              child: const Text('هەوڵدانەوە'),
                            ),
                          ],
                        ),
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.games_outlined,
            color: AppColors.mediumText,
            size: 64,
          ),
          const SizedBox(height: AppDimensions.paddingL),
          const Text(
            'هیچ بەشێک نەدۆزرایەوە',
            style: TextStyle(
              color: AppColors.lightText,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppDimensions.paddingM),
          const Text(
            'سەرەتا بەش دروستبکە، پاشان پرسیار زیادبکە',
            style: TextStyle(color: AppColors.mediumText, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppDimensions.paddingL),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(Icons.add),
            label: const Text('بەش دروستبکە'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryTeal,
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.paddingL,
                vertical: AppDimensions.paddingM,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToAddQuestions(BuildContext context, ScheduledGameModel game) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateQuestionScreen(gameSection: game),
      ),
    );
  }

  void _navigateToViewQuestions(BuildContext context, ScheduledGameModel game) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SectionQuestionsScreen(gameSection: game),
      ),
    );
  }
}
