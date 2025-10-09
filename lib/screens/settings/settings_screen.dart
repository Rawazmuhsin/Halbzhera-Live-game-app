// File: lib/screens/settings/settings_screen.dart
// Description: User settings screen with user info display and notification toggle

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/common/gradient_background.dart';
import 'user_details_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserModel = ref.watch(currentUserModelProvider);
    final settings = ref.watch(settingsProvider);

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text(
            'ڕێکخستنەکان',
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
        body: currentUserModel.when(
          data: (user) => _buildSettingsContent(context, ref, user, settings),
          loading:
              () => const Center(
                child: CircularProgressIndicator(color: AppColors.primaryTeal),
              ),
          error:
              (error, stackTrace) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: AppColors.error,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'هەڵەیەک ڕوویدا: $error',
                      style: const TextStyle(color: AppColors.error),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
        ),
      ),
    );
  }

  Widget _buildSettingsContent(
    BuildContext context,
    WidgetRef ref,
    UserModel? user,
    UserSettings settings,
  ) {
    if (user == null) {
      return const Center(
        child: Text(
          'تکایە چوونەژوورەوە بکە بۆ دەستڕاگەیشتن بە ڕێکخستنەکان',
          style: TextStyle(color: AppColors.lightText),
          textAlign: TextAlign.center,
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      children: [
        // User profile card
        _buildProfileCard(context, ref, user),

        const SizedBox(height: AppDimensions.paddingXL),

        // Notification settings section
        _buildSection(
          context,
          title: 'ئاگادارکردنەوەکان',
          icon: Icons.notifications_outlined,
          children: [_buildNotificationSetting(context, ref, settings)],
        ),

        const SizedBox(height: AppDimensions.paddingXL),

        // Account actions section
        _buildSection(
          context,
          title: 'کردارەکانی ئەکاونت',
          icon: Icons.account_circle_outlined,
          children: [_buildLogoutButton(context, ref)],
        ),
      ],
    );
  }

  Widget _buildProfileCard(
    BuildContext context,
    WidgetRef ref,
    UserModel user,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingL),
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
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => UserDetailsScreen(user: user),
            ),
          );
        },
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingM),
          child: Row(
            children: [
              // User avatar
              Stack(
                children: [
                  CircleAvatar(
                    radius: 35,
                    backgroundColor: AppColors.primaryTeal,
                    backgroundImage:
                        user.photoURL != null
                            ? NetworkImage(user.photoURL!)
                            : null,
                    child:
                        user.photoURL == null
                            ? Text(
                              user.displayName?.substring(0, 1).toUpperCase() ??
                                  'U',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: AppColors.white,
                              ),
                            )
                            : null,
                  ),
                  // Online status indicator
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color:
                            user.isOnline
                                ? AppColors.success
                                : AppColors.mediumText,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.surface2, width: 2),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(width: AppDimensions.paddingL),

              // User info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.displayName ?? 'بەکارهێنەر',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.lightText,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (user.email != null && user.email!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        user.email!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.mediumText,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildQuickStat(
                          'خاڵ',
                          user.totalScore.toString(),
                          AppColors.accentYellow,
                        ),
                        const SizedBox(width: 16),
                        _buildQuickStat(
                          'یاری',
                          user.gamesPlayed.toString(),
                          AppColors.primaryTeal,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Arrow indicator
              const Icon(
                Icons.arrow_forward_ios,
                color: AppColors.mediumText,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStat(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.mediumText),
        ),
      ],
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
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
                fontSize: 18,
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

  Widget _buildNotificationSetting(
    BuildContext context,
    WidgetRef ref,
    UserSettings settings,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingL,
        vertical: AppDimensions.paddingM,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryTeal.withOpacity(0.2),
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            ),
            child: const Icon(
              Icons.notifications_active,
              color: AppColors.primaryTeal,
              size: 24,
            ),
          ),
          const SizedBox(width: AppDimensions.paddingL),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ئاگادارکردنەوەی یادکردنەوە',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.lightText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'ئاگادارکردنەوە وەردەگریت بۆ یاری و یادکردنەوەکان',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.mediumText.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: settings.notificationsEnabled,
            onChanged: (value) {
              ref
                  .read(settingsProvider.notifier)
                  .setNotificationsEnabled(value);

              // Show feedback to user
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    value
                        ? 'ئاگادارکردنەوەکان چالاک کران'
                        : 'ئاگادارکردنەوەکان ناچالاک کران',
                    style: const TextStyle(color: AppColors.white),
                  ),
                  backgroundColor:
                      value ? AppColors.success : AppColors.mediumText,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            activeThumbColor: AppColors.primaryTeal,
            activeTrackColor: AppColors.primaryTeal.withOpacity(0.3),
            inactiveThumbColor: AppColors.mediumText,
            inactiveTrackColor: AppColors.mediumText.withOpacity(0.3),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingL,
        vertical: AppDimensions.paddingM,
      ),
      child: InkWell(
        onTap: () => _showLogoutDialog(context, ref),
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingM),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                ),
                child: const Icon(
                  Icons.logout,
                  color: AppColors.error,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppDimensions.paddingL),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'چوونەدەرەوە',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.error,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'چوونەدەرەوە لە ئەکاونتەکەت',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.mediumText,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                color: AppColors.error,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: AppColors.surface2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusL),
            ),
            title: const Text(
              'چوونەدەرەوە',
              style: TextStyle(color: AppColors.lightText),
            ),
            content: const Text(
              'دەتەوێت چووبیتە دەرەوە لە ئەکاونتەکەت؟',
              style: TextStyle(color: AppColors.mediumText),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'پاشگەزبوونەوە',
                  style: TextStyle(color: AppColors.mediumText),
                ),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  try {
                    await ref.read(authNotifierProvider.notifier).signOut();
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('هەڵە لە چوونەدەرەوە: $e'),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
                  }
                },
                child: const Text(
                  'چوونەدەرەوە',
                  style: TextStyle(color: AppColors.error),
                ),
              ),
            ],
          ),
    );
  }
}
