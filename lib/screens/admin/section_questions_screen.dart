// File: lib/screens/admin/section_questions_screen.dart
// Description: Screen to view all questions in a game section with pagination

// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halbzhera/widgets/admin/question_item_card.dart';
import '../../models/scheduled_game_model.dart';
import '../../providers/question_provider.dart';
import 'create_question_screen.dart';

class SectionQuestionsScreen extends ConsumerStatefulWidget {
  final ScheduledGameModel gameSection;

  const SectionQuestionsScreen({super.key, required this.gameSection});

  @override
  ConsumerState<SectionQuestionsScreen> createState() =>
      _SectionQuestionsScreenState();
}

class _SectionQuestionsScreenState
    extends ConsumerState<SectionQuestionsScreen> {
  int _displayLimit = 20; // Start with 20 questions

  void _loadMore() {
    setState(() {
      _displayLimit += 20; // Load 20 more questions
    });
  }

  @override
  Widget build(BuildContext context) {
    final questionsAsync = ref.watch(
      questionsByCategoryLimitedProvider((
        categoryId: widget.gameSection.categoryName,
        limit: _displayLimit,
      )),
    );
    final questionCount = ref.watch(
      totalQuestionCountProvider(widget.gameSection.categoryName),
    );

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.gameSection.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'پرسیارەکان',
              style: TextStyle(color: Colors.grey[400], fontSize: 14),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: questionCount.when(
                data:
                    (count) =>
                        count >= 10
                            ? Colors.green.withOpacity(0.2)
                            : Colors.orange.withOpacity(0.2),
                loading: () => Colors.grey.withOpacity(0.2),
                error: (_, __) => Colors.red.withOpacity(0.2),
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: questionCount.when(
              data:
                  (count) => Text(
                    '$count/10',
                    style: TextStyle(
                      color: count >= 10 ? Colors.green : Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              loading:
                  () => const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                    ),
                  ),
              error:
                  (_, __) => const Text(
                    '0/10',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
            ),
          ),
        ],
      ),
      body: questionsAsync.when(
        data: (questions) {
          if (questions.isEmpty) {
            return _buildEmptyState(context);
          }

          return Column(
            children: [
              // Section Info Card
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F3460),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.blue.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.gamepad, color: Colors.blue[300], size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.gameSection.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (widget.gameSection.description.isNotEmpty)
                                Text(
                                  widget.gameSection.description,
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 14,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildInfoChip(
                          'کۆی پرسیار',
                          '${questions.length}',
                          Icons.quiz,
                          questions.length >= 10 ? Colors.green : Colors.orange,
                        ),
                        const SizedBox(width: 12),
                        _buildInfoChip(
                          'خاڵ',
                          widget.gameSection.prize,
                          Icons.stars,
                          Colors.amber,
                        ),
                        const SizedBox(width: 12),
                        _buildInfoChip(
                          'کات',
                          '${widget.gameSection.duration} خولەک',
                          Icons.timer,
                          Colors.blue,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Questions List
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: questions.length,
                        itemBuilder: (context, index) {
                          final question = questions[index];
                          return QuestionItemCard(
                            key: ValueKey(question.id),
                            question: question,
                            index: index + 1,
                            onQuestionUpdated: () {
                              // Refresh the questions list
                              ref.invalidate(
                                questionsByCategoryLimitedProvider((
                                  categoryId: widget.gameSection.categoryName,
                                  limit: _displayLimit,
                                )),
                              );
                            },
                          );
                        },
                      ),
                    ),
                    // Load More button if there are more questions
                    questionCount.when(
                      data: (totalCount) {
                        if (questions.length < totalCount) {
                          return Container(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                ElevatedButton.icon(
                                  onPressed: _loadMore,
                                  icon: const Icon(Icons.arrow_downward),
                                  label: Text(
                                    'بارکردنی زیاتر (${questions.length}/$totalCount)',
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        return const SizedBox();
                      },
                      loading: () => const SizedBox(),
                      error: (_, __) => const SizedBox(),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
        loading:
            () => const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
            ),
        error:
            (error, stackTrace) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: Colors.red[300], size: 64),
                  const SizedBox(height: 16),
                  Text(
                    'هەڵەیەک ڕوویدا',
                    style: TextStyle(
                      color: Colors.red[300],
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    error.toString(),
                    style: TextStyle(color: Colors.grey[400], fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) =>
                      CreateQuestionScreen(gameSection: widget.gameSection),
            ),
          );
        },
        backgroundColor: Colors.blue,
        icon: const Icon(Icons.add),
        label: const Text(
          'پرسیاری نوێ',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.quiz_outlined, color: Colors.grey[600], size: 80),
          const SizedBox(height: 24),
          Text(
            'هیچ پرسیارێک نەدۆزرایەوە',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'سەرەتا پرسیار زیاد بکە بۆ ئەم بەشە',
            style: TextStyle(color: Colors.grey[500], fontSize: 16),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) =>
                          CreateQuestionScreen(gameSection: widget.gameSection),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            icon: const Icon(Icons.add),
            label: const Text(
              'یەکەم پرسیار زیاد بکە',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                label,
                style: TextStyle(color: color.withOpacity(0.7), fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
