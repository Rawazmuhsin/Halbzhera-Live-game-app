// File: lib/widgets/common/social_media_links.dart
// Description: Widget for displaying social media links

// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../utils/constants.dart';

class SocialMediaLinks extends StatelessWidget {
  const SocialMediaLinks({super.key});

  // Social media links
  static const String instagramUrl =
      'https://www.instagram.com/yusf_11223?igsh=MWQ1em92M2lsNnR1OQ%3D%3D&utm_source=qr';
  static const String snapchatUrl = 'https://t.snapchat.com/KJgqq2FM';
  static const String tiktokUrl =
      'https://www.tiktok.com/@bestun.outo?_t=ZS-8zSQOGhAvS5&_r=1';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        border: Border.all(color: AppColors.border1.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            'پەیوەندیمان پێوە بکە',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.lightText,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppDimensions.paddingM),
          Text(
            'ئێمە لەم پلاتفۆرمانەدا بەردەستین بۆ پەیوەندیکردن:',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.mediumText),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppDimensions.paddingL),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildSocialButton(
                context: context,
                imagePath: 'assets/social/instagram.png',
                label: 'Instagram',
                color: const Color(0xFFE1306C),
                url: instagramUrl,
              ),
              _buildSocialButton(
                context: context,
                imagePath: 'assets/social/snapchat.png',
                label: 'Snapchat',
                color: const Color(0xFFFFFC00),
                textColor: Colors.black87,
                url: snapchatUrl,
              ),
              _buildSocialButton(
                context: context,
                imagePath: 'assets/social/tiktok.png',
                label: 'TikTok',
                color: const Color.fromARGB(255, 238, 229, 229),
                url: tiktokUrl,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSocialButton({
    required BuildContext context,
    required String imagePath,
    required String label,
    required Color color,
    Color? textColor,
    required String url,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: () => _launchUrl(url),
          borderRadius: BorderRadius.circular(30),
          child: Container(
            width: 60,
            height: 60,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Image.asset(imagePath, fit: BoxFit.contain),
          ),
        ),
        const SizedBox(height: AppDimensions.paddingS),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.mediumText),
        ),
      ],
    );
  }

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }
}
