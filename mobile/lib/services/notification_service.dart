import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Top-level background message handler for FCM
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
    debugPrint('[FCM Background] Message received: ${message.messageId} - ${message.notification?.title}');
  } catch (e) {
    debugPrint('[FCM Background] Error in handler: $e');
  }
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  FirebaseMessaging? _messaging;
  bool _initialized = false;
  bool _supported = false;
  String? _currentCohortTopic;
  String? _currentCrTopic;
  String? _currentFacultyTopic;

  // Stream controller to broadcast foreground push notices to UI (e.g. In-App Snackbars/Toasts)
  final _messageStreamController = StreamController<RemoteMessage>.broadcast();
  Stream<RemoteMessage> get onForegroundMessage => _messageStreamController.stream;

  bool get isSupportedPlatform {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  Future<void> initialize() async {
    if (_initialized) return;

    if (!isSupportedPlatform) {
      debugPrint('[NotificationService] Platform $defaultTargetPlatform does not support native mobile FCM. Running in desktop/fallback mode.');
      _initialized = true;
      _supported = false;
      return;
    }

    try {
      await Firebase.initializeApp();
      _messaging = FirebaseMessaging.instance;
      _supported = true;

      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // Request notification permissions (Android 13+ / iOS)
      final settings = await _messaging!.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      debugPrint('[NotificationService] Notification permission status: ${settings.authorizationStatus}');

      // Foreground message listener
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('[FCM Foreground] ${message.notification?.title}: ${message.notification?.body}');
        _messageStreamController.add(message);
      });

      // App opened from notification listener
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('[FCM Opened App] User tapped notification: ${message.data}');
      });

      _initialized = true;
    } catch (e) {
      debugPrint('[NotificationService] Initialization error (safe fallback): $e');
      _supported = false;
      _initialized = true;
    }
  }

  String _sanitizeTopic(String topic) {
    return topic.trim().replaceAll(RegExp(r'[^a-zA-Z0-9-_.~%]'), '_').toLowerCase();
  }

  /// Subscribe to cohort topics based on User profile
  Future<void> syncUserCohortTopics({
    required String department,
    required String batch,
    required String section,
    bool isCr = false,
    String? facultyInitials,
  }) async {
    if (!_initialized) await initialize();
    if (!_supported || _messaging == null) return;

    try {
      // 1. Unsubscribe from old cohort topic if changed
      final newCohortTopic = _sanitizeTopic('dept_${department}_batch_${batch}_sec_$section');
      if (_currentCohortTopic != null && _currentCohortTopic != newCohortTopic) {
        await _messaging!.unsubscribeFromTopic(_currentCohortTopic!);
        debugPrint('[NotificationService] Unsubscribed from old topic: $_currentCohortTopic');
      }

      // Subscribe to section topic
      if (department.isNotEmpty && batch.isNotEmpty && section.isNotEmpty) {
        await _messaging!.subscribeToTopic(newCohortTopic);
        _currentCohortTopic = newCohortTopic;
        debugPrint('[NotificationService] Subscribed to section topic: $newCohortTopic');
      }

      // 2. CR Room Freed Broadcast Topic
      final newCrTopic = _sanitizeTopic('dept_${department}_crs');
      if (isCr) {
        if (_currentCrTopic != newCrTopic) {
          await _messaging!.subscribeToTopic(newCrTopic);
          _currentCrTopic = newCrTopic;
          debugPrint('[NotificationService] Subscribed to CR topic: $newCrTopic');
        }
      } else if (_currentCrTopic != null) {
        await _messaging!.unsubscribeFromTopic(_currentCrTopic!);
        _currentCrTopic = null;
      }

      // 3. Faculty Topic
      if (facultyInitials != null && facultyInitials.isNotEmpty) {
        final newFacultyTopic = _sanitizeTopic('faculty_$facultyInitials');
        if (_currentFacultyTopic != newFacultyTopic) {
          await _messaging!.subscribeToTopic(newFacultyTopic);
          _currentFacultyTopic = newFacultyTopic;
          debugPrint('[NotificationService] Subscribed to faculty topic: $newFacultyTopic');
        }
      }
    } catch (e) {
      debugPrint('[NotificationService] Error syncing topics: $e');
    }
  }

  /// Clean up topics on logout
  Future<void> unsubscribeAll() async {
    if (!_supported || _messaging == null) return;
    try {
      if (_currentCohortTopic != null) {
        await _messaging!.unsubscribeFromTopic(_currentCohortTopic!);
        _currentCohortTopic = null;
      }
      if (_currentCrTopic != null) {
        await _messaging!.unsubscribeFromTopic(_currentCrTopic!);
        _currentCrTopic = null;
      }
      if (_currentFacultyTopic != null) {
        await _messaging!.unsubscribeFromTopic(_currentFacultyTopic!);
        _currentFacultyTopic = null;
      }
    } catch (e) {
      debugPrint('[NotificationService] Error unsubscribing: $e');
    }
  }
}
