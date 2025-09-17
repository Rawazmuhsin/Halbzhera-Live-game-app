// File: lib/widgets/common/theme_aware_gradient_background.dart
// Description: An improved gradient background that adapts to the app's theme

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../utils/constants.dart';
import '../../providers/app_theme_provider.dart';

class ThemeAwareGradientBackground extends ConsumerStatefulWidget {
  final Widget child;
  final bool showAnimation;
  final bool showSparkles;

  const ThemeAwareGradientBackground({
    super.key,
    required this.child,
    this.showAnimation = true,
    this.showSparkles = true,
  });

  @override
  ConsumerState<ThemeAwareGradientBackground> createState() =>
      _ThemeAwareGradientBackgroundState();
}

class _ThemeAwareGradientBackgroundState
    extends ConsumerState<ThemeAwareGradientBackground>
    with TickerProviderStateMixin {
  late AnimationController _backgroundController;
  late AnimationController _sparkleController;
  late Animation<double> _backgroundAnimation;
  late Animation<double> _sparkleAnimation;

  @override
  void initState() {
    super.initState();

    _backgroundController = AnimationController(
      duration: AppConstants.backgroundAnimation,
      vsync: this,
    );

    _sparkleController = AnimationController(
      duration: const Duration(seconds: 15),
      vsync: this,
    );

    _backgroundAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _backgroundController, curve: Curves.easeInOut),
    );

    _sparkleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _sparkleController, curve: Curves.linear),
    );

    if (widget.showAnimation) {
      _backgroundController.repeat();
    }

    if (widget.showSparkles) {
      _sparkleController.repeat();
    }
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    _sparkleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get the current theme mode
    final isDark = ref.watch(isDarkModeProvider);

    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: Stack(
        children: [
          // Base gradient background
          _buildBaseGradient(isDark),

          // Animated floating gradients
          if (widget.showAnimation) _buildFloatingGradients(isDark),

          // Sparkle effects
          if (widget.showSparkles) _buildSparkleEffects(isDark),

          // Child content
          widget.child,
        ],
      ),
    );
  }

  Widget _buildBaseGradient(bool isDark) {
    // Use different background colors based on theme
    final colors =
        isDark
            ? [
              AppColors.darkBlue1,
              AppColors.darkBlue2,
              AppColors.darkBlue3,
            ] // Dark theme
            : [
              const Color(0xFFF5F5F5), // Light gray for light theme
              const Color(0xFFEEEEEE), // Medium gray for light theme
              const Color(0xFFE0E0E0), // Dark gray for light theme
            ];

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: const [0.0, 0.5, 1.0],
          colors: colors,
        ),
      ),
    );
  }

  Widget _buildFloatingGradients(bool isDark) {
    // Adjust opacity and colors based on theme
    final opacityFactor = isDark ? 1.0 : 0.5; // Less opacity in light mode

    return AnimatedBuilder(
      animation: _backgroundAnimation,
      builder: (context, child) {
        return Stack(
          children: [
            // First floating gradient
            Positioned(
              top: 100 + (_backgroundAnimation.value * 20),
              left: 50 + (_backgroundAnimation.value * 15),
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF7877c6).withOpacity(0.3 * opacityFactor),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Second floating gradient
            Positioned(
              bottom: 150 + (_backgroundAnimation.value * -25),
              right: 30 + (_backgroundAnimation.value * 10),
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.primaryRed.withOpacity(0.3 * opacityFactor),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Third floating gradient
            Positioned(
              top: MediaQuery.of(context).size.height / 2 - 100,
              left: MediaQuery.of(context).size.width / 2 - 100,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.primaryTeal.withOpacity(0.2 * opacityFactor),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Fourth floating gradient
            Positioned(
              top: 200 + (_backgroundAnimation.value * -15),
              right: 100 + (_backgroundAnimation.value * 20),
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.accentYellow.withOpacity(0.15 * opacityFactor),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSparkleEffects(bool isDark) {
    // Adjust sparkle brightness based on theme
    final sparkleColor = isDark ? Colors.white : Colors.black;
    final opacityFactor = isDark ? 1.0 : 0.4; // Less visible in light mode

    return AnimatedBuilder(
      animation: _sparkleAnimation,
      builder: (context, child) {
        return Stack(
          children: List.generate(30, (index) {
            final screenWidth = MediaQuery.of(context).size.width;
            final screenHeight = MediaQuery.of(context).size.height;

            // Create different sparkle patterns
            final x = (index * 37.0) % screenWidth;
            final y = (index * 23.0) % screenHeight;
            final size = (index % 3) + 1.0; // 1, 2, or 3
            final speed = (index % 5) + 1; // Different speeds

            final offset = Offset(
              (_sparkleAnimation.value * speed * 10) % 20 - 10,
              (_sparkleAnimation.value * speed * -20) % 40 - 20,
            );

            return Positioned(
              left: x + offset.dx,
              top: y + offset.dy,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: sparkleColor.withOpacity(
                    (0.1 + (_sparkleAnimation.value * 0.1)) * opacityFactor,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: sparkleColor.withOpacity(0.2 * opacityFactor),
                      blurRadius: size * 2,
                    ),
                  ],
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

// Alternative simpler background for better performance
class SimpleThemeAwareGradientBackground extends ConsumerWidget {
  final Widget child;

  const SimpleThemeAwareGradientBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(isDarkModeProvider);

    // Use different background colors based on theme
    final colors =
        isDark
            ? [
              AppColors.darkBlue1,
              AppColors.darkBlue2,
              AppColors.darkBlue3,
            ] // Dark theme
            : [
              const Color(0xFFF5F5F5), // Light gray for light theme
              const Color(0xFFEEEEEE), // Medium gray for light theme
              const Color(0xFFE0E0E0), // Dark gray for light theme
            ];

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: const [0.0, 0.5, 1.0],
          colors: colors,
        ),
      ),
      child: child,
    );
  }
}
