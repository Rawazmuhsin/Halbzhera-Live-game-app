// File: lib/widgets/lobby/countdown_timer.dart
// Description: Countdown timer widget for lobby

// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../../utils/constants.dart';

class CountdownTimer extends StatefulWidget {
  final int timeRemaining;

  const CountdownTimer({super.key, required this.timeRemaining});

  @override
  State<CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(CountdownTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.timeRemaining <= 10 && widget.timeRemaining > 0) {
      _pulseController.repeat(reverse: true);
    } else {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Widget _buildTimeBlock(String time, String label) {
    return Column(
      children: [
        Text(
          time,
          style: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.w800,
            color: _getTimerColor(),
            fontFamily: 'Courier New',
            height: 1.0,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.mediumText,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Color _getTimerColor() {
    if (widget.timeRemaining <= 5) {
      return AppColors.error;
    } else if (widget.timeRemaining <= 15) {
      return AppColors.accentYellow;
    } else {
      return AppColors.primaryRed;
    }
  }

  Color _getBorderColor() {
    if (widget.timeRemaining <= 5) {
      return AppColors.error.withOpacity(0.6);
    } else if (widget.timeRemaining <= 15) {
      return AppColors.accentYellow.withOpacity(0.5);
    } else {
      return AppColors.primaryRed.withOpacity(0.4);
    }
  }

  @override
  Widget build(BuildContext context) {
    final minutes = widget.timeRemaining ~/ 60;
    final seconds = widget.timeRemaining % 60;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.paddingXXL),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.surface2.withOpacity(0.8),
            AppColors.surface1.withOpacity(0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusXXL),
        border: Border.all(color: AppColors.border1.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'ئامادەبوون بۆ یاری',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: AppColors.lightText,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: AppDimensions.paddingXL),

          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: widget.timeRemaining <= 10 ? _pulseAnimation.value : 1.0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.paddingXL,
                    vertical: AppDimensions.paddingL,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.background.withOpacity(0.8),
                    border: Border.all(color: _getBorderColor(), width: 2),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildTimeBlock(
                        minutes.toString().padLeft(2, '0'),
                        'خولەک',
                      ),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          ':',
                          style: TextStyle(
                            fontSize: 40,
                            color: _getTimerColor(),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      _buildTimeBlock(
                        seconds.toString().padLeft(2, '0'),
                        'چرکە',
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: AppDimensions.paddingL),

          // Timer bar
          Container(
            width: 200,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border1.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
            child: FractionallySizedBox(
              widthFactor: widget.timeRemaining / 60,
              alignment: Alignment.centerLeft,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _getTimerColor(),
                      _getTimerColor().withOpacity(0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),

          const SizedBox(height: AppDimensions.paddingM),

          Text(
            'یاری دەست پێدەکات...',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.mediumText,
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
