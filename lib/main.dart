// File: lib/main.dart
// Description: Main entry point with Riverpod and Firebase initialization

// ignore_for_file: deprecated_member_use, avoid_print

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'config/firebase_config.dart';
import 'config/app_theme.dart';
import 'config/app_routes.dart';
import 'screens/auth/auth_gate.dart';
import 'utils/constants.dart';
import 'utils/debug_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize Firebase
  try {
    await FirebaseConfig.initialize();
    print('✅ Firebase initialized successfully!');

    // Add debug information
    DebugHelper.logGoogleSignInConfiguration();
    DebugHelper.logFirebaseConfiguration();
    await DebugHelper.testGoogleSignInAvailability();
  } catch (e) {
    print('❌ Error initializing Firebase: $e');
    DebugHelper.printTroubleshootingGuide();
  }

  runApp(ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,

      // Theme configuration
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark, // Force dark theme for now
      // Use AuthGate as the home screen
      home: const AuthGate(),

      // Navigation using our routes
      onGenerateRoute: AppRoutes.onGenerateRoute,

      // Global settings
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(1.0)),
          child: child!,
        );
      },
    );
  }
}

// ============================================================================
// SPLASH SCREEN
// ============================================================================

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // App Logo
                      Container(
                        width: 120,
                        height: 120,
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
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusXXL,
                          ),
                          child: Image.asset(
                            AppConstants.logoPath,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),

                      const SizedBox(height: AppDimensions.paddingXL),

                      // App Title
                      ShaderMask(
                        shaderCallback: (bounds) {
                          return AppColors.primaryGradient.createShader(bounds);
                        },
                        child: Text(
                          AppTexts.appTitle,
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            color: AppColors.white,
                            letterSpacing: -1,
                          ),
                        ),
                      ),

                      const SizedBox(height: AppDimensions.paddingM),

                      // Loading indicator
                      SizedBox(
                        width: 50,
                        height: 50,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.primaryRed.withOpacity(0.8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// ERROR SCREEN
// ============================================================================

class ErrorScreen extends StatelessWidget {
  final String error;

  const ErrorScreen({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingL),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 80, color: AppColors.error),

                const SizedBox(height: AppDimensions.paddingL),

                Text(
                  'هەڵەیەک ڕوویدا',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppColors.lightText,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: AppDimensions.paddingM),

                Text(
                  error,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppColors.mediumText),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: AppDimensions.paddingXL),

                ElevatedButton(
                  onPressed: () {
                    // Restart the app
                    SystemChannels.platform.invokeMethod('SystemNavigator.pop');
                  },
                  child: Text('دووبارە هەوڵبدەوە'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// NOT FOUND SCREEN
// ============================================================================

class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingL),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '404',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    color: AppColors.primaryRed,
                  ),
                ),

                const SizedBox(height: AppDimensions.paddingM),

                Text(
                  'پەڕە دۆزرایەوە',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppColors.lightText,
                  ),
                ),

                const SizedBox(height: AppDimensions.paddingXL),

                ElevatedButton(
                  onPressed:
                      () => Navigator.of(context).pushReplacementNamed('/'),
                  child: Text('گەڕانەوە بۆ سەرەکی'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
