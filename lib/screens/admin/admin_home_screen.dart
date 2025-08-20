// File: lib/screens/admin/admin_home_screen.dart
// Description: Main admin dashboard structure

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../utils/constants.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/gradient_background.dart';
import '../../widgets/admin/admin_header.dart';
import '../../widgets/admin/admin_tab_bar.dart';
import '../../widgets/admin/overview_tab.dart';
import '../../widgets/admin/users_tab.dart';
import '../../widgets/admin/games_tab.dart';
import '../../widgets/admin/analytics_tab.dart';

class AdminHomeScreen extends ConsumerStatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  ConsumerState<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends ConsumerState<AdminHomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch auth state to ensure admin access
    final currentUser = ref.watch(currentUserProvider);
    final isAdmin = ref.watch(isAdminProvider);

    if (currentUser == null) {
      return const Scaffold(
        body: Center(
          child: Text(
            'تکایە وەک ئەدمین بچۆرە ژوورەوە',
            style: TextStyle(color: AppColors.lightText, fontSize: 16),
          ),
        ),
      );
    }

    if (!isAdmin) {
      return const Scaffold(
        body: Center(
          child: Text(
            'دەستڕاگەیشتن قەدەغەیە. مافی ئەدمین پێویستە.',
            style: TextStyle(color: AppColors.error, fontSize: 16),
          ),
        ),
      );
    }

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              AdminHeader(currentUser: currentUser),
              AdminTabBar(controller: _tabController),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: const [
                    OverviewTab(),
                    UsersTab(),
                    GamesTab(),
                    AnalyticsTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
