// File: lib/screens/settings/settings_screen.dart
// Description: User settings screen

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';
import 'user_info_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserModel = ref.watch(currentUserModelProvider);
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings'), centerTitle: true),
      body: currentUserModel.when(
        data: (user) => _buildSettingsContent(context, ref, user, settings),
        loading: () => const Center(child: CircularProgressIndicator()),
        error:
            (error, stackTrace) =>
                Center(child: Text('Error loading settings: $error')),
      ),
    );
  }

  Widget _buildSettingsContent(
    BuildContext context,
    WidgetRef ref,
    UserModel? user,
    UserSettings settings,
  ) {
    if (user == null) {
      return const Center(child: Text('Please sign in to access settings'));
    }

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // User profile card
        _buildProfileCard(context, ref, user),

        const SizedBox(height: 24),

        const SizedBox(height: 16),

        // Notification settings
        _buildSection(
          context,
          title: 'Notifications',
          children: [_buildNotificationSetting(context, ref, settings)],
        ),
      ],
    );
  }

  Widget _buildProfileCard(
    BuildContext context,
    WidgetRef ref,
    UserModel user,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                // User avatar
                CircleAvatar(
                  radius: 30,
                  backgroundImage:
                      user.photoURL != null
                          ? NetworkImage(user.photoURL!)
                          : null,
                  child:
                      user.photoURL == null
                          ? Text(
                            user.displayName?.substring(0, 1).toUpperCase() ??
                                'U',
                            style: const TextStyle(fontSize: 24),
                          )
                          : null,
                ),

                const SizedBox(width: 16),

                // User info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.displayName ?? 'User',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (user.email != null && user.email!.isNotEmpty)
                        Text(
                          user.email!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ),

                // Info button
                IconButton(
                  icon: const Icon(Icons.info_outline),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UserInfoScreen(user: user),
                      ),
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Stats
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatItem('Score', user.totalScore.toString()),
                _buildStatItem('Games', user.gamesPlayed.toString()),
                _buildStatItem('Won', user.gamesWon.toString()),
                _buildStatItem(
                  'Win Rate',
                  '${user.winRate.toStringAsFixed(0)}%',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ),
        Card(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildNotificationSetting(
    BuildContext context,
    WidgetRef ref,
    UserSettings settings,
  ) {
    return SwitchListTile(
      title: const Text('Enable Notifications'),
      subtitle: const Text('Receive game alerts and updates'),
      secondary: const Icon(Icons.notifications),
      value: settings.notificationsEnabled,
      onChanged: (value) {
        ref.read(settingsProvider.notifier).setNotificationsEnabled(value);
      },
    );
  }
}
