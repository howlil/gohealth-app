import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/env_config.dart';
import '../utils/api_endpoints.dart';
import '../utils/storage_util.dart';

// SINGLE background message handler - must be top-level function
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('📱 FCM Background Message: ${message.messageId}');
  debugPrint('📱 FCM Background Title: ${message.notification?.title}');
  debugPrint('📱 FCM Background Body: ${message.notification?.body}');

  // Show local notification for background messages
  await FCMService._showLocalNotification(message, isBackground: true);
}

class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  String? _fcmToken;
  bool _isInitialized = false;

  String? get fcmToken => _fcmToken;
  bool get isInitialized => _isInitialized;

  // UNIFIED CHANNEL CONFIGURATION
  static const String _channelId = 'gohealth_notifications';
  static const String _channelName = 'GoHealth Notifications';
  static const String _channelDescription = 'All GoHealth app notifications';

  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('📱 FCM already initialized, skipping...');
      return;
    }

    debugPrint('📱 FCM Starting initialization...');

    try {
      // Step 1: Initialize local notifications FIRST
      debugPrint('📱 FCM Step 1: Initializing local notifications...');
      await _initLocalNotifications();

      // Step 2: Request permissions with enhanced settings
      debugPrint('📱 FCM Step 2: Requesting permissions...');
      await _requestEnhancedPermissions();

      // Step 3: Configure FCM settings
      debugPrint('📱 FCM Step 3: Configuring FCM settings...');
      await _configureFCMSettings();

      // Step 4: Get and manage FCM token
      debugPrint('📱 FCM Step 4: Getting FCM token...');
      await _initializeToken();

      // Step 5: Setup message listeners
      debugPrint('📱 FCM Step 5: Setting up message listeners...');
      _setupMessageListeners();

      _isInitialized = true;
      debugPrint('📱 FCM Initialization completed successfully!');

      // Test notification after initialization
      await _testNotification();
    } catch (e) {
      debugPrint('📱 FCM Initialization error: $e');
      // Don't rethrow to prevent app crash
    }
  }

  // Test notification to verify setup
  Future<void> _testNotification() async {
    try {
      await Future.delayed(const Duration(seconds: 2));

      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.max,
        priority: Priority.max,
        playSound: true,
        enableVibration: true,
        enableLights: true,
        autoCancel: true,
        icon: '@mipmap/ic_launcher',
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.timeSensitive,
      );

      const NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
        macOS: iosDetails,
      );

      await _localNotifications.show(
        999999, // Test notification ID
        '🎉 GoHealth Ready!',
        'Notifications are working properly',
        platformDetails,
      );

      debugPrint('📱 FCM Test notification sent successfully!');
    } catch (e) {
      debugPrint('📱 FCM Test notification error: $e');
    }
  }

  // Initialize local notifications with proper channel
  static Future<void> _initLocalNotifications() async {
    try {
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings initializationSettingsDarwin =
          DarwinInitializationSettings(
        requestSoundPermission: true,
        requestBadgePermission: true,
        requestAlertPermission: true,
        defaultPresentAlert: true,
        defaultPresentSound: true,
        defaultPresentBadge: true,
      );

      const InitializationSettings initializationSettings =
          InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsDarwin,
        macOS: initializationSettingsDarwin,
      );

      final bool? initialized = await _localNotifications.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          debugPrint('📱 Local notification tapped: ${response.payload}');
        },
      );

      debugPrint('📱 Local notifications initialized: $initialized');

      // Create notification channel for Android
      if (Platform.isAndroid) {
        await _createNotificationChannel();
      }
    } catch (e) {
      debugPrint('📱 Local notification init error: $e');
      rethrow;
    }
  }

  // Create HIGH PRIORITY notification channel
  static Future<void> _createNotificationChannel() async {
    try {
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDescription,
        importance: Importance.max, // MAXIMUM importance
        playSound: true,
        enableVibration: true,
        enableLights: true,
        showBadge: true,
        sound: RawResourceAndroidNotificationSound('notification'),
      );

      final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
          _localNotifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlugin != null) {
        await androidPlugin.createNotificationChannel(channel);
        debugPrint('📱 Android notification channel created successfully');
      } else {
        debugPrint('📱 Android plugin not available');
      }
    } catch (e) {
      debugPrint('📱 Error creating notification channel: $e');
      rethrow;
    }
  }

  // Request enhanced permissions
  Future<void> _requestEnhancedPermissions() async {
    try {
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: true,
        provisional: false,
        sound: true,
      );

      debugPrint('📱 FCM Permission status: ${settings.authorizationStatus}');
      debugPrint('📱 FCM Alert permission: ${settings.alert}');
      debugPrint('📱 FCM Sound permission: ${settings.sound}');
      debugPrint('📱 FCM Badge permission: ${settings.badge}');

      if (settings.authorizationStatus != AuthorizationStatus.authorized &&
          settings.authorizationStatus != AuthorizationStatus.provisional) {
        throw Exception(
            'FCM permissions denied - Status: ${settings.authorizationStatus}');
      }

      // Additional permission check for Android
      if (Platform.isAndroid) {
        final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
            _localNotifications.resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();

        if (androidPlugin != null) {
          final bool? permissionGranted =
              await androidPlugin.requestNotificationsPermission();
          debugPrint(
              '📱 Android local notification permission: $permissionGranted');
        }
      }
    } catch (e) {
      debugPrint('📱 Error requesting permissions: $e');
      rethrow;
    }
  }

  // Configure FCM settings
  Future<void> _configureFCMSettings() async {
    try {
      // Enable auto initialization
      await _firebaseMessaging.setAutoInitEnabled(true);
      debugPrint('📱 FCM auto-init enabled');

      // Set foreground notification presentation options (iOS)
      if (Platform.isIOS) {
        await _firebaseMessaging.setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
        debugPrint('📱 iOS foreground options set');
      }
    } catch (e) {
      debugPrint('📱 Error configuring FCM: $e');
      rethrow;
    }
  }

  // Initialize and manage FCM token
  Future<void> _initializeToken() async {
    try {
      _fcmToken = await _firebaseMessaging.getToken();
      debugPrint('📱 FCM Token received: ${_fcmToken?.substring(0, 20)}...');

      if (_fcmToken != null) {
        await _sendTokenToServer(_fcmToken!);
      } else {
        debugPrint('📱 FCM Token is null - retrying...');
        // Retry after delay
        await Future.delayed(const Duration(seconds: 2));
        _fcmToken = await _firebaseMessaging.getToken();
        if (_fcmToken != null) {
          await _sendTokenToServer(_fcmToken!);
        }
      }

      // Listen for token refresh
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        debugPrint('📱 FCM Token refreshed: ${newToken.substring(0, 20)}...');
        _fcmToken = newToken;
        _sendTokenToServer(newToken).catchError((error) {
          debugPrint('📱 Error sending refreshed token: $error');
        });
      });
    } catch (e) {
      debugPrint('📱 Error initializing FCM token: $e');
      // Don't rethrow - token might be available later
    }
  }

  // Setup message listeners
  void _setupMessageListeners() {
    debugPrint('📱 Setting up FCM message listeners...');

    // FOREGROUND messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('📱 FCM Foreground Message received:');
      debugPrint('📱   - Message ID: ${message.messageId}');
      debugPrint('📱   - Title: ${message.notification?.title}');
      debugPrint('📱   - Body: ${message.notification?.body}');
      debugPrint('📱   - Data: ${message.data}');

      _handleForegroundMessage(message);
    });

    // BACKGROUND to FOREGROUND (app opened from notification)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('📱 FCM Message opened app:');
      debugPrint('📱   - Message ID: ${message.messageId}');
      debugPrint('📱   - Title: ${message.notification?.title}');

      _handleMessageTap(message);
    });

    // TERMINATED to FOREGROUND (app launched from notification)
    _firebaseMessaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        debugPrint('📱 FCM Initial message (app launched):');
        debugPrint('📱   - Message ID: ${message.messageId}');
        debugPrint('📱   - Title: ${message.notification?.title}');

        _handleMessageTap(message);
      }
    });

    debugPrint('📱 FCM Message listeners set up successfully');
  }

  // Handle foreground messages
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('📱 Handling foreground message...');

    if (message.notification != null) {
      await _showLocalNotification(message, isBackground: false);
    } else {
      debugPrint('📱 No notification payload in message');
    }
  }

  // Handle message tap (navigation)
  void _handleMessageTap(RemoteMessage message) {
    debugPrint('📱 Handling message tap...');

    // TODO: Add navigation logic based on message.data
    // Example:
    // if (message.data['type'] == 'health_reminder') {
    //   // Navigate to health screen
    // }

    // For now, just show a simple feedback
    HapticFeedback.lightImpact();
  }

  // UNIFIED local notification display
  static Future<void> _showLocalNotification(RemoteMessage message,
      {required bool isBackground}) async {
    try {
      debugPrint(
          '📱 Showing local notification (background: $isBackground)...');

      final notification = message.notification;
      if (notification == null) {
        debugPrint('📱 No notification payload to show');
        return;
      }

      // Generate unique notification ID
      final int notificationId =
          DateTime.now().millisecondsSinceEpoch.remainder(100000);

      final AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.max,
        priority: Priority.max,
        playSound: true,
        enableVibration: true,
        enableLights: true,
        autoCancel: true,
        ongoing: false,
        showWhen: true,
        when: DateTime.now().millisecondsSinceEpoch,
        icon: '@mipmap/ic_launcher',
        largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        styleInformation: BigTextStyleInformation(
          notification.body ?? 'You have a new notification',
          contentTitle: notification.title ?? 'GoHealth',
          summaryText: 'GoHealth',
        ),
        category: AndroidNotificationCategory.message,
        visibility: NotificationVisibility.public,
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.timeSensitive,
        threadIdentifier: 'gohealth',
      );

      final NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
        macOS: iosDetails,
      );

      await _localNotifications.show(
        notificationId,
        notification.title ?? 'GoHealth',
        notification.body ?? 'You have a new notification',
        platformDetails,
        payload: jsonEncode({
          ...message.data,
          'messageId': message.messageId,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );

      debugPrint(
          '📱 Local notification shown successfully (ID: $notificationId)');
    } catch (e) {
      debugPrint('📱 Error showing local notification: $e');
    }
  }

  // Send token to server
  Future<void> _sendTokenToServer(String token) async {
    try {
      final accessToken = await StorageUtil.getAccessToken();
      if (accessToken == null) {
        debugPrint('📱 FCM: No access token available, skipping token send');
        return;
      }

      debugPrint('📱 FCM: Sending token to server...');

      final response = await http
          .put(
            Uri.parse('${EnvConfig.apiBaseUrl}${ApiEndpoints.users}/fcm-token'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $accessToken',
            },
            body: jsonEncode({
              'fcmToken': token,
              'platform': Platform.operatingSystem,
              'deviceInfo': {
                'platform': Platform.operatingSystem,
                'timestamp': DateTime.now().toIso8601String(),
                'appVersion': '1.0.0',
              },
            }),
          )
          .timeout(const Duration(seconds: 10));

      debugPrint('📱 FCM: Token send response status: ${response.statusCode}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        debugPrint('📱 FCM: Token sent successfully to server');
      } else {
        debugPrint(
            '📱 FCM: Failed to send token - Status: ${response.statusCode}');
        debugPrint('📱 FCM: Response body: ${response.body}');
      }
    } catch (e) {
      debugPrint('📱 FCM: Error sending token to server: $e');
    }
  }

  // Public method to send token to server (called after login)
  Future<void> sendTokenToServer() async {
    if (_fcmToken != null) {
      await _sendTokenToServer(_fcmToken!);
    } else {
      debugPrint('📱 FCM: No token available to send to server');
    }
  }

  // Topic subscription methods
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      debugPrint('📱 FCM: Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('📱 FCM: Error subscribing to topic $topic: $e');
    }
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      debugPrint('📱 FCM: Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('📱 FCM: Error unsubscribing from topic $topic: $e');
    }
  }

  // Check notification permissions
  Future<bool> areNotificationsEnabled() async {
    try {
      final settings = await _firebaseMessaging.getNotificationSettings();
      final isEnabled =
          settings.authorizationStatus == AuthorizationStatus.authorized ||
              settings.authorizationStatus == AuthorizationStatus.provisional;

      debugPrint('📱 FCM: Notifications enabled: $isEnabled');
      return isEnabled;
    } catch (e) {
      debugPrint('📱 FCM: Error checking notification permissions: $e');
      return false;
    }
  }

  // Manual test notification
  Future<void> sendTestNotification() async {
    try {
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.max,
        priority: Priority.max,
        playSound: true,
        enableVibration: true,
        icon: '@mipmap/ic_launcher',
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
        macOS: iosDetails,
      );

      await _localNotifications.show(
        DateTime.now().millisecondsSinceEpoch.remainder(100000),
        '🧪 Test Notification',
        'This is a manual test notification from GoHealth app',
        platformDetails,
      );

      debugPrint('📱 FCM: Manual test notification sent');
    } catch (e) {
      debugPrint('📱 FCM: Error sending test notification: $e');
    }
  }

  // Get debug info
  Map<String, dynamic> getDebugInfo() {
    return {
      'isInitialized': _isInitialized,
      'hasToken': _fcmToken != null,
      'tokenPreview': _fcmToken?.substring(0, 20),
      'platform': Platform.operatingSystem,
      'channelId': _channelId,
      'channelName': _channelName,
    };
  }
}
