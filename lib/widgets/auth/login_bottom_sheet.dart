// File: lib/widgets/auth/login_bottom_sheet.dart
// Description: Updated bottom sheet modal for login options with loading states

// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../utils/constants.dart';
import '../../providers/auth_provider.dart';
import 'social_login_button.dart';

class LoginBottomSheet extends ConsumerStatefulWidget {
  final VoidCallback? onGoogleLogin;
  final VoidCallback? onFacebookLogin;
  final VoidCallback? onGuestLogin;

  const LoginBottomSheet({
    super.key,
    this.onGoogleLogin,
    this.onFacebookLogin,
    this.onGuestLogin,
  });

  // Static method to show the bottom sheet
  static void show(
    BuildContext context, {
    VoidCallback? onGoogleLogin,
    VoidCallback? onFacebookLogin,
    VoidCallback? onGuestLogin,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      builder:
          (context) => LoginBottomSheet(
            onGoogleLogin: onGoogleLogin,
            onFacebookLogin: onFacebookLogin,
            onGuestLogin: onGuestLogin,
          ),
    );
  }

  @override
  ConsumerState<LoginBottomSheet> createState() => _LoginBottomSheetState();
}

class _LoginBottomSheetState extends ConsumerState<LoginBottomSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  // Track individual button loading states
  bool _isGoogleLoading = false;
  bool _isFacebookLoading = false;
  bool _isGuestLoading = false;

  // Flag to prevent multiple close attempts
  bool _isClosing = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: AppConstants.normalAnimation,
      vsync: this,
    );

    _slideAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _closeSheet() {
    if (!mounted || _isClosing) return;

    _isClosing = true;

    // Safely close the sheet
    _animationController.reverse().then((_) {
      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
    });
  }

  void _safeCloseSheet() {
    if (!mounted || _isClosing) return;

    // Use post-frame callback to ensure we're not in the middle of a build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_isClosing && Navigator.canPop(context)) {
        _closeSheet();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _safeCloseSheet,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Container(
            color: AppColors.overlay1.withOpacity(_fadeAnimation.value * 0.6),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: GestureDetector(
                onTap: () {}, // Prevent closing when tapping on sheet
                child: Transform.translate(
                  offset: Offset(
                    0,
                    MediaQuery.of(context).size.height *
                        0.4 *
                        _slideAnimation.value,
                  ),
                  child: _buildBottomSheet(),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBottomSheet() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF282a4e).withOpacity(0.95),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppDimensions.radiusXXL),
          topRight: Radius.circular(AppDimensions.radiusXXL),
        ),
        border: Border.all(
          color: AppColors.border1,
          width: AppDimensions.borderThin,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.3),
            blurRadius: 50,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(AppDimensions.radiusXXL),
            topRight: Radius.circular(AppDimensions.radiusXXL),
          ),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.white.withOpacity(0.1), Colors.transparent],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppDimensions.paddingL,
            AppDimensions.paddingXL,
            AppDimensions.paddingL,
            AppDimensions.paddingXXL,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDragHandle(),
              const SizedBox(height: AppDimensions.paddingL),
              _buildHeader(),
              const SizedBox(height: AppDimensions.paddingXL),
              _buildLoginOptions(),
              const SizedBox(height: AppDimensions.paddingL),
              _buildGuestOption(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDragHandle() {
    return Container(
      width: 50,
      height: 4,
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Text(
          AppTexts.chooseLoginMethod,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.lightText,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppDimensions.paddingS),
        Text(
          AppTexts.loginDescription,
          style: TextStyle(
            fontSize: 14,
            color: AppColors.subtleText,
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildLoginOptions() {
    final isAnyLoading =
        _isGoogleLoading || _isFacebookLoading || _isGuestLoading;

    return Column(
      children: [
        SocialLoginButton(
          type: SocialLoginType.google,
          isLoading: _isGoogleLoading,
          isDisabled:
              isAnyLoading &&
              !_isGoogleLoading, // Only disable if another button is loading
          onPressed: () => _handleGoogleLogin(),
        ),
        const SizedBox(height: AppDimensions.paddingM),
        SocialLoginButton(
          type: SocialLoginType.facebook,
          isLoading: _isFacebookLoading,
          isDisabled:
              isAnyLoading &&
              !_isFacebookLoading, // Only disable if another button is loading
          onPressed: () => _handleFacebookLogin(),
        ),
      ],
    );
  }

  Widget _buildGuestOption() {
    final isAnyLoading =
        _isGoogleLoading || _isFacebookLoading || _isGuestLoading;

    return Container(
      width: double.infinity,
      height: AppDimensions.buttonHeightL,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        border: Border.all(
          color:
              (isAnyLoading &&
                      !_isGuestLoading) // Only dim if another button is loading
                  ? AppColors.border1.withOpacity(0.5)
                  : AppColors.border1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          onTap:
              (isAnyLoading && !_isGuestLoading)
                  ? null
                  : () => _handleGuestLogin(),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.paddingL,
              vertical: AppDimensions.paddingM,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isGuestLoading) ...[
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.subtleText,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppDimensions.paddingM),
                ] else ...[
                  Icon(
                    Icons.person_outline,
                    color:
                        (isAnyLoading && !_isGuestLoading)
                            ? AppColors.subtleText.withOpacity(0.5)
                            : AppColors.subtleText,
                    size: AppDimensions.iconM,
                  ),
                  const SizedBox(width: AppDimensions.paddingM),
                ],
                Text(
                  AppTexts.continueAsGuest,
                  style: TextStyle(
                    color:
                        (isAnyLoading && !_isGuestLoading)
                            ? AppColors.subtleText.withOpacity(0.5)
                            : AppColors.subtleText,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleGoogleLogin() async {
    if (_isGoogleLoading || !mounted) return;

    if (mounted) {
      setState(() {
        _isGoogleLoading = true;
      });
    }

    try {
      // Call the auth service directly
      await ref.read(authNotifierProvider.notifier).signInWithGoogle();

      // Success - close the sheet
      if (mounted) {
        _closeSheet();
      }
    } catch (e) {
      // Error - reset loading state and show error
      if (mounted) {
        setState(() {
          _isGoogleLoading = false;
        });
        _showErrorSnackBar('خەڵەیەک ڕوویدا لە چوونە ژوورەوە: ${e.toString()}');
      }
    }
  }

  Future<void> _handleFacebookLogin() async {
    if (_isFacebookLoading || widget.onFacebookLogin == null || !mounted) {
      return;
    }

    if (mounted) {
      setState(() {
        _isFacebookLoading = true;
      });
    }

    try {
      widget.onFacebookLogin!();
    } catch (e) {
      if (mounted) {
        setState(() {
          _isFacebookLoading = false;
        });
        _showErrorSnackBar(
          'خەڵەیەک ڕوویدا لە چوونە ژوورەوە بە Facebook: ${e.toString()}',
        );
      }
    }
  }

  Future<void> _handleGuestLogin() async {
    if (_isGuestLoading || !mounted) return;

    if (mounted) {
      setState(() {
        _isGuestLoading = true;
      });
    }

    try {
      // Call the auth service directly
      await ref.read(authNotifierProvider.notifier).signInAnonymously();

      // Success - close the sheet
      if (mounted) {
        _closeSheet();
      }
    } catch (e) {
      // Error - reset loading state and show error
      if (mounted) {
        setState(() {
          _isGuestLoading = false;
        });
        _showErrorSnackBar('خەڵەیەک ڕوویدا لە چوونە ژوورەوە: ${e.toString()}');
      }
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return; // Guard against unmounted widget

    // Use a post-frame callback to ensure the context is still valid
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(color: AppColors.white, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          ),
          margin: const EdgeInsets.all(AppDimensions.paddingM),
          action: SnackBarAction(
            label: 'پاشگەزبوونەوە',
            textColor: AppColors.white,
            onPressed: () {
              if (mounted) {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              }
            },
          ),
        ),
      );
    });
  }
}
