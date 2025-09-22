// File: lib/screens/settings/user_details_screen.dart
// Description: Detailed user information screen accessible from settings

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/user_model.dart';
import '../../utils/constants.dart';
import '../../utils/formatters.dart';
import '../../widgets/common/gradient_background.dart';

class UserDetailsScreen extends ConsumerWidget {
  final UserModel user;

  const UserDetailsScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text(
            'زانیاریەکانی بەکارهێنەر',
            style: TextStyle(
              color: AppColors.lightText,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: AppColors.lightText),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.paddingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User profile header
              _buildProfileHeader(context),

              const SizedBox(height: AppDimensions.paddingXL),

              // Account information
              _buildInfoSection(
                context,
                'زانیاریەکانی ئەکاونت',
                Icons.account_circle_outlined,
                [
                  _buildInfoRow('ناسنامەی بەکارهێنەر', user.uid),
                  _buildInfoRow('ناو', user.displayName ?? 'دانەنراوە'),
                  _buildInfoRow('ئیمەیل', user.email ?? 'دابین نەکراوە'),
                  _buildInfoRow(
                    'جۆری چوونەژوورەوە',
                    _getProviderName(user.provider),
                  ),
                ],
              ),

              const SizedBox(height: AppDimensions.paddingXL),

              // Game statistics
              _buildInfoSection(
                context,
                'ئامارەکانی یاری',
                Icons.sports_esports_outlined,
                [
                  _buildInfoRow('کۆی خاڵەکان', user.totalScore.toString()),
                  _buildInfoRow('یاریە کراوەکان', user.gamesPlayed.toString()),
                  _buildInfoRow('یاریە بردووەکان', user.gamesWon.toString()),
                  _buildInfoRow(
                    'ڕێژەی بردنەوە',
                    '${user.winRate.toStringAsFixed(1)}%',
                  ),
                  _buildInfoRow(
                    'ناوەندی خاڵ لە یارییەک',
                    user.averageScore.toStringAsFixed(1),
                  ),
                ],
              ),

              const SizedBox(height: AppDimensions.paddingXL),

              // Account status
              _buildInfoSection(
                context,
                'بارودۆخی ئەکاونت',
                Icons.info_outline,
                [
                  _buildInfoRow('دۆخ', user.isOnline ? 'چالاک' : 'ناچالاک'),
                  _buildInfoRow(
                    'بەرواری دروستکردن',
                    _formatDate(user.firstLoginAt ?? user.createdAt),
                  ),
                  _buildInfoRow('دوایین چالاکی', _formatDate(user.lastSeen)),
                ],
              ),

              const SizedBox(height: AppDimensions.paddingXL),

              // Preferences
              if (user.preferences.isNotEmpty)
                _buildInfoSection(
                  context,
                  'ڕێکخستنەکان',
                  Icons.settings_outlined,
                  user.preferences.entries
                      .map(
                        (entry) =>
                            _buildInfoRow(entry.key, entry.value.toString()),
                      )
                      .toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingXL),
      decoration: BoxDecoration(
        color: AppColors.surface2.withOpacity(0.8),
        borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
        border: Border.all(color: AppColors.border1.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // User avatar
          Stack(
            children: [
              CircleAvatar(
                radius: 60,
                backgroundColor: AppColors.primaryTeal,
                backgroundImage:
                    user.photoURL != null ? NetworkImage(user.photoURL!) : null,
                child:
                    user.photoURL == null
                        ? Text(
                          user.displayName?.substring(0, 1).toUpperCase() ??
                              'U',
                          style: const TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: AppColors.white,
                          ),
                        )
                        : null,
              ),
              // Online status indicator
              Positioned(
                bottom: 4,
                right: 4,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color:
                        user.isOnline
                            ? AppColors.success
                            : AppColors.mediumText,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.surface2, width: 3),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppDimensions.paddingL),

          // User name
          Text(
            user.displayName ?? 'بەکارهێنەر',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.lightText,
            ),
            textAlign: TextAlign.center,
          ),

          if (user.email != null && user.email!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              user.email!,
              style: const TextStyle(fontSize: 16, color: AppColors.mediumText),
              textAlign: TextAlign.center,
            ),
          ],

          const SizedBox(height: AppDimensions.paddingL),

          // Quick stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatColumn(
                'خاڵ',
                user.totalScore.toString(),
                AppColors.accentYellow,
              ),
              _buildStatColumn(
                'یاری',
                user.gamesPlayed.toString(),
                AppColors.primaryTeal,
              ),
              _buildStatColumn(
                'بردنەوە',
                user.gamesWon.toString(),
                AppColors.success,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: AppColors.mediumText),
        ),
      ],
    );
  }

  Widget _buildInfoSection(
    BuildContext context,
    String title,
    IconData icon,
    List<Widget> children,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: AppColors.primaryTeal, size: 24),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.lightText,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.paddingM),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface2.withOpacity(0.6),
            borderRadius: BorderRadius.circular(AppDimensions.radiusL),
            border: Border.all(color: AppColors.border1.withOpacity(0.3)),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingL,
        vertical: AppDimensions.paddingM,
      ),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.border1, width: 0.5),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.mediumText,
              ),
            ),
          ),
          const SizedBox(width: AppDimensions.paddingM),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, color: AppColors.lightText),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  String _getProviderName(LoginProvider provider) {
    switch (provider) {
      case LoginProvider.google:
        return 'گووگڵ';
      case LoginProvider.facebook:
        return 'فەیسبووک';
      case LoginProvider.anonymous:
        return 'نەناسراو';
    }
  }

  String _formatDate(DateTime date) {
    try {
      // Try to use the formatters.dart utility
      return formatDateTime(date);
    } catch (e) {
      // Fallback to simple format
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    }
  }
}
