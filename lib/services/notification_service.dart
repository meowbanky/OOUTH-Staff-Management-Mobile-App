import 'package:flutter/material.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import '../models/app_notification.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class NotificationService {
  static const String oneSignalAppId = 'c04a0f15-e70b-4d40-a3c6-284b1898b5b6';
  static bool _initialized = false;
  final String baseUrl;
  final String token;
  final String userId; // Changed from staffId to userId to match User model

  NotificationService({
    required this.baseUrl,
    required this.token,
    required this.userId, // Changed parameter name
  }) {
    initialize();
  }

  Future<List<AppNotification>> getNotifications() async {
    try {
      final response = await http.get(
        Uri.parse(
            '$baseUrl/api/auth/notifications.php?staff_id=$userId'), // Using userId
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      print('baseurl:$baseUrl');
      print('useridnotifiction:$userId');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body)['data'];
        return data.map((json) => AppNotification.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load notifications');
      }
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
      throw Exception('Error: $e');
    }
  }

  Future<void> markAsRead(int notificationId) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/api/auth/notifications.php/$notificationId/read'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'staff_id': userId, // Include staff_id in request
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to mark notification as read');
      }
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
      throw Exception('Error: $e');
    }
  }

  Future<int> getUnreadCount() async {
    try {
      final response = await http.get(
        Uri.parse(
            '$baseUrl/api/auth/notifications.php?count=true&unread-count&staff_id=$userId'), // Add staff_id parameter
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['count'] ?? 0;
      } else {
        throw Exception('Failed to get unread count');
      }
    } catch (e) {
      debugPrint('Error getting unread count: $e');
      return 0;
    }
  }

  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      OneSignal.initialize(oneSignalAppId);
      OneSignal.Notifications.requestPermission(true);

      OneSignal.Notifications.addClickListener(
          (OSNotificationClickEvent event) {
        debugPrint('Notification clicked:');
        debugPrint('Title: ${event.notification.title}');
        debugPrint('Body: ${event.notification.body}');
        debugPrint('Additional Data: ${event.notification.additionalData}');
        _handleNotificationOpen(event);
      });

      OneSignal.Notifications.addForegroundWillDisplayListener(
          (OSNotificationWillDisplayEvent event) {
        debugPrint('Notification received in foreground');
        debugPrint('Title: ${event.notification.title}');
        debugPrint('Body: ${event.notification.body}');

        // Get staffId from additional data if available
        final staffId =
            event.notification.additionalData?['staff_id']?.toString();
        if (staffId != null) {
          _saveNotificationToDatabase(event.notification, staffId);
        }
      });

      _initialized = true;
      debugPrint('OneSignal initialized successfully');
    } catch (e) {
      debugPrint('Error initializing OneSignal: $e');
    }
  }

  static Future<void> _saveNotificationToDatabase(
      OSNotification notification, String staffId) async {
    try {
      // Here you would typically make an API call to save the notification
      final Map<String, dynamic> notificationData = {
        'staff_id': staffId,
        'title': notification.title,
        'message': notification.body,
        'status': 'unread',
      };

      // Make API call to save notification
      // const response = await http.post(...);

      debugPrint('Notification saved to database for staff: $staffId');
    } catch (e) {
      debugPrint('Error saving notification to database: $e');
    }
  }

  static Future<void> setExternalUserId(String userId) async {
    try {
      await OneSignal.login(userId);
      debugPrint('External user ID set: $userId');
    } catch (e) {
      debugPrint('Error setting external user ID: $e');
    }
  }

  static void _handleNotificationOpen(OSNotificationClickEvent event) {
    try {
      final data = event.notification.additionalData;
      if (data != null) {
        switch (data['type']) {
          case 'payslip':
          case 'salary_ready':
            _navigateToPayslip(data['payslip_id']?.toString());
            break;
          case 'announcement':
            _navigateToAnnouncement(data['announcement_id']?.toString());
            break;
          default:
            _navigateToNotifications();
            break;
        }
      }
    } catch (e) {
      debugPrint('Error handling notification open: $e');
    }
  }

  static void _navigateToPayslip(String? payslipId) {
    debugPrint('Navigate to payslip: $payslipId');
  }

  static void _navigateToAnnouncement(String? announcementId) {
    debugPrint('Navigate to announcement: $announcementId');
  }

  static void _navigateToNotifications() {
    debugPrint('Navigate to notifications screen');
  }

  static Future<void> subscribeToTopic(String topic) async {
    try {
      await OneSignal.User.addTagWithKey(topic, 'true');
      debugPrint('Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('Error subscribing to topic: $e');
    }
  }

  static Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await OneSignal.User.removeTag(topic);
      debugPrint('Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('Error unsubscribing from topic: $e');
    }
  }

  static void listenForPermissionChanges() {
    OneSignal.Notifications.addPermissionObserver((bool permission) {
      debugPrint("Notification permission state changed: $permission");
    });
  }

  static Future<bool> areNotificationsEnabled() async {
    return OneSignal.Notifications.permission;
  }
}
