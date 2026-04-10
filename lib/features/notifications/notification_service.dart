import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:unipast/core/supabase_config.dart';
import 'package:path_provider/path_provider.dart';
import 'package:universal_io/io.dart';
import 'dart:convert';

class NotificationService {
  final SupabaseClient _client;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  NotificationService(this._client);

  static DateTime? _sessionLastCleared;

  Future<File> _getClearFile() async {
    if (kIsWeb) throw Exception('PathProvider not supported on web');
    final dir = await getApplicationDocumentsDirectory();
    final user = _client.auth.currentUser;
    final fileName = user != null ? 'notifications_clear_${user.id}.json' : 'notifications_clear_anon.json';
    return File('${dir.path}/$fileName');
  }

  Future<void> _updateLastClearedAt() async {
    final now = DateTime.now().toUtc();
    _sessionLastCleared = now;
    
    try {
      final file = await _getClearFile();
      final data = {'last_cleared_at': now.toIso8601String()};
      await file.writeAsString(jsonEncode(data));
    } catch (e) {
      debugPrint('[NOTIFICATION] PathProvider unavailable, using session fallback: $e');
    }
  }

  Future<DateTime?> _getLastClearedAt() async {
    if (_sessionLastCleared != null) return _sessionLastCleared;
    
    try {
      final file = await _getClearFile();
      if (await file.exists()) {
        final content = await file.readAsString();
        final data = jsonDecode(content);
        return DateTime.parse(data['last_cleared_at']);
      }
    } catch (e) {
      // Graceful fail - no persistent clearing until restart
      debugPrint('[NOTIFICATION] Error reading clear timestamp: $e');
    }
    return null;
  }

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

  Future<List<Map<String, dynamic>>> getNotifications() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return [];

      final response = await _client
          .from('notifications')
          .select()
          .or('user_id.eq.${user.id},user_id.is.null') // Targeted or global
          .order('created_at', ascending: false);
      
      final notifications = List<Map<String, dynamic>>.from(response);
      final lastCleared = await _getLastClearedAt();

      if (lastCleared == null) return notifications;

      // Filter: If it's a global notification (user_id is null), 
      // only show if it was created AFTER the last clear.
      return notifications.where((n) {
        if (n['user_id'] != null) return true; // Keep private ones
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
      // 1. Mark everything as read
      await _client.from('notifications').update({'is_read': true}).eq('user_id', user.id);
      // 2. Delete targeted ones from DB
      await _client.from('notifications').delete().eq('user_id', user.id);
      // 3. Save local clear timestamp for global ones
      await _updateLastClearedAt();
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
  return ref.watch(notificationServiceProvider).getNotifications();
});

final fcmTokenProvider = FutureProvider<String?>((ref) {
  return ref.read(notificationServiceProvider).getToken();
});

