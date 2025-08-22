// File: lib/widgets/home/game_details.dart
// Description: Game details (time and prize)

import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import 'game_detail_row.dart';

class GameDetails extends StatelessWidget {
  final String timeToStart;
  final String prize;

  const GameDetails({
    super.key,
    required this.timeToStart,
    required this.prize,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GameDetailRow(
          icon: Icons.access_time_rounded,
          label: 'کات بۆ دەستپێکردن',
          value: timeToStart,
          valueColor: AppColors.primaryTeal,
        ),
        const SizedBox(height: AppDimensions.paddingM),
        GameDetailRow(
          icon: Icons.emoji_events_rounded,
          label: 'خەڵات',
          value: prize,
          valueColor: AppColors.accentYellow,
        ),
      ],
    );
  }
}
