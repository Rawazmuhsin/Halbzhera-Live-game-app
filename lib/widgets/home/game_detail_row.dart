// File: lib/widgets/home/game_detail_row.dart
// Description: Individual detail row in game card

import 'package:flutter/material.dart';
import '../../utils/constants.dart';

class GameDetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color valueColor;

  const GameDetailRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: AppColors.mediumText),
            const SizedBox(width: AppDimensions.paddingS),
            Text(
              label,
              style: TextStyle(fontSize: 14, color: AppColors.mediumText),
            ),
          ],
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
