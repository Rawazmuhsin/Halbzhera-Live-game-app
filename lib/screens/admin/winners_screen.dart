import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halbzhera/models/game_result_model.dart';
import 'package:halbzhera/providers/database_provider.dart';
import 'package:halbzhera/services/game_result_service.dart';
import 'package:halbzhera/screens/admin/manage_winners_screen.dart';
import 'package:intl/intl.dart';

class AdminWinnersScreen extends ConsumerStatefulWidget {
  const AdminWinnersScreen({super.key});

  @override
  _AdminWinnersScreenState createState() => _AdminWinnersScreenState();
}

class _AdminWinnersScreenState extends ConsumerState<AdminWinnersScreen> {
  List<GameResultModel> _allWinners = [];
  List<GameResultModel> _filteredWinners = [];
  bool _isLoading = true;
  String _searchQuery = '';
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _loadAllWinners();
  }

  Future<void> _loadAllWinners() async {
    setState(() => _isLoading = true);
    try {
      // Get all winners from all games
      print('Admin screen: Loading all winners');
      final winners =
          await ref.read(databaseServiceProvider).getAllGameWinners();
      print('Admin screen: Received ${winners.length} winners');

      // Log some details about the winners for debugging
      for (int i = 0; i < winners.length && i < 5; i++) {
        final winner = winners[i];
        print(
          'Admin screen winner #$i: ${winner.userDisplayName} (${winner.userId}) - Game: ${winner.gameId}',
        );
      }

      setState(() {
        _allWinners = winners;
        _filteredWinners = winners;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading winners: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('هەڵە ڕوویدا لە بارکردنی براوەکان: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
      setState(() => _isLoading = false);
    }
  }

  void _filterWinners() {
    List<GameResultModel> filtered = _allWinners;

    // Filter by search query (user name)
    if (_searchQuery.isNotEmpty) {
      filtered =
          filtered.where((winner) {
            final displayName = winner.userDisplayName?.toLowerCase() ?? '';
            final userId = winner.userId.toLowerCase();
            final email = winner.userEmail?.toLowerCase() ?? '';
            return displayName.contains(_searchQuery.toLowerCase()) ||
                userId.contains(_searchQuery.toLowerCase()) ||
                email.contains(_searchQuery.toLowerCase());
          }).toList();
    }

    // Filter by date range
    if (_startDate != null) {
      filtered =
          filtered.where((winner) {
            final completedAt = winner.completedAt;
            return completedAt != null && completedAt.isAfter(_startDate!);
          }).toList();
    }

    if (_endDate != null) {
      final endOfDay = DateTime(
        _endDate!.year,
        _endDate!.month,
        _endDate!.day,
        23,
        59,
        59,
      );
      filtered =
          filtered.where((winner) {
            final completedAt = winner.completedAt;
            return completedAt != null && completedAt.isBefore(endOfDay);
          }).toList();
    }

    setState(() {
      _filteredWinners = filtered;
    });
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange:
          _startDate != null && _endDate != null
              ? DateTimeRange(start: _startDate!, end: _endDate!)
              : null,
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _filterWinners();
    }
  }

  void _clearFilters() {
    setState(() {
      _searchQuery = '';
      _startDate = null;
      _endDate = null;
      _filteredWinners = _allWinners;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('براوەکان'),
        backgroundColor: const Color(0xFF1A1F36),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAllWinners,
            tooltip: 'نوێکردنەوە',
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterBottomSheet(context),
            tooltip: 'فلتەرکردن',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _navigateToManageWinnersScreen(context),
            tooltip: 'بەڕێوەبردن',
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
        child:
            _isLoading
                ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFF2DCCDB)),
                )
                : _buildWinnersList(),
      ),
    );
  }

  Widget _buildWinnersList() {
    if (_filteredWinners.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.emoji_events_outlined,
              color: Colors.white54,
              size: 64,
            ),
            const SizedBox(height: 16),
            const Text(
              'هیچ براوەیەک نەدۆزرایەوە',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            // Show debug info
            Text(
              'داتاکان کۆ کراونەتەوە: ${_allWinners.length}',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('هەوڵدانەوە'),
              onPressed: _loadAllWinners,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2DCCDB),
              ),
            ),
            const SizedBox(height: 16),
            if (_searchQuery.isNotEmpty ||
                _startDate != null ||
                _endDate != null)
              TextButton.icon(
                icon: const Icon(Icons.clear),
                label: const Text('پاککردنەوەی فلتەرەکان'),
                onPressed: _clearFilters,
              ),
          ],
        ),
      );
    }

    // Display date range if filtered
    Widget? dateFilterChip;
    if (_startDate != null && _endDate != null) {
      final formatter = DateFormat('yyyy/MM/dd');
      dateFilterChip = Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Chip(
          backgroundColor: const Color(0xFF2DCCDB).withOpacity(0.2),
          label: Text(
            '${formatter.format(_startDate!)} - ${formatter.format(_endDate!)}',
            style: const TextStyle(color: Colors.white),
          ),
          deleteIcon: const Icon(Icons.close, size: 18, color: Colors.white),
          onDeleted: () {
            setState(() {
              _startDate = null;
              _endDate = null;
            });
            _filterWinners();
          },
        ),
      );
    }

    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'گەڕان بە ناوی بەکارهێنەر یان ئیمەیل...',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
              prefixIcon: const Icon(Icons.search, color: Colors.white),
              filled: true,
              fillColor: Colors.white.withOpacity(0.1),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF2DCCDB)),
              ),
              suffixIcon:
                  _searchQuery.isNotEmpty
                      ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white),
                        onPressed: () {
                          setState(() => _searchQuery = '');
                          _filterWinners();
                        },
                      )
                      : null,
            ),
            onChanged: (value) {
              setState(() => _searchQuery = value);
              _filterWinners();
            },
          ),
        ),

        // Date filter chip
        if (dateFilterChip != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Text(
                  'فلتەری بەروار:',
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(width: 8),
                dateFilterChip,
              ],
            ),
          ),

        // Winners count
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text(
                '${_filteredWinners.length} براوە',
                style: TextStyle(color: Colors.white.withOpacity(0.7)),
              ),
              const Spacer(),
              if (_filteredWinners.length != _allWinners.length)
                TextButton.icon(
                  icon: const Icon(Icons.clear, size: 16),
                  label: const Text('پاککردنەوەی فلتەرەکان'),
                  onPressed: _clearFilters,
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF2DCCDB),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
            ],
          ),
        ),

        // Winners list
        Expanded(
          child: ListView.builder(
            itemCount: _filteredWinners.length,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemBuilder: (context, index) {
              final winner = _filteredWinners[index];
              final completedDate =
                  winner.completedAt != null
                      ? DateFormat(
                        'yyyy/MM/dd - HH:mm',
                      ).format(winner.completedAt!)
                      : 'N/A';

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                color: const Color(0xFF1A1F36).withOpacity(0.7),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.white.withOpacity(0.1)),
                ),
                child: InkWell(
                  onTap: () => _showWinnerDetails(winner),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // User info row
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: const Color(0xFF2DCCDB),
                              backgroundImage:
                                  winner.userPhotoUrl != null
                                      ? NetworkImage(winner.userPhotoUrl!)
                                      : null,
                              child:
                                  winner.userPhotoUrl == null
                                      ? Text(
                                        winner.userDisplayName != null &&
                                                winner
                                                    .userDisplayName!
                                                    .isNotEmpty
                                            ? winner.userDisplayName![0]
                                                .toUpperCase()
                                            : '?',
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                      )
                                      : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    winner.userDisplayName ??
                                        'بەکارهێنەری نەناسراو',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    winner.userEmail ?? winner.userId,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.emoji_events,
                              color: Color(0xFFFFD700),
                              size: 24,
                            ),
                          ],
                        ),

                        const Divider(color: Colors.white24, height: 24),

                        // Game info
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'خاڵ: ${winner.score}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              completedDate,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'یاری: ${winner.gameId}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon(
                              icon: const Icon(Icons.info_outline, size: 16),
                              label: const Text('وردەکاری'),
                              onPressed: () => _showWinnerDetails(winner),
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFF2DCCDB),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1F36),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => StatefulBuilder(
            builder: (context, setModalState) {
              return Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'فلتەرکردنی براوەکان',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'بەرواری براوەکان',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () async {
                        Navigator.of(context).pop();
                        await _selectDateRange(context);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white24),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.date_range,
                              color: Color(0xFF2DCCDB),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              _startDate != null && _endDate != null
                                  ? '${DateFormat('yyyy/MM/dd').format(_startDate!)} - ${DateFormat('yyyy/MM/dd').format(_endDate!)}'
                                  : 'هەڵبژاردنی بەروارەکان',
                              style: const TextStyle(color: Colors.white),
                            ),
                            const Spacer(),
                            const Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.white54,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              _clearFilters();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white24,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'پاککردنەوە',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              _filterWinners();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2DCCDB),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'جێبەجێکردن',
                              style: TextStyle(color: Color(0xFF0B1120)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
    );
  }

  void _showWinnerDetails(GameResultModel winner) async {
    // Fetch game details
    final gameDetails = await ref
        .read(databaseServiceProvider)
        .getGameDetails(winner.gameId);

    if (!mounted) return;

    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            backgroundColor: const Color(0xFF1A1F36),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              padding: const EdgeInsets.all(24),
              constraints: const BoxConstraints(maxWidth: 500),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      const Icon(
                        Icons.emoji_events,
                        color: Color(0xFFFFD700),
                        size: 32,
                      ),
                      const SizedBox(width: 16),
                      const Text(
                        'وردەکاری براوە',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const Divider(color: Colors.white24, height: 32),

                  // User info
                  const Text(
                    'بەکارهێنەر',
                    style: TextStyle(
                      color: Color(0xFF2DCCDB),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: const Color(0xFF2DCCDB),
                        backgroundImage:
                            winner.userPhotoUrl != null
                                ? NetworkImage(winner.userPhotoUrl!)
                                : null,
                        child:
                            winner.userPhotoUrl == null
                                ? Text(
                                  winner.userDisplayName != null &&
                                          winner.userDisplayName!.isNotEmpty
                                      ? winner.userDisplayName![0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                  ),
                                )
                                : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              winner.userDisplayName ?? 'بەکارهێنەری نەناسراو',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              winner.userEmail ?? 'بێ ئیمەیل',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'ناسنامە: ${winner.userId}',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Game info
                  const Text(
                    'یاری',
                    style: TextStyle(
                      color: Color(0xFF2DCCDB),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow('ناوی یاری', gameDetails?['title'] ?? 'N/A'),
                  _buildInfoRow('پۆل', gameDetails?['category'] ?? 'N/A'),
                  _buildInfoRow('ناسنامەی یاری', winner.gameId),
                  _buildInfoRow(
                    'بەرواری تەواوبوون',
                    winner.completedAt != null
                        ? DateFormat(
                          'yyyy/MM/dd - HH:mm:ss',
                        ).format(winner.completedAt!)
                        : 'N/A',
                  ),
                  const SizedBox(height: 24),

                  // Score info
                  const Text(
                    'ئەنجام',
                    style: TextStyle(
                      color: Color(0xFF2DCCDB),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFFFD700).withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.stars,
                          color: Color(0xFFFFD700),
                          size: 24,
                        ),
                        const SizedBox(width: 16),
                        Text(
                          'خاڵ: ${winner.score}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Close button
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2DCCDB),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'داخستن',
                        style: TextStyle(
                          color: Color(0xFF0B1120),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToManageWinnersScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ManageWinnersScreen()),
    );
  }
}
