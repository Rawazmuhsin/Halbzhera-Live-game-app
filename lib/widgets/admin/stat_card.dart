// File: lib/widgets/admin/stat_card.dart
// Description: Reusable statistic card widget

// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../../utils/constants.dart';

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String? trend;
  final VoidCallback? onTap;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.trend,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          border: Border.all(color: theme.colorScheme.outline.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(context),
            const SizedBox(height: AppDimensions.paddingM),
            _buildValue(context),
            const SizedBox(height: 4),
            _buildTitle(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        if (trend != null) _buildTrendBadge(context),
      ],
    );
  }

  Widget _buildTrendBadge(BuildContext context) {
    final theme = Theme.of(context);
    final isPositive = trend!.startsWith('+');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (isPositive
                ? theme.colorScheme.tertiary
                : theme.colorScheme.error)
            .withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        trend!,
        style: TextStyle(
          color:
              isPositive ? theme.colorScheme.tertiary : theme.colorScheme.error,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildValue(BuildContext context) {
    final theme = Theme.of(context);

    return Flexible(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          value,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildTitle(BuildContext context) {
    final theme = Theme.of(context);

    return Flexible(
      child: Text(
        title,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
