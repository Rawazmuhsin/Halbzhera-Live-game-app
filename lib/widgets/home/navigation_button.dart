// File: lib/widgets/home/navigation_button.dart
// Description: Individual navigation button

import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import 'navigation_item.dart';

class NavigationButton extends StatelessWidget {
  final NavigationItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const NavigationButton({
    super.key,
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(
          vertical: AppDimensions.paddingL,
          horizontal: AppDimensions.paddingM,
        ),
        decoration: BoxDecoration(
          gradient:
              isSelected
                  ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primaryRed.withOpacity(0.15),
                      AppColors.primaryTeal.withOpacity(0.1),
                    ],
                  )
                  : null,
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          border: Border.all(
            color:
                isSelected
                    ? AppColors.primaryRed.withOpacity(0.3)
                    : AppColors.border1.withOpacity(0.1),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              item.icon,
              size: 24,
              color: isSelected ? AppColors.primaryRed : AppColors.mediumText,
            ),
            const SizedBox(height: AppDimensions.paddingS),
            Text(
              item.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isSelected ? AppColors.primaryRed : AppColors.mediumText,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
