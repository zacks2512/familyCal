import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;
// TODO: Re-enable after fixing compatibility issue
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Top-level handler for background notifications
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('📬 Background notification: ${message.notification?.title}');
}

/// Service for handling push notifications via FCM
class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  final FlutterLocalNotificationsPlugin _localNotifications = 
      FlutterLocalNotificationsPlugin();
  
  // Callbacks for notification taps
  Function(String eventId)? onEventAssignedTap;
  Function(String familyId)? onUnassignedAlertTap;
  Function(String eventId)? onEventConfirmedTap;
  
  /// Initialize notification service
  Future<void> initialize() async {
    // Set background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    
    // Request permission
    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    
    debugPrint('📱 Notification permission: ${settings.authorizationStatus}');
    
    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      
      // Initialize local notifications for foreground display
      await _initializeLocalNotifications();
      
      // Get and save FCM token
      final token = await _fcm.getToken();
      if (token != null) {
        await _saveFcmToken(token);
      }
      
      // Listen to token refresh
      _fcm.onTokenRefresh.listen(_saveFcmToken);
      
      // Handle foreground notifications
      FirebaseMessaging.onMessage.listen(_handleForegroundNotification);
      
      // Handle notification tap (app opened from notification)
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
      
      // Check if app was opened from a notification
      final initialMessage = await _fcm.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationTap(initialMessage);
      }
    }
  }
  
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );
    
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) {
        if (response.payload != null) {
          _handleLocalNotificationTap(response.payload!);
        }
      },
    );
    
    // Create notification channels for Android
    if (Platform.isAndroid) {
      await _createNotificationChannels();
    }
  }
  
  Future<void> _createNotificationChannels() async {
    final androidPlugin = _localNotifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidPlugin != null) {
      // Assignment notifications channel
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'assignments',
          'Assignment Notifications',
          description: 'Notifications when events are assigned to you',
          importance: Importance.high,
          playSound: true,
        ),
      );
      
      // Confirmation notifications channel
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'confirmations',
          'Confirmation Notifications',
          description: 'Notifications when family members confirm events',
          importance: Importance.defaultImportance,
          playSound: true,
        ),
      );
      
      // Alert notifications channel (unassigned events)
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'alerts',
          'Alert Notifications',
          description: 'Alerts for unassigned events and important updates',
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
        ),
      );
    }
  }
  
  Future<void> _saveFcmToken(String token) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;
    
    try {
      final deviceId = Platform.isAndroid ? 'android_device' : 'ios_device';
      
      await _firestore
        .collection('users')
        .doc(userId)
        .set({
          'fcm_tokens': {
            deviceId: {
              'token': token,
              'platform': Platform.operatingSystem,
              'last_seen': FieldValue.serverTimestamp(),
            }
          }
        }, SetOptions(merge: true));
      
      debugPrint('✅ Saved FCM token');
    } catch (e) {
      debugPrint('❌ Failed to save FCM token: $e');
    }
  }
  
  void _handleForegroundNotification(RemoteMessage message) {
    debugPrint('📬 Foreground notification: ${message.notification?.title}');
    
    // Show local notification
    _showLocalNotification(message);
    
    // Handle different notification types
    final type = message.data['type'] as String?;
    
    switch (type) {
      case 'event_assigned':
        _handleEventAssigned(message.data);
        break;
      case 'unassigned_events_alert':
        _handleUnassignedAlert(message.data);
        break;
      case 'event_confirmed':
        _handleEventConfirmed(message.data);
        break;
      case 'event_updated':
        _handleEventUpdated(message.data);
        break;
      case 'event_deleted':
        _handleEventDeleted(message.data);
        break;
      case 'calendar_removal':
        _handleCalendarRemoval(message.data);
        break;
    }
  }
  
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;
    
    final type = message.data['type'] as String?;
    String channelId = 'general';
    
    // Determine channel based on notification type
    switch (type) {
      case 'event_assigned':
        channelId = 'assignments';
        break;
      case 'event_confirmed':
        channelId = 'confirmations';
        break;
      case 'unassigned_events_alert':
      case 'event_updated':
      case 'event_deleted':
        channelId = 'alerts';
        break;
    }
    
    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelId.replaceAll('_', ' ').toUpperCase(),
      importance: Importance.high,
      priority: Priority.high,
    );
    
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    await _localNotifications.show(
      message.hashCode,
      notification.title,
      notification.body,
      details,
      payload: message.data['event_id'] as String?,
    );
  }
  
  void _handleNotificationTap(RemoteMessage message) {
    final type = message.data['type'] as String?;
    
    switch (type) {
      case 'event_assigned':
        final eventId = message.data['event_id'] as String?;
        if (eventId != null && onEventAssignedTap != null) {
          onEventAssignedTap!(eventId);
        }
        break;
        
      case 'unassigned_events_alert':
        final familyId = message.data['family_id'] as String?;
        if (familyId != null && onUnassignedAlertTap != null) {
          onUnassignedAlertTap!(familyId);
        }
        break;
        
      case 'event_confirmed':
        final eventId = message.data['event_id'] as String?;
        if (eventId != null && onEventConfirmedTap != null) {
          onEventConfirmedTap!(eventId);
        }
        break;
    }
  }
  
  void _handleLocalNotificationTap(String payload) {
    // Handle local notification tap with event ID as payload
    if (onEventAssignedTap != null) {
      onEventAssignedTap!(payload);
    }
  }
  
  void _handleEventAssigned(Map<String, dynamic> data) {
    // Parse event data and trigger calendar sync
    final action = data['action'] as String?;
    
    if (action == 'calendar_sync') {
      // Trigger calendar sync in app state
      debugPrint('📅 Triggering calendar sync for assigned event');
    }
  }
  
  void _handleUnassignedAlert(Map<String, dynamic> data) {
    debugPrint('⚠️ Unassigned event alert received');
  }
  
  void _handleEventConfirmed(Map<String, dynamic> data) {
    debugPrint('✅ Event confirmation notification received');
  }
  
  void _handleEventUpdated(Map<String, dynamic> data) {
    debugPrint('📝 Event updated notification received');
    // Trigger calendar update in app state
  }
  
  void _handleEventDeleted(Map<String, dynamic> data) {
    debugPrint('🗑️ Event deleted notification received');
    // Trigger calendar removal in app state
  }
  
  void _handleCalendarRemoval(Map<String, dynamic> data) {
    final eventId = data['event_id'] as String?;
    if (eventId != null) {
      debugPrint('🗑️ Removing event from calendar: $eventId');
      // Trigger calendar removal
    }
  }
  
  /// Update user notification settings
  Future<void> updateNotificationSettings({
    bool? assignments,
    bool? confirmations,
    bool? unassignedAlerts,
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;
    
    try {
      final updates = <String, dynamic>{};
      
      if (assignments != null) {
        updates['settings.notifications.assignments'] = assignments;
      }
      if (confirmations != null) {
        updates['settings.notifications.confirmations'] = confirmations;
      }
      if (unassignedAlerts != null) {
        updates['settings.notifications.unassigned_alerts'] = unassignedAlerts;
      }
      
      await _firestore
        .collection('users')
        .doc(userId)
        .update(updates);
      
      debugPrint('✅ Updated notification settings');
    } catch (e) {
      debugPrint('❌ Failed to update notification settings: $e');
    }
  }
  
  /// Get current notification settings
  Future<Map<String, bool>> getNotificationSettings() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return {
        'assignments': true,
        'confirmations': true,
        'unassigned_alerts': true,
      };
    }
    
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final settings = userDoc.data()?['settings'] as Map<String, dynamic>? ?? {};
      final notifications = settings['notifications'] as Map<String, dynamic>? ?? {};
      
      return {
        'assignments': notifications['assignments'] as bool? ?? true,
        'confirmations': notifications['confirmations'] as bool? ?? true,
        'unassigned_alerts': notifications['unassigned_alerts'] as bool? ?? true,
      };
    } catch (e) {
      debugPrint('❌ Failed to get notification settings: $e');
      return {
        'assignments': true,
        'confirmations': true,
        'unassigned_alerts': true,
      };
    }
  }
}

