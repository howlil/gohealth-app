import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import './fcm_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../utils/env_config.dart';
import '../utils/api_endpoints.dart';
import '../utils/storage_util.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await NotificationManager.instance.setupFlutterNotifications();
  await NotificationManager.instance.showNotification(message);
}

class NotificationManager {
  NotificationManager._();
  static final NotificationManager instance = NotificationManager._();

  final _messaging = FirebaseMessaging.instance;
  final _localNotifications = FlutterLocalNotificationsPlugin();
  bool _isFlutterLocalNotificationsInitialized = false;
  String? _fcmToken;

  String? get fcmToken => _fcmToken;

  Future<void> initialize() async {
    try {
      // Set up background message handler - this enables receiving notifications
      // even when the app is closed or phone is in sleep mode
      FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler);

      // Request enhanced permissions including background notifications
      await _requestPermission();

      // Setup local notifications for showing notifications when app is closed
      await setupFlutterNotifications();

      // Setup message handlers for different app states
      await _setupMessageHandlers();

      // Initialize FCM token and send to server
      await _initializeToken();

      // Listen for token refresh and update server
      _messaging.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        _updateTokenOnServer(newToken).catchError((error) {
          debugPrint('Error updating refreshed token on server: $error');
        });
      });
    } catch (e) {
      print('❌ Error initializing NotificationManager: $e');
      if (e.toString().contains('SERVICE_NOT_AVAILABLE')) {
        print(
            '⚠️ Google Play Services not available. Running on emulator or device without Google Play?');
      }
    }
  }

  Future<void> _initializeToken() async {
    try {
      _fcmToken = await _messaging.getToken();
      if (_fcmToken != null) {
        print('FCM Token: $_fcmToken');
        await _updateTokenOnServer(_fcmToken!);
      }
    } catch (e) {
      print('Error getting FCM token: $e');
    }
  }

  Future<void> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    print('Permission status: ${settings.authorizationStatus}');
  }

  Future<void> setupFlutterNotifications() async {
    if (_isFlutterLocalNotificationsInitialized) return;

    const channel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'This channel is used for important notifications.',
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    const initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettingsDarwin = DarwinInitializationSettings();

    final initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse:
          (NotificationResponse notificationResponse) {
        _handleNotificationTap(notificationResponse.payload);
      },
    );

    _isFlutterLocalNotificationsInitialized = true;
  }

  Future<void> showNotification(RemoteMessage message) async {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && !kIsWeb) {
      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            channelDescription:
                'This channel is used for important notifications.',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: jsonEncode(message.data),
      );
    }
  }

  Future<void> _setupMessageHandlers() async {
    FirebaseMessaging.onMessage.listen((message) {
      print('Got a message whilst in the foreground!');
      print('Message data: ${message.data}');

      if (message.notification != null) {
        print('Message also contained a notification: ${message.notification}');
      }

      showNotification(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleBackgroundMessage(initialMessage);
    }
  }

  void _handleBackgroundMessage(RemoteMessage message) {
    print('Handling background message: ${message.messageId}');

    if (message.data['type'] == 'chat') {
      // Navigate to chat screen
    } else if (message.data['type'] == 'health_reminder') {
      // Navigate to health tracking screen
    }
    // Add more navigation logic based on notification type
  }

  void _handleNotificationTap(String? payload) {
    if (payload != null) {
      final data = jsonDecode(payload) as Map<String, dynamic>;
      print('Notification tapped with payload: $data');

      // Handle navigation based on payload data
      if (data['type'] == 'chat') {
        // Navigate to chat screen
      } else if (data['type'] == 'health_reminder') {
        // Navigate to health tracking screen
      }
    }
  }

  Future<void> _updateTokenOnServer(String token) async {
    try {
      final accessToken = await StorageUtil.getAccessToken();

      if (accessToken == null) {
        print('No access token available, skipping FCM token update');
        return;
      }

      print('Sending FCM token to server: $token');

      final response = await http.put(
        Uri.parse('${EnvConfig.apiBaseUrl}${ApiEndpoints.users}/fcm-token'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({
          'fcmToken': token,
          'platform': kIsWeb ? 'web' : Platform.operatingSystem,
          'deviceInfo': await _getDeviceInfo(),
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          print('FCM token successfully sent to server');
        } else {
          print('Server rejected FCM token: ${responseData['message']}');
        }
      } else {
        print('Failed to send FCM token. Status: ${response.statusCode}');
        print('Response: ${response.body}');
      }
    } catch (e) {
      print('Error sending FCM token to server: $e');
    }
  }

  Future<Map<String, dynamic>> _getDeviceInfo() async {
    final deviceInfo = <String, dynamic>{};

    try {
      deviceInfo['platform'] = kIsWeb ? 'web' : Platform.operatingSystem;
      deviceInfo['timestamp'] = DateTime.now().toIso8601String();
    } catch (e) {
      print('Error getting device info: $e');
    }

    return deviceInfo;
  }

  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      print('Subscribed to topic: $topic');
    } catch (e) {
      print('Error subscribing to topic $topic: $e');
    }
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      print('Unsubscribed from topic: $topic');
    } catch (e) {
      print('Error unsubscribing from topic $topic: $e');
    }
  }

  /// Send current FCM token to server (can be called after login)
  Future<void> sendTokenToServer() async {
    if (_fcmToken != null) {
      await _updateTokenOnServer(_fcmToken!);
    } else {
      print('No FCM token available to send to server');
    }
  }
}
