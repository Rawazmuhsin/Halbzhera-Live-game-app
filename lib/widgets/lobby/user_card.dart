// File: lib/widgets/lobby/user_card.dart
// Description: Individual user card widget for lobby

// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../../utils/constants.dart';

import '../../models/joined_user_model.dart';

class UserCard extends StatefulWidget {
  final JoinedUserModel user;
  final int index;

  const UserCard({super.key, required this.user, required this.index});

  @override
  State<UserCard> createState() => _UserCardState();
}

class _UserCardState extends State<UserCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _slideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    // Staggered animation based on index
    Future.delayed(Duration(milliseconds: widget.index * 100), () {
      if (mounted) {
        _animationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Color _getAvatarColor(String avatar) {
    // Generate consistent colors based on avatar letter
    const colors = [
      AppColors.primaryTeal,
      AppColors.primaryRed,
      AppColors.accentYellow,
      Color(0xFF8B5CF6), // Purple
      Color(0xFF06B6D4), // Cyan
      Color(0xFF10B981), // Emerald
      Color(0xFFF59E0B), // Amber
      Color(0xFFEF4444), // Red
    ];

    final index = avatar.codeUnitAt(0) % colors.length;
    return colors[index];
  }

  String _getJoinedTimeText(DateTime joinedAt) {
    final now = DateTime.now();
    final difference = now.difference(joinedAt);

    if (difference.inMinutes < 1) {
      return 'ئێستا';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} خولەک پێش ئێستا';
    } else {
      return '${difference.inHours} کاتژمێر پێش ئێستا';
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final avatarLetter =
        (user.userDisplayName != null && user.userDisplayName!.isNotEmpty)
            ? user.userDisplayName![0].toUpperCase()
            : (user.userEmail.isNotEmpty
                ? user.userEmail[0].toUpperCase()
                : '?');
    final avatarColor = _getAvatarColor(avatarLetter);

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Container(
              padding: const EdgeInsets.all(AppDimensions.paddingL),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.surface1.withOpacity(0.3),
                    AppColors.surface2.withOpacity(0.1),
                  ],
                ),
                border: Border.all(color: AppColors.border1.withOpacity(0.2)),
                borderRadius: BorderRadius.circular(AppDimensions.radiusL),
              ),
              child: Row(
                children: [
                  // User Avatar
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [avatarColor, avatarColor.withOpacity(0.8)],
                      ),
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: avatarColor.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        avatarLetter,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: AppDimensions.paddingM),

                  // User Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.userDisplayName ?? user.userEmail,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.lightText,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getJoinedTimeText(user.joinedAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.mediumText.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Status Indicator
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color:
                              user.isActive
                                  ? AppColors.success
                                  : AppColors.mediumText,
                          borderRadius: BorderRadius.circular(4),
                          boxShadow:
                              user.isActive
                                  ? [
                                    BoxShadow(
                                      color: AppColors.success.withOpacity(0.6),
                                      blurRadius: 6,
                                      spreadRadius: 1,
                                    ),
                                  ]
                                  : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        user.isActive ? 'ئامادە' : 'دەرەوە',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color:
                              user.isActive
                                  ? AppColors.success
                                  : AppColors.mediumText,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
