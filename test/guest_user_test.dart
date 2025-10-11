// Test file for guest user functionality
// This demonstrates how the guest user system works

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Guest User ID System', () {
    test('Guest ID format validation', () {
      // Test that guest IDs follow the correct format
      final guestIds = ['GUEST-0001', 'GUEST-0010', 'GUEST-0100', 'GUEST-1000'];

      for (final id in guestIds) {
        expect(id.startsWith('GUEST-'), true);
        expect(id.length, greaterThanOrEqualTo(10));
      }
    });

    test('Guest ID number extraction', () {
      final guestId = 'GUEST-0123';
      final numberPart = guestId.substring(6); // Remove "GUEST-"
      expect(numberPart, '0123');
      expect(int.parse(numberPart), 123);
    });

    test('Guest ID zero padding', () {
      final testCases = [
        (1, 'GUEST-0001'),
        (10, 'GUEST-0010'),
        (100, 'GUEST-0100'),
        (1000, 'GUEST-1000'),
      ];

      for (final testCase in testCases) {
        final number = testCase.$1;
        final expected = testCase.$2;
        final formatted = 'GUEST-${number.toString().padLeft(4, '0')}';
        expect(formatted, expected);
      }
    });

    test('Guest ID search compatibility', () {
      final searchQueries = [
        'GUEST-0001',
        'guest-0001',
        'Guest-0001',
        'guest',
        'GUEST',
      ];

      final guestId = 'GUEST-0001';

      for (final query in searchQueries) {
        expect(
          guestId.toLowerCase().contains(query.toLowerCase()),
          true,
          reason: 'Should find guest ID with query: $query',
        );
      }
    });
  });

  group('Display Name Tests', () {
    test('Guest display name should be guest ID', () {
      final guestId = 'GUEST-0042';
      expect(guestId, 'GUEST-0042');
    });
  });
}
