// ignore_for_file: deprecated_member_use, avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halbzhera/models/game_result_model.dart';
import 'package:halbzhera/services/game_result_service.dart';
import 'package:halbzhera/providers/database_provider.dart';

class ResultsScreen extends ConsumerStatefulWidget {
  final String gameId;

  const ResultsScreen({super.key, required this.gameId});

  @override
  _ResultsScreenState createState() => _ResultsScreenState();
}

class _ResultsScreenState extends ConsumerState<ResultsScreen> {
  bool _isLoading = true;
  List<GameResultModel> _results = [];

  @override
  void initState() {
    super.initState();
    // Initial load with non-stream method as a backup
    _loadGameResults();
  }

  Future<void> _loadGameResults() async {
    setState(() => _isLoading = true);
    try {
      final results = await ref
          .read(databaseServiceProvider)
          .getGameResults(gameId: widget.gameId);
      setState(() {
        _results = results;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading game results: $e');
      // Show error to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('هەڵە ڕوویدا لە بارکردنی ئەنجامەکان: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ئەنجامی یاری'),
        backgroundColor: const Color(0xFF1A1F36),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'نوێکردنەوە',
            onPressed: () {
              setState(() {
                _isLoading = true;
              });
              _loadGameResults();
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0B1120), Color(0xFF1A1F36), Color(0xFF2A1B3D)],
          ),
        ),
        child: StreamBuilder<List<GameResultModel>>(
          // Use the stream for live updates
          stream: ref
              .read(databaseServiceProvider)
              .getGameWinnersStream(widget.gameId),
          builder: (context, snapshot) {
            // Show the fallback results if we're still loading the stream
            if (_isLoading && !snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFF2DCCDB)),
              );
            }

            // If stream has data, use it
            if (snapshot.hasData && snapshot.data!.isNotEmpty) {
              return _buildResultsList(snapshot.data!);
            }

            // If stream is done but empty, and we have fallback data
            if (snapshot.connectionState == ConnectionState.active &&
                _results.isNotEmpty) {
              return _buildResultsList(_results);
            }

            // If stream has error, show it
            if (snapshot.hasError) {
              print('Error in winners stream: ${snapshot.error}');
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                    const SizedBox(height: 16),
                    Text(
                      'هەڵەیەک ڕوویدا لە بارکردنی براوەکان',
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    // If we have fallback results, offer to show them
                    if (_results.isNotEmpty)
                      TextButton(
                        onPressed: () {
                          setState(() {
                            // Force using the fallback results
                            _isLoading = false;
                          });
                        },
                        child: const Text('پیشاندانی داتای پاشەکەوت'),
                      ),
                  ],
                ),
              );
            }

            // Default case - no data yet, or stream is empty
            return _buildResultsList(_results);
          },
        ),
      ),
    );
  }

  Widget _buildResultsList([List<GameResultModel>? results]) {
    // Use provided results or fallback to the instance variable
    final displayResults = results ?? _results;

    // Since we're pulling from the winners collection, all results are winners
    if (displayResults.isEmpty) {
      return const Center(
        child: Text(
          'هیچ براوەیەک نەدۆزرایەوە!',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
      );
    }

    return Column(
      children: [
        // Header with trophy
        Container(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            children: [
              const Icon(
                Icons.emoji_events,
                color: Color(0xFFFFD700),
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                'براوەکان (${displayResults.length})',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),

        // Winners list
        Expanded(
          child: ListView.builder(
            itemCount: displayResults.length,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemBuilder: (context, index) {
              final result = displayResults[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                color: const Color(0xFF1A1F36).withOpacity(0.7),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.white.withOpacity(0.1)),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF2DCCDB),
                    backgroundImage:
                        result.userPhotoUrl != null &&
                                result.userPhotoUrl!.isNotEmpty
                            ? NetworkImage(result.userPhotoUrl!)
                            : null,
                    child:
                        (result.userPhotoUrl == null ||
                                result.userPhotoUrl!.isEmpty)
                            ? Text(
                              result.userDisplayName != null &&
                                      result.userDisplayName!.isNotEmpty
                                  ? result.userDisplayName![0].toUpperCase()
                                  : '${index + 1}',
                              style: const TextStyle(color: Colors.white),
                            )
                            : null,
                  ),
                  title: Text(
                    result.userDisplayName != null &&
                            result.userDisplayName!.isNotEmpty
                        ? result.userDisplayName!
                        : 'بەکارهێنەر: ${result.userId.substring(0, 6)}...',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'خاڵ: ${result.score}',
                        style: TextStyle(color: Colors.white.withOpacity(0.7)),
                      ),
                      if (result.userEmail != null &&
                          result.userEmail!.isNotEmpty)
                        Text(
                          result.userEmail!,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                  trailing: const Icon(Icons.star, color: Color(0xFFFFD700)),
                  isThreeLine:
                      result.userEmail != null && result.userEmail!.isNotEmpty,
                ),
              );
            },
          ),
        ),

        // Navigation buttons
        Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Leaderboard button
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pushNamed(
                    '/game-leaderboard',
                    arguments: {'gameId': widget.gameId},
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFC107),
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 32,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.emoji_events),
                label: const Text(
                  'پیشاندانی پێشەنگەکانی یاری',
                  style: TextStyle(fontSize: 16),
                ),
              ),

              const SizedBox(height: 16),

              // Back to games button
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2DCCDB),
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 32,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'گەڕانەوە بۆ یارییەکان',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
