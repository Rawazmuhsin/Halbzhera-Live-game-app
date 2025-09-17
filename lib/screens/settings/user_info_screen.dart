// File: lib/screens/settings/user_info_screen.dart
// Description: User details screen with all user information

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/user_model.dart';
import '../../utils/formatters.dart';

class UserInfoScreen extends ConsumerWidget {
  final UserModel user;

  const UserInfoScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('User Information'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User profile header
            _buildProfileHeader(context),

            const SizedBox(height: 24),

            // Account information
            _buildInfoSection(context, 'Account Information', [
              _buildInfoRow('User ID', user.uid),
              _buildInfoRow('Display Name', user.displayName ?? 'Not set'),
              _buildInfoRow('Email', user.email ?? 'Not provided'),
              _buildInfoRow(
                'Sign in Provider',
                _getProviderName(user.provider),
              ),
              _buildInfoRow('Created', _formatDate(user.createdAt)),
              _buildInfoRow('Last Seen', _formatDate(user.lastSeen)),
            ]),

            const SizedBox(height: 16),

            // Game statistics
            _buildInfoSection(context, 'Game Statistics', [
              _buildInfoRow('Total Score', user.totalScore.toString()),
              _buildInfoRow('Games Played', user.gamesPlayed.toString()),
              _buildInfoRow('Games Won', user.gamesWon.toString()),
              _buildInfoRow('Win Rate', '${user.winRate.toStringAsFixed(1)}%'),
              _buildInfoRow(
                'Average Score',
                user.averageScore.toStringAsFixed(1),
              ),
            ]),

            const SizedBox(height: 16),

            // User preferences
            _buildInfoSection(context, 'User Preferences', [
              ..._buildPreferencesList(user.preferences),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    return Center(
      child: Column(
        children: [
          // User avatar
          CircleAvatar(
            radius: 50,
            backgroundImage:
                user.photoURL != null ? NetworkImage(user.photoURL!) : null,
            child:
                user.photoURL == null
                    ? Text(
                      user.displayName?.substring(0, 1).toUpperCase() ?? 'U',
                      style: const TextStyle(fontSize: 40),
                    )
                    : null,
          ),

          const SizedBox(height: 16),

          // User name
          Text(
            user.displayName ?? 'User',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),

          if (user.email != null && user.email!.isNotEmpty)
            Text(
              user.email!,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),

          // Online status indicator
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: user.isOnline ? Colors.green[100] : Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: user.isOnline ? Colors.green : Colors.grey,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  user.isOnline ? 'Online' : 'Offline',
                  style: TextStyle(
                    color: user.isOnline ? Colors.green[700] : Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(
    BuildContext context,
    String title,
    List<Widget> children,
  ) {
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
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(children: children),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  List<Widget> _buildPreferencesList(Map<String, dynamic> preferences) {
    if (preferences.isEmpty) {
      return [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(child: Text('No preferences set')),
        ),
      ];
    }

    return preferences.entries
        .map(
          (e) => _buildInfoRow(
            _formatPreferenceKey(e.key),
            _formatPreferenceValue(e.value),
          ),
        )
        .toList();
  }

  String _formatPreferenceKey(String key) {
    // Convert camelCase or snake_case to Title Case
    String result = key.replaceAll('_', ' ');
    // Insert space before capital letters
    result = result.replaceAllMapped(
      RegExp(r'([a-z])([A-Z])'),
      (match) => '${match.group(1)} ${match.group(2)}',
    );
    // Capitalize first letter of each word
    result = result
        .split(' ')
        .map((word) {
          if (word.isEmpty) return word;
          return word[0].toUpperCase() + word.substring(1);
        })
        .join(' ');

    return result;
  }

  String _formatPreferenceValue(dynamic value) {
    if (value == null) return 'Not set';
    if (value is bool) return value ? 'Enabled' : 'Disabled';
    if (value is int && _isThemeModeIndex(value)) {
      switch (value) {
        case 0:
          return 'System Default';
        case 1:
          return 'Light';
        case 2:
          return 'Dark';
        default:
          return 'Unknown';
      }
    }
    return value.toString();
  }

  bool _isThemeModeIndex(int value) {
    return value >= 0 && value <= 2 && (value == 0 || value == 1 || value == 2);
  }

  String _getProviderName(LoginProvider provider) {
    switch (provider) {
      case LoginProvider.google:
        return 'Google';
      case LoginProvider.facebook:
        return 'Facebook';
      case LoginProvider.anonymous:
        return 'Anonymous';
    }
  }

  String _formatDate(DateTime date) {
    try {
      // Try to use the formatters.dart utility
      return formatDateTime(date);
    } catch (e) {
      // Fallback to simple format
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    }
  }
}
