// ignore_for_file: deprecated_member_use, avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halbzhera/providers/database_provider.dart';
import 'package:halbzhera/widgets/loading_widget.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:halbzhera/widgets/common/theme_aware_gradient_background.dart';
import 'package:halbzhera/utils/app_theme.dart';

class LeaderboardScreen extends ConsumerStatefulWidget {
  final String? gameId;

  const LeaderboardScreen({
    super.key,
    this.gameId, // If null, show global leaderboard
  });

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> {
  late Future<List<Map<String, dynamic>>> _leaderboardFuture;

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
  }

  void _loadLeaderboard() {
    final databaseService = ref.read(databaseServiceProvider);

    if (widget.gameId != null) {
      // Load game-specific leaderboard
      _leaderboardFuture = databaseService.getGameTopWinners(
        gameId: widget.gameId!,
        limit: 50,
      );
    } else {
      // Load global leaderboard
      _leaderboardFuture = databaseService.getTopWinners(limit: 50);
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          widget.gameId != null ? 'پێشەنگەکانی ئەم یاریە' : 'پێشەنگەکان',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: theme.colorScheme.onSurface,
            shadows: [
              Shadow(
                offset: const Offset(1.0, 1.0),
                blurRadius: 3.0,
                color: Colors.black.withOpacity(0.5),
              ),
            ],
          ),
        ),
      ),
      body: ThemeAwareGradientBackground(child: _buildLeaderboardTab()),
    );
  }

  Widget _buildLeaderboardTab() {
    return RefreshIndicator(
      onRefresh: () async {
        setState(() {
          _loadLeaderboard();
        });
      },
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _leaderboardFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingWidget();
          } else if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  'هەڵەیەک ڕوویدا: ${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            print('No leaderboard data available');
            final theme = Theme.of(context);
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Trophy icon with animation
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0.8, end: 1.0),
                    duration: const Duration(seconds: 2),
                    curve: Curves.elasticOut,
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: value,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.tertiary.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Icon(
                              Icons.emoji_events_outlined,
                              size: 80,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // Empty state message
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: theme.colorScheme.outline.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      widget.gameId != null
                          ? 'هیچ پێشەنگێک نییە بۆ ئەم یارییە'
                          : 'هێشتا هیچ پێشەنگێک نییە',
                      style: TextStyle(
                        fontSize: 18,
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Refresh button with animation
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOutBack,
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: value,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              _loadLeaderboard();
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            foregroundColor: theme.colorScheme.onTertiary,
                            backgroundColor: theme.colorScheme.tertiary,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 4,
                            shadowColor: theme.colorScheme.shadow,
                          ),
                          icon: const Icon(Icons.refresh),
                          label: const Text(
                            'تازەکردنەوە',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          }

          final winners = snapshot.data!;
          // Debug log the data
          print('Leaderboard data: ${winners.length} entries');
          if (winners.isNotEmpty) {
            print('First entry: ${winners.first}');
          }

          final theme = Theme.of(context);

          return CustomScrollView(
            slivers: [
              // Section for the top 3 players (podium style)
              SliverToBoxAdapter(
                child:
                    winners.length >= 3
                        ? _buildTopPodium(winners.sublist(0, 3))
                        : winners.isNotEmpty
                        ? _buildTopPodium(
                          winners.sublist(
                            0,
                            winners.length < 3 ? winners.length : 3,
                          ),
                        )
                        : const SizedBox.shrink(),
              ),

              // Add extra spacing between top podium and list
              SliverToBoxAdapter(
                child: SizedBox(height: 20), // Extra spacing
              ),

              // Title for the list section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 30, 20, 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 15,
                    ),
                    decoration: BoxDecoration(
                      gradient: AppTheme.getPrimaryGradient(),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: theme.shadowColor.withOpacity(0.2),
                          offset: const Offset(0, 3),
                          blurRadius: 5,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.format_list_numbered,
                          color: theme.colorScheme.onPrimary,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'لیستی پێشەنگەکان',
                          style: TextStyle(
                            color: theme.colorScheme.onPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // List of all players
              SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final player = winners[index];
                  return _buildPlayerListItem(player, index);
                }, childCount: winners.length),
              ),

              // Bottom spacing
              const SliverToBoxAdapter(child: SizedBox(height: 30)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTopPodium(List<Map<String, dynamic>> topPlayers) {
    // Make sure we have at least one player
    if (topPlayers.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.only(
        top: 20,
        bottom: 20,
      ), // Increased bottom padding
      child: Column(
        children: [
          // Podium title
          Container(
            margin: const EdgeInsets.only(bottom: 30), // Increased margin to 30
            child: Text(
              "🏆 پێشەنگەکان 🏆",
              style: TextStyle(
                fontSize: 22, // Slightly reduced font size
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
                shadows: [
                  Shadow(
                    offset: const Offset(1.0, 1.0),
                    blurRadius: 3.0,
                    color: theme.shadowColor.withOpacity(0.3),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 40),

          // Podium display
          SizedBox(
            height: 320, // Increased height to accommodate the content
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                // Podium platforms
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 2nd Place (left)
                    if (topPlayers.length >= 2)
                      _buildPodiumStand(
                        topPlayers[1],
                        height: 150, // Reduced height
                        color: const Color(0xFFC0C0C0),
                        position: 2,
                        width: 100,
                      ),

                    const SizedBox(width: 8),

                    // 1st Place (center)
                    if (topPlayers.isNotEmpty)
                      _buildPodiumStand(
                        topPlayers[0],
                        height: 180, // Reduced height
                        color: const Color(0xFFFFD700),
                        position: 1,
                        width: 120,
                        showCrown: true,
                      ),

                    const SizedBox(width: 8),

                    // 3rd Place (right)
                    if (topPlayers.length >= 3)
                      _buildPodiumStand(
                        topPlayers[2],
                        height: 120, // Reduced height
                        color: const Color(0xFFCD7F32),
                        position: 3,
                        width: 100,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPodiumStand(
    Map<String, dynamic> player, {
    required double height,
    required Color color,
    required int position,
    required double width,
    bool showCrown = false,
  }) {
    final theme = Theme.of(context);

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      mainAxisSize: MainAxisSize.min, // Use min size to prevent overflow
      children: [
        // Player avatar with optional crown
        Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // Player avatar
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.5),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: position == 1 ? 36 : 28, // Slightly reduced radius
                backgroundColor: color,
                child:
                    player['photoUrl'] != null &&
                            player['photoUrl'].toString().isNotEmpty
                        ? ClipOval(
                          child: CachedNetworkImage(
                            imageUrl: player['photoUrl'],
                            placeholder:
                                (context, url) => CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: theme.colorScheme.onPrimary,
                                ),
                            errorWidget:
                                (context, url, error) => Icon(
                                  Icons.person,
                                  color: theme.colorScheme.onPrimary,
                                  size: position == 1 ? 36 : 28,
                                ),
                            fit: BoxFit.cover,
                            width: position == 1 ? 72 : 56,
                            height: position == 1 ? 72 : 56,
                          ),
                        )
                        : Icon(
                          Icons.person,
                          color: theme.colorScheme.onPrimary,
                          size: position == 1 ? 36 : 28,
                        ),
              ),
            ),

            // Crown for 1st place
            if (showCrown)
              Positioned(
                top: -20, // Reduced distance
                child: Icon(
                  Icons.workspace_premium,
                  color: theme.colorScheme.tertiary,
                  size: 30, // Reduced size
                  shadows: [
                    Shadow(
                      offset: const Offset(1, 1),
                      blurRadius: 3,
                      color: theme.shadowColor.withOpacity(0.3),
                    ),
                  ],
                ),
              ),

            // Position badge
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 22, // Slightly reduced size
                height: 22, // Slightly reduced size
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                  border: Border.all(
                    color: theme.colorScheme.surface,
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: theme.shadowColor.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    position.toString(),
                    style: TextStyle(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12, // Reduced font size
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),

        // Player name
        Container(
          margin: const EdgeInsets.only(top: 6, bottom: 3), // Reduced margins
          width: width,
          child: Text(
            player['displayName'] ?? 'Unknown',
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.bold,
              fontSize: position == 1 ? 14 : 12, // Reduced font size
            ),
          ),
        ),

        // Score
        Container(
          margin: const EdgeInsets.only(bottom: 6), // Reduced margin
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 2,
          ), // Reduced padding
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(0.5), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.star,
                color: theme.colorScheme.tertiary,
                size: 12, // Reduced size
              ),
              const SizedBox(width: 2), // Reduced spacing
              Text(
                '${player['score'] ?? 0}',
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: 12, // Reduced font size
                ),
              ),
            ],
          ),
        ),

        // Podium stand
        Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [color, color.withOpacity(0.7)],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
            boxShadow: [
              BoxShadow(
                color: theme.shadowColor.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Center(
            child:
                position == 1
                    ? Text(
                      "١",
                      style: TextStyle(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 44, // Reduced font size
                      ),
                    )
                    : position == 2
                    ? Text(
                      "٢",
                      style: TextStyle(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 36, // Reduced font size
                      ),
                    )
                    : Text(
                      "٣",
                      style: TextStyle(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 36, // Reduced font size
                      ),
                    ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlayerListItem(Map<String, dynamic> player, int index) {
    // Skip the top 3 players as they are already shown in the podium
    if (index < 3) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.2),
            offset: const Offset(0, 2),
            blurRadius: 4,
          ),
        ],
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          children: [
            // Rank number
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.7),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: theme.shadowColor.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),

            const SizedBox(width: 12),

            // Player avatar
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: theme.shadowColor.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 20,
                backgroundColor: theme.colorScheme.secondary.withOpacity(0.5),
                child:
                    player['photoUrl'] != null &&
                            player['photoUrl'].toString().isNotEmpty
                        ? ClipOval(
                          child: CachedNetworkImage(
                            imageUrl: player['photoUrl'],
                            placeholder:
                                (context, url) => CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: theme.colorScheme.onSecondary,
                                ),
                            errorWidget:
                                (context, url, error) => Icon(
                                  Icons.person,
                                  color: theme.colorScheme.onSecondary,
                                  size: 20,
                                ),
                            fit: BoxFit.cover,
                            width: 40,
                            height: 40,
                          ),
                        )
                        : Icon(
                          Icons.person,
                          color: theme.colorScheme.onSecondary,
                          size: 20,
                        ),
              ),
            ),

            const SizedBox(width: 16),

            // Player name and stats
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    player['displayName'] ?? 'Unknown',
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (widget.gameId == null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          Icon(
                            Icons.emoji_events_outlined,
                            color: theme.colorScheme.tertiary,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${player['gamesWon'] ?? 0} یاری براوە',
                            style: TextStyle(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            // Score
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                gradient: AppTheme.getPrimaryGradient(),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star, color: theme.colorScheme.tertiary, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '${player['score'] ?? 0}',
                    style: TextStyle(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
