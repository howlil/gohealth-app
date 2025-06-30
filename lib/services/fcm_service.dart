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
import 'package:firebase_core/firebase_core.dart';

// Background message handler - harus di top level
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
    debugPrint('🔔 Background FCM diterima: ${message.notification?.title}');

    // Tampilkan notifikasi untuk background messages
    await FCMService._showBackgroundNotification(message);
  } catch (e) {
    debugPrint('❌ Error handling background message: $e');
  }
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

  static const String _channelId = 'gohealth_main';
  static const String _channelName = 'GoHealth Notifications';
  static const String _channelDescription =
      'Notifikasi utama dari aplikasi GoHealth';

  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('⚠️ FCM sudah diinisialisasi sebelumnya');
      return;
    }

    try {
      debugPrint('🔄 Memulai inisialisasi FCM...');

      // Step 1: Initialize local notifications FIRST
      await _initLocalNotifications();
      debugPrint('✅ Local notifications initialized');

      // Step 2: Request permissions
      await _requestPermissions();
      debugPrint('✅ Permissions requested');

      // Step 3: Setup message listeners
      _setupMessageListeners();
      debugPrint('✅ Message listeners setup');

      // Step 4: Initialize token
      await _initializeToken();
      debugPrint('✅ Token initialized');

      _isInitialized = true;
      debugPrint('🎉 FCM berhasil diinisialisasi!');

      // Test dengan menampilkan notifikasi
      await Future.delayed(const Duration(seconds: 2));
      await showTestNotification();
    } catch (e, stackTrace) {
      debugPrint('❌ Error FCM initialization: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      rethrow;
    }
  }

  static Future<void> _initLocalNotifications() async {
    try {
      debugPrint('🔧 Inisialisasi local notifications...');

      // Android initialization
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('ic_notification');

      // iOS initialization
      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
        requestSoundPermission: true,
        requestBadgePermission: true,
        requestAlertPermission: true,
        defaultPresentAlert: true,
        defaultPresentBadge: true,
        defaultPresentSound: true,
      );

      const InitializationSettings initializationSettings =
          InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );

      final bool? initialized = await _localNotifications.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationResponse,
      );

      debugPrint('✅ Local notifications initialized: $initialized');

      // Create notification channel untuk Android
      if (Platform.isAndroid) {
        await _createNotificationChannel();
        debugPrint('✅ Android notification channel created');
      }
    } catch (e) {
      debugPrint('❌ Error initializing local notifications: $e');
      rethrow;
    }
  }

  static Future<void> _createNotificationChannel() async {
    try {
      final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
          _localNotifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlugin != null) {
        // Create main channel dengan konfigurasi optimal
        const AndroidNotificationChannel channel = AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: _channelDescription,
          importance: Importance.high, // Turunkan dari max ke high
          playSound: true,
          enableVibration: true,
          enableLights: true,
          ledColor: Color(0xFF4CAF50),
          showBadge: true,
        );

        await androidPlugin.createNotificationChannel(channel);
        debugPrint('✅ Notification channel created: $_channelId');

        // Verify channel was created
        final List<AndroidNotificationChannel>? channels =
            await androidPlugin.getNotificationChannels();

        final bool channelExists =
            channels?.any((ch) => ch.id == _channelId) ?? false;
        debugPrint(
            '🔍 Channel verification: $_channelId exists = $channelExists');

        if (channels != null) {
          debugPrint('📱 Available channels:');
          for (var ch in channels) {
            debugPrint(
                '   - ${ch.id}: ${ch.name} (importance: ${ch.importance})');
          }
        }
      } else {
        debugPrint('⚠️ Android plugin not available for notification channel');
      }
    } catch (e) {
      debugPrint('❌ Error creating notification channel: $e');
      rethrow;
    }
  }

  Future<void> _requestPermissions() async {
    try {
      // Request Android notification permissions untuk Android 13+
      if (Platform.isAndroid) {
        final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
            _localNotifications.resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();

        if (androidPlugin != null) {
          final bool? granted =
              await androidPlugin.requestNotificationsPermission();
          debugPrint('📱 Android notification permission: $granted');

          // Check exact alarm permission
          final bool? exactAlarmGranted =
              await androidPlugin.requestExactAlarmsPermission();
          debugPrint('📱 Android exact alarm permission: $exactAlarmGranted');
        }
      }

      // Request FCM permissions
      final NotificationSettings settings =
          await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
        announcement: false,
        carPlay: false,
        criticalAlert: false,
      );

      debugPrint('📱 FCM permission status: ${settings.authorizationStatus}');
      debugPrint('📱 FCM alert setting: ${settings.alert}');
      debugPrint('📱 FCM badge setting: ${settings.badge}');
      debugPrint('📱 FCM sound setting: ${settings.sound}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('✅ FCM permissions granted');
      } else if (settings.authorizationStatus ==
          AuthorizationStatus.provisional) {
        debugPrint('⚠️ FCM permissions granted provisionally');
      } else {
        debugPrint('❌ FCM permissions denied');
      }
    } catch (e) {
      debugPrint('❌ Error requesting permissions: $e');
    }
  }

  Future<void> _initializeToken() async {
    try {
      // Get FCM token
      _fcmToken = await _firebaseMessaging.getToken();

      if (_fcmToken != null) {
        debugPrint('✅ FCM Token obtained: ${_fcmToken!.substring(0, 50)}...');
        debugPrint('📝 Token will be sent to server when user logs in');
        // Don't send token here - wait for explicit call after login
      } else {
        debugPrint('⚠️ FCM Token is null');
      }

      // Listen for token refresh
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        debugPrint('🔄 FCM Token refreshed: ${newToken.substring(0, 20)}...');
        _fcmToken = newToken;

        // Only send refreshed token if user is logged in
        StorageUtil.isLoggedIn().then((isLoggedIn) {
          if (isLoggedIn) {
            debugPrint(
                '🔄 User is logged in, sending refreshed token to server');
            _sendTokenToServer(newToken);
          } else {
            debugPrint('⚠️ User not logged in, skipping refreshed token send');
          }
        });
      });
    } catch (e) {
      debugPrint('❌ Error getting FCM token: $e');
    }
  }

  void _setupMessageListeners() {
    // FOREGROUND messages - app sedang aktif
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint(
          '📱 FOREGROUND message received: ${message.notification?.title}');
      debugPrint('📱 Message data: ${message.data}');
      _showLocalNotification(message);
    });

    // App opened from notification - app di background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint(
          '📱 App opened from notification: ${message.notification?.title}');
      debugPrint('📱 Message data: ${message.data}');
      _handleNotificationTap(message);
    });

    // App launched from notification - app terminated
    _firebaseMessaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        debugPrint(
            '📱 App launched from notification: ${message.notification?.title}');
        debugPrint('📱 Message data: ${message.data}');
        _handleNotificationTap(message);
      }
    });
  }

  // Show notification untuk background messages
  static Future<void> _showBackgroundNotification(RemoteMessage message) async {
    try {
      debugPrint('🔔 Menampilkan background notification...');

      // Initialize local notifications jika belum
      if (!_instance._isInitialized) {
        await _initLocalNotifications();
      }

      // Show notification
      await _showLocalNotification(message);
      debugPrint('✅ Background notification ditampilkan');
    } catch (e) {
      debugPrint('❌ Error showing background notification: $e');
    }
  }

  // Show local notification dengan konfigurasi yang optimal
  static Future<void> _showLocalNotification(RemoteMessage message) async {
    try {
      debugPrint('🔔 Menampilkan local notification...');

      final notification = message.notification;
      if (notification == null) {
        debugPrint('⚠️ No notification payload, creating custom notification');
        // Jika tidak ada notification payload, buat notifikasi dari data
        await _showDataNotification(message);
        return;
      }

      final String title = notification.title ?? 'GoHealth';
      final String body = notification.body ?? 'Anda memiliki notifikasi baru';
      final int notificationId =
          DateTime.now().millisecondsSinceEpoch.remainder(100000);

      debugPrint('📱 Notification details:');
      debugPrint('   Title: $title');
      debugPrint('   Body: $body');
      debugPrint('   ID: $notificationId');

      // Android notification details dengan konfigurasi optimal
      final AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.high, // Turunkan dari max
        priority: Priority.high, // Turunkan dari max
        showWhen: true,
        when: DateTime.now().millisecondsSinceEpoch,
        playSound: true,
        enableVibration: true,
        enableLights: true,
        icon: 'ic_notification',
        color: const Color(0xFF4CAF50),
        ledColor: const Color(0xFF4CAF50),
        autoCancel: true,
        ongoing: false, // Pastikan false agar bisa di-dismiss
        category: AndroidNotificationCategory.message,
        visibility: NotificationVisibility.public,
        styleInformation: BigTextStyleInformation(
          body,
          contentTitle: title,
          summaryText: 'GoHealth',
        ),
        // Tambahan untuk debugging
        ticker: title,
      );

      // iOS notification details
      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'default',
      );

      final NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Show notification
      await _localNotifications.show(
        notificationId,
        title,
        body,
        platformDetails,
        payload: message.data.isNotEmpty
            ? jsonEncode(message.data)
            : jsonEncode({'type': 'default', 'from': 'fcm'}),
      );

      debugPrint('✅ Local notification ditampilkan dengan ID: $notificationId');
    } catch (e) {
      debugPrint('❌ Error showing local notification: $e');
    }
  }

  // Show notification dari data jika tidak ada notification payload
  static Future<void> _showDataNotification(RemoteMessage message) async {
    try {
      final Map<String, dynamic> data = message.data;
      final String title = data['title'] ?? 'GoHealth';
      final String body = data['body'] ?? 'Anda memiliki notifikasi baru';

      debugPrint('📱 Creating notification from data: $title - $body');

      final int notificationId =
          DateTime.now().millisecondsSinceEpoch.remainder(100000);

      final AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        playSound: true,
        enableVibration: true,
        icon: 'ic_notification',
        color: const Color(0xFF4CAF50),
        autoCancel: true,
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.show(
        notificationId,
        title,
        body,
        platformDetails,
        payload: jsonEncode(data),
      );

      debugPrint('✅ Data notification ditampilkan');
    } catch (e) {
      debugPrint('❌ Error showing data notification: $e');
    }
  }

  // Handle notification response
  static void _onNotificationResponse(NotificationResponse response) {
    debugPrint('📱 Notification tapped: ${response.payload}');

    if (response.payload != null) {
      try {
        final Map<String, dynamic> data = jsonDecode(response.payload!);
        _instance._handleNotificationData(data);
      } catch (e) {
        debugPrint('❌ Error parsing notification payload: $e');
      }
    }
  }

  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('📱 Handling notification tap');
    _handleNotificationData(message.data);
  }

  void _handleNotificationData(Map<String, dynamic> data) {
    final String? type = data['type'];
    debugPrint('📱 Notification type: $type');

    // Handle navigation berdasarkan tipe notifikasi
    switch (type) {
      case 'MEAL_REMINDER':
        debugPrint('📱 Navigate to meal screen');
        break;
      case 'GOAL_ACHIEVED':
        debugPrint('📱 Navigate to achievement screen');
        break;
      default:
        debugPrint('📱 Navigate to notifications screen');
        break;
    }
  }

  Future<void> _sendTokenToServer(String token) async {
    try {
      // Add small delay to ensure access token is properly saved after login
      await Future.delayed(const Duration(milliseconds: 500));

      final accessToken = await StorageUtil.getAccessToken();
      if (accessToken == null) {
        debugPrint('⚠️ No access token available, skipping FCM token send');
        return;
      }

      debugPrint('🔄 Sending FCM token to server...');
      debugPrint('📱 Token preview: ${token.substring(0, 20)}...');

      final response = await http
          .put(
            Uri.parse('${EnvConfig.apiBaseUrl}${ApiEndpoints.users}/fcm-token'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $accessToken',
              'Accept': 'application/json',
              'ngrok-skip-browser-warning': 'true',
              'User-Agent': 'GoHealth-Flutter-App/1.0.0',
            },
            body: jsonEncode({
              'fcmToken': token,
              'platform': Platform.operatingSystem,
              'appVersion': '1.0.0',
            }),
          )
          .timeout(const Duration(seconds: 15));

      debugPrint('📊 FCM token send response status: ${response.statusCode}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        debugPrint('✅ FCM token sent to server successfully');
        try {
          final responseData = jsonDecode(response.body);
          if (responseData['message'] != null) {
            debugPrint('📝 Server response: ${responseData['message']}');
          }
        } catch (e) {
          // Ignore JSON parsing errors for response
        }
      } else {
        final errorMessage =
            'Failed to send FCM token - HTTP ${response.statusCode}';
        debugPrint('❌ $errorMessage');
        debugPrint('📥 Response body: ${response.body}');

        // If 401, maybe token is expired - retry once after a delay
        if (response.statusCode == 401) {
          debugPrint(
              '🔄 Access token might be expired, retrying in 2 seconds...');
          await Future.delayed(const Duration(seconds: 2));
          await _retryTokenSend(token);
        }
      }
    } catch (e) {
      debugPrint('❌ Error sending FCM token to server: $e');

      // Retry once if it's a network error
      if (e.toString().contains('TimeoutException') ||
          e.toString().contains('SocketException') ||
          e.toString().contains('ClientException')) {
        debugPrint(
            '🔄 Network error detected, retrying FCM token send in 3 seconds...');
        await Future.delayed(const Duration(seconds: 3));
        await _retryTokenSend(token);
      }
    }
  }

  Future<void> _retryTokenSend(String token) async {
    try {
      debugPrint('🔄 Retrying FCM token send...');

      final accessToken = await StorageUtil.getAccessToken();
      if (accessToken == null) {
        debugPrint('⚠️ Still no access token available for retry');
        return;
      }

      final response = await http
          .put(
            Uri.parse('${EnvConfig.apiBaseUrl}${ApiEndpoints.users}/fcm-token'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $accessToken',
              'Accept': 'application/json',
              'ngrok-skip-browser-warning': 'true',
              'User-Agent': 'GoHealth-Flutter-App/1.0.0',
            },
            body: jsonEncode({
              'fcmToken': token,
              'platform': Platform.operatingSystem,
              'appVersion': '1.0.0',
            }),
          )
          .timeout(const Duration(seconds: 15));

      debugPrint('📊 FCM token retry response status: ${response.statusCode}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        debugPrint('✅ FCM token sent to server successfully on retry');
      } else {
        debugPrint('❌ FCM token send failed on retry: ${response.statusCode}');
        debugPrint('📥 Retry response body: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ FCM token retry also failed: $e');
    }
  }

  Future<void> sendTokenToServer() async {
    if (_fcmToken != null) {
      debugPrint('📱 Public sendTokenToServer called');
      await _sendTokenToServer(_fcmToken!);
    } else {
      debugPrint('⚠️ FCM token is null, cannot send to server');
    }
  }

  Future<bool> areNotificationsEnabled() async {
    try {
      if (Platform.isAndroid) {
        final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
            _localNotifications.resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();

        if (androidPlugin != null) {
          final bool? enabled = await androidPlugin.areNotificationsEnabled();
          debugPrint('📱 Android notifications enabled: $enabled');
          return enabled ?? false;
        }
      }

      final NotificationSettings settings =
          await _firebaseMessaging.getNotificationSettings();
      final bool isEnabled =
          settings.authorizationStatus == AuthorizationStatus.authorized;
      debugPrint('📱 FCM notifications enabled: $isEnabled');
      return isEnabled;
    } catch (e) {
      debugPrint('❌ Error checking notification permissions: $e');
      return false;
    }
  }

  // Method untuk test notification lokal
  Future<void> showTestNotification() async {
    try {
      debugPrint('🧪 Menampilkan test notification...');

      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: 'Test notification dari GoHealth',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        playSound: true,
        enableVibration: true,
        enableLights: true,
        icon: 'ic_notification',
        color: Color(0xFF4CAF50),
        ledColor: Color(0xFF4CAF50),
        autoCancel: true,
        styleInformation: BigTextStyleInformation(
          'Jika Anda melihat notifikasi ini, berarti konfigurasi FCM sudah benar! Sekarang notifikasi dari server juga akan muncul.',
          contentTitle: 'Test Notification GoHealth',
          summaryText: 'GoHealth',
        ),
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.show(
        99999, // ID khusus untuk test
        'Test Notification GoHealth',
        'FCM Configuration Test Success! 🎉',
        platformDetails,
        payload: jsonEncode({'type': 'TEST', 'message': 'Test notification'}),
      );

      debugPrint('✅ Test notification berhasil ditampilkan');
    } catch (e) {
      debugPrint('❌ Error showing test notification: $e');
    }
  }

  // Method untuk mendapatkan status lengkap FCM
  Future<Map<String, dynamic>> getFCMStatus() async {
    try {
      final notificationsEnabled = await areNotificationsEnabled();
      final settings = await _firebaseMessaging.getNotificationSettings();

      return {
        'isInitialized': _isInitialized,
        'hasToken': _fcmToken != null,
        'tokenLength': _fcmToken?.length ?? 0,
        'tokenPreview':
            _fcmToken != null ? '${_fcmToken!.substring(0, 20)}...' : null,
        'notificationsEnabled': notificationsEnabled,
        'authorizationStatus': settings.authorizationStatus.toString(),
        'alert': settings.alert.toString(),
        'badge': settings.badge.toString(),
        'sound': settings.sound.toString(),
      };
    } catch (e) {
      debugPrint('❌ Error getting FCM status: $e');
      return {'error': e.toString()};
    }
  }

  // Method untuk debug dan troubleshooting FCM
  Future<void> debugFCM() async {
    debugPrint('🔍 === FCM DEBUG INFO ===');

    final status = await getFCMStatus();
    for (final entry in status.entries) {
      debugPrint('🔍 ${entry.key}: ${entry.value}');
    }

    debugPrint('🔍 === END FCM DEBUG ===');
  }

  // Method untuk reset dan reinitialize FCM
  Future<void> resetFCM() async {
    try {
      debugPrint('🔄 Resetting FCM...');

      _isInitialized = false;
      _fcmToken = null;

      await initialize();

      debugPrint('✅ FCM reset completed');
    } catch (e) {
      debugPrint('❌ Error resetting FCM: $e');
    }
  }
}
