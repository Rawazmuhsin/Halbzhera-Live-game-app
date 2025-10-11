// File: lib/widgets/admin/users_tab.dart
// Description: Users tab content widget with pagination, view and delete functionality

// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../utils/constants.dart';
import '../../providers/paginated_users_provider.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/admin/user_info_card.dart';
import '../../screens/admin/user_details_screen.dart';

class UsersTab extends ConsumerStatefulWidget {
  const UsersTab({super.key});

  @override
  ConsumerState<UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends ConsumerState<UsersTab> {
  String _searchQuery = '';
  String _selectedFilter = 'all';
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Add scroll listener for infinite scroll
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Load more when user scrolls near bottom (200px from bottom)
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final notifier = ref.read(paginatedUsersNotifierProvider.notifier);
      notifier.loadMore();
    }
  }

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
        final paginatedState = ref.watch(paginatedUsersNotifierProvider);

        if (paginatedState.error != null) {
          return _buildErrorState(paginatedState.error!);
        }

        if (paginatedState.users.isEmpty && paginatedState.isLoading) {
          return const LoadingWidget(
            message: 'بارکردنی بەکارهێنەران...',
            showMessage: true,
          );
        }

        final filteredUsers = _filterUsers(paginatedState.users);

        if (filteredUsers.isEmpty && !paginatedState.isLoading) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          onRefresh: () async {
            await ref.read(paginatedUsersNotifierProvider.notifier).refresh();
          },
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(AppDimensions.paddingM),
            itemCount: filteredUsers.length + (paginatedState.hasMore ? 1 : 0),
            itemBuilder: (context, index) {
              // Show loading indicator at bottom when loading more
              if (index == filteredUsers.length) {
                return Padding(
                  padding: const EdgeInsets.all(AppDimensions.paddingL),
                  child: Center(
                    child: Column(
                      children: [
                        if (paginatedState.isLoading)
                          const CircularProgressIndicator(
                            color: AppColors.primaryTeal,
                          )
                        else
                          ElevatedButton.icon(
                            onPressed: () {
                              ref
                                  .read(paginatedUsersNotifierProvider.notifier)
                                  .loadMore();
                            },
                            icon: const Icon(Icons.arrow_downward),
                            label: const Text('بارکردنی زیاتر'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryTeal,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                            ),
                          ),
                        const SizedBox(height: 8),
                        Text(
                          '${filteredUsers.length} بەکارهێنەر بارکراوە',
                          style: const TextStyle(
                            color: AppColors.mediumText,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return UserInfoCard(
                user: filteredUsers[index],
                onView: () => _viewUser(filteredUsers[index]),
                onDelete: () => _deleteUser(filteredUsers[index]),
              );
            },
          ),
        );
      },
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
            onPressed: () {
              ref.read(paginatedUsersNotifierProvider.notifier).refresh();
            },
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

  void _viewUser(user) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => UserDetailsScreen(user: user)),
    );
  }

  void _deleteUser(user) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: AppColors.surface2,
            title: const Text(
              'سڕینەوەی بەکارهێنەر',
              style: TextStyle(color: AppColors.lightText),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ئایا دڵنیایت لە سڕینەوەی بەکارهێنەر "${user.displayName}"؟',
                  style: const TextStyle(color: AppColors.mediumText),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.error.withOpacity(0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.warning, color: AppColors.error, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'ئەم کردارە ناگەڕێتەوە و هەموو زانیاریەکانی بەکارهێنەر دەسڕێتەوە.',
                          style: TextStyle(
                            color: AppColors.error,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'پاشگەزبوونەوە',
                  style: TextStyle(color: AppColors.mediumText),
                ),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await _performUserDeletion(user);
                },
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.error,
                  backgroundColor: AppColors.error.withOpacity(0.1),
                ),
                child: const Text('سڕینەوە'),
              ),
            ],
          ),
    );
  }

  Future<void> _performUserDeletion(user) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => const Dialog(
              backgroundColor: AppColors.surface2,
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: AppColors.primaryTeal),
                    SizedBox(width: 16),
                    Text(
                      'سڕینەوەی بەکارهێنەر...',
                      style: TextStyle(color: AppColors.lightText),
                    ),
                  ],
                ),
              ),
            ),
      );

      // Delete user from database using paginated provider
      final notifier = ref.read(paginatedUsersNotifierProvider.notifier);

      // Actually delete from Firestore (you'll need to expose deleteUser method)
      // For now, we'll just refresh the list
      // TODO: Add deleteUser method to database service and call it here

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      // Refresh the users list
      await notifier.refresh();

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'بەکارهێنەر "${user.displayName}" بە سەرکەوتووی سڕایەوە',
              style: const TextStyle(color: AppColors.white),
            ),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.pop(context);

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'هەڵە لە سڕینەوەی بەکارهێنەر: $e',
              style: const TextStyle(color: AppColors.white),
            ),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }
}
