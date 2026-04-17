import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:unipast/core/supabase_config.dart';
import 'package:unipast/features/auth/profile_service.dart';

class NotificationService {
  final SupabaseClient _client;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  NotificationService(this._client);

  FirebaseMessaging? get _fcm {
    try {
      return FirebaseMessaging.instance;
    } catch (_) {
      return null;
    }
  }

  Future<void> initialize() async {
    final fcm = _fcm;
    if (fcm == null) return;

    try {
      // Request permission
      await fcm.requestPermission();

      // Initialize local notifications for foreground messages
      const initializationSettings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      );
      await _localNotifications.initialize(initializationSettings);

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        _showLocalNotification(message);
      });
    } catch (e) {
      debugPrint('[NOTIFICATION] Notification initialization non-critical failure: $e');
    }
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'unipast_channel',
        'UniPast Notifications',
      ),
      iOS: DarwinNotificationDetails(),
    );
    await _localNotifications.show(
      0,
      message.notification?.title,
      message.notification?.body,
      details,
    );
  }

  Future<String?> getToken() async {
    try {
      return await _fcm?.getToken();
    } catch (e) {
      debugPrint('[NOTIFICATION] Error getting FCM token: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getNotifications(UserProfile? profile) async {
    try {
      if (profile == null) return [];

      // Fetch notifications that are:
      // 1. Specifically for this user
      // 2. OR for this user's programme
      // 3. OR global (no user_id and no programme_id)
      final response = await _client
          .from('notifications')
          .select()
          .or('user_id.eq.${profile.id},programme_id.eq.${profile.programmeId},and(user_id.is.null,programme_id.is.null)')
          .order('created_at', ascending: false);
      
      final notifications = List<Map<String, dynamic>>.from(response);
      final lastCleared = profile.notificationsClearedAt;

      if (lastCleared == null) return notifications;

      // Only show notifications created AFTER the user last cleared them.
      return notifications.where((n) {
        final createdAt = DateTime.parse(n['created_at']).toUtc();
        return createdAt.isAfter(lastCleared.toUtc());
      }).toList();
    } catch (e) {
      debugPrint('[NOTIFICATION] Error fetching notifications: $e');
      return [];
    }
  }

  Future<void> markAsRead(String id) async {
    await _client.from('notifications').update({'is_read': true}).eq('id', id);
  }

  Future<void> clearAll() async {
    final user = _client.auth.currentUser;
    if (user == null) return;
    try {
      // 1. Persistent clear: update the profile's timestamp in Supabase
      await _client.from('profiles').update({
        'notifications_cleared_at': DateTime.now().toUtc().toIso8601String()
      }).eq('id', user.id);
      
      // 2. Clean up targeted notifications from DB
      await _client.from('notifications').delete().eq('user_id', user.id);
    } catch (e) {
      debugPrint('[NOTIFICATION] Error clearing notifications: $e');
    }
  }
}

final notificationServiceProvider = Provider<NotificationService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return NotificationService(client);
});

final notificationsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) {
  final profile = ref.watch(myProfileProvider).value;
  return ref.watch(notificationServiceProvider).getNotifications(profile);
});

final fcmTokenProvider = FutureProvider<String?>((ref) {
  return ref.read(notificationServiceProvider).getToken();
});
