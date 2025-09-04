// File: lib/screens/about/about_screen.dart
// Description: About page for Halbzhera app with information about the game and managers

import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import '../../widgets/common/gradient_background.dart';
import '../../widgets/common/social_media_links.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildTabBar(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildAboutGameTab(),
                    _buildAboutManagersTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.lightText),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: AppDimensions.paddingS),
          Text(
            'دەربارەی ئێمە',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppColors.lightText,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: AppColors.white,
        unselectedLabelColor: AppColors.mediumText,
        indicator: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        ),
        tabs: const [
          Tab(text: 'دەربارەی یاری'),
          Tab(text: 'دەربارەی بەڕێوەبەران'),
        ],
      ),
    );
  }

  Widget _buildAboutGameTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionCard(
            title: 'دەربارەی یاری هەڵبژێرە',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'هەڵبژێرە یارییەکی زیندووە کە بە شێوەیەکی ڕاستەوخۆ لە کاتی دیاریکراودا بەڕێوە دەچێت. بەشداربووان دەتوانن خۆیان تۆمار بکەن و بەشداری یارییەکان بکەن بۆ وەرگرتنی خەڵات و خاڵ.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.lightText,
                      ),
                ),
                const SizedBox(height: AppDimensions.paddingM),
                Image.asset(
                  AppConstants.logoPath,
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.contain,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.paddingM),
          _buildSectionCard(
            title: 'خاڵ و خەڵات',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'بەشداربووان لە هەر یاریەکدا خاڵ کۆدەکەنەوە بەپێی:',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.lightText,
                      ),
                ),
                const SizedBox(height: AppDimensions.paddingS),
                _buildPointItem('وەڵامی ڕاست', '10 خاڵ بۆ هەر پرسیارێک'),
                _buildPointItem('خێرایی وەڵامدانەوە', 'تا خێراتر بیت، خاڵی زیاتر وەردەگریت'),
                _buildPointItem('بەشداریکردنی بەردەوام', 'خاڵی تایبەت بۆ ئەوانەی کە بەردەوامن'),
                const SizedBox(height: AppDimensions.paddingM),
                Text(
                  'خەڵاتەکان:',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.lightText,
                      ),
                ),
                const SizedBox(height: AppDimensions.paddingS),
                Text(
                  'بەشداربووانی سەرکەوتوو خەڵاتی نەختینە و دیاری تایبەت وەردەگرن کە لە کۆتایی هەر یارییەک ڕادەگەیەنرێن.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.lightText,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.paddingM),
          _buildSectionCard(
            title: 'چۆنیەتی بەشداریکردن',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStepItem(
                  1,
                  'هەژمار دروست بکە',
                  'بە خۆڕایی هەژمارێک دروست بکە لە ئەپەکە',
                ),
                _buildStepItem(
                  2,
                  'کاتی یاری ببینە',
                  'لە بەشی سەرەکی ئەپەکە کاتی یارییەکان ببینە',
                ),
                _buildStepItem(
                  3,
                  'بەشداری بکە',
                  'لە کاتی دیاریکراودا ئەپەکە بکەرەوە و بەشداری بکە',
                ),
                _buildStepItem(
                  4,
                  'وەڵام بدەرەوە و خاڵ کۆبکەرەوە',
                  'هەوڵبدە بە خێرایی و دروست وەڵامی پرسیارەکان بدەیتەوە',
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.paddingM),
          _buildSectionCard(
            title: 'بەڕێوەبردنی یارییەکان',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'یارییەکانی هەڵبژێرە لەلایەن تیمێکی پسپۆڕەوە بەڕێوە دەبرێن:',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.lightText,
                      ),
                ),
                const SizedBox(height: AppDimensions.paddingM),
                _buildManagementItem(
                  'بەشەکان و پرسیارەکان',
                  'پرسیارەکان لە چەندین بەشی جیاوازەوە ئامادە کراون بۆ ئەوەی هەموو بەشداربووان چێژ لە یارییەکە ببینن.',
                ),
                _buildManagementItem(
                  'کاتبەندی و خشتە',
                  'یارییەکان بەپێی خشتەیەکی دیاریکراو بەڕێوە دەبرێن و هەموو هەفتەیەک چەند یارییەک ئەنجام دەدرێت.',
                ),
                _buildManagementItem(
                  'خەڵات و دابەشکردن',
                  'دابەشکردنی خەڵات بەپێی خاڵ و پلەبەندی بەشداربووان دەبێت لە کۆتایی هەر یارییەک.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutManagersTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionCard(
            title: 'تیمی بەڕێوەبەران و گەشەپێدەران',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'یارییەکانی هەڵبژێرە لەلایەن ئەم تیمەوە بەڕێوە دەبرێن و گەشە پێدەدرێن:',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.lightText,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.paddingL),
          
          // Developer Profile
          _buildManagerProfileCard(
            name: 'رەوەز محسین',
            role: 'گەشەپێدەری ئەپ',
            imagePath: 'assets/managerimage/developer.jpg',
            description: 'بەرپرسی دیزاینکردن و گەشەپێدانی ئەپەکە. کارەکانی بریتین لە:'
                '\n• دیزاینکردن و جێبەجێکردنی پەیکەری ئەپەکە'
                '\n• جێبەجێکردنی هەموو تایبەتمەندی و فەنکشنەکانی ئەپەکە'
                '\n• چارەسەرکردنی کێشەکان و باشترکردنی کارایی ئەپەکە'
                '\n• بەڕێوەبردنی پەیوەندی لەگەڵ سێرڤەرەکان',
            skills: ['Flutter', 'Firebase', 'UI/UX Design', 'API Integration'],
          ),
          
          const SizedBox(height: AppDimensions.paddingL),
          
          // Manager Profile
          _buildManagerProfileCard(
            name: 'یوسف ومید',
            role: 'بەڕێوەبەری یارییەکان',
            imagePath: 'assets/managerimage/manager.jpg',
            description: 'بەرپرسی بەڕێوەبردن و ڕێکخستنی یارییەکان. کارەکانی بریتین لە:'
                '\n• ڕێکخستنی یارییەکان و دیاریکردنی کاتەکان'
                '\n• دانانی پرسیارەکان و دڵنیابوون لە دروستی و جۆراوجۆرییان'
                '\n• بەڕێوەبردنی بەشداربووان و چارەسەرکردنی کێشەکانیان'
                '\n• دابەشکردنی خەڵاتەکان و ڕێکخستنی پلەبەندی یاریزانەکان',
            skills: ['Quiz Design', 'Event Management', 'Community Management', 'Content Creation'],
          ),
          
          const SizedBox(height: AppDimensions.paddingL),
          
                    // Social Media Links Section
          const SocialMediaLinks(),
        ],
      ),
    );
  }
  
  Widget _buildManagerProfileCard({
    required String name,
    required String role,
    required String imagePath,
    required String description,
    required List<String> skills,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        border: Border.all(color: AppColors.border1.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Header with image
          ClipRRect(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(AppDimensions.radiusL),
              topRight: Radius.circular(AppDimensions.radiusL),
            ),
            child: Stack(
              children: [
                // Background gradient overlay
                Container(
                  height: 120,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: AppColors.primaryGradient,
                  ),
                ),
                
                // Profile info with image
                Padding(
                  padding: const EdgeInsets.all(AppDimensions.paddingM),
                  child: Row(
                    children: [
                      // Profile image
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.black.withOpacity(0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(45),
                          child: Image.asset(
                            imagePath,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppDimensions.paddingM),
                      // Name and role
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: AppColors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppDimensions.paddingS, 
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                              ),
                              child: Text(
                                role,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: AppColors.white,
                                    ),
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
          ),
          
          // Description
          Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.lightText,
                        height: 1.5,
                      ),
                ),
                const SizedBox(height: AppDimensions.paddingM),
                
                // Skills section
                Text(
                  'شارەزاییەکان:',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.lightText,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: AppDimensions.paddingS),
                Wrap(
                  spacing: AppDimensions.paddingS,
                  runSpacing: AppDimensions.paddingS,
                  children: skills.map((skill) => _buildSkillChip(skill)).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSkillChip(String skill) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingM,
        vertical: AppDimensions.paddingXS,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface3,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXXL),
        border: Border.all(color: AppColors.border1),
      ),
      child: Text(
        skill,
        style: TextStyle(
          color: AppColors.mediumText,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildSectionCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        border: Border.all(color: AppColors.border1.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppDimensions.paddingM),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(AppDimensions.radiusL),
                topRight: Radius.circular(AppDimensions.radiusL),
              ),
            ),
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingM),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildPointItem(String title, String points) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.paddingS),
      child: Row(
        children: [
          const Icon(Icons.star, color: AppColors.accentYellow, size: 18),
          const SizedBox(width: AppDimensions.paddingS),
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.lightText,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(width: AppDimensions.paddingS),
          Text(
            '- $points',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.mediumText,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepItem(int number, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.paddingM),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$number',
                style: const TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppDimensions.paddingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.lightText,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.mediumText,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManagementItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.paddingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle, color: AppColors.primaryRed, size: 18),
              const SizedBox(width: AppDimensions.paddingS),
              Text(
                title,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.lightText,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: AppDimensions.paddingL),
            child: Text(
              description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.mediumText,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
