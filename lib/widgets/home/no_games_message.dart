// File: lib/widgets/home/no_games_message.dart
// Description: Message when no games available

// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../../utils/constants.dart';

class NoGamesMessage extends StatelessWidget {
  const NoGamesMessage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.paddingXXL),
      decoration: BoxDecoration(
        color: AppColors.surface2.withOpacity(0.3),
        borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
        border: Border.all(color: AppColors.border1.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.sports_esports_rounded,
            size: 64,
            color: AppColors.mediumText.withOpacity(0.5),
          ),
          const SizedBox(height: AppDimensions.paddingL),
          const Text(
            'هیچ یارییەک نییە',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.lightText,
            ),
          ),
          const SizedBox(height: AppDimensions.paddingS),
          Text(
            'تکایە دواتر بگەڕێوە',
            style: TextStyle(fontSize: 14, color: AppColors.mediumText),
          ),
        ],
      ),
    );
  }
}
