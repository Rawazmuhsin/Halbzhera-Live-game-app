import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/firebase_config.dart';

class AdminNotificationService {
  // Check if the user is an admin
  static Future<bool> isAdmin(String userId) async {
    try {
      final userDoc = await FirebaseConfig.users.doc(userId).get();
      final userData = userDoc.data() as Map<String, dynamic>?;
      return userData != null && userData['role'] == 'admin';
    } catch (e) {
      debugPrint('❌ Error checking admin status: $e');
      return false;
    }
  }

  // Send a notification to all users (server-less implementation)
  static Future<Map<String, dynamic>> sendGlobalNotification({
    required String title,
    required String body,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      debugPrint('🔔 Sending global notification: $title');

      // Create notification data
      final notificationData = {
        'title': title,
        'body': body,
        'sentAt': FieldValue.serverTimestamp(),
        'data': additionalData ?? {},
        'status': 'pending',
      };

      // Save the notification in Firestore
      final notificationRef = await FirebaseConfig.firestore
          .collection('notifications')
          .add(notificationData);

      debugPrint(
        '✅ Notification saved to Firestore with ID: ${notificationRef.id}',
      );

      // In a real production app, you would need a small server component or use Firebase Functions
      // to send the actual FCM notification. For this solution, we'll store the notification in Firestore
      // and rely on users' app to listen to this collection for new notifications.

      // Here we're returning success even though the push notification itself isn't sent
      return {
        'success': true,
        'notificationId': notificationRef.id,
        'message':
            'Notification saved successfully. A server component is required to actually send FCM notifications.',
      };
    } catch (e) {
      debugPrint('❌ Error sending notification: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // Method to add a real-time listener for notifications in the app
  static Stream<QuerySnapshot> getNotificationsStream() {
    return FirebaseConfig.firestore
        .collection('notifications')
        .orderBy('sentAt', descending: true)
        .limit(50)
        .snapshots();
  }

  // Method to mark notification as seen by a user
  static Future<void> markNotificationAsSeen(
    String notificationId,
    String userId,
  ) async {
    try {
      await FirebaseConfig.firestore
          .collection('notifications')
          .doc(notificationId)
          .collection('seen_by')
          .doc(userId)
          .set({'timestamp': FieldValue.serverTimestamp()});
    } catch (e) {
      debugPrint('❌ Error marking notification as seen: $e');
    }
  }
}
