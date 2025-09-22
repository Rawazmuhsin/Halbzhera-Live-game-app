// File: lib/utils/formatters.dart
// Description: Utility functions for formatting data

import 'package:intl/intl.dart';

/// Format a DateTime object to a readable string
String formatDateTime(DateTime dateTime) {
  final now = DateTime.now();
  final difference = now.difference(dateTime);

  if (difference.inDays == 0) {
    // Today - show time
    return 'ئەمڕۆ ${DateFormat.Hm().format(dateTime)}';
  } else if (difference.inDays == 1) {
    // Yesterday
    return 'دوێنێ ${DateFormat.Hm().format(dateTime)}';
  } else if (difference.inDays < 7) {
    // This week - show day name
    return '${difference.inDays} ڕۆژ لەمەوبەر';
  } else if (difference.inDays < 30) {
    // This month - show weeks
    final weeks = (difference.inDays / 7).floor();
    return '$weeks هەفتە لەمەوبەر';
  } else if (difference.inDays < 365) {
    // This year - show months
    final months = (difference.inDays / 30).floor();
    return '$months مانگ لەمەوبەر';
  } else {
    // More than a year - show full date
    return DateFormat('yyyy/MM/dd').format(dateTime);
  }
}

/// Format a number with Kurdish separators
String formatNumber(int number) {
  final formatter = NumberFormat('#,###');
  return formatter.format(number);
}

/// Format percentage with one decimal place
String formatPercentage(double percentage) {
  return '${percentage.toStringAsFixed(1)}%';
}

/// Format score with proper styling
String formatScore(int score) {
  if (score >= 1000000) {
    return '${(score / 1000000).toStringAsFixed(1)}M';
  } else if (score >= 1000) {
    return '${(score / 1000).toStringAsFixed(1)}K';
  } else {
    return score.toString();
  }
}

/// Format time duration to readable string
String formatDuration(Duration duration) {
  if (duration.inDays > 0) {
    return '${duration.inDays} ڕۆژ';
  } else if (duration.inHours > 0) {
    return '${duration.inHours} کاتژمێر';
  } else if (duration.inMinutes > 0) {
    return '${duration.inMinutes} خولەک';
  } else {
    return '${duration.inSeconds} چرکە';
  }
}

/// Format file size
String formatFileSize(int bytes) {
  if (bytes >= 1024 * 1024 * 1024) {
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  } else if (bytes >= 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  } else if (bytes >= 1024) {
    return '${(bytes / 1024).toStringAsFixed(1)} KB';
  } else {
    return '$bytes B';
  }
}
