// File: lib/screens/admin/user_details_screen.dart
// Description: Screen to view detailed user information

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/user_model.dart';
import '../../utils/constants.dart';

class UserDetailsScreen extends ConsumerWidget {
  final UserModel user;

  const UserDetailsScreen({
    super.key,
    required this.user,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'زانیاریەکانی بەکارهێنەر',
          style: TextStyle(color: AppColors.lightText),
        ),
        backgroundColor: AppColors.surface2,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.lightText),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildUserHeader(),
            const SizedBox(height: AppDimensions.paddingL),
            _buildUserStats(),
            const SizedBox(height: AppDimensions.paddingL),
            _buildUserDetails(),
            const SizedBox(height: AppDimensions.paddingL),
            _buildAccountInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildUserHeader() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        border: Border.all(color: AppColors.border1),
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: user.isOnline ? AppColors.success : AppColors.border1,
                width: 3,
              ),
            ),
            child: CircleAvatar(
              radius: 40,
              backgroundColor: AppColors.primaryTeal,
              backgroundImage: user.photoURL != null ? NetworkImage(user.photoURL!) : null,
              child: user.photoURL == null
                  ? Text(
                      user.displayName?.substring(0, 1).toUpperCase() ?? 'U',
                      style: const TextStyle(
                        color: AppColors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 28,
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(width: AppDimensions.paddingL),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.displayName ?? 'Unknown User',
                  style: const TextStyle(
                    color: AppColors.lightText,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
                if (user.email != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    user.email!,
                    style: const TextStyle(
                      color: AppColors.mediumText,
                      fontSize: 16,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: user.isOnline
                        ? AppColors.success.withOpacity(0.2)
                        : AppColors.mediumText.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: user.isOnline
                          ? AppColors.success.withOpacity(0.5)
                          : AppColors.mediumText.withOpacity(0.5),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: user.isOnline ? AppColors.success : AppColors.mediumText,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        user.isOnline ? 'چالاک' : 'ناچالاک',
                        style: TextStyle(
                          color: user.isOnline ? AppColors.success : AppColors.mediumText,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserStats() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        border: Border.all(color: AppColors.border1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ئامارەکان',
            style: TextStyle(
              color: AppColors.lightText,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppDimensions.paddingM),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'کۆی خاڵ',
                  '${user.totalScore}',
                  AppColors.accentYellow,
                  Icons.star,
                ),
              ),
              const SizedBox(width: AppDimensions.paddingM),
              Expanded(
                child: _buildStatCard(
                  'یاریکراو',
                  '${user.gamesPlayed}',
                  AppColors.primaryTeal,
                  Icons.sports_esports,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.paddingM),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'بردنەوە',
                  '${user.gamesWon}',
                  AppColors.success,
                  Icons.emoji_events,
                ),
              ),
              const SizedBox(width: AppDimensions.paddingM),
              Expanded(
                child: _buildStatCard(
                  'ڕێژەی بردنەوە',
                  '${user.winRate.toStringAsFixed(1)}%',
                  AppColors.info,
                  Icons.trending_up,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.paddingM),
          _buildStatCard(
            'تێکڕای خاڵ بۆ یارییەک',
            user.averageScore.toStringAsFixed(1),
            AppColors.warning,
            Icons.analytics,
            fullWidth: true,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    Color color,
    IconData icon, {
    bool fullWidth = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: fullWidth
          ? Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          color: color,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        value,
                        style: TextStyle(
                          color: color,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            )
          : Column(
              children: [
                Icon(icon, color: color, size: 32),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ],
            ),
    );
  }

  Widget _buildUserDetails() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        border: Border.all(color: AppColors.border1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'زانیاریەکانی زیاتر',
            style: TextStyle(
              color: AppColors.lightText,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppDimensions.paddingM),
          _buildDetailRow('ناسنامەی بەکارهێنەر', user.uid),
          _buildDetailRow('دواجار بینراوە', _formatDateTime(user.lastSeen)),
          _buildDetailRow('بەروار دروستکردن', _formatDateTime(user.createdAt)),
          _buildDetailRow(
            'جۆری چوونەژوورەوە',
            _getProviderName(user.provider),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountInfo() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        border: Border.all(color: AppColors.border1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'زانیاریەکانی ئەکاونت',
            style: TextStyle(
              color: AppColors.lightText,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppDimensions.paddingM),
          if (user.preferences.isNotEmpty) ...[
            const Text(
              'ڕێکخستنەکان:',
              style: TextStyle(
                color: AppColors.mediumText,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            ...user.preferences.entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Text(
                      '• ${entry.key}: ',
                      style: const TextStyle(
                        color: AppColors.mediumText,
                        fontSize: 14,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '${entry.value}',
                        style: const TextStyle(
                          color: AppColors.lightText,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else
            const Text(
              'هیچ ڕێکخستنێک نەدۆزرایەوە',
              style: TextStyle(
                color: AppColors.mediumText,
                fontSize: 14,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.paddingS),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label:',
            style: const TextStyle(
              color: AppColors.mediumText,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.lightText,
              fontSize: 14,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} ڕۆژ لەمەوبەر';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} کاتژمێر لەمەوبەر';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} خولەک لەمەوبەر';
    } else {
      return 'ئێستا';
    }
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
}
