// File: lib/screens/home/home.dart
// Description: Enhanced home screen with automatic lobby navigation using streams

// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import '../../widgets/common/gradient_background.dart';
import '../../widgets/home/home_header.dart';
import '../../widgets/home/welcome_section.dart';
import '../../widgets/home/navigation_grid.dart';
import '../../widgets/home/games_list.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/scheduled_game_provider.dart';
import '../../providers/joined_user_provider.dart';
import '../../providers/auto_navigation_provider.dart';
import '../../models/scheduled_game_model.dart';
import '../../screens/games/lobby_screen.dart';
import '../../providers/auth_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _animationController.forward();
  }

  Future<void> _navigateToLobby(ScheduledGameModel game) async {
    if (!mounted) return;

    try {
      // Show notification
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.sports_esports, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '🎮 ${game.name} دەست پێکرد! چوونە ناو لۆبی...',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          ),
        ),
      );

      // Small delay for user to see the notification
      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;

      // Navigate to lobby
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder:
              (_) => LobbyScreen(
                game: game,
                isPreviewMode: false, // Game has started
              ),
        ),
      );

      // Mark as navigated to prevent duplicate navigation
      if (mounted) {
        ref.read(autoNavigationProvider.notifier).markAsNavigated(game.id);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error navigating to lobby: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch for auto navigation signals
    ref.listen<AutoNavigationState>(autoNavigationProvider, (previous, next) {
      // Check if we should navigate
      if (next.shouldNavigate &&
          next.gameToNavigate != null &&
          previous?.shouldNavigate != true) {
        _navigateToLobby(next.gameToNavigate!);
      }
    });

    // Watch these to keep UI updated
    final upcomingGamesAsync = ref.watch(upcomingScheduledGamesProvider);
    final currentUser = ref.watch(currentUserProvider);
    final userJoinedGames = ref.watch(userJoinedGamesProvider);

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: const HomeHeader(),
        body: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: RefreshIndicator(
                  onRefresh: () async {
                    // Refresh the game list
                    ref.invalidate(upcomingScheduledGamesProvider);
                    ref.invalidate(userJoinedGamesProvider);
                    await Future.delayed(const Duration(seconds: 1));
                  },
                  color: AppColors.primaryTeal,
                  backgroundColor: AppColors.surface2,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(AppDimensions.paddingL),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const WelcomeSection(),
                        const SizedBox(height: AppDimensions.paddingXL),

                        // Show joined games indicator if user has joined any
                        userJoinedGames.when(
                          data: (joinedGames) {
                            if (joinedGames.isNotEmpty) {
                              return Container(
                                margin: const EdgeInsets.only(
                                  bottom: AppDimensions.paddingL,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppDimensions.paddingM,
                                  vertical: AppDimensions.paddingS,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.success.withOpacity(0.1),
                                  border: Border.all(
                                    color: AppColors.success.withOpacity(0.3),
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    AppDimensions.radiusM,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      color: AppColors.success,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'تۆ بەشداری ${joinedGames.length} یاری دەکەیت',
                                      style: TextStyle(
                                        color: AppColors.success,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const SizedBox.shrink(),
                        ),

                        const NavigationGrid(),
                        const SizedBox(height: AppDimensions.paddingXL),
                        const GamesList(),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
