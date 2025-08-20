// File: lib/widgets/admin/admin_tab_bar.dart
// Description: Reusable admin tab bar widget

import 'package:flutter/material.dart';
import '../../utils/constants.dart';

class AdminTabBar extends StatelessWidget {
  final TabController controller;

  const AdminTabBar({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        border: Border.all(color: AppColors.border1),
      ),
      child: TabBar(
        controller: controller,
        indicator: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        ),
        indicatorPadding: const EdgeInsets.all(4),
        labelColor: AppColors.white,
        unselectedLabelColor: AppColors.mediumText,
        labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        tabs: const [
          Tab(icon: Icon(Icons.dashboard, size: 20), text: 'سەرەکی'),
          Tab(icon: Icon(Icons.people, size: 20), text: 'بەکارهێنەران'),
          Tab(icon: Icon(Icons.games, size: 20), text: 'یاریەکان'),
          Tab(icon: Icon(Icons.analytics, size: 20), text: 'ئامارەکان'),
        ],
      ),
    );
  }
}
