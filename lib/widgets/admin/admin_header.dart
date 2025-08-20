// File: lib/widgets/admin/admin_header.dart
// Description: Reusable admin header widget

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../utils/constants.dart';
import '../../providers/auth_provider.dart';

class AdminHeader extends ConsumerWidget {
  final User currentUser;

  const AdminHeader({super.key, required this.currentUser});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.border1,
            width: AppDimensions.borderThin,
          ),
        ),
      ),
      child: Row(
        children: [
          _buildLogo(),
          const SizedBox(width: AppDimensions.paddingM),
          _buildTitle(),
          const Spacer(),
          _buildProfileSection(context, ref),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryRed.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Center(
        child: Text(
          'H',
          style: TextStyle(
            color: AppColors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Halbzhera Admin',
          style: TextStyle(
            color: AppColors.lightText,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          'بەڕێوەبردنی یاری زیندوو',
          style: TextStyle(color: AppColors.mediumText, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildProfileSection(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => _showProfileMenu(context, ref),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            currentUser.displayName ?? 'Admin',
            style: const TextStyle(
              color: AppColors.lightText,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: AppDimensions.paddingS),
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.primaryTeal,
            backgroundImage:
                currentUser.photoURL != null
                    ? NetworkImage(currentUser.photoURL!)
                    : null,
            child:
                currentUser.photoURL == null
                    ? const Icon(
                      Icons.admin_panel_settings,
                      color: AppColors.white,
                    )
                    : null,
          ),
        ],
      ),
    );
  }

  void _showProfileMenu(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            padding: const EdgeInsets.all(AppDimensions.paddingL),
            decoration: const BoxDecoration(
              color: AppColors.surface2,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(AppDimensions.radiusXL),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.person, color: AppColors.lightText),
                  title: const Text(
                    'پڕۆفایل',
                    style: TextStyle(color: AppColors.lightText),
                  ),
                  onTap: () => Navigator.pop(context),
                ),
                ListTile(
                  leading: const Icon(
                    Icons.settings,
                    color: AppColors.lightText,
                  ),
                  title: const Text(
                    'ڕێکخستنەکان',
                    style: TextStyle(color: AppColors.lightText),
                  ),
                  onTap: () => Navigator.pop(context),
                ),
                ListTile(
                  leading: const Icon(Icons.logout, color: AppColors.error),
                  title: const Text(
                    'چوونەدەرەوە',
                    style: TextStyle(color: AppColors.error),
                  ),
                  onTap: () async {
                    Navigator.pop(context); // Close the bottom sheet first

                    // Show loading dialog
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder:
                          (context) =>
                              const Center(child: CircularProgressIndicator()),
                    );

                    try {
                      // Call the signOut method from auth provider
                      await ref.read(authNotifierProvider.notifier).signOut();

                      // Close loading dialog
                      if (context.mounted) {
                        Navigator.pop(context);
                      }

                      // The AuthGate will automatically navigate to login screen
                      // when the auth state changes to null
                    } catch (e) {
                      // Close loading dialog
                      if (context.mounted) {
                        Navigator.pop(context);

                        // Show error message
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('هەڵە لە چوونەدەرەوە: $e'),
                            backgroundColor: AppColors.error,
                          ),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
          ),
    );
  }
}
