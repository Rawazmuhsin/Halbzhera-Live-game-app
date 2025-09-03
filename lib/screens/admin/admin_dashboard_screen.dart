import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halbzhera/providers/auth_provider.dart';
import 'package:halbzhera/screens/admin/winners_screen.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Check if user is admin
    final isAdmin = ref.watch(isAdminProvider);

    if (!isAdmin) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('ناوەندی بەڕێوەبەرایەتی'),
          backgroundColor: const Color(0xFF1A1F36),
        ),
        body: const Center(
          child: Text(
            'ڕێگەت پێنادرێت بۆ بینینی ئەم پەڕەیە',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('ناوەندی بەڕێوەبەرایەتی'),
        backgroundColor: const Color(0xFF1A1F36),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0B1120), Color(0xFF1A1F36), Color(0xFF2A1B3D)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'بەڕێوەبردنی سیستەم',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),

              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  children: [
                    _buildAdminTile(
                      context,
                      'براوەکان',
                      'بینینی هەموو براوەکانی یارییەکان',
                      Icons.emoji_events,
                      Colors.amber,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AdminWinnersScreen(),
                        ),
                      ),
                    ),
                    _buildAdminTile(
                      context,
                      'یارییەکان',
                      'بەڕێوەبردنی یارییەکان',
                      Icons.games,
                      Colors.green,
                      () {
                        // Navigate to games management
                      },
                    ),
                    _buildAdminTile(
                      context,
                      'بەکارهێنەران',
                      'بەڕێوەبردنی بەکارهێنەران',
                      Icons.people,
                      Colors.blue,
                      () {
                        // Navigate to users management
                      },
                    ),
                    _buildAdminTile(
                      context,
                      'ڕاپۆرت',
                      'بینینی ڕاپۆرت و داتاکان',
                      Icons.bar_chart,
                      Colors.purple,
                      () {
                        // Navigate to reports
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdminTile(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1F36).withOpacity(0.7),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: color),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
