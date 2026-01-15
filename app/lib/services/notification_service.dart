import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class NotificationService {
  static const String baseUrl = 'https://manga-api.intern.phudevelopement.xyz';

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  /// Initialize notification service
  Future<void> initialize() async {
    // Request notification permissions
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      if (kDebugMode) {
        print('User granted notification permission');
      }
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      if (kDebugMode) {
        print('User granted provisional notification permission');
      }
    } else {
      if (kDebugMode) {
        print('User declined or has not accepted notification permission');
      }
    }

    // Initialize local notifications
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channel for Android
    const androidChannel = AndroidNotificationChannel(
      'manga_activity_channel',
      'Manga-Aktivitäten',
      description: 'Benachrichtigungen über Änderungen in der Manga-Sammlung',
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle notification taps
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Check if app was opened from notification
    RemoteMessage? initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }
  }

  /// Get FCM token
  Future<String?> getToken() async {
    try {
      return await _messaging.getToken();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting FCM token: $e');
      }
      return null;
    }
  }

  /// Register device token with backend
  Future<void> registerToken(String authToken) async {
    try {
      final fcmToken = await getToken();
      if (fcmToken == null) {
        if (kDebugMode) {
          print('No FCM token available');
        }
        return;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/device-token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode({
          'token': fcmToken,
          'deviceType': 'android',
          'deviceName': 'Android Device',
        }),
      );

      if (response.statusCode == 200) {
        if (kDebugMode) {
          print('Device token registered successfully');
        }
      } else {
        if (kDebugMode) {
          print('Failed to register device token: ${response.statusCode}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error registering device token: $e');
      }
    }
  }

  /// Unregister device token
  Future<void> unregisterToken(String authToken) async {
    try {
      final fcmToken = await getToken();
      if (fcmToken == null) return;

      final response = await http.delete(
        Uri.parse('$baseUrl/api/auth/device-token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode({
          'token': fcmToken,
        }),
      );

      if (response.statusCode == 200) {
        if (kDebugMode) {
          print('Device token unregistered successfully');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error unregistering device token: $e');
      }
    }
  }

  /// Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    if (kDebugMode) {
      print('Foreground message received: ${message.notification?.title}');
    }

    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null) {
      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'manga_activity_channel',
            'Manga-Aktivitäten',
            channelDescription: 'Benachrichtigungen über Änderungen in der Manga-Sammlung',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
        ),
        payload: jsonEncode(message.data),
      );
    }
  }

  /// Handle notification tap
  void _handleNotificationTap(RemoteMessage message) {
    if (kDebugMode) {
      print('Notification tapped: ${message.data}');
    }

    // Navigate to manga detail if manga_id is present
    if (message.data.containsKey('manga_id')) {
      // TODO: Navigate to manga detail screen
      // This would require a navigation service or global key
    }
  }

  /// Handle local notification tap
  void _onNotificationTapped(NotificationResponse response) {
    if (response.payload != null) {
      final data = jsonDecode(response.payload!);
      if (kDebugMode) {
        print('Local notification tapped: $data');
      }
      // TODO: Navigate to manga detail
    }
  }

  /// Listen to token refresh
  void onTokenRefresh(Function(String) callback) {
    _messaging.onTokenRefresh.listen((newToken) {
      callback(newToken);
    });
  }
}
