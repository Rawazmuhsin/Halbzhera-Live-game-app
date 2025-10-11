// File: lib/providers/paginated_users_provider.dart
// Description: Paginated users provider for admin with load more functionality

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../services/database_service.dart';
import 'auth_provider.dart';

/// State for paginated users
class PaginatedUsersState {
  final List<UserModel> users;
  final bool hasMore;
  final bool isLoading;
  final DocumentSnapshot? lastDocument;
  final String? error;

  const PaginatedUsersState({
    this.users = const [],
    this.hasMore = true,
    this.isLoading = false,
    this.lastDocument,
    this.error,
  });

  PaginatedUsersState copyWith({
    List<UserModel>? users,
    bool? hasMore,
    bool? isLoading,
    DocumentSnapshot? lastDocument,
    String? error,
  }) {
    return PaginatedUsersState(
      users: users ?? this.users,
      hasMore: hasMore ?? this.hasMore,
      isLoading: isLoading ?? this.isLoading,
      lastDocument: lastDocument ?? this.lastDocument,
      error: error,
    );
  }
}

/// Paginated users notifier for admin
class PaginatedUsersNotifier extends StateNotifier<PaginatedUsersState> {
  final DatabaseService _databaseService;
  static const int _pageSize = 20; // Load 20 users at a time

  PaginatedUsersNotifier(this._databaseService)
    : super(const PaginatedUsersState()) {
    // Load initial page on creation
    loadMore();
  }

  /// Load more users (pagination)
  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      Query query = FirebaseFirestore.instance
          .collection('users')
          .orderBy('createdAt', descending: true)
          .limit(_pageSize);

      // If we have a last document, start after it
      if (state.lastDocument != null) {
        query = query.startAfterDocument(state.lastDocument!);
      }

      final snapshot = await query.get();

      if (snapshot.docs.isEmpty) {
        // No more users to load
        state = state.copyWith(isLoading: false, hasMore: false);
        return;
      }

      // Convert documents to UserModel
      final newUsers =
          snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();

      // Append new users to existing list
      final updatedUsers = [...state.users, ...newUsers];

      state = state.copyWith(
        users: updatedUsers,
        isLoading: false,
        hasMore: snapshot.docs.length == _pageSize, // More if we got full page
        lastDocument: snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load users: $e',
      );
    }
  }

  /// Refresh users list (clear and reload from start)
  Future<void> refresh() async {
    state = const PaginatedUsersState(); // Reset state
    await loadMore();
  }

  /// Search users by name or email
  Future<void> search(String query) async {
    if (query.isEmpty) {
      // If search is cleared, refresh to original list
      await refresh();
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      // Firestore doesn't support full-text search, so we'll do client-side filtering
      // For production, consider using Algolia or similar service
      final allUsers = await _databaseService.getAllUsers(limit: 100);

      final filteredUsers =
          allUsers.where((user) {
            final searchLower = query.toLowerCase();
            final nameLower = user.displayName?.toLowerCase() ?? '';
            final emailLower = user.email?.toLowerCase() ?? '';

            return nameLower.contains(searchLower) ||
                emailLower.contains(searchLower);
          }).toList();

      state = state.copyWith(
        users: filteredUsers,
        isLoading: false,
        hasMore: false, // No pagination for search results
        lastDocument: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to search users: $e',
      );
    }
  }
}

/// Provider for paginated users
final paginatedUsersNotifierProvider =
    StateNotifierProvider<PaginatedUsersNotifier, PaginatedUsersState>((ref) {
      final databaseService = ref.read(databaseServiceProvider);
      return PaginatedUsersNotifier(databaseService);
    });
