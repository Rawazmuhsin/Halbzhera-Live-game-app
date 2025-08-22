// File: lib/widgets/home/game_title.dart
// Description: Game title widget

import 'package:flutter/material.dart';
import '../../utils/constants.dart';

class GameTitle extends StatelessWidget {
  final String title;

  const GameTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: AppColors.lightText,
        height: 1.3,
      ),
    );
  }
}
