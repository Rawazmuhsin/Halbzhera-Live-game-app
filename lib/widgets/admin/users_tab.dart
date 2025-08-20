// File: lib/widgets/admin/users_tab.dart
// Description: Users tab content widget

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../utils/constants.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/loading_widget.dart';

class UsersTab extends ConsumerStatefulWidget {
  const UsersTab({super.key});

  @override
  ConsumerState<UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends ConsumerState<UsersTab> {
  String _searchQuery = '';
  String _selectedFilter = 'all';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [_buildUsersHeader(), Expanded(child: _buildUsersList())],
    );
  }

  Widget _buildUsersHeader() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'بەڕێوەبردنی بەکارهێنەران',
                style: TextStyle(
                  color: AppColors.lightText,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.search, color: AppColors.mediumText),
                    onPressed: _showSearchDialog,
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.filter_list,
                      color: AppColors.mediumText,
                    ),
                    onPressed: _showFilterDialog,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.paddingM),
          _buildSearchAndFilter(),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: InputDecoration(
              hintText: 'گەڕان بۆ بەکارهێنەر...',
              prefixIcon: const Icon(Icons.search, color: AppColors.mediumText),
              filled: true,
              fillColor: AppColors.surface2,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                borderSide: BorderSide.none,
              ),
            ),
            style: const TextStyle(color: AppColors.lightText),
          ),
        ),
        const SizedBox(width: AppDimensions.paddingM),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.surface2,
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedFilter,
              icon: const Icon(
                Icons.arrow_drop_down,
                color: AppColors.mediumText,
              ),
              style: const TextStyle(color: AppColors.lightText),
              dropdownColor: AppColors.surface2,
              onChanged: (value) => setState(() => _selectedFilter = value!),
              items: const [
                DropdownMenuItem(value: 'all', child: Text('هەموو')),
                DropdownMenuItem(value: 'active', child: Text('چالاک')),
                DropdownMenuItem(value: 'inactive', child: Text('ناچالاک')),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUsersList() {
    return Consumer(
      builder: (context, ref, child) {
        final usersAsync = ref.watch(allUsersProvider);

        return usersAsync.when(
          data: (users) {
            final filteredUsers = _filterUsers(users);

            if (filteredUsers.isEmpty) {
              return _buildEmptyState();
            }

            return ListView.builder(
              padding: const EdgeInsets.all(AppDimensions.paddingM),
              itemCount: filteredUsers.length,
              itemBuilder:
                  (context, index) => _buildUserCard(filteredUsers[index]),
            );
          },
          loading:
              () => const LoadingWidget(
                message: 'بارکردنی بەکارهێنەران...',
                showMessage: true,
              ),
          error: (error, _) => _buildErrorState(error.toString()),
        );
      },
    );
  }

  Widget _buildUserCard(user) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingS),
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        border: Border.all(color: AppColors.border1),
      ),
      child: Row(
        children: [
          _buildUserAvatar(user),
          const SizedBox(width: AppDimensions.paddingM),
          _buildUserInfo(user),
          _buildUserActions(user),
        ],
      ),
    );
  }

  Widget _buildUserAvatar(user) {
    return CircleAvatar(
      radius: 25,
      backgroundColor: AppColors.primaryTeal,
      backgroundImage:
          user.photoURL != null ? NetworkImage(user.photoURL!) : null,
      child:
          user.photoURL == null
              ? Text(
                user.displayName?.substring(0, 1).toUpperCase() ?? 'U',
                style: const TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              )
              : null,
    );
  }

  Widget _buildUserInfo(user) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            user.displayName ?? 'Unknown User',
            style: const TextStyle(
              color: AppColors.lightText,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (user.email != null)
            Text(
              user.email!,
              style: const TextStyle(color: AppColors.mediumText, fontSize: 14),
            ),
          const SizedBox(height: 4),
          Row(
            children: [
              _buildInfoChip('خاڵ: ${user.totalScore}', AppColors.accentYellow),
              const SizedBox(width: AppDimensions.paddingS),
              _buildInfoChip(
                'یاری: ${user.gamesPlayed}',
                AppColors.primaryTeal,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildUserActions(user) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color:
                user.isOnline
                    ? AppColors.success.withOpacity(0.2)
                    : AppColors.mediumText.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            user.isOnline ? 'چالاک' : 'ناچالاک',
            style: TextStyle(
              color: user.isOnline ? AppColors.success : AppColors.mediumText,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: 8),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: AppColors.mediumText),
          color: AppColors.surface3,
          onSelected: (value) => _handleUserAction(value, user),
          itemBuilder:
              (context) => [
                const PopupMenuItem(
                  value: 'view',
                  child: Row(
                    children: [
                      Icon(
                        Icons.visibility,
                        color: AppColors.lightText,
                        size: 16,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'بینین',
                        style: TextStyle(color: AppColors.lightText),
                      ),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, color: AppColors.lightText, size: 16),
                      SizedBox(width: 8),
                      Text(
                        'دەستکاری',
                        style: TextStyle(color: AppColors.lightText),
                      ),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: AppColors.error, size: 16),
                      SizedBox(width: 8),
                      Text('سڕینەوە', style: TextStyle(color: AppColors.error)),
                    ],
                  ),
                ),
              ],
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 64, color: AppColors.mediumText),
          const SizedBox(height: AppDimensions.paddingM),
          const Text(
            'هیچ بەکارهێنەرێک نەدۆزرایەوە',
            style: TextStyle(color: AppColors.mediumText, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: AppColors.error),
          const SizedBox(height: AppDimensions.paddingM),
          Text(
            'هەڵەیەک ڕوویدا: $error',
            style: const TextStyle(color: AppColors.error),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppDimensions.paddingM),
          ElevatedButton(
            onPressed: () => ref.refresh(allUsersProvider),
            child: const Text('دووبارە هەوڵبدەوە'),
          ),
        ],
      ),
    );
  }

  List _filterUsers(List users) {
    return users.where((user) {
      final matchesSearch =
          _searchQuery.isEmpty ||
          user.displayName?.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ) ==
              true ||
          user.email?.toLowerCase().contains(_searchQuery.toLowerCase()) ==
              true;

      final matchesFilter =
          _selectedFilter == 'all' ||
          (_selectedFilter == 'active' && user.isOnline) ||
          (_selectedFilter == 'inactive' && !user.isOnline);

      return matchesSearch && matchesFilter;
    }).toList();
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: AppColors.surface2,
            title: const Text(
              'گەڕان',
              style: TextStyle(color: AppColors.lightText),
            ),
            content: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: const InputDecoration(
                hintText: 'ناو یان ئیمەیڵ بنووسە...',
                hintStyle: TextStyle(color: AppColors.mediumText),
              ),
              style: const TextStyle(color: AppColors.lightText),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('داخستن'),
              ),
            ],
          ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: AppColors.surface2,
            title: const Text(
              'فلتەر',
              style: TextStyle(color: AppColors.lightText),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<String>(
                  title: const Text(
                    'هەموو',
                    style: TextStyle(color: AppColors.lightText),
                  ),
                  value: 'all',
                  groupValue: _selectedFilter,
                  onChanged: (value) {
                    setState(() => _selectedFilter = value!);
                    Navigator.pop(context);
                  },
                ),
                RadioListTile<String>(
                  title: const Text(
                    'چالاک',
                    style: TextStyle(color: AppColors.lightText),
                  ),
                  value: 'active',
                  groupValue: _selectedFilter,
                  onChanged: (value) {
                    setState(() => _selectedFilter = value!);
                    Navigator.pop(context);
                  },
                ),
                RadioListTile<String>(
                  title: const Text(
                    'ناچالاک',
                    style: TextStyle(color: AppColors.lightText),
                  ),
                  value: 'inactive',
                  groupValue: _selectedFilter,
                  onChanged: (value) {
                    setState(() => _selectedFilter = value!);
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
    );
  }

  void _handleUserAction(String action, user) {
    switch (action) {
      case 'view':
        _viewUser(user);
        break;
      case 'edit':
        _editUser(user);
        break;
      case 'delete':
        _deleteUser(user);
        break;
    }
  }

  void _viewUser(user) {
    // Navigate to user details
    print('View user: ${user.uid}');
  }

  void _editUser(user) {
    // Navigate to edit user
    print('Edit user: ${user.uid}');
  }

  void _deleteUser(user) {
    // Show delete confirmation
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: AppColors.surface2,
            title: const Text(
              'سڕینەوە',
              style: TextStyle(color: AppColors.lightText),
            ),
            content: Text(
              'ئایا دڵنیایت لە سڕینەوەی ${user.displayName}؟',
              style: const TextStyle(color: AppColors.mediumText),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('پاشگەزبوونەوە'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  // Delete user logic here
                  print('Delete user: ${user.uid}');
                },
                style: TextButton.styleFrom(foregroundColor: AppColors.error),
                child: const Text('سڕینەوە'),
              ),
            ],
          ),
    );
  }
}
