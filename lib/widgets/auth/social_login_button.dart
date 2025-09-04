// File: lib/widgets/auth/social_login_button.dart
// Description: Social login buttons with Google and Facebook logos

// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../../utils/constants.dart';

enum SocialLoginType { google, facebook, guest }

class SocialLoginButton extends StatefulWidget {
  final SocialLoginType type;
  final VoidCallback onPressed;
  final bool isLoading;
  final bool isDisabled;

  const SocialLoginButton({
    super.key,
    required this.type,
    required this.onPressed,
    this.isLoading = false,
    this.isDisabled = false,
  });

  @override
  State<SocialLoginButton> createState() => _SocialLoginButtonState();
}

class _SocialLoginButtonState extends State<SocialLoginButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: AppConstants.fastAnimation,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (!widget.isDisabled && !widget.isLoading) {
      _animationController.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    _animationController.reverse();
  }

  void _onTapCancel() {
    _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: (widget.isDisabled || widget.isLoading) ? null : widget.onPressed,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: _buildButton(),
          );
        },
      ),
    );
  }

  Widget _buildButton() {
    final config = _getButtonConfig();

    return Container(
      width: double.infinity,
      height: AppDimensions.buttonHeightL,
      decoration: BoxDecoration(
        color: config.backgroundColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        border: Border.all(
          color: config.borderColor,
          width: AppDimensions.borderNormal,
        ),
        boxShadow:
            widget.type == SocialLoginType.guest
                ? null
                : [
                  BoxShadow(
                    color: config.shadowColor,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          onTap:
              widget.isDisabled || widget.isLoading ? null : widget.onPressed,
          splashColor:
              widget.type == SocialLoginType.google
                  ? AppColors.googleRed.withOpacity(0.1)
                  : widget.type == SocialLoginType.facebook
                  ? AppColors.facebookBlue.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.1),
          highlightColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.paddingL,
              vertical: AppDimensions.paddingM,
            ),
            child: _buildButtonContent(config),
          ),
        ),
      ),
    );
  }

  Widget _buildButtonContent(_ButtonConfig config) {
    if (widget.isLoading) {
      return const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
          ),
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (config.icon != null) ...[
          config.icon!,
          const SizedBox(width: AppDimensions.paddingM),
        ],
        Text(
          config.text,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: config.textColor,
          ),
        ),
      ],
    );
  }

  _ButtonConfig _getButtonConfig() {
    final Color textColor =
        widget.isDisabled
            ? AppColors.lightText.withOpacity(0.5)
            : AppColors.lightText;

    switch (widget.type) {
      case SocialLoginType.google:
        return _ButtonConfig(
          text: AppTexts.continueWithGoogle,
          backgroundColor: AppColors.surface2.withOpacity(0.8),
          borderColor:
              widget.isDisabled
                  ? AppColors.border1.withOpacity(0.5)
                  : AppColors.border1,
          textColor: textColor,
          shadowColor: AppColors.googleRed.withOpacity(0.2),
          icon: _buildIconForType(SocialLoginType.google, widget.isDisabled),
        );

      case SocialLoginType.facebook:
        return _ButtonConfig(
          text: AppTexts.continueWithFacebook,
          backgroundColor: AppColors.surface2.withOpacity(0.8),
          borderColor:
              widget.isDisabled
                  ? AppColors.border1.withOpacity(0.5)
                  : AppColors.border1,
          textColor: textColor,
          shadowColor: AppColors.facebookBlue.withOpacity(0.2),
          icon: _buildIconForType(SocialLoginType.facebook, widget.isDisabled),
        );

      case SocialLoginType.guest:
        return _ButtonConfig(
          text: AppTexts.continueAsGuest,
          backgroundColor: Colors.transparent,
          borderColor:
              widget.isDisabled
                  ? AppColors.border1.withOpacity(0.5)
                  : AppColors.border1,
          textColor:
              widget.isDisabled
                  ? AppColors.subtleText.withOpacity(0.5)
                  : AppColors.subtleText,
          shadowColor: Colors.transparent,
          icon: Icon(
            Icons.person_outline,
            color:
                widget.isDisabled
                    ? AppColors.subtleText.withOpacity(0.5)
                    : AppColors.subtleText,
            size: AppDimensions.iconM,
          ),
        );
    }
  }

  Widget _buildIconForType(SocialLoginType type, bool isDisabled) {
    switch (type) {
      case SocialLoginType.google:
        return _buildFallbackGoogleIcon(isDisabled);
      case SocialLoginType.facebook:
        return _buildFallbackFacebookIcon(isDisabled);
      default:
        return const SizedBox();
    }
  }

  // Fallback icons in case the asset images are not available
  Widget _buildFallbackGoogleIcon(bool isDisabled) {
    return Container(
      width: AppDimensions.iconM,
      height: AppDimensions.iconM,
      decoration: BoxDecoration(
        color: isDisabled ? AppColors.white.withOpacity(0.5) : AppColors.white,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          'G',
          style: TextStyle(
            color:
                isDisabled
                    ? AppColors.googleRed.withOpacity(0.5)
                    : AppColors.googleRed,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackFacebookIcon(bool isDisabled) {
    return Container(
      width: AppDimensions.iconM,
      height: AppDimensions.iconM,
      decoration: BoxDecoration(
        color:
            isDisabled
                ? AppColors.facebookBlue.withOpacity(0.5)
                : AppColors.facebookBlue,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          'f',
          style: TextStyle(
            color:
                isDisabled ? AppColors.white.withOpacity(0.5) : AppColors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _ButtonConfig {
  final String text;
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;
  final Color shadowColor;
  final Widget? icon;

  _ButtonConfig({
    required this.text,
    required this.backgroundColor,
    required this.borderColor,
    required this.textColor,
    required this.shadowColor,
    this.icon,
  });
}
