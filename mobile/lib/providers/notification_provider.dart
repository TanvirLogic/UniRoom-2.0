import 'dart:async';
import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/notification_item_model.dart';
import '../models/schedule_slot_model.dart';
import '../services/notification_service.dart';

/// NotificationProvider
/// Manages in-app notifications, unread badges, local persistence,
/// and real-time syncing with Firebase Cloud Messaging (FCM).
class NotificationProvider extends ChangeNotifier {
  static const String _storageKey = 'uniroom_inapp_notifications_v1';
  static const int _maxStoredNotifications = 100;

  List<NotificationItemModel> _notifications = [];
  bool _isLoading = false;
  StreamSubscription<RemoteMessage>? _fcmSubscription;

  NotificationProvider() {
    _init();
  }

  List<NotificationItemModel> get notifications => List.unmodifiable(_notifications);
  int get unreadCount => _notifications.where((n) => !n.isRead).length;
  bool get hasUnread => unreadCount > 0;
  bool get isLoading => _isLoading;

  Future<void> _init() async {
    await loadNotifications();
    _listenToFcm();
  }

  /// Listen to real-time FCM messages arriving in the foreground
  void _listenToFcm() {
    _fcmSubscription?.cancel();
    _fcmSubscription = NotificationService().onForegroundMessage.listen((msg) {
      addFromRemoteMessage(msg);
    });
  }

  /// Load persisted notifications from SharedPreferences
  Future<void> loadNotifications() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw != null && raw.isNotEmpty) {
        final List decoded = jsonDecode(raw);
        _notifications = decoded
            .map((item) => NotificationItemModel.fromJson(Map<String, dynamic>.from(item)))
            .toList();
      }
    } catch (e) {
      debugPrint('[NotificationProvider] Error loading notifications: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Add a new notification and persist
  Future<void> addNotification(NotificationItemModel item) async {
    // Avoid exact duplicate IDs
    _notifications.removeWhere((n) => n.id == item.id);
    _notifications.insert(0, item);

    if (_notifications.length > _maxStoredNotifications) {
      _notifications = _notifications.sublist(0, _maxStoredNotifications);
    }

    notifyListeners();
    await _saveToStorage();
  }

  /// Ingest RemoteMessage from FCM
  Future<void> addFromRemoteMessage(RemoteMessage msg) async {
    final title = msg.notification?.title ?? msg.data['title'] ?? 'Classroom Alert';
    final body = msg.notification?.body ?? msg.data['body'] ?? '';
    final id = msg.messageId ?? DateTime.now().millisecondsSinceEpoch.toString();

    final type = _inferType(title, body, msg.data['type']);

    final item = NotificationItemModel(
      id: id,
      title: title,
      body: body,
      timestamp: DateTime.now(),
      isRead: false,
      type: type,
      data: msg.data.isNotEmpty ? msg.data : null,
    );

    await addNotification(item);
  }

  /// Automatically sync routine overrides from today's timetable
  /// e.g. Class Cancellations, Rescheduled slots, or shifted rooms
  Future<void> syncScheduleAlerts(List<ScheduleSlotModel> todaySlots) async {
    bool hasAddedNew = false;
    final now = DateTime.now();

    for (final slot in todaySlots) {
      if (slot.isCancelled) {
        final alertId = 'alert_cancelled_${slot.id}_${now.year}_${now.month}_${now.day}';
        final exists = _notifications.any((n) => n.id == alertId);
        if (!exists) {
          _notifications.insert(
            0,
            NotificationItemModel(
              id: alertId,
              title: 'Class Cancelled: ${slot.courseCode}',
              body: slot.overrideReason?.isNotEmpty == true
                  ? slot.overrideReason!
                  : 'Faculty or CR marked this class as suspended for today (${slot.startTime} - ${slot.endTime}).',
              timestamp: now,
              isRead: false,
              type: 'cancellation',
              data: {'slotId': slot.id, 'courseCode': slot.courseCode},
            ),
          );
          hasAddedNew = true;
        }
      } else if (slot.isRescheduled) {
        final alertId = 'alert_rescheduled_${slot.id}_${now.year}_${now.month}_${now.day}';
        final exists = _notifications.any((n) => n.id == alertId);
        if (!exists) {
          _notifications.insert(
            0,
            NotificationItemModel(
              id: alertId,
              title: 'Class Rescheduled: ${slot.courseCode}',
              body: 'Class adjusted to ${slot.startTime} - ${slot.endTime} (Room ${slot.roomNumber ?? "TBA"}).',
              timestamp: now,
              isRead: false,
              type: 'reschedule',
              data: {'slotId': slot.id, 'courseCode': slot.courseCode},
            ),
          );
          hasAddedNew = true;
        }
      }
    }

    if (hasAddedNew) {
      if (_notifications.length > _maxStoredNotifications) {
        _notifications = _notifications.sublist(0, _maxStoredNotifications);
      }
      notifyListeners();
      await _saveToStorage();
    }
  }

  /// Mark single notification as read
  Future<void> markAsRead(String id) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1 && !_notifications[index].isRead) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      notifyListeners();
      await _saveToStorage();
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    bool hasUnread = _notifications.any((n) => !n.isRead);
    if (!hasUnread) return;

    _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
    notifyListeners();
    await _saveToStorage();
  }

  /// Delete a single notification
  Future<void> deleteNotification(String id) async {
    _notifications.removeWhere((n) => n.id == id);
    notifyListeners();
    await _saveToStorage();
  }

  /// Clear all notifications
  Future<void> clearAll() async {
    _notifications.clear();
    notifyListeners();
    await _saveToStorage();
  }

  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(_notifications.map((n) => n.toJson()).toList());
      await prefs.setString(_storageKey, encoded);
    } catch (e) {
      debugPrint('[NotificationProvider] Error saving notifications: $e');
    }
  }

  String _inferType(String title, String body, dynamic rawType) {
    if (rawType != null && rawType.toString().isNotEmpty) {
      return rawType.toString().toLowerCase();
    }
    final combined = '$title $body'.toLowerCase();
    if (combined.contains('cancel') || combined.contains('suspend')) {
      return 'cancellation';
    }
    if (combined.contains('reschedul') || combined.contains('shift') || combined.contains('timing')) {
      return 'reschedule';
    }
    if (combined.contains('room') || combined.contains('freed') || combined.contains('booked')) {
      return 'room';
    }
    if (combined.contains('emergency') || combined.contains('announcement') || combined.contains('broadcast')) {
      return 'announcement';
    }
    return 'general';
  }

  @override
  void dispose() {
    _fcmSubscription?.cancel();
    super.dispose();
  }
}
