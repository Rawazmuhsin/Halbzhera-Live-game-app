// File: lib/screens/admin/create_game_screen.dart
// Description: Screen for creating new scheduled games

// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../utils/constants.dart';
import '../../models/scheduled_game_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/scheduled_game_provider.dart';
import '../../widgets/common/gradient_background.dart';

class CreateGameScreen extends ConsumerStatefulWidget {
  final ScheduledGameModel? gameToEdit;

  const CreateGameScreen({super.key, this.gameToEdit});

  @override
  ConsumerState<CreateGameScreen> createState() => _CreateGameScreenState();
}

class _CreateGameScreenState extends ConsumerState<CreateGameScreen> {
  final _formKey = GlobalKey<FormState>();

  // Form controllers
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _prizeController = TextEditingController();
  final _durationController = TextEditingController();
  final _maxParticipantsController = TextEditingController();
  final _questionsCountController = TextEditingController();
  final _categoryController = TextEditingController();

  // Form state
  DateTime? _selectedDateTime;
  List<String> _tags = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    if (widget.gameToEdit != null) {
      final game = widget.gameToEdit!;
      _nameController.text = game.name;
      _descriptionController.text = game.description;
      _prizeController.text = game.prize;
      _durationController.text = game.duration.toString();
      _maxParticipantsController.text = game.maxParticipants.toString();
      _questionsCountController.text = game.questionsCount.toString();
      _selectedDateTime = game.scheduledTime;
      _categoryController.text = game.categoryName;
      _tags = List.from(game.tags);
    } else {
      // Set default values
      _durationController.text = '30';
      _maxParticipantsController.text = '100';
      _questionsCountController.text = '10';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _prizeController.dispose();
    _durationController.dispose();
    _maxParticipantsController.dispose();
    _questionsCountController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            widget.gameToEdit != null ? 'دەستکاری یاری' : 'یاری نوێ دروستبکە',
            style: const TextStyle(color: AppColors.lightText),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.lightText),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.paddingL),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildGameInfoSection(),
                const SizedBox(height: AppDimensions.paddingL),
                _buildScheduleSection(),
                const SizedBox(height: AppDimensions.paddingL),
                _buildGameSettingsSection(),
                const SizedBox(height: AppDimensions.paddingL),
                _buildCategorySection(),
                const SizedBox(height: AppDimensions.paddingL),
                _buildTagsSection(),
                const SizedBox(height: AppDimensions.paddingXL),
                _buildActionButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGameInfoSection() {
    return _buildSection(
      title: 'زانیاری یاری',
      icon: Icons.info_outline,
      children: [
        _buildTextField(
          controller: _nameController,
          label: 'ناوی یاری',
          hint: 'ناوی یاری بنووسە...',
          icon: Icons.games,
          validator: (value) {
            if (value?.isEmpty ?? true) {
              return 'ناوی یاری پێویستە';
            }
            return null;
          },
        ),
        const SizedBox(height: AppDimensions.paddingM),
        _buildTextField(
          controller: _descriptionController,
          label: 'وردەکاری یاری',
          hint: 'وردەکاری یاری بنووسە...',
          icon: Icons.description,
          maxLines: 3,
          validator: (value) {
            if (value?.isEmpty ?? true) {
              return 'وردەکاری یاری پێویستە';
            }
            return null;
          },
        ),
        const SizedBox(height: AppDimensions.paddingM),
        _buildTextField(
          controller: _prizeController,
          label: 'خەڵات',
          hint: 'خەڵاتی یاری بنووسە...',
          icon: Icons.emoji_events,
          validator: (value) {
            if (value?.isEmpty ?? true) {
              return 'خەڵات پێویستە';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildScheduleSection() {
    return _buildSection(
      title: 'کاتی دەستپێکردن',
      icon: Icons.schedule,
      children: [
        Container(
          padding: const EdgeInsets.all(AppDimensions.paddingM),
          decoration: BoxDecoration(
            color: AppColors.surface3,
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            border: Border.all(color: AppColors.border1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.calendar_today, color: AppColors.lightText),
                  const SizedBox(width: AppDimensions.paddingS),
                  const Text(
                    'کاتی دەستپێکردن',
                    style: TextStyle(
                      color: AppColors.lightText,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.paddingM),
              if (_selectedDateTime != null)
                Container(
                  padding: const EdgeInsets.all(AppDimensions.paddingM),
                  decoration: BoxDecoration(
                    color: AppColors.primaryTeal.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                    border: Border.all(color: AppColors.primaryTeal),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        color: AppColors.primaryTeal,
                      ),
                      const SizedBox(width: AppDimensions.paddingS),
                      Text(
                        DateFormat(
                          'yyyy/MM/dd - hh:mm a',
                        ).format(_selectedDateTime!),
                        style: const TextStyle(
                          color: AppColors.primaryTeal,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: AppDimensions.paddingM),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _selectDateTime,
                  icon: const Icon(Icons.event),
                  label: Text(
                    _selectedDateTime == null ? 'کات هەڵبژێرە' : 'کات گۆڕە',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryTeal,
                    padding: const EdgeInsets.all(AppDimensions.paddingM),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGameSettingsSection() {
    return _buildSection(
      title: 'ڕێکخستنەکانی یاری',
      icon: Icons.settings,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildNumberField(
                controller: _durationController,
                label: 'ماوە (خولەک)',
                icon: Icons.timer,
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'ماوە پێویستە';
                  final duration = int.tryParse(value!);
                  if (duration == null || duration <= 0) {
                    return 'ماوە دروست نییە';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: AppDimensions.paddingM),
            Expanded(
              child: _buildNumberField(
                controller: _maxParticipantsController,
                label: 'زۆرترین بەشداربوو',
                icon: Icons.people,
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'ژمارە پێویستە';
                  final count = int.tryParse(value!);
                  if (count == null || count <= 0) {
                    return 'ژمارە دروست نییە';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.paddingM),
        _buildNumberField(
          controller: _questionsCountController,
          label: 'ژمارەی پرسیارەکان',
          icon: Icons.quiz,
          validator: (value) {
            if (value?.isEmpty ?? true) return 'ژمارەی پرسیار پێویستە';
            final count = int.tryParse(value!);
            if (count == null || count <= 0) {
              return 'ژمارە دروست نییە';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildCategorySection() {
    return _buildSection(
      title: 'بەش',
      icon: Icons.category,
      children: [
        TextFormField(
          controller: _categoryController,
          decoration: InputDecoration(
            labelText: 'ناوی بەش بنووسە',
            hintText: 'وەک: مێژوو، زانست، وەرزش...',
            prefixIcon: const Icon(Icons.category, color: AppColors.mediumText),
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
              borderSide: const BorderSide(
                color: AppColors.primaryTeal,
                width: 2,
              ),
            ),
            filled: true,
            fillColor: AppColors.surface3,
          ),
          style: const TextStyle(color: AppColors.lightText),
          validator: (value) {
            if (value?.trim().isEmpty ?? true) {
              return 'ناوی بەش بنووسە';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildTagsSection() {
    return _buildSection(
      title: 'تاگەکان (ئیختیاری)',
      icon: Icons.tag,
      children: [
        Wrap(
          spacing: AppDimensions.paddingS,
          runSpacing: AppDimensions.paddingS,
          children: [
            ..._tags.map(
              (tag) => Chip(
                label: Text(tag),
                backgroundColor: AppColors.primaryTeal.withOpacity(0.2),
                labelStyle: const TextStyle(color: AppColors.primaryTeal),
                deleteIcon: const Icon(
                  Icons.close,
                  color: AppColors.primaryTeal,
                  size: 16,
                ),
                onDeleted: () {
                  setState(() {
                    _tags.remove(tag);
                  });
                },
              ),
            ),
            ActionChip(
              label: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add, size: 16, color: AppColors.lightText),
                  SizedBox(width: 4),
                  Text(
                    'تاگ زیادبکە',
                    style: TextStyle(color: AppColors.lightText),
                  ),
                ],
              ),
              backgroundColor: AppColors.surface3,
              side: const BorderSide(color: AppColors.border1),
              onPressed: _addTag,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _saveGame,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryRed,
              padding: const EdgeInsets.all(AppDimensions.paddingL),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              ),
            ),
            child:
                _isLoading
                    ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: AppColors.white,
                        strokeWidth: 2,
                      ),
                    )
                    : Text(
                      widget.gameToEdit != null
                          ? 'نوێکردنەوە'
                          : 'یاری دروستبکە',
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
          ),
        ),
        const SizedBox(height: AppDimensions.paddingM),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _isLoading ? null : () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.all(AppDimensions.paddingL),
              side: const BorderSide(color: AppColors.border1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              ),
            ),
            child: const Text(
              'هەڵوەشاندنەوە',
              style: TextStyle(color: AppColors.lightText, fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
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
              Icon(icon, color: AppColors.lightText),
              const SizedBox(width: AppDimensions.paddingS),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.lightText,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.paddingM),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: AppColors.lightText),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.mediumText),
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
        labelStyle: const TextStyle(color: AppColors.mediumText),
        hintStyle: const TextStyle(color: AppColors.mediumText),
      ),
      validator: validator,
    );
  }

  Widget _buildNumberField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      style: const TextStyle(color: AppColors.lightText),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.mediumText),
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
        labelStyle: const TextStyle(color: AppColors.mediumText),
      ),
      validator: validator,
    );
  }

  void _selectDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate:
          _selectedDateTime ?? DateTime.now().add(const Duration(hours: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primaryTeal,
              surface: AppColors.surface2,
            ),
          ),
          child: child!,
        );
      },
    );

    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime:
            _selectedDateTime != null
                ? TimeOfDay.fromDateTime(_selectedDateTime!)
                : TimeOfDay.now(),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.dark(
                primary: AppColors.primaryTeal,
                surface: AppColors.surface2,
              ),
            ),
            child: child!,
          );
        },
      );

      if (time != null) {
        setState(() {
          _selectedDateTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  void _addTag() {
    showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          backgroundColor: AppColors.surface2,
          title: const Text(
            'تاگ نوێ زیادبکە',
            style: TextStyle(color: AppColors.lightText),
          ),
          content: TextField(
            controller: controller,
            style: const TextStyle(color: AppColors.lightText),
            decoration: const InputDecoration(
              hintText: 'تاگ بنووسە...',
              hintStyle: TextStyle(color: AppColors.mediumText),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('هەڵوەشاندنەوە'),
            ),
            ElevatedButton(
              onPressed: () {
                final tag = controller.text.trim();
                if (tag.isNotEmpty && !_tags.contains(tag)) {
                  setState(() {
                    _tags.add(tag);
                  });
                }
                Navigator.pop(context);
              },
              child: const Text('زیادکردن'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveGame() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedDateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('کاتی دەستپێکردن هەڵبژێرە'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_selectedDateTime!.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('کاتی دەستپێکردن نابێت لە ڕابردوو بێت'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = ref.read(currentUserProvider);
      if (currentUser == null) {
        throw Exception('بەکارهێنەر نەدۆزرایەوە');
      }

      final game = ScheduledGameModel(
        id: widget.gameToEdit?.id ?? '',
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        scheduledTime: _selectedDateTime!,
        prize: _prizeController.text.trim(),
        categoryId: '', // Will be generated by the system
        categoryName: _categoryController.text.trim(),
        duration: int.parse(_durationController.text),
        maxParticipants: int.parse(_maxParticipantsController.text),
        questionsCount: int.parse(_questionsCountController.text),
        status: widget.gameToEdit?.status ?? GameStatus.scheduled,
        createdBy: currentUser.uid,
        createdAt: widget.gameToEdit?.createdAt ?? DateTime.now(),
        updatedAt: widget.gameToEdit != null ? DateTime.now() : null,
        tags: _tags,
        gameSettings: {
          'allowLateJoin': true,
          'showCorrectAnswers': true,
          'shuffleQuestions': true,
          'shuffleAnswers': true,
        },
      );

      final gameNotifier = ref.read(scheduledGameNotifierProvider.notifier);

      // Either update or create the game
      bool success = false;
      if (widget.gameToEdit != null) {
        success = await gameNotifier.updateGame(game);
      } else {
        final gameId = await gameNotifier.createGame(game);
        success = gameId != null;
      }

      if (mounted && success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.gameToEdit != null
                  ? 'یاری بە سەرکەوتوویی نوێکرایەوە'
                  : 'یاری بە سەرکەوتوویی دروستکرا',
            ),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate success
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
}
