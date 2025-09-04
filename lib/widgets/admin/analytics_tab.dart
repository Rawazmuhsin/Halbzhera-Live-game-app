// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../utils/constants.dart';
import '../../widgets/common/loading_widget.dart';
import '../../providers/analytics_provider.dart';
import '../../models/category_model.dart';

class AnalyticsTab extends ConsumerWidget {
  const AnalyticsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(analyticsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: analyticsAsync.when(
        data: (data) => _buildAnalyticsContent(context, data),
        loading: () => const LoadingWidget(message: 'Loading analytics...'),
        error:
            (error, stackTrace) => Center(
              child: Text(
                'Failed to load analytics: $error',
                style: const TextStyle(color: AppColors.error),
              ),
            ),
      ),
    );
  }

  Widget _buildAnalyticsContent(BuildContext context, AnalyticsData data) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.paddingL),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight - AppDimensions.paddingL * 2,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Dashboard',
                  style: TextStyle(
                    color: AppColors.lightText,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppDimensions.paddingS),
                Text(
                  'Last updated: ${DateFormat.yMMMd().add_jm().format(DateTime.now())}',
                  style: const TextStyle(
                    color: AppColors.mediumText,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: AppDimensions.paddingL),
                _buildOverviewGrid(data, constraints),
                const SizedBox(height: AppDimensions.paddingL),
                _buildChartCard(
                  'User Growth (Last 30 Days)',
                  _buildLineChart(data.userGrowth, AppColors.primaryTeal),
                ),
                const SizedBox(height: AppDimensions.paddingL),
                _buildChartCard(
                  'Game Activity (Last 30 Days)',
                  _buildLineChart(data.gameActivity, AppColors.primaryRed),
                ),
                const SizedBox(height: AppDimensions.paddingL),
                _buildChartCard(
                  'Top 5 Category Popularity',
                  _buildBarChart(data.categoryPopularity),
                ),
                const SizedBox(
                  height: AppDimensions.paddingL,
                ), // Extra bottom padding
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOverviewGrid(AnalyticsData data, BoxConstraints constraints) {
    return LayoutBuilder(
      builder: (context, gridConstraints) {
        final isWide = constraints.maxWidth > 600;
        return GridView.count(
          crossAxisCount: 2,
          childAspectRatio: isWide ? 2.0 : 1.3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: AppDimensions.paddingM,
          mainAxisSpacing: AppDimensions.paddingM,
          children: [
            _buildStatCard(
              'Total Users',
              data.totalUsers.toString(),
              Icons.people_outline,
              AppColors.primaryTeal,
            ),
            _buildStatCard(
              'Active Users (7d)',
              data.activeUsers.toString(),
              Icons.person_pin_circle_outlined,
              AppColors.success,
            ),
            _buildStatCard(
              'Games Played',
              data.totalGamesPlayed.toString(),
              Icons.gamepad_outlined,
              AppColors.primaryRed,
            ),
            _buildStatCard(
              'Avg. Session',
              '${data.averageSessionDuration.toStringAsFixed(1)} min',
              Icons.timer_outlined,
              AppColors.warning,
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        border: Border.all(color: AppColors.border1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 32, color: color),
          const SizedBox(height: AppDimensions.paddingS),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: const TextStyle(
                  color: AppColors.lightText,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Flexible(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.mediumText, fontSize: 14),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartCard(String title, Widget chart) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxWidth > 600 ? 250.0 : 200.0;
        return Container(
          padding: const EdgeInsets.all(AppDimensions.paddingL),
          decoration: BoxDecoration(
            color: AppColors.surface2,
            borderRadius: BorderRadius.circular(AppDimensions.radiusL),
            border: Border.all(color: AppColors.border1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.lightText,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppDimensions.paddingL),
              SizedBox(height: height, child: chart),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLineChart(List<Map<String, dynamic>> data, Color color) {
    if (data.isEmpty) {
      return const Center(
        child: Text(
          'No data available',
          style: TextStyle(color: AppColors.mediumText),
        ),
      );
    }

    final spots =
        data.asMap().entries.map((entry) {
          return FlSpot(
            entry.key.toDouble(),
            (entry.value['count'] as int).toDouble(),
          );
        }).toList();

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          getDrawingHorizontalLine:
              (value) => FlLine(color: AppColors.border1, strokeWidth: 0.5),
          getDrawingVerticalLine:
              (value) => FlLine(color: AppColors.border1, strokeWidth: 0.5),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: (data.length / 5).ceilToDouble(),
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < data.length) {
                  try {
                    // Handle both string and potential different date formats
                    final dayData = data[index]['day'];
                    DateTime date;

                    if (dayData is String) {
                      // Parse string format "YYYY-M-D" or "YYYY-MM-DD"
                      final parts = dayData.split('-');
                      if (parts.length == 3) {
                        final year = int.parse(parts[0]);
                        final month = int.parse(parts[1]);
                        final day = int.parse(parts[2]);
                        date = DateTime(year, month, day);
                      } else {
                        // Fallback to DateTime.parse
                        date = DateTime.parse(dayData);
                      }
                    } else {
                      // Handle other potential formats
                      date = DateTime.now(); // Fallback
                    }

                    return SideTitleWidget(
                      meta: meta,
                      child: Text(
                        DateFormat('d MMM').format(date),
                        style: const TextStyle(
                          color: AppColors.mediumText,
                          fontSize: 10,
                        ),
                      ),
                    );
                  } catch (e) {
                    // Handle format exception gracefully
                    return SideTitleWidget(
                      meta: meta,
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: AppColors.mediumText,
                          fontSize: 10,
                        ),
                      ),
                    );
                  }
                }
                return Container();
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget:
                  (value, meta) => Text(
                    value.toInt().toString(),
                    style: const TextStyle(
                      color: AppColors.mediumText,
                      fontSize: 10,
                    ),
                    textAlign: TextAlign.left,
                  ),
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: AppColors.border1),
        ),
        minX: 0,
        maxX: (spots.length - 1).toDouble(),
        minY: 0,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: color,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: color.withOpacity(0.2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart(List<CategoryModel> categories) {
    if (categories.isEmpty) {
      return const Center(
        child: Text(
          'No data available',
          style: TextStyle(color: AppColors.mediumText),
        ),
      );
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY:
            categories
                .map((c) => c.totalPlays)
                .reduce((a, b) => a > b ? a : b)
                .toDouble() *
            1.2,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine:
              (value) => FlLine(color: AppColors.border1, strokeWidth: 0.5),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 35,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < categories.length) {
                  return SideTitleWidget(
                    meta: meta,
                    space: 4,
                    child: Text(
                      categories[index].name,
                      style: const TextStyle(
                        color: AppColors.mediumText,
                        fontSize: 10,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }
                return Container();
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget:
                  (value, meta) => Text(
                    value.toInt().toString(),
                    style: const TextStyle(
                      color: AppColors.mediumText,
                      fontSize: 10,
                    ),
                  ),
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups:
            categories.asMap().entries.map((entry) {
              final index = entry.key;
              final category = entry.value;
              return BarChartGroupData(
                x: index,
                barRods: [
                  BarChartRodData(
                    toY: category.totalPlays.toDouble(),
                    color: AppColors.primaryRed,
                    width: 16,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(4),
                    ),
                  ),
                ],
              );
            }).toList(),
      ),
    );
  }
}
