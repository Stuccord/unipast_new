import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unipast/core/supabase_config.dart';
import 'activity_model.dart';

final activityServiceProvider = Provider<ActivityService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return ActivityService(client);
});

class ActivityService {
  final SupabaseClient _client;
  ActivityService(this._client);

  /// Record a new activity in the database.
  Future<void> recordActivity({
    required String eventType,
    required String description,
    Map<String, dynamic>? metadata,
    String? userId,
  }) async {
    try {
      final currentUserId = userId ?? _client.auth.currentUser?.id;
      await _client.from('activities').insert({
        'user_id': currentUserId,
        'event_type': eventType,
        'description': description,
        'metadata': metadata ?? {},
      });
    } catch (e) {
      // We don't want to break the app if logging fails, just print in debug
      print('DEBUG: Activity log error: $e');
    }
  }

  /// Get the recent activities for the admin dashboard.
  Future<List<Activity>> getRecentActivities({int limit = 50}) async {
    final response = await _client
        .from('activities')
        .select('*, profiles(full_name)')
        .order('created_at', ascending: false)
        .limit(limit);

    final data = response as List<dynamic>;
    return data.map((json) => Activity.fromJson(json)).toList();
  }

  /// Stream of real-time activities for the dashboard feed.
  Stream<List<Activity>> streamActivities() {
    return _client
        .from('activities')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .limit(20)
        .asyncMap((data) async {
          // This stream is limited as Supabase doesn't easily join on stream yet.
          // We'll refetch joined data when a change occurs.
          return await getRecentActivities(limit: 20);
        });
  }
}

// Providers for the UI
final recentActivitiesProvider = FutureProvider<List<Activity>>((ref) {
  return ref.watch(activityServiceProvider).getRecentActivities();
});

final activitiesStreamProvider = StreamProvider<List<Activity>>((ref) {
  return ref.watch(activityServiceProvider).streamActivities();
});
