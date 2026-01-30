import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import '../models/alert_model.dart';
import '../utils/constants.dart';
import 'database_service.dart';

// Top-level function for background message handling
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Background message received: ${message.messageId}');
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final DatabaseService _databaseService = DatabaseService();

  bool _initialized = false;

  // Initialize notification service
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Request permission
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('Notification permission granted');
      } else {
        debugPrint('Notification permission denied');
        return;
      }

      // Configure local notifications
      await _initializeLocalNotifications();

      // Set up foreground message handler
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Set up background message handler
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // Handle notification taps
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      // Get and save FCM token
      String? token = await _messaging.getToken();
      if (token != null) {
        debugPrint('FCM Token: $token');
        // Token will be saved when user logs in
      }

      // Listen for token refresh
      _messaging.onTokenRefresh.listen((newToken) {
        debugPrint('FCM Token refreshed: $newToken');
        // Save new token to database
      });

      _initialized = true;
      debugPrint('Notification service initialized');
    } catch (e) {
      debugPrint('Error initializing notification service: $e');
    }
  }

  // Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('Notification tapped: ${response.payload}');
      },
    );

    // Create notification channels for Android
    const AndroidNotificationChannel alertChannel = AndroidNotificationChannel(
      AppConstants.alertChannelId,
      AppConstants.alertChannelName,
      description: 'Notifications for fall alerts',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    const AndroidNotificationChannel monitoringChannel = AndroidNotificationChannel(
      AppConstants.monitoringChannelId,
      AppConstants.monitoringChannelName,
      description: 'Ongoing monitoring status',
      importance: Importance.low,
      playSound: false,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(alertChannel);

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(monitoringChannel);
  }

  // Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Foreground message received: ${message.notification?.title}');
    
    if (message.notification != null) {
      showLocalNotification(
        title: message.notification!.title ?? 'Fall Alert',
        body: message.notification!.body ?? 'A fall has been detected',
        payload: message.data.toString(),
      );
    }
  }

  // Handle notification tap
  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('Notification tapped: ${message.data}');
    // Navigate to appropriate screen based on notification data
  }

  // Show local notification
  Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
    bool isHighPriority = true,
  }) async {
    AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      isHighPriority ? AppConstants.alertChannelId : AppConstants.monitoringChannelId,
      isHighPriority ? AppConstants.alertChannelName : AppConstants.monitoringChannelName,
      importance: isHighPriority ? Importance.max : Importance.low,
      priority: isHighPriority ? Priority.high : Priority.low,
      showWhen: true,
      enableVibration: isHighPriority,
      playSound: isHighPriority,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: payload,
    );
  }

  // Show monitoring notification (persistent)
  Future<void> showMonitoringNotification() async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      AppConstants.monitoringChannelId,
      AppConstants.monitoringChannelName,
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      showWhen: false,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      0, // Fixed ID for monitoring notification
      'Fall Detection Active',
      'Monitoring for falls in the background',
      details,
    );
  }

  // Cancel monitoring notification
  Future<void> cancelMonitoringNotification() async {
    await _localNotifications.cancel(0);
  }

  // Send fall alert notification to caregivers
  Future<void> sendFallAlertToCaregivers(
    List<String> caregiverIds,
    AlertModel alert,
  ) async {
    try {
      // Get FCM tokens for caregivers
      List<String> tokens = await _databaseService.getFCMTokens(caregiverIds);

      if (tokens.isEmpty) {
        debugPrint('No FCM tokens found for caregivers');
        return;
      }

      // In a real app, you would send this to a backend server
      // that uses Firebase Admin SDK to send the notification
      // For now, we'll just log it
      debugPrint('Would send fall alert to ${tokens.length} caregivers');
      debugPrint('Alert: ${alert.personName} has fallen at ${alert.timestamp}');
      
      // Note: To actually send push notifications, you need to implement
      // a backend server with Firebase Admin SDK or use Cloud Functions
    } catch (e) {
      debugPrint('Error sending fall alert: $e');
    }
  }

  // Get FCM token for current device
  Future<String?> getToken() async {
    return await _messaging.getToken();
  }

  // Save FCM token for user
  Future<void> saveTokenForUser(String userId) async {
    try {
      String? token = await getToken();
      if (token != null) {
        await _databaseService.saveFCMToken(userId, token);
      }
    } catch (e) {
      debugPrint('Error saving FCM token: $e');
    }
  }
}
