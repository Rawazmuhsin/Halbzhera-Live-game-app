// File: lib/services/broadcast_notification_service.dart
// Description: Service to handle broadcast notifications via Firestore + Local Notifications

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_service.dart';

class BroadcastNotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService;
  StreamSubscription<QuerySnapshot>? _broadcastSubscription;

  static const String _lastNotificationIdKey = 'last_broadcast_notification_id';

  BroadcastNotificationService(this._notificationService);

  /// Admin sends a broadcast notification - stores in Firestore
  Future<bool> sendBroadcastNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    debugPrint('📡 Sending broadcast notification: $title');

    try {
      await _firestore.collection('broadcast_notifications').add({
        'title': title,
        'body': body,
        'payload': payload ?? 'broadcast_notification',
        'timestamp': FieldValue.serverTimestamp(),
        'createdAt': DateTime.now().millisecondsSinceEpoch,
        'isActive': true,
        'type': 'admin_broadcast',
      });

      debugPrint('✅ Broadcast notification stored in Firestore successfully');
      return true;
    } catch (e) {
      debugPrint('❌ Error sending broadcast notification: $e');
      return false;
    }
  }

  /// Start listening for new broadcast notifications (call this when app starts)
  void startListeningForBroadcastNotifications() {
    debugPrint('🔔 Starting to listen for broadcast notifications...');

    _broadcastSubscription?.cancel(); // Cancel any existing subscription

    // Add a small delay to ensure Firebase is fully initialized
    Future.delayed(Duration(seconds: 2), () {
      // Start with a simple query that doesn't require an index
      _broadcastSubscription = _firestore
          .collection('broadcast_notifications')
          .where('isActive', isEqualTo: true)
          .limit(10)
          .snapshots()
          .listen(
            _handleBroadcastNotifications,
            onError: (error) {
              debugPrint('❌ Error listening for broadcast notifications: $error');
              // Retry after 5 seconds
              Future.delayed(Duration(seconds: 5), () {
                debugPrint('🔄 Retrying broadcast notification listener...');
                startListeningForBroadcastNotifications();
              });
            },
          );
      debugPrint('✅ Broadcast notification listener started');
    });
  }

  /// Handle incoming broadcast notifications
  Future<void> _handleBroadcastNotifications(QuerySnapshot snapshot) async {
    debugPrint('📡 Received broadcast notifications update: ${snapshot.docChanges.length} changes');

    // Get the last processed notification ID
    final prefs = await SharedPreferences.getInstance();
    final lastProcessedId = prefs.getString(_lastNotificationIdKey);
    debugPrint('🔍 Last processed notification ID: $lastProcessedId');

    for (var docChange in snapshot.docChanges) {
      if (docChange.type == DocumentChangeType.added) {
        final doc = docChange.doc;
        final data = doc.data() as Map<String, dynamic>;

        // Skip if we've already processed this notification
        if (lastProcessedId == doc.id) {
          debugPrint('⏭️ Skipping already processed notification: ${doc.id}');
          continue;
        }

        // Check if this is a new notification (created in the last 10 minutes)
        final createdAt = data['createdAt'] as int?;
        if (createdAt != null) {
          final notificationTime = DateTime.fromMillisecondsSinceEpoch(
            createdAt,
          );
          final now = DateTime.now();
          final timeDifference = now.difference(notificationTime);

          // Only show notifications that are less than 10 minutes old
          if (timeDifference.inMinutes > 10) {
            debugPrint(
              '⏰ Notification too old, skipping: ${timeDifference.inMinutes} minutes old',
            );
            continue;
          }
        }

        debugPrint(
          '📩 Processing new broadcast notification: ${data['title']}',
        );

        // Show local notification on this device
        await _notificationService.sendCustomNotification(
          title: data['title'] ?? 'إشعار جديد',
          body: data['body'] ?? '',
          payload: data['payload'] ?? 'broadcast_notification',
          channelId: 'broadcast_channel',
        );

        // Update the last processed notification ID
        await prefs.setString(_lastNotificationIdKey, doc.id);

        debugPrint('✅ Broadcast notification displayed successfully');
      }
    }
  }

  /// Stop listening for broadcast notifications
  void stopListeningForBroadcastNotifications() {
    debugPrint('🔔 Stopping broadcast notification listener...');
    _broadcastSubscription?.cancel();
    _broadcastSubscription = null;
  }

  /// Get recent broadcast notifications for history
  Future<List<Map<String, dynamic>>> getRecentBroadcastNotifications({
    int limit = 20,
  }) async {
    try {
      final querySnapshot =
          await _firestore
              .collection('broadcast_notifications')
              .where('isActive', isEqualTo: true)
              .limit(limit)
              .get();

      // Sort manually after fetching
      final notifications = querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      // Sort by timestamp or createdAt
      notifications.sort((a, b) {
        final aTime = a['createdAt'] ?? a['timestamp'];
        final bTime = b['createdAt'] ?? b['timestamp'];
        if (aTime is Timestamp && bTime is Timestamp) {
          return bTime.compareTo(aTime);
        } else if (aTime is int && bTime is int) {
          return bTime.compareTo(aTime);
        }
        return 0;
      });

      return notifications;
    } catch (e) {
      debugPrint('❌ Error getting recent broadcast notifications: $e');
      return [];
    }
  }

  /// Delete a broadcast notification (Admin only)
  Future<bool> deleteBroadcastNotification(String notificationId) async {
    try {
      await _firestore
          .collection('broadcast_notifications')
          .doc(notificationId)
          .update({'isActive': false});

      debugPrint('✅ Broadcast notification deleted successfully');
      return true;
    } catch (e) {
      debugPrint('❌ Error deleting broadcast notification: $e');
      return false;
    }
  }

  /// Clear all old notifications (older than 30 days)
  Future<void> cleanupOldNotifications() async {
    try {
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      final querySnapshot =
          await _firestore
              .collection('broadcast_notifications')
              .where(
                'timestamp',
                isLessThan: Timestamp.fromDate(thirtyDaysAgo),
              )
              .get();

      final batch = _firestore.batch();
      for (var doc in querySnapshot.docs) {
        batch.update(doc.reference, {'isActive': false});
      }

      await batch.commit();
      debugPrint(
        '🧹 Cleaned up ${querySnapshot.docs.length} old notifications',
      );
    } catch (e) {
      debugPrint('❌ Error cleaning up old notifications: $e');
    }
  }

  /// Dispose the service
  void dispose() {
    stopListeningForBroadcastNotifications();
  }
}

// Provider for the broadcast notification service
final broadcastNotificationServiceProvider =
    Provider<BroadcastNotificationService>((ref) {
      final notificationService = ref.read(notificationServiceProvider);
      return BroadcastNotificationService(notificationService);
    });

// Provider to automatically start listening when app starts
final broadcastNotificationListenerProvider = Provider<void>((ref) {
  final broadcastService = ref.read(broadcastNotificationServiceProvider);

  // Start listening when the provider is first accessed
  broadcastService.startListeningForBroadcastNotifications();

  // Cleanup when provider is disposed
  ref.onDispose(() {
    broadcastService.dispose();
  });
});
