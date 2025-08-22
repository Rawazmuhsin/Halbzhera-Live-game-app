// File: lib/widgets/home/join_game_button.dart
// Description: Join game button

import 'package:flutter/material.dart';
import '../../utils/constants.dart';

class JoinGameButton extends StatelessWidget {
  final VoidCallback onPressed;

  const JoinGameButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryRed,
          foregroundColor: AppColors.white,
          padding: const EdgeInsets.symmetric(vertical: AppDimensions.paddingM),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          ),
          elevation: 4,
        ),
        child: const Text(
          'بەشداری بکە',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
