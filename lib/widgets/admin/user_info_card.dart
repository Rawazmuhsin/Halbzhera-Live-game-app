// File: lib/widgets/admin/user_info_card.dart
// Description: User information display card for admin panel

// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../utils/constants.dart';

class UserInfoCard extends StatelessWidget {
  final UserModel user;
  final VoidCallback? onView;
  final VoidCallback? onDelete;

  const UserInfoCard({
    super.key,
    required this.user,
    this.onView,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingS),
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        border: Border.all(color: AppColors.border1),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildUserAvatar(),
          const SizedBox(width: AppDimensions.paddingM),
          Expanded(child: _buildUserInfo()),
          _buildUserActions(),
        ],
      ),
    );
  }

  Widget _buildUserAvatar() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: user.isOnline ? AppColors.success : AppColors.border1,
          width: 2,
        ),
      ),
      child: CircleAvatar(
        radius: 28,
        backgroundColor: AppColors.primaryTeal,
        backgroundImage:
            user.photoURL != null ? NetworkImage(user.photoURL!) : null,
        child:
            user.photoURL == null
                ? Text(
                  user.displayName?.substring(0, 1).toUpperCase() ?? 'U',
                  style: const TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                )
                : null,
      ),
    );
  }

  Widget _buildUserInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          user.displayName ?? 'Unknown User',
          style: const TextStyle(
            color: AppColors.lightText,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        if (user.email != null) ...[
          const SizedBox(height: 4),
          Text(
            user.email!,
            style: const TextStyle(color: AppColors.mediumText, fontSize: 14),
            overflow: TextOverflow.ellipsis,
          ),
        ],
        // Show guest ID for anonymous users
        if (user.provider == LoginProvider.anonymous &&
            user.guestId != null) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.person_outline, color: AppColors.info, size: 14),
              const SizedBox(width: 4),
              Text(
                user.guestId!,
                style: TextStyle(
                  color: AppColors.info,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
        const SizedBox(height: 8),
        Wrap(
          spacing: AppDimensions.paddingS,
          runSpacing: 6,
          children: [
            _buildInfoChip('خاڵ: ${user.totalScore}', AppColors.accentYellow),
            _buildInfoChip('یاری: ${user.gamesPlayed}', AppColors.primaryTeal),
            _buildInfoChip('بردنەوە: ${user.gamesWon}', AppColors.success),
            _buildInfoChip(
              'ڕێژە: ${user.winRate.toStringAsFixed(1)}%',
              AppColors.info,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildUserActions() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color:
                user.isOnline
                    ? AppColors.success.withOpacity(0.2)
                    : AppColors.mediumText.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color:
                  user.isOnline
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
                  color:
                      user.isOnline ? AppColors.success : AppColors.mediumText,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                user.isOnline ? 'چالاک' : 'ناچالاک',
                style: TextStyle(
                  color:
                      user.isOnline ? AppColors.success : AppColors.mediumText,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: onView,
              icon: const Icon(Icons.visibility_outlined),
              color: AppColors.primaryTeal,
              iconSize: 20,
              style: IconButton.styleFrom(
                backgroundColor: AppColors.primaryTeal.withOpacity(0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                minimumSize: const Size(36, 36),
              ),
              tooltip: 'بینین',
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline),
              color: AppColors.error,
              iconSize: 20,
              style: IconButton.styleFrom(
                backgroundColor: AppColors.error.withOpacity(0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                minimumSize: const Size(36, 36),
              ),
              tooltip: 'سڕینەوە',
            ),
          ],
        ),
      ],
    );
  }
}
