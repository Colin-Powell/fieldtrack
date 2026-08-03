import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:fieldtrack/core/network/api_client.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../constants/app_constants.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('[FCM] Background message received: ${message.messageId}');
  debugPrint(
    '[FCM] Background payload: title=${message.notification?.title}, body=${message.notification?.body}, data=${message.data}',
  );
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

      NotificationSettings settings = await _firebaseMessaging
          .requestPermission(
            alert: true,
            badge: true,
            sound: true,
            provisional: false,
          );

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        await _firebaseMessaging.setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
        // Initialize local notifications
        const AndroidInitializationSettings initializationSettingsAndroid =
            AndroidInitializationSettings('@mipmap/ic_launcher');

        final InitializationSettings initializationSettings =
            InitializationSettings(
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
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
            ?.createNotificationChannel(channel);

        // Get FCM Token
        String? token = await _firebaseMessaging.getToken();
        if (token != null) {
          await syncTokenWithBackend(token, auth: false);
        }

        // Listen for token refresh
        _firebaseMessaging.onTokenRefresh.listen((newToken) async {
          await syncTokenWithBackend(newToken, force: true, auth: false);
        });

        // Listen for foreground messages
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          final notification = message.notification;
          final android = notification?.android;
          final title =
              notification?.title ??
              message.data['title'] ??
              'New notification';
          final body =
              notification?.body ??
              message.data['body'] ??
              'You have a new update';

          if (notification != null && android != null) {
            _localNotificationsPlugin.show(
              id: notification.hashCode,
              title: title,
              body: body,
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
          } else {
            _localNotificationsPlugin.show(
              id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
              title: title,
              body: body,
              notificationDetails: NotificationDetails(
                android: AndroidNotificationDetails(
                  channel.id,
                  channel.name,
                  channelDescription: channel.description,
                  icon: '@mipmap/ic_launcher',
                  importance: Importance.max,
                  priority: Priority.high,
                ),
              ),
            );
          }
        });

        FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler,
        );

        _initialized = true;
      }
    } catch (e) {
      debugPrint('FCM Init Error: $e');
    }
  }

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  Future<bool> _sendTokenToBackend(String token) async {
    try {
      final headers = <String, String>{'Content-Type': 'application/json'};

      // Always try to include JWT for user association
      final jwtToken = await _secureStorage.read(key: 'jwt_token');
      if (jwtToken != null && jwtToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $jwtToken';
      }

      final directDio = Dio(
        BaseOptions(baseUrl: AppConstants.apiUrl, headers: headers),
      );

      final response = await directDio.put('/fcm-token', data: {'fcmToken': token});
      final linked = response.data?['linked'] == true;
      if (!linked) {
        debugPrint('⚠ FCM token sent but NOT linked to user (no valid auth)');
      }
      return linked;
    } catch (e) {
      debugPrint('⚠ Failed to send FCM token to backend: $e');
      rethrow;
    }
  }

  Future<void> syncTokenWithBackend(
    String token, {
    bool force = false,
    bool auth = false, // kept for API compatibility but no longer used
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final previousToken = prefs.getString('fcm_token');

      if (!force && previousToken == token) {
        return;
      }

      final linked = await _sendTokenToBackend(token);

      await prefs.setString('fcm_token', token);
      if (linked) {
        debugPrint('✓ FCM token synced and linked to user${force ? ' (forced)' : ''}');
      } else {
        debugPrint('⚠ FCM token synced but NOT linked — will retry after login');
      }
    } catch (e) {
      debugPrint('⚠ Failed to sync FCM token: $e');
    }
  }
}
