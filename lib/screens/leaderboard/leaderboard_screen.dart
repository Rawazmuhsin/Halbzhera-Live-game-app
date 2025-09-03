import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halbzhera/providers/database_provider.dart';
import 'package:halbzhera/services/database_service.dart';
import 'package:halbzhera/widgets/loading_widget.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LeaderboardScreen extends ConsumerStatefulWidget {
  final String? gameId;

  const LeaderboardScreen({
    Key? key,
    this.gameId, // If null, show global leaderboard
  }) : super(key: key);

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<List<Map<String, dynamic>>> _leaderboardFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.gameId != null ? 'بردەوەکانی ئەم یاریە' : 'خشتەی سەرکەوتووان',
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'براوەکان'), Tab(text: 'ئامارەکان')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildLeaderboardTab(), _buildStatsTab()],
      ),
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
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.emoji_events_outlined,
                    size: 80,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.gameId != null
                        ? 'هیچ براوەیەک نییە بۆ ئەم یارییە'
                        : 'هێشتا هیچ براوەیەک نییە',
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _loadLeaderboard();
                      });
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('تازەکردنەوە'),
                  ),
                ],
              ),
            );
          }

          final winners = snapshot.data!;
          return ListView.builder(
            itemCount: winners.length,
            itemBuilder: (context, index) {
              final winner = winners[index];

              // Get appropriate medal color for top 3
              Color? medalColor;
              IconData medalIcon;

              if (index == 0) {
                medalColor = Colors.amber;
                medalIcon = Icons.looks_one;
              } else if (index == 1) {
                medalColor = Colors.grey.shade400;
                medalIcon = Icons.looks_two;
              } else if (index == 2) {
                medalColor = Colors.brown.shade300;
                medalIcon = Icons.looks_3;
              } else {
                medalColor = null;
                medalIcon = Icons.emoji_events_outlined;
              }

              // Format timestamp if available
              String timeAgo = '';
              if (winner['completedAt'] != null || winner['lastWin'] != null) {
                final timestamp =
                    (winner['completedAt'] ?? winner['lastWin']) as Timestamp;
                final date = timestamp.toDate();
                timeAgo = DateFormat('yyyy-MM-dd HH:mm').format(date);
              }

              return Card(
                margin: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 4.0,
                ),
                elevation: index < 3 ? 8 : 2,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: medalColor,
                    child:
                        winner['photoUrl'] != null &&
                                winner['photoUrl'].toString().isNotEmpty
                            ? ClipOval(
                              child: CachedNetworkImage(
                                imageUrl: winner['photoUrl'],
                                placeholder:
                                    (context, url) =>
                                        const CircularProgressIndicator(),
                                errorWidget:
                                    (context, url, error) => Icon(
                                      Icons.person,
                                      color:
                                          medalColor != null
                                              ? Colors.white
                                              : null,
                                    ),
                                fit: BoxFit.cover,
                                width: 40,
                                height: 40,
                              ),
                            )
                            : Icon(medalIcon, color: Colors.white),
                  ),
                  title: Text(
                    winner['displayName'] ?? 'Unknown',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.gameId == null && winner['gamesWon'] != null)
                        Text('تەواوبوو: ${winner['gamesWon']} یاری'),
                      if (winner['score'] != null)
                        Text('خاڵ: ${winner['score']}'),
                      if (timeAgo.isNotEmpty) Text(timeAgo),
                    ],
                  ),
                  trailing: CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildStatsTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _leaderboardFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingWidget();
        } else if (snapshot.hasError ||
            !snapshot.hasData ||
            snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.bar_chart, size: 80, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  snapshot.hasError
                      ? 'هەڵەیەک ڕوویدا: ${snapshot.error}'
                      : 'داتا بەردەست نییە بۆ پیشاندانی ئامار',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final winners = snapshot.data!;

        // Calculate statistics
        int totalParticipants = winners.length;
        int totalGamesWon = 0;
        int totalPoints = 0;

        for (final winner in winners) {
          totalGamesWon += (winner['gamesWon'] as int?) ?? 1;
          totalPoints +=
              (winner['totalScore'] as int?) ?? (winner['score'] as int?) ?? 0;
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildStatCard(
                'بەشداربووان',
                totalParticipants.toString(),
                Icons.people,
                Colors.blue,
              ),
              _buildStatCard(
                'کۆی یاری تەواوکراو',
                totalGamesWon.toString(),
                Icons.emoji_events,
                Colors.amber,
              ),
              _buildStatCard(
                'کۆی خاڵ',
                totalPoints.toString(),
                Icons.score,
                Colors.green,
              ),
              const SizedBox(height: 20),
              if (winners.isNotEmpty) ...[
                const Text(
                  'براوەی یەکەم',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                _buildTopPlayerCard(winners.first),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 25,
              backgroundColor: color.withOpacity(0.2),
              child: Icon(icon, color: color, size: 30),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopPlayerCard(Map<String, dynamic> winner) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.amber,
              child:
                  winner['photoUrl'] != null &&
                          winner['photoUrl'].toString().isNotEmpty
                      ? ClipOval(
                        child: CachedNetworkImage(
                          imageUrl: winner['photoUrl'],
                          placeholder:
                              (context, url) =>
                                  const CircularProgressIndicator(),
                          errorWidget:
                              (context, url, error) => const Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 50,
                              ),
                          fit: BoxFit.cover,
                          width: 90,
                          height: 90,
                        ),
                      )
                      : const Icon(
                        Icons.emoji_events,
                        color: Colors.white,
                        size: 50,
                      ),
            ),
            const SizedBox(height: 16),
            Text(
              winner['displayName'] ?? 'Unknown',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              widget.gameId == null && winner['gamesWon'] != null
                  ? '${winner['gamesWon']} یاری براوە | ${winner['totalScore']} خاڵ'
                  : '${winner['score']} خاڵ',
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
