// File: lib/widgets/home/game_description.dart
// Description: Game description widget

import 'package:flutter/material.dart';
import '../../utils/constants.dart';

class GameDescription extends StatelessWidget {
  final String description;

  const GameDescription({super.key, required this.description});

  @override
  Widget build(BuildContext context) {
    return Text(
      description,
      style: TextStyle(fontSize: 14, color: AppColors.mediumText, height: 1.5),
    );
  }
}
