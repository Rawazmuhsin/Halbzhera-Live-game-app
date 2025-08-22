// File: lib/widgets/home/welcome_section.dart
// Description: Welcome message widget

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../utils/constants.dart';
import '../../providers/auth_provider.dart';

class WelcomeSection extends ConsumerWidget {
  const WelcomeSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(authStateProvider);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.paddingXL),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.surface2.withOpacity(0.8),
            AppColors.surface1.withOpacity(0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
        border: Border.all(color: AppColors.border1.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          userAsync.when(
            data: (user) {
              String displayName = 'کاربەر';
              if (user != null) {
                if (user.displayName?.isNotEmpty == true) {
                  displayName = user.displayName!;
                } else if (user.email?.isNotEmpty == true) {
                  // Extract name from email (before @)
                  displayName = user.email!.split('@').first;
                }
              }
              return Text(
                'بەخێرهاتنەوە، $displayName!',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: AppColors.lightText,
                ),
                textAlign: TextAlign.center,
              );
            },
            loading:
                () => const Text(
                  'بەخێرهاتنەوە!',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: AppColors.lightText,
                  ),
                  textAlign: TextAlign.center,
                ),
            error:
                (_, __) => const Text(
                  'بەخێرهاتنەوە!',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: AppColors.lightText,
                  ),
                  textAlign: TextAlign.center,
                ),
          ),
          const SizedBox(height: AppDimensions.paddingS),
          Text(
            'یاریە داهاتووەکان',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.mediumText,
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
