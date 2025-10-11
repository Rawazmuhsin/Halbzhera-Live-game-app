// File: lib/screens/auth/login_screen.dart
// Description: Updated login screen using the new design system

// ignore_for_file: avoid_print, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../utils/constants.dart';
import '../../widgets/common/gradient_background.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/auth/login_bottom_sheet.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _titleController;
  late Animation<double> _logoAnimation;
  late Animation<double> _titleAnimation;

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      duration: AppConstants.logoAnimation,
      vsync: this,
    )..repeat(reverse: true);

    _titleController = AnimationController(
      duration: AppConstants.titleAnimation,
      vsync: this,
    )..repeat(reverse: true);

    _logoAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeInOut),
    );

    _titleAnimation = Tween<double>(begin: 1.0, end: 1.4).animate(
      CurvedAnimation(parent: _titleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _logoController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final bool isSmallScreen = screenHeight < 700;

    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight:
                          MediaQuery.of(context).size.height -
                          MediaQuery.of(context).padding.top -
                          MediaQuery.of(context).padding.bottom -
                          100, // Space for button
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildAppLogo(),
                        SizedBox(
                          height:
                              isSmallScreen
                                  ? AppDimensions.paddingL
                                  : AppDimensions.paddingXL,
                        ),
                        _buildAppTitle(),
                        SizedBox(
                          height:
                              isSmallScreen
                                  ? AppDimensions.paddingS
                                  : AppDimensions.paddingM,
                        ),
                        _buildSubtitle(),
                        SizedBox(
                          height:
                              isSmallScreen
                                  ? AppDimensions.paddingL
                                  : AppDimensions.paddingXXL,
                        ),
                        _buildFeatureIcons(),
                      ],
                    ),
                  ),
                ),
              ),
              _buildGetStartedButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppLogo() {
    final screenHeight = MediaQuery.of(context).size.height;
    final bool isSmallScreen = screenHeight < 700;
    final double logoWidthFactor = isSmallScreen ? 0.4 : 0.5;

    return AnimatedBuilder(
      animation: _logoAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _logoAnimation.value * -12),
          child: Transform.scale(
            scale: 1.0 + (_logoAnimation.value * 0.05),
            child: Transform.rotate(
              angle: _logoAnimation.value * 0.05,
              child: FractionallySizedBox(
                widthFactor: logoWidthFactor,
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusXXL,
                      ),
                      gradient: AppColors.primaryGradient,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryRed.withOpacity(0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                        BoxShadow(
                          color: AppColors.white.withOpacity(0.1),
                          blurRadius: 0,
                          offset: const Offset(0, 0),
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: Container(
                      margin: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        gradient: AppColors.primaryGradient,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: Image.asset(
                          AppConstants.logoPath,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAppTitle() {
    final screenHeight = MediaQuery.of(context).size.height;
    final bool isSmallScreen = screenHeight < 700;
    final double titleFontSize = isSmallScreen ? 48 : 58;

    return AnimatedBuilder(
      animation: _titleAnimation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return AppColors.primaryGradient.createShader(bounds);
          },
          child: Text(
            AppTexts.appTitle,
            style: TextStyle(
              fontSize: titleFontSize,
              fontWeight: FontWeight.w900,
              color: AppColors.white,
              letterSpacing: -1,
              shadows: [
                Shadow(
                  color: AppColors.primaryRed.withOpacity(0.3),
                  blurRadius: 30,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSubtitle() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 340),
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingL),
      child: Text(
        AppTexts.appSubtitle,
        style: TextStyle(
          fontSize: 18,
          color: AppColors.mediumText,
          fontWeight: FontWeight.w400,
          height: 1.5,
          shadows: [
            Shadow(
              color: AppColors.black.withOpacity(0.3),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildFeatureIcons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildFeatureItem('⚡', AppTexts.fastFeature),
        const SizedBox(width: AppDimensions.paddingXL),
        _buildFeatureItem('🏆', AppTexts.rewardFeature),
        const SizedBox(width: AppDimensions.paddingXL),
        _buildFeatureItem('🎮', AppTexts.funFeature),
      ],
    );
  }

  Widget _buildFeatureItem(String icon, String text) {
    return Column(
      children: [
        Container(
          width: AppDimensions.logoS,
          height: AppDimensions.logoS,
          decoration: BoxDecoration(
            color: AppColors.white.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(icon, style: const TextStyle(fontSize: 20)),
          ),
        ),
        const SizedBox(height: AppDimensions.paddingS),
        Text(text, style: TextStyle(fontSize: 13, color: AppColors.subtleText)),
      ],
    );
  }

  Widget _buildGetStartedButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      child: CustomButton(
        text: AppTexts.getStarted,
        type: ButtonType.primary,
        size: ButtonSize.large,
        isFullWidth: true,
        onPressed: _showLoginOptions,
      ),
    );
  }

  void _showLoginOptions() {
    LoginBottomSheet.show(
      context,
      onGoogleLogin: _handleGoogleLogin,
      onFacebookLogin: _handleFacebookLogin,
      onGuestLogin: _handleGuestLogin,
    );
  }

  void _handleGoogleLogin() async {
    try {
      await ref.read(authNotifierProvider.notifier).signInWithGoogle();
    } catch (e) {
      // Error handling is done in the auth notifier
      print('Google login error: $e');
    }
  }

  void _handleFacebookLogin() {
    // TODO: Implement Facebook login
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Facebook login is not yet implemented'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _handleGuestLogin() async {
    try {
      await ref.read(authNotifierProvider.notifier).signInAnonymously();
    } catch (e) {
      // Error handling is done in the auth notifier
      print('Anonymous login error: $e');
    }
  }
}
