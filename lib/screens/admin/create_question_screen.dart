// File: lib/screens/admin/create_question_screen.dart
// Description: Screen for creating questions for a specific game section

// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../utils/constants.dart';
import '../../models/scheduled_game_model.dart';
import '../../models/question_model.dart';
import '../../providers/question_provider.dart';
import '../../widgets/common/gradient_background.dart';

class CreateQuestionScreen extends ConsumerStatefulWidget {
  final ScheduledGameModel gameSection;

  const CreateQuestionScreen({super.key, required this.gameSection});

  @override
  ConsumerState<CreateQuestionScreen> createState() =>
      _CreateQuestionScreenState();
}

class _CreateQuestionScreenState extends ConsumerState<CreateQuestionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _questionController = TextEditingController();
  final _explanationController = TextEditingController();
  final _pointsController = TextEditingController();
  final _timeLimitController = TextEditingController();

  QuestionType _selectedType = QuestionType.multipleChoice;
  QuestionDifficulty _selectedDifficulty = QuestionDifficulty.medium;
  List<String> _options = ['', '', '', ''];
  int _correctAnswerIndex = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _pointsController.text = '10';
    _timeLimitController.text = '15';
  }

  @override
  void dispose() {
    _questionController.dispose();
    _explanationController.dispose();
    _pointsController.dispose();
    _timeLimitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final questionCountAsync = ref.watch(
      totalQuestionCountProvider(widget.gameSection.categoryName),
    );

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            'پرسیار نوێ دروستبکە',
            style: TextStyle(color: AppColors.lightText),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.lightText),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: questionCountAsync.when(
          data: (questionCount) => _buildBody(context, questionCount),
          loading: () => _buildBody(context, 0),
          error: (error, stack) => _buildBody(context, 0),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, int questionCount) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section info header
            _buildSectionHeader(questionCount),

            const SizedBox(height: AppDimensions.paddingL),

            // Question form
            _buildQuestionForm(),

            const SizedBox(height: AppDimensions.paddingXL),

            // Action buttons
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(int questionCount) {
    final progress = questionCount / widget.gameSection.questionsCount;
    final progressClamped = progress.clamp(0.0, 1.0);

    Color progressColor;
    if (questionCount >= 15) {
      progressColor = AppColors.success;
    } else if (questionCount >= 10) {
      progressColor = AppColors.warning;
    } else {
      progressColor = AppColors.error;
    }

    return Container(
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
              Container(
                padding: const EdgeInsets.all(AppDimensions.paddingS),
                decoration: BoxDecoration(
                  color: AppColors.primaryTeal.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                ),
                child: const Icon(Icons.quiz, color: AppColors.primaryTeal),
              ),
              const SizedBox(width: AppDimensions.paddingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.gameSection.name,
                      style: const TextStyle(
                        color: AppColors.lightText,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.gameSection.categoryName,
                      style: const TextStyle(
                        color: AppColors.mediumText,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: AppDimensions.paddingM),

          // Progress
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
                '$questionCount/${widget.gameSection.questionsCount}',
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
        ],
      ),
    );
  }

  Widget _buildQuestionForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Question text
        _buildSection(
          title: 'پرسیار',
          icon: Icons.help_outline,
          children: [
            TextFormField(
              controller: _questionController,
              maxLines: 3,
              style: const TextStyle(color: AppColors.lightText),
              decoration: _getInputDecoration(hintText: 'پرسیارەکەت بنووسە...'),
              validator: (value) {
                if (value?.trim().isEmpty ?? true) {
                  return 'پرسیار پێویستە';
                }
                return null;
              },
            ),
          ],
        ),

        const SizedBox(height: AppDimensions.paddingL),

        // Question type and difficulty
        Row(
          children: [
            Expanded(
              child: _buildSection(
                title: 'جۆری پرسیار',
                icon: Icons.category,
                children: [
                  DropdownButtonFormField<QuestionType>(
                    value: _selectedType,
                    style: const TextStyle(color: AppColors.lightText),
                    decoration: _getInputDecoration(),
                    dropdownColor: AppColors.surface3,
                    items:
                        QuestionType.values.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(_getTypeText(type)),
                          );
                        }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedType = value!;
                        if (_selectedType == QuestionType.trueFalse) {
                          _options = ['ڕاست', 'هەڵە', '', ''];
                          _correctAnswerIndex = 0;
                        } else {
                          _options = ['', '', '', ''];
                          _correctAnswerIndex = 0;
                        }
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppDimensions.paddingM),
            Expanded(
              child: _buildSection(
                title: 'ئاستی ئاڵۆزی',
                icon: Icons.trending_up,
                children: [
                  DropdownButtonFormField<QuestionDifficulty>(
                    value: _selectedDifficulty,
                    style: const TextStyle(color: AppColors.lightText),
                    decoration: _getInputDecoration(),
                    dropdownColor: AppColors.surface3,
                    items:
                        QuestionDifficulty.values.map((difficulty) {
                          return DropdownMenuItem(
                            value: difficulty,
                            child: Text(_getDifficultyText(difficulty)),
                          );
                        }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedDifficulty = value!;
                      });
                    },
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: AppDimensions.paddingL),

        // Options (if multiple choice or true/false)
        if (_selectedType != QuestionType.fillInTheBlank) ...[
          _buildSection(
            title:
                _selectedType == QuestionType.trueFalse
                    ? 'هەڵبژاردەکان'
                    : 'هەڵبژاردەکان',
            icon: Icons.list,
            children: [..._buildOptionFields()],
          ),
          const SizedBox(height: AppDimensions.paddingL),
        ],

        // Correct answer
        _buildSection(
          title: 'وەڵامی دروست',
          icon: Icons.check_circle,
          children: [
            if (_selectedType == QuestionType.fillInTheBlank)
              TextFormField(
                style: const TextStyle(color: AppColors.lightText),
                decoration: _getInputDecoration(
                  hintText: 'وەڵامی دروست بنووسە...',
                ),
                onChanged: (value) {
                  _options[0] = value;
                },
                validator: (value) {
                  if (value?.trim().isEmpty ?? true) {
                    return 'وەڵامی دروست پێویستە';
                  }
                  return null;
                },
              )
            else
              DropdownButtonFormField<int>(
                value: _correctAnswerIndex,
                style: const TextStyle(color: AppColors.lightText),
                decoration: _getInputDecoration(),
                dropdownColor: AppColors.surface3,
                items: _getCorrectAnswerItems(),
                onChanged: (value) {
                  setState(() {
                    _correctAnswerIndex = value!;
                  });
                },
              ),
          ],
        ),

        const SizedBox(height: AppDimensions.paddingL),

        // Settings
        Row(
          children: [
            Expanded(
              child: _buildSection(
                title: 'خاڵ',
                icon: Icons.star,
                children: [
                  TextFormField(
                    controller: _pointsController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: AppColors.lightText),
                    decoration: _getInputDecoration(),
                    validator: (value) {
                      if (value?.isEmpty ?? true) return 'خاڵ پێویستە';
                      final points = int.tryParse(value!);
                      if (points == null || points <= 0) {
                        return 'خاڵ دروست نییە';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppDimensions.paddingM),
            Expanded(
              child: _buildSection(
                title: 'کات (چرکە)',
                icon: Icons.timer,
                children: [
                  TextFormField(
                    controller: _timeLimitController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: AppColors.lightText),
                    decoration: _getInputDecoration(),
                    validator: (value) {
                      if (value?.isEmpty ?? true) return 'کات پێویستە';
                      final time = int.tryParse(value!);
                      if (time == null || time <= 0) {
                        return 'کات دروست نییە';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: AppDimensions.paddingL),

        // Explanation (optional)
        _buildSection(
          title: 'ڕوونکردنەوە (ئیختیاری)',
          icon: Icons.info_outline,
          children: [
            TextFormField(
              controller: _explanationController,
              maxLines: 2,
              style: const TextStyle(color: AppColors.lightText),
              decoration: _getInputDecoration(
                hintText: 'ڕوونکردنەوەی وەڵام...',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: AppColors.lightText, size: 18),
            const SizedBox(width: AppDimensions.paddingS),
            Text(
              title,
              style: const TextStyle(
                color: AppColors.lightText,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.paddingS),
        ...children,
      ],
    );
  }

  List<Widget> _buildOptionFields() {
    final optionCount = _selectedType == QuestionType.trueFalse ? 2 : 4;

    return List.generate(optionCount, (index) {
      if (_selectedType == QuestionType.trueFalse && index < 2) {
        return Padding(
          padding: const EdgeInsets.only(bottom: AppDimensions.paddingS),
          child: Container(
            padding: const EdgeInsets.all(AppDimensions.paddingM),
            decoration: BoxDecoration(
              color:
                  _correctAnswerIndex == index
                      ? AppColors.success.withOpacity(0.1)
                      : AppColors.surface3,
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              border: Border.all(
                color:
                    _correctAnswerIndex == index
                        ? AppColors.success
                        : AppColors.border1,
              ),
            ),
            child: Row(
              children: [
                Radio<int>(
                  value: index,
                  groupValue: _correctAnswerIndex,
                  onChanged: (value) {
                    setState(() {
                      _correctAnswerIndex = value!;
                    });
                  },
                  activeColor: AppColors.success,
                ),
                const SizedBox(width: AppDimensions.paddingS),
                Text(
                  _options[index],
                  style: const TextStyle(
                    color: AppColors.lightText,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        );
      }

      return Padding(
        padding: const EdgeInsets.only(bottom: AppDimensions.paddingS),
        child: Row(
          children: [
            Radio<int>(
              value: index,
              groupValue: _correctAnswerIndex,
              onChanged: (value) {
                setState(() {
                  _correctAnswerIndex = value!;
                });
              },
              activeColor: AppColors.success,
            ),
            const SizedBox(width: AppDimensions.paddingS),
            Expanded(
              child: TextFormField(
                initialValue: _options[index],
                style: const TextStyle(color: AppColors.lightText),
                decoration: _getInputDecoration(
                  hintText: 'هەڵبژاردەی ${index + 1}',
                ),
                onChanged: (value) {
                  _options[index] = value;
                },
                validator: (value) {
                  if (value?.trim().isEmpty ?? true) {
                    return 'هەڵبژاردە پێویستە';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
      );
    });
  }

  List<DropdownMenuItem<int>> _getCorrectAnswerItems() {
    final optionCount = _selectedType == QuestionType.trueFalse ? 2 : 4;

    return List.generate(optionCount, (index) {
      String optionText;
      if (_selectedType == QuestionType.trueFalse) {
        optionText =
            _options[index].isNotEmpty
                ? _options[index]
                : (index == 0 ? 'ڕاست' : 'هەڵە');
      } else {
        optionText =
            _options[index].isNotEmpty
                ? _options[index]
                : 'هەڵبژاردەی ${index + 1}';
      }

      return DropdownMenuItem(value: index, child: Text(optionText));
    });
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _saveQuestion,
            icon:
                _isLoading
                    ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: AppColors.white,
                        strokeWidth: 2,
                      ),
                    )
                    : const Icon(Icons.add),
            label: Text(_isLoading ? 'دروستکردن...' : 'پرسیار دروستبکە'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryTeal,
              padding: const EdgeInsets.all(AppDimensions.paddingL),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppDimensions.paddingM),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _isLoading ? null : () => Navigator.pop(context),
            icon: const Icon(Icons.close),
            label: const Text('هەڵوەشاندنەوە'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.all(AppDimensions.paddingL),
              side: const BorderSide(color: AppColors.border1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              ),
            ),
          ),
        ),
      ],
    );
  }

  InputDecoration _getInputDecoration({String? hintText}) {
    return InputDecoration(
      hintText: hintText,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        borderSide: const BorderSide(color: AppColors.border1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        borderSide: const BorderSide(color: AppColors.border1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        borderSide: const BorderSide(color: AppColors.primaryTeal, width: 2),
      ),
      filled: true,
      fillColor: AppColors.surface3,
      hintStyle: const TextStyle(color: AppColors.mediumText),
    );
  }

  String _getTypeText(QuestionType type) {
    switch (type) {
      case QuestionType.multipleChoice:
        return 'هەڵبژاردەی فرە';
      case QuestionType.trueFalse:
        return 'ڕاست/هەڵە';
      case QuestionType.fillInTheBlank:
        return 'پڕکردنەوەی بۆشاڵی';
    }
  }

  String _getDifficultyText(QuestionDifficulty difficulty) {
    switch (difficulty) {
      case QuestionDifficulty.easy:
        return 'ئاسان';
      case QuestionDifficulty.medium:
        return 'مامناوەند';
      case QuestionDifficulty.hard:
        return 'ئاڵۆز';
    }
  }

  Future<void> _saveQuestion() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validate options for multiple choice and true/false
    if (_selectedType != QuestionType.fillInTheBlank) {
      final optionCount = _selectedType == QuestionType.trueFalse ? 2 : 4;
      for (int i = 0; i < optionCount; i++) {
        if (_options[i].trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('هەڵبژاردەی ${i + 1} بۆش نابێت'),
              backgroundColor: AppColors.error,
            ),
          );
          return;
        }
      }
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final questionNotifier = ref.read(questionNotifierProvider.notifier);

      final correctAnswer =
          _selectedType == QuestionType.fillInTheBlank
              ? _options[0]
              : _options[_correctAnswerIndex];

      final filteredOptions =
          _selectedType == QuestionType.trueFalse
              ? _options.take(2).toList()
              : _selectedType == QuestionType.fillInTheBlank
              ? [correctAnswer]
              : _options.where((option) => option.trim().isNotEmpty).toList();

      await questionNotifier.createQuestion(
        question: _questionController.text.trim(),
        type: _selectedType,
        options: filteredOptions,
        correctAnswer: correctAnswer,
        explanation:
            _explanationController.text.trim().isEmpty
                ? null
                : _explanationController.text.trim(),
        categoryId: widget.gameSection.categoryName,
        difficulty: _selectedDifficulty,
        points: int.parse(_pointsController.text),
        timeLimit: int.parse(_timeLimitController.text),
      );

      if (mounted) {
        // Refresh the question count
        ref.invalidate(
          totalQuestionCountProvider(widget.gameSection.categoryName),
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('پرسیار بە سەرکەوتوویی زیادکرا'),
            backgroundColor: AppColors.success,
          ),
        );

        // Reset form for next question
        _resetForm();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('هەڵە: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _resetForm() {
    _questionController.clear();
    _explanationController.clear();
    _pointsController.text = '10';
    _timeLimitController.text = '15';

    setState(() {
      _selectedType = QuestionType.multipleChoice;
      _selectedDifficulty = QuestionDifficulty.medium;
      _options = ['', '', '', ''];
      _correctAnswerIndex = 0;
    });
  }
}
