// File: lib/widgets/home/navigation_grid.dart
// Description: 4-button navigation grid

// ignore_for_file: deprecated_member_use, avoid_print

import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import '../../config/app_routes.dart';
import 'navigation_button.dart';
import 'navigation_item.dart';

class NavigationGrid extends StatefulWidget {
  const NavigationGrid({super.key});

  @override
  State<NavigationGrid> createState() => _NavigationGridState();
}

class _NavigationGridState extends State<NavigationGrid> {
  int selectedIndex = 0;

  final List<NavigationItem> navigationItems = [
    NavigationItem(icon: Icons.home_rounded, label: 'سەرەکی', page: 'home'),
    NavigationItem(
      icon: Icons.leaderboard_rounded,
      label: 'پێشەنگەکان',
      page: 'leaderboard',
    ),
    NavigationItem(
      icon: Icons.settings_rounded,
      label: 'ڕێکخستنەکان',
      page: 'settings',
    ),
    NavigationItem(
      icon: Icons.info_rounded,
      label: 'دەربارەمان',
      page: 'about',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      decoration: BoxDecoration(
        color: AppColors.surface2.withOpacity(0.4),
        borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
        border: Border.all(color: AppColors.border1.withOpacity(0.3)),
      ),
      child: Row(
        children: List.generate(
          navigationItems.length,
          (index) => Expanded(
            child: NavigationButton(
              item: navigationItems[index],
              isSelected: selectedIndex == index,
              onTap: () {
                setState(() {
                  selectedIndex = index;
                });
                _navigateToPage(navigationItems[index].page);
              },
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToPage(String page) {
    print('Navigate to: $page');
    switch (page) {
      case 'leaderboard':
        Navigator.of(context).pushNamed('/leaderboard');
        break;
      case 'settings':
        Navigator.of(context).pushNamed('/settings');
        break;
      case 'about':
        Navigator.of(context).pushNamed(AppRoutes.about);
        break;
      case 'home':
      default:
        // Already on home, do nothing
        break;
    }
  }
}
