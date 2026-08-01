import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:fieldtrack/core/network/api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    try {
      if (kIsWeb) return; 

      // Request permission
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        // Initialize local notifications
        const AndroidInitializationSettings initializationSettingsAndroid =
            AndroidInitializationSettings('@mipmap/ic_launcher');
        
        final InitializationSettings initializationSettings = InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: const DarwinInitializationSettings(),
        );

        await _localNotificationsPlugin.initialize(
          settings: initializationSettings,
          onDidReceiveNotificationResponse: (details) {
            // Handle notification tap
          },
        );

        // Configure Android channel
        const AndroidNotificationChannel channel = AndroidNotificationChannel(
          'high_importance_channel', // id
          'High Importance Notifications', // title
          description: 'This channel is used for important notifications.',
          importance: Importance.max,
        );

        await _localNotificationsPlugin
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(channel);

        // Get FCM Token
        String? token = await _firebaseMessaging.getToken();
        if (token != null) {
          await syncTokenWithBackend(token);
        }

        // Listen for token refresh
        _firebaseMessaging.onTokenRefresh.listen((newToken) {
          syncTokenWithBackend(newToken);
        });

        // Listen for foreground messages
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          RemoteNotification? notification = message.notification;
          AndroidNotification? android = message.notification?.android;

          if (notification != null && android != null) {
            _localNotificationsPlugin.show(
              id: notification.hashCode,
              title: notification.title,
              body: notification.body,
              notificationDetails: NotificationDetails(
                android: AndroidNotificationDetails(
                  channel.id,
                  channel.name,
                  channelDescription: channel.description,
                  icon: android.smallIcon ?? '@mipmap/ic_launcher',
                  importance: Importance.max,
                  priority: Priority.high,
                ),
              ),
            );
          }
        });

        FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

        _initialized = true;
      }
    } catch (e) {
      debugPrint('FCM Init Error: $e');
    }
  }

  Future<void> syncTokenWithBackend(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedToken = prefs.getString('fcm_token');
      
      // Sync logic here
      final api = ApiClient();
      await api.dio.put('/auth/fcm-token', data: {'fcmToken': token});
      
      await prefs.setString('fcm_token', token);
    } catch (e) {
      debugPrint('Failed to sync FCM token: $e');
    }
  }
}
