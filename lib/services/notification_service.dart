// File: lib/services/notification_service.dart
// Description: Service to handle app notifications

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class NotificationService {
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  // Initialize notification channels and request permissions
  Future<void> initialize() async {
    debugPrint('🔔 Initializing notification service...');

    try {
      // Initialize timezone
      tz_data.initializeTimeZones();
      debugPrint('🔔 Timezone initialized.');

      // Subscribe to the 'all' topic to receive global notifications
      await subscribeToTopic('all');
      debugPrint('🔔 Subscribed to "all" topic for global notifications.');

      // Initialize platform specific settings
      const AndroidInitializationSettings androidInitializationSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      final DarwinInitializationSettings darwinInitializationSettings =
          DarwinInitializationSettings(
            requestAlertPermission: true,
            requestBadgePermission: true,
            requestSoundPermission: true,
            onDidReceiveLocalNotification: (
              int id,
              String? title,
              String? body,
              String? payload,
            ) async {
              debugPrint('🔔 iOS foreground notification received: $title');
            },
          );

      final InitializationSettings initializationSettings =
          InitializationSettings(
            android: androidInitializationSettings,
            iOS: darwinInitializationSettings,
          );

      // Request Android notification permissions
      if (Platform.isAndroid) {
        final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
            _flutterLocalNotificationsPlugin
                .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin
                >();

        final bool? granted =
            await androidPlugin?.requestNotificationsPermission();
        debugPrint(
          '🔔 Android notification permissions ${granted == true ? 'granted' : 'denied'}.',
        );
      }

      // Initialize local notifications
      await _flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          debugPrint(
            '🔔 Notification tapped with payload: ${response.payload}',
          );
          _handleNotificationTap(response.payload);
        },
      );

      debugPrint('🔔 Local notifications initialized successfully.');

      // For iOS, explicitly request notification settings
      if (Platform.isIOS) {
        await _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >()
            ?.requestPermissions(alert: true, badge: true, sound: true);
        debugPrint('🔔 iOS notification permissions explicitly requested.');
      }

      // Request permissions for Firebase Messaging (remote)
      await _requestFirebaseNotificationPermissions();

      // Listen for Firebase messages when app is in background or terminated
      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );

      // Listen for Firebase messages when app is in foreground
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        _handleFirebaseMessage(message);
      });

      // Handle when app is opened from a notification
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        _handleNotificationTap(message.data['payload']);
      });

      // Create notification channels
      await _createNotificationChannel();
    } catch (e) {
      debugPrint('❌ Error initializing notification service: $e');
    }
  }

  Future<void> _requestFirebaseNotificationPermissions() async {
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted notification permission');
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      debugPrint('User granted provisional notification permission');
    } else {
      debugPrint('User declined notification permission');
    }
  }

  // Handle notification tap
  void _handleNotificationTap(String? payload) {
    if (payload != null && payload.isNotEmpty) {
      // Parse the payload and navigate to the appropriate screen
      debugPrint('Notification payload: $payload');

      // Example payload handling - you'll need to implement navigation logic
      // Navigator.pushNamed(context, '/game-details', arguments: {'gameId': payload});
    }
  }

  // Handle Firebase messages when app is in foreground
  void _handleFirebaseMessage(RemoteMessage message) {
    final notification = message.notification;
    final data = message.data;

    if (notification != null) {
      _flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'games_channel',
            'Game Notifications',
            channelDescription: 'Notifications about games',
            importance: Importance.high,
            priority: Priority.high,
            color: Colors.red,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: data['gameId'],
      );
    }
  }

  // Create Android notification channel
  Future<void> _createNotificationChannel() async {
    if (Platform.isAndroid) {
      debugPrint('🔔 Creating Android notification channels...');

      try {
        const AndroidNotificationChannel gamesChannel =
            AndroidNotificationChannel(
              'games_channel',
              'Game Notifications',
              description: 'Notifications about games',
              importance: Importance.high,
              sound: RawResourceAndroidNotificationSound('correct'),
              enableVibration: true,
              playSound: true,
            );

        const AndroidNotificationChannel remindersChannel =
            AndroidNotificationChannel(
              'games_reminder_channel',
              'Game Reminders',
              description: 'Reminders for upcoming games',
              importance: Importance.high,
              sound: RawResourceAndroidNotificationSound('timer'),
              enableVibration: true,
              playSound: true,
            );

        const AndroidNotificationChannel winnersChannel =
            AndroidNotificationChannel(
              'winners_channel',
              'Winner Announcements',
              description: 'Announcements about game winners',
              importance: Importance.high,
              sound: RawResourceAndroidNotificationSound('correct'),
              enableVibration: true,
              playSound: true,
            );

        const AndroidNotificationChannel testChannel =
            AndroidNotificationChannel(
              'test_channel',
              'Test Notifications',
              description: 'For testing notifications',
              importance: Importance.max,
              sound: RawResourceAndroidNotificationSound('correct'),
              enableVibration: true,
              playSound: true,
              showBadge: true,
            );

        const AndroidNotificationChannel customChannel =
            AndroidNotificationChannel(
              'custom_channel',
              'Custom Notifications',
              description: 'Custom notifications from admin',
              importance: Importance.high,
              sound: RawResourceAndroidNotificationSound('correct'),
              enableVibration: true,
              playSound: true,
              showBadge: true,
            );

        const AndroidNotificationChannel broadcastChannel =
            AndroidNotificationChannel(
              'broadcast_channel',
              'Broadcast Notifications',
              description: 'Broadcast notifications sent to all users',
              importance: Importance.high,
              sound: RawResourceAndroidNotificationSound('correct'),
              enableVibration: true,
              playSound: true,
              showBadge: true,
            );

        final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
            _flutterLocalNotificationsPlugin
                .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin
                >();

        await androidPlugin?.createNotificationChannel(gamesChannel);
        await androidPlugin?.createNotificationChannel(remindersChannel);
        await androidPlugin?.createNotificationChannel(winnersChannel);
        await androidPlugin?.createNotificationChannel(testChannel);
        await androidPlugin?.createNotificationChannel(customChannel);
        await androidPlugin?.createNotificationChannel(broadcastChannel);

        debugPrint('✅ Android notification channels created successfully!');
      } catch (e) {
        debugPrint('❌ Error creating Android notification channels: $e');
      }
    }
  }

  // Subscribe to topics for targeted notifications
  Future<void> subscribeToTopic(String topic) async {
    await _firebaseMessaging.subscribeToTopic(topic);
  }

  // Unsubscribe from topics
  Future<void> unsubscribeFromTopic(String topic) async {
    await _firebaseMessaging.unsubscribeFromTopic(topic);
  }

  // Send local notification when a new game is created
  Future<void> sendNewGameNotification({
    required String gameId,
    required String gameTitle,
    required DateTime gameStartTime,
  }) async {
    debugPrint('🔔 Sending new game notification for: $gameTitle');

    try {
      await _flutterLocalNotificationsPlugin.show(
        gameId.hashCode,
        'بەشداربوونی نوێ: $gameTitle',
        'یاریەکی نوێ بەردەستە! دەستپێدەکات: ${_formatDateTime(gameStartTime)}',
        NotificationDetails(
          android: const AndroidNotificationDetails(
            'games_channel',
            'Game Notifications',
            channelDescription: 'Notifications about games',
            importance: Importance.high,
            priority: Priority.high,
            color: Colors.red,
            sound: RawResourceAndroidNotificationSound('correct'),
            icon: '@mipmap/ic_launcher',
            playSound: true,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            sound: 'correct.mp3',
          ),
        ),
        payload: gameId,
      );
      debugPrint('✅ New game notification sent successfully!');
    } catch (e) {
      debugPrint('❌ Error sending new game notification: $e');
    }
  }

  // Schedule a notification for 5 minutes before game starts
  Future<void> scheduleGameReminderNotification({
    required String gameId,
    required String gameTitle,
    required DateTime gameStartTime,
  }) async {
    // Calculate 5 minutes before start time
    final scheduledTime = gameStartTime.subtract(const Duration(minutes: 5));
    final now = DateTime.now();

    debugPrint('⏰ Scheduling reminder for game: $gameTitle (ID: $gameId)');
    debugPrint('⏰ Game start time: ${gameStartTime.toString()}');
    debugPrint('⏰ Reminder scheduled for: ${scheduledTime.toString()}');
    debugPrint('⏰ Current time: ${now.toString()}');
    debugPrint('⏰ Is scheduled time in future? ${scheduledTime.isAfter(now)}');
    debugPrint(
      '⏰ Time until reminder: ${scheduledTime.difference(now).inSeconds} seconds',
    );

    // Only schedule if in the future
    if (scheduledTime.isAfter(now)) {
      debugPrint('⏰ Scheduling notification for future time...');

      try {
        await _flutterLocalNotificationsPlugin.zonedSchedule(
          gameId.hashCode + 1, // Different ID from new game notification
          'یاری ئامادەیە: $gameTitle',
          'یاریەکە دەستپێدەکات لە ٥ خولەکێکی تر!',
          tz.TZDateTime.from(scheduledTime, tz.local),
          NotificationDetails(
            android: const AndroidNotificationDetails(
              'games_reminder_channel',
              'Game Reminders',
              channelDescription: 'Reminders for upcoming games',
              importance: Importance.max, // Using max importance
              priority: Priority.max, // Using max priority
              color: Colors.red,
              sound: RawResourceAndroidNotificationSound('timer'),
              icon: '@mipmap/ic_launcher',
              playSound: true,
              enableLights: true,
              enableVibration: true,
              fullScreenIntent: true, // Add full screen intent for visibility
              visibility: NotificationVisibility.public,
            ),
            iOS: const DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
              sound: 'timer.mp3',
              interruptionLevel:
                  InterruptionLevel.timeSensitive, // Use time sensitive level
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: gameId,
          matchDateTimeComponents:
              DateTimeComponents
                  .time, // Match time component for better accuracy
        );

        // Also schedule a notification for when the game starts
        await _flutterLocalNotificationsPlugin.zonedSchedule(
          gameId.hashCode + 3, // Different ID from other notifications
          'یاری دەستیپێکرد: $gameTitle',
          'یاریەکە ئێستا دەستیپێکرد!',
          tz.TZDateTime.from(gameStartTime, tz.local),
          NotificationDetails(
            android: const AndroidNotificationDetails(
              'games_channel',
              'Game Notifications',
              channelDescription: 'Notifications about games',
              importance: Importance.max,
              priority: Priority.max,
              color: Colors.red,
              sound: RawResourceAndroidNotificationSound('correct'),
              icon: '@mipmap/ic_launcher',
              playSound: true,
              enableLights: true,
              enableVibration: true,
              fullScreenIntent: true,
              visibility: NotificationVisibility.public,
            ),
            iOS: const DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
              sound: 'correct.mp3',
              interruptionLevel: InterruptionLevel.timeSensitive,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: gameId,
          matchDateTimeComponents: DateTimeComponents.time,
        );
        debugPrint(
          '✅ Game reminder and start notifications scheduled successfully!',
        );

        // List all pending notifications for debugging
        final List<PendingNotificationRequest> pendingNotifications =
            await _flutterLocalNotificationsPlugin
                .pendingNotificationRequests();
        debugPrint(
          '⏰ Total pending notifications: ${pendingNotifications.length}',
        );

        for (final notification in pendingNotifications) {
          debugPrint(
            '⏰ Pending notification: ID=${notification.id}, Title=${notification.title}, Body=${notification.body}',
          );
        }
      } catch (e) {
        debugPrint('❌ Error scheduling game reminder notification: $e');
        debugPrint('❌ Stack trace: ${StackTrace.current}');
      }
    } else {
      debugPrint(
        '⏰ Reminder time is in the past, not scheduling notification.',
      );
      debugPrint('⏰ Game start time: ${gameStartTime.toString()}');
      debugPrint('⏰ 5 minutes before: ${scheduledTime.toString()}');
      debugPrint('⏰ Current time: ${now.toString()}');
    }
  }

  // Send notification about daily winners
  Future<void> sendDailyWinnersNotification({
    required int winnerCount,
    required String topWinnerName,
    required String gameId,
  }) async {
    await _flutterLocalNotificationsPlugin.show(
      gameId.hashCode + 2, // Different ID from other notifications
      'ئەنجامەکانی یارییەکە ئامادەن!',
      '$topWinnerName و $winnerCount کەسی تر براوە بوون!',
      NotificationDetails(
        android: const AndroidNotificationDetails(
          'winners_channel',
          'Winner Announcements',
          channelDescription: 'Announcements about game winners',
          importance: Importance.high,
          priority: Priority.high,
          color: Colors.green,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: gameId,
    );
  }

  // Generic show notification method for flexibility
  Future<void> show({
    required int id,
    required String title,
    required String body,
    required String payload,
    required String channelId,
  }) async {
    await _flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelId == 'games_channel'
              ? 'Game Notifications'
              : channelId == 'games_reminder_channel'
              ? 'Game Reminders'
              : 'Winner Announcements',
          channelDescription: 'Notifications about games',
          importance: Importance.high,
          priority: Priority.high,
          color: Colors.red,
          icon: '@mipmap/ic_launcher',
          sound: RawResourceAndroidNotificationSound('correct'),
          playSound: true,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          sound: 'correct.mp3',
        ),
      ),
      payload: payload,
    );
  }

  // Format date time for notifications
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  // Check if notifications are allowed
  Future<bool> areNotificationsAllowed() async {
    bool allowed = false;

    try {
      if (Platform.isIOS) {
        final IOSFlutterLocalNotificationsPlugin? iosPlugin =
            _flutterLocalNotificationsPlugin
                .resolvePlatformSpecificImplementation<
                  IOSFlutterLocalNotificationsPlugin
                >();
        allowed =
            await iosPlugin?.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            ) ??
            false;
      } else if (Platform.isAndroid) {
        final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
            _flutterLocalNotificationsPlugin
                .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin
                >();
        allowed = await androidPlugin?.areNotificationsEnabled() ?? false;
      }

      debugPrint('🔔 Notifications allowed: $allowed');
      return allowed;
    } catch (e) {
      debugPrint('❌ Error checking notification permissions: $e');
      return false;
    }
  }

  // Send custom notification for admin broadcasts
  Future<void> sendCustomNotification({
    required String title,
    required String body,
    String? payload,
    String channelId = 'custom_channel',
  }) async {
    debugPrint('🔔 Sending custom notification: $title');

    try {
      // Generate a unique ID based on current time
      final notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      await _flutterLocalNotificationsPlugin.show(
        notificationId,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channelId,
            channelId == 'games_channel'
                ? 'Game Notifications'
                : channelId == 'games_reminder_channel'
                ? 'Game Reminders'
                : channelId == 'winners_channel'
                ? 'Winner Announcements'
                : channelId == 'custom_channel'
                ? 'Custom Notifications'
                : channelId == 'broadcast_channel'
                ? 'Broadcast Notifications'
                : 'Custom Notifications',
            channelDescription:
                channelId == 'broadcast_channel'
                    ? 'Broadcast notifications sent to all users'
                    : 'Custom notifications from admin',
            importance: Importance.high,
            priority: Priority.high,
            color:
                channelId == 'broadcast_channel' ? Colors.orange : Colors.blue,
            icon: '@mipmap/ic_launcher',
            playSound: true,
            enableVibration: true,
            visibility: NotificationVisibility.public,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            interruptionLevel: InterruptionLevel.timeSensitive,
          ),
        ),
        payload: payload ?? 'custom_notification',
      );

      debugPrint('✅ Custom notification sent successfully!');
    } catch (e) {
      debugPrint('❌ Error sending custom notification: $e');
    }
  }

  // Schedule custom notification for later
  Future<void> scheduleCustomNotification({
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
    String channelId = 'custom_channel',
  }) async {
    debugPrint(
      '🔔 Scheduling custom notification: $title for ${scheduledTime.toString()}',
    );

    try {
      // Generate a unique ID based on title hash and scheduled time
      final notificationId =
          title.hashCode + scheduledTime.millisecondsSinceEpoch ~/ 1000;

      // Only schedule if in the future
      if (scheduledTime.isAfter(DateTime.now())) {
        await _flutterLocalNotificationsPlugin.zonedSchedule(
          notificationId,
          title,
          body,
          tz.TZDateTime.from(scheduledTime, tz.local),
          NotificationDetails(
            android: AndroidNotificationDetails(
              channelId,
              channelId == 'custom_channel'
                  ? 'Custom Notifications'
                  : 'Scheduled Notifications',
              channelDescription: 'Scheduled custom notifications from admin',
              importance: Importance.high,
              priority: Priority.high,
              color: Colors.purple,
              icon: '@mipmap/ic_launcher',
              sound: RawResourceAndroidNotificationSound('correct'),
              playSound: true,
              enableVibration: true,
              visibility: NotificationVisibility.public,
            ),
            iOS: const DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
              sound: 'correct.mp3',
              interruptionLevel: InterruptionLevel.timeSensitive,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: payload ?? 'scheduled_custom_notification',
        );

        debugPrint('✅ Custom notification scheduled successfully!');
      } else {
        debugPrint(
          '⚠️ Scheduled time is in the past, not scheduling notification.',
        );
      }
    } catch (e) {
      debugPrint('❌ Error scheduling custom notification: $e');
    }
  }

  // Send test notification immediately
  Future<void> sendTestNotification() async {
    debugPrint('🧪 Sending test notification...');

    try {
      // Immediate test notification
      await _flutterLocalNotificationsPlugin.show(
        9999, // Unique ID for test notification
        'تاقیکردنەوەی ئاگادارکردنەوە',
        'ئەگەر ئەمە دەبینیت، ئاگادارکردنەوەکانت کار دەکەن! 👍',
        NotificationDetails(
          android: const AndroidNotificationDetails(
            'test_channel',
            'Test Notifications',
            channelDescription: 'For testing notifications',
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            color: Colors.orange,
            sound: RawResourceAndroidNotificationSound('correct'),
            playSound: true,
            enableVibration: true,
            fullScreenIntent: true,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            sound: 'correct.mp3',
            interruptionLevel: InterruptionLevel.timeSensitive,
          ),
        ),
        payload: 'test_notification',
      );

      // Also schedule a notification for 10 seconds from now
      final now = DateTime.now();
      final scheduled = now.add(const Duration(seconds: 10));

      await _flutterLocalNotificationsPlugin.zonedSchedule(
        9998, // Different ID
        'تاقیکردنەوەی کاتی',
        'ئەم ئاگادارکردنەوە دوای ١٠ چرکە دەردەچێت',
        tz.TZDateTime.from(scheduled, tz.local),
        NotificationDetails(
          android: const AndroidNotificationDetails(
            'test_channel',
            'Test Notifications',
            channelDescription: 'For testing notifications',
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            sound: RawResourceAndroidNotificationSound('timer'),
            playSound: true,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            sound: 'timer.mp3',
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );

      debugPrint('✅ Test notifications sent successfully!');

      // Check pending notifications
      final pendingNotifications =
          await _flutterLocalNotificationsPlugin.pendingNotificationRequests();
      debugPrint(
        '⏰ Total pending notifications: ${pendingNotifications.length}',
      );

      for (final notification in pendingNotifications) {
        debugPrint(
          '⏰ Pending notification: ID=${notification.id}, Title=${notification.title}',
        );
      }
    } catch (e) {
      debugPrint('❌ Error sending test notification: $e');
      debugPrint('❌ Stack trace: ${StackTrace.current}');
    }
  }
}

// Function to handle background messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // This will be called when the app is in the background and a message is received
  debugPrint('Handling a background message: ${message.messageId}');

  // No need to initialize Firebase here - it will cause errors
  // Just log that we received the message
  debugPrint('Background message data: ${message.data}');
  debugPrint('Background message notification: ${message.notification?.title}');
}

// Provider for the NotificationService
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});
