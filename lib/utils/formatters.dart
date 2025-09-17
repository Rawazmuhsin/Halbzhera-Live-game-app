// File: lib/utils/formatters.dart
// Description: Helper functions for formatting values

import 'package:intl/intl.dart';

/// Format a DateTime to a readable string
String formatDateTime(DateTime dateTime) {
  final now = DateTime.now();
  final difference = now.difference(dateTime);

  if (difference.inDays == 0) {
    // Today, show time
    return 'Today, ${DateFormat('h:mm a').format(dateTime)}';
  } else if (difference.inDays == 1) {
    // Yesterday
    return 'Yesterday, ${DateFormat('h:mm a').format(dateTime)}';
  } else if (difference.inDays < 7) {
    // Within the last week
    return DateFormat(
      'EEEE, h:mm a',
    ).format(dateTime); // e.g., "Monday, 3:45 PM"
  } else {
    // More than a week ago
    return DateFormat('MMM d, y').format(dateTime); // e.g., "Jun 15, 2023"
  }
}

/// Format a duration to a readable string
String formatDuration(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  final seconds = duration.inSeconds.remainder(60);

  final parts = <String>[];

  if (hours > 0) {
    parts.add('${hours}h');
  }

  if (minutes > 0 || hours > 0) {
    parts.add('${minutes}m');
  }

  parts.add('${seconds}s');

  return parts.join(' ');
}

/// Format a number with comma separators
String formatNumber(num number) {
  final formatter = NumberFormat('#,###');
  return formatter.format(number);
}

/// Format currency with 2 decimal places and symbol
String formatCurrency(num amount, {String symbol = '\$'}) {
  final formatter = NumberFormat.currency(symbol: symbol, decimalDigits: 2);
  return formatter.format(amount);
}

/// Format percentage with proper decimals
String formatPercentage(double percentage, {int decimalPlaces = 1}) {
  final formatter =
      NumberFormat.percentPattern()..maximumFractionDigits = decimalPlaces;
  return formatter.format(percentage / 100);
}
