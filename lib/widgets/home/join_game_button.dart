// File: lib/widgets/home/join_game_button.dart
// Description: Join game button

import 'package:flutter/material.dart';
import '../../utils/constants.dart';

class JoinGameButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String? text;
  final Color? backgroundColor;
  final Color? textColor;

  const JoinGameButton({
    super.key,
    required this.onPressed,
    this.text,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? AppColors.primaryRed,
          foregroundColor: textColor ?? AppColors.white,
          padding: const EdgeInsets.symmetric(vertical: AppDimensions.paddingM),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          ),
          elevation: onPressed != null ? 4 : 0,
          disabledBackgroundColor: AppColors.mediumText,
          disabledForegroundColor: AppColors.darkText,
        ),
        child: Text(
          text ?? 'بەشداری بکە',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
