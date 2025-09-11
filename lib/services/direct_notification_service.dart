// File: lib/services/direct_notification_service.dart
// A service to send notifications directly from the app admin panel

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DirectNotificationService {
  // This would be stored securely and not exposed in code in a real production app
  // For development purposes, we're storing it here

  // WARNING: Replace this with your actual FCM server key for testing
  // Then delete it from the code once it works
  static const String _serverKey = 'YOUR_FCM_SERVER_KEY';

  // FCM API endpoint
  static const String _fcmUrl = 'https://fcm.googleapis.com/fcm/send';

  static final FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  static const String _keyName = 'fcm_server_key';

  // Save server key securely
  static Future<void> saveServerKey(String serverKey) async {
    await _secureStorage.write(key: _keyName, value: serverKey);
  }

  // Get the stored server key
  static Future<String?> getServerKey() async {
    return await _secureStorage.read(key: _keyName);
  }

  // Send notification to a specific topic
  static Future<bool> sendTopicNotification({
    required String title,
    required String body,
    required String topic,
    Map<String, dynamic>? data,
  }) async {
    try {
      debugPrint('🔔 Sending topic notification to: $topic');

      String? serverKey = await getServerKey();
      debugPrint(
        '🔑 Server key retrieved: ${serverKey != null ? "Not null (length: ${serverKey.length})" : "null"}',
      );

      if (serverKey == null || serverKey.isEmpty) {
        debugPrint('⚠️ Server key is null or empty, using default key');
        // Check if default key is usable
        if (_serverKey == 'YOUR_FCM_SERVER_KEY') {
          debugPrint('❌ Default key is not usable');
          throw Exception(
            'FCM Server Key not configured. Please set it in the settings.',
          );
        }

        serverKey = _serverKey;
        debugPrint('🔑 Using default key: ${serverKey.substring(0, 5)}...');
        // Save the default key for future use
        await saveServerKey(serverKey);
      }

      debugPrint('🔔 Preparing to send notification to FCM');
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'key=$serverKey',
      };
      debugPrint('🔔 Headers prepared: ${headers.keys.join(', ')}');

      final notificationData = {
        'notification': {'title': title, 'body': body, 'sound': 'default'},
        'data': data ?? {'click_action': 'FLUTTER_NOTIFICATION_CLICK'},
        'to': '/topics/$topic',
        'priority': 'high',
      };
      debugPrint('🔔 Notification data prepared');

      debugPrint('🔔 Sending HTTP POST request to FCM');
      final response = await http.post(
        Uri.parse(_fcmUrl),
        headers: headers,
        body: jsonEncode(notificationData),
      );
      debugPrint(
        '🔔 Received response with status code: ${response.statusCode}',
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        debugPrint('✅ FCM Response: $responseData');

        // Check for errors in the FCM response
        if (responseData.containsKey('failure') &&
            responseData['failure'] > 0) {
          final results = responseData['results'] as List;
          if (results.isNotEmpty && results[0].containsKey('error')) {
            debugPrint('❌ FCM Error: ${results[0]['error']}');

            // Log the failed attempt
            await _logNotification(title, body, topic, false, null);
            return false;
          }
        }

        // Log the notification for admin tracking
        await _logNotification(
          title,
          body,
          topic,
          true,
          responseData['message_id'],
        );

        return true;
      } else {
        debugPrint(
          '❌ Failed to send notification. Status: ${response.statusCode}',
        );
        debugPrint('❌ Response body: ${response.body}');

        // Log the failed attempt
        await _logNotification(title, body, topic, false, null);

        return false;
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error sending notification: $e');
      debugPrint('❌ Stack trace: $stackTrace');

      // More detailed error logging
      if (e.toString().contains('SocketException')) {
        debugPrint('❌ Network error: Check your internet connection');
      } else if (e.toString().contains('Authentication') ||
          e.toString().contains('Authorization')) {
        debugPrint('❌ Authentication error: Invalid FCM server key');
      } else if (e.toString().contains('FCM Server Key not configured')) {
        debugPrint('❌ Configuration error: FCM server key not set');
      } else {
        debugPrint('❌ Unknown error: $e');
      }

      return false;
    }
  }

  // Check if the current user is an admin
  static Future<bool> isCurrentUserAdmin() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;

      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

      return userDoc.data()?['role'] == 'admin';
    } catch (e) {
      debugPrint('❌ Error checking admin status: $e');
      return false;
    }
  }

  // Test if the FCM server key is valid
  static Future<bool> testServerKey() async {
    try {
      debugPrint('🔍 Testing FCM server key...');
      String? serverKey = await getServerKey();
      debugPrint(
        '🔑 Retrieved server key: ${serverKey != null ? "Not null (length: ${serverKey.length})" : "null"}',
      );

      if (serverKey == null || serverKey.isEmpty) {
        if (_serverKey == 'YOUR_FCM_SERVER_KEY') {
          debugPrint('❌ No server key configured');
          return false;
        }
        serverKey = _serverKey;
        debugPrint('🔑 Using default key');
      }

      // Print first and last 5 characters of the key for debugging
      if (serverKey.length > 10) {
        debugPrint(
          '🔑 Key format check: ${serverKey.substring(0, 5)}...${serverKey.substring(serverKey.length - 5)}',
        );
      }

      debugPrint('🔧 Sending test request to FCM...');
      // Send a test request to FCM
      final response = await http.post(
        Uri.parse('https://fcm.googleapis.com/fcm/send'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'key=$serverKey',
        },
        body: jsonEncode({
          'notification': {
            'title': 'Test',
            'body': 'This is a test notification',
          },
          'to': '/topics/nonexistent_topic_for_test',
          'dry_run': true, // This prevents the message from being actually sent
        }),
      );

      debugPrint(
        '🔑 FCM server key test result: Status ${response.statusCode}',
      );
      debugPrint('🔑 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData.containsKey('error')) {
          debugPrint('❌ FCM error in response: ${responseData['error']}');
          return false;
        }
        return true;
      } else {
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error testing server key: $e');
      return false;
    }
  }

  // Log notification for tracking
  static Future<void> _logNotification(
    String title,
    String body,
    String topic,
    bool success,
    String? messageId,
  ) async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      await FirebaseFirestore.instance.collection('notification_logs').add({
        'title': title,
        'body': body,
        'topic': topic,
        'success': success,
        'messageId': messageId,
        'sentBy': user?.uid ?? 'system',
        'sentAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('❌ Error logging notification: $e');
    }
  }
}
