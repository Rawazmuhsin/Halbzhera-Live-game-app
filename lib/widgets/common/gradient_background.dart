// File: lib/widgets/common/gradient_background.dart
// Description: Animated gradient background with floating orbs and sparkles

// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../../utils/constants.dart';

class GradientBackground extends StatefulWidget {
  final Widget child;
  final bool showAnimation;
  final bool showSparkles;
  final List<Color>? customColors;

  const GradientBackground({
    super.key,
    required this.child,
    this.showAnimation = true,
    this.showSparkles = true,
    this.customColors,
  });

  @override
  State<GradientBackground> createState() => _GradientBackgroundState();
}

class _GradientBackgroundState extends State<GradientBackground>
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
    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: Stack(
        children: [
          // Base gradient background
          _buildBaseGradient(),

          // Animated floating gradients
          if (widget.showAnimation) _buildFloatingGradients(),

          // Sparkle effects
          if (widget.showSparkles) _buildSparkleEffects(),

          // Child content
          widget.child,
        ],
      ),
    );
  }

  Widget _buildBaseGradient() {
    final colors =
        widget.customColors ??
        [AppColors.darkBlue1, AppColors.darkBlue2, AppColors.darkBlue3];

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

  Widget _buildFloatingGradients() {
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
                      const Color(0xFF7877c6).withOpacity(0.3),
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
                      AppColors.primaryRed.withOpacity(0.3),
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
                      AppColors.primaryTeal.withOpacity(0.2),
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
                      AppColors.accentYellow.withOpacity(0.15),
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

  Widget _buildSparkleEffects() {
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
                  color: Colors.white.withOpacity(
                    0.1 + (_sparkleAnimation.value * 0.1),
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.2),
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
class SimpleGradientBackground extends StatelessWidget {
  final Widget child;
  final List<Color>? customColors;

  const SimpleGradientBackground({
    super.key,
    required this.child,
    this.customColors,
  });

  @override
  Widget build(BuildContext context) {
    final colors =
        customColors ??
        [AppColors.darkBlue1, AppColors.darkBlue2, AppColors.darkBlue3];

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
