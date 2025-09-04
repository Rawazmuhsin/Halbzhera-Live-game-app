// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halbzhera/providers/database_provider.dart';

class ManageWinnersScreen extends ConsumerStatefulWidget {
  const ManageWinnersScreen({super.key});

  @override
  _ManageWinnersScreenState createState() => _ManageWinnersScreenState();
}

class _ManageWinnersScreenState extends ConsumerState<ManageWinnersScreen> {
  bool _isLoading = false;
  String _statusMessage = '';
  bool _isSuccess = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('بەڕێوەبردنی براوەکان'),
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
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                color: const Color(0xFF1A1F36).withOpacity(0.7),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.white.withOpacity(0.1)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'گواستنەوەی براوەکان',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'ئەم کارە هەموو براوەکانی کۆکراوە لە کۆڵێکشنی game_results دەگوازێتەوە بۆ کۆڵێکشنی تایبەتی بە براوەکان. ئەم کارە تەنها جارێک پێویستە ئەنجام بدرێت.',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _migrateWinners,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2DCCDB),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child:
                              _isLoading
                                  ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Color(0xFF0B1120),
                                      strokeWidth: 3,
                                    ),
                                  )
                                  : const Text(
                                    'گواستنەوەی براوەکان',
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

              // Status message
              if (_statusMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color:
                          _isSuccess
                              ? Colors.green.withOpacity(0.2)
                              : Colors.red.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color:
                            _isSuccess
                                ? Colors.green.withOpacity(0.5)
                                : Colors.red.withOpacity(0.5),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _isSuccess ? Icons.check_circle : Icons.error,
                          color: _isSuccess ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            _statusMessage,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Help info
              const SizedBox(height: 24),
              Card(
                color: const Color(0xFF1A1F36).withOpacity(0.7),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.white.withOpacity(0.1)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: Color(0xFF2DCCDB),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'زانیاری دەربارەی کۆڵێکشنەکان',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildInfoItem(
                        'کۆڵێکشنی game_results',
                        'هەموو ئەنجامەکان تۆمار دەکات، بەکارهێنەرانی براوە و نەبراوە.',
                      ),
                      const SizedBox(height: 8),
                      _buildInfoItem(
                        'کۆڵێکشنی winners',
                        'تەنها بەکارهێنەرانی براوە تۆمار دەکات، بۆ پیشاندان لە سکرینی ئەنجامەکان و بەشی ئەدمین.',
                      ),
                      const SizedBox(height: 8),
                      _buildInfoItem(
                        'سوود',
                        'هێنانەوەی داتا لە کۆڵێکشنی تایبەتی خێراترە لە فلتەرکردنی کۆڵێکشنی گەورە.',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Future<void> _migrateWinners() async {
    setState(() {
      _isLoading = true;
      _statusMessage = '';
    });

    try {
      await ref.read(databaseServiceProvider).migrateExistingWinners();

      setState(() {
        _isLoading = false;
        _statusMessage = 'گواستنەوەی براوەکان بە سەرکەوتوویی تەواو بوو!';
        _isSuccess = true;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'هەڵە ڕوویدا: $e';
        _isSuccess = false;
      });
    }
  }
}
