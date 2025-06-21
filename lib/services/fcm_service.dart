import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:io';

// Background message handler - must be top-level function
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('🔔 Background message received: ${message.messageId}');
  debugPrint('📱 Title: ${message.notification?.title}');
  debugPrint('📱 Body: ${message.notification?.body}');
  debugPrint('📱 Data: ${message.data}');

  // Show local notification for background messages
  await FCMService._showBackgroundNotification(message);
}

class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  String? _fcmToken;

  String? get fcmToken => _fcmToken;

  // Initialize local notifications
  static Future<void> _initLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
      macOS: initializationSettingsDarwin,
    );

    await _localNotifications.initialize(initializationSettings);

    // Create notification channel for Android
    if (Platform.isAndroid) {
      await _createNotificationChannel();
    }
  }

  // Create high-priority notification channel for Android
  static Future<void> _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'gohealth_high_importance', // Channel ID
      'GoHealth High Importance Notifications', // Channel name
      description: 'This channel is used for important GoHealth notifications.',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
      enableLights: true,
      showBadge: true,
    );

    final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
        _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.createNotificationChannel(channel);
  }

  // Show background notification
  static Future<void> _showBackgroundNotification(RemoteMessage message) async {
    try {
      // Initialize notifications if not already done
      await _initLocalNotifications();

      final AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'gohealth_high_importance',
        'GoHealth High Importance Notifications',
        channelDescription:
            'This channel is used for important GoHealth notifications.',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        enableLights: true,
        autoCancel: true,
        ongoing: false,
        showWhen: true,
        when: DateTime.now().millisecondsSinceEpoch,
      );

      const DarwinNotificationDetails iOSPlatformChannelSpecifics =
          DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.timeSensitive,
      );

      final NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics,
        macOS: iOSPlatformChannelSpecifics,
      );

      await _localNotifications.show(
        message.notification.hashCode,
        message.notification?.title ?? 'GoHealth',
        message.notification?.body ?? 'You have a new notification',
        platformChannelSpecifics,
        payload: message.data.toString(),
      );
    } catch (e) {
      debugPrint('Error showing background notification: $e');
    }
  }

  Future<void> initialize() async {
    try {
      // Initialize local notifications first
      await _initLocalNotifications();

      // Request enhanced permissions for background notifications
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: true, // Enable critical alerts
        provisional: false,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        // Set background message handler
        FirebaseMessaging.onBackgroundMessage(
            firebaseMessagingBackgroundHandler);

        // Enable auto initialization for better background processing
        await _firebaseMessaging.setAutoInitEnabled(true);

        // Get FCM token
        _fcmToken = await _firebaseMessaging.getToken();
        debugPrint('🔑 FCM Token: $_fcmToken');

        // Listen for token refresh
        _firebaseMessaging.onTokenRefresh.listen((newToken) {
          _fcmToken = newToken;
          debugPrint('🔄 FCM Token Refreshed: $newToken');
        });

        // Set foreground notification presentation options (iOS)
        if (Platform.isIOS) {
          await _firebaseMessaging.setForegroundNotificationPresentationOptions(
            alert: true,
            badge: true,
            sound: true,
          );
        }

        debugPrint('✅ FCM initialized successfully');
      } else {
        debugPrint('❌ FCM permission denied');
      }
    } catch (e) {
      debugPrint('❌ Error initializing FCM: $e');
    }
  }

  Future<bool> requestPermission() async {
    try {
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      return settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    } catch (e) {
      print('Error requesting permission: $e');
      return false;
    }
  }

  Future<bool> areNotificationsEnabled() async {
    try {
      final settings = await _firebaseMessaging.getNotificationSettings();
      return settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    } catch (e) {
      print('Error checking notification status: $e');
      return false;
    }
  }

  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      print('Subscribed to topic: $topic');
    } catch (e) {
      print('Error subscribing to topic $topic: $e');
    }
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      print('Unsubscribed from topic: $topic');
    } catch (e) {
      print('Error unsubscribing from topic $topic: $e');
    }
  }

  void configureFCMListeners({
    Function(RemoteMessage)? onMessage,
    Function(RemoteMessage)? onMessageOpenedApp,
  }) {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('📱 Foreground message received!');
      debugPrint('📱 Message data: ${message.data}');

      if (message.notification != null) {
        debugPrint('📱 Notification: ${message.notification}');
        // Show local notification for foreground messages
        _showForegroundNotification(message);
      }

      onMessage?.call(message);
    });

    // Handle app opened from background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('🚀 App opened from background notification!');
      debugPrint('📱 Message data: ${message.data}');
      onMessageOpenedApp?.call(message);
    });

    // Check for initial message when app is opened from terminated state
    _firebaseMessaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        debugPrint('🚀 App launched from terminated state via notification!');
        debugPrint('📱 Message data: ${message.data}');
        onMessageOpenedApp?.call(message);
      }
    });
  }

  // Show foreground notification
  Future<void> _showForegroundNotification(RemoteMessage message) async {
    try {
      final AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'gohealth_high_importance',
        'GoHealth High Importance Notifications',
        channelDescription:
            'This channel is used for important GoHealth notifications.',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        enableLights: true,
        autoCancel: true,
        ongoing: false,
        showWhen: true,
        when: DateTime.now().millisecondsSinceEpoch,
      );

      const DarwinNotificationDetails iOSPlatformChannelSpecifics =
          DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.active,
      );

      final NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics,
        macOS: iOSPlatformChannelSpecifics,
      );

      await _localNotifications.show(
        message.notification.hashCode,
        message.notification?.title ?? 'GoHealth',
        message.notification?.body ?? 'You have a new notification',
        platformChannelSpecifics,
        payload: message.data.toString(),
      );
    } catch (e) {
      debugPrint('❌ Error showing foreground notification: $e');
    }
  }

  static Future<void> handleBackgroundMessage(RemoteMessage message) async {
    debugPrint('🔔 Handling a background message: ${message.messageId}');
    debugPrint('📱 Message data: ${message.data}');
    debugPrint('📱 Message notification: ${message.notification}');

    // Show local notification for background messages
    await _showBackgroundNotification(message);
  }
}
