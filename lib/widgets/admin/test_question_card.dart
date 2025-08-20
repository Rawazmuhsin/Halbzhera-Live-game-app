import 'package:flutter/material.dart';
import 'package:halbzhera/models/question_model.dart';

class TestQuestionCard extends StatelessWidget {
  final QuestionModel question;
  final int index;
  final VoidCallback? onQuestionUpdated;

  const TestQuestionCard({
    super.key,
    required this.question,
    required this.index,
    this.onQuestionUpdated,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F3460),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2), width: 1),
      ),
      child: Text(
        '$index. ${question.question}',
        style: const TextStyle(color: Colors.white),
      ),
    );
  }
}
