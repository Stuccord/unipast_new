import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:universal_io/io.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:unipast/features/offline/offline_service.dart';
import 'package:unipast/features/offline/cached_item_model.dart';


class UserStats {
  final Set<String> viewedIds;
  final int streakCount;
  final DateTime lastActivityDate;

  UserStats({
    required this.viewedIds,
    required this.streakCount,
    required this.lastActivityDate,
  });

  Map<String, dynamic> toJson() => {
        'viewedIds': viewedIds.toList(),
        'streakCount': streakCount,
        'lastActivityDate': lastActivityDate.toIso8601String(),
      };

  factory UserStats.fromJson(Map<String, dynamic> json) => UserStats(
        viewedIds: Set<String>.from(json['viewedIds'] ?? []),
        streakCount: json['streakCount'] ?? 0,
        lastActivityDate: DateTime.parse(
            json['lastActivityDate'] ?? DateTime.now().toIso8601String()),
      );
}

final statsServiceProvider = Provider<StatsService>((ref) => StatsService());

class StatsService {
  final _supabase = Supabase.instance.client;

  Future<File?> get _localFile async {
    if (kIsWeb) return null;
    try {
      final directory = await getApplicationDocumentsDirectory();
      return File('${directory.path}/user_stats.json');
    } catch (_) {
      return null;
    }
  }

  Future<UserStats> getStats() async {
    // Try Supabase first if authenticated
    final user = _supabase.auth.currentUser;
    if (user != null) {
      try {
        final response = await _supabase
            .from('stats')
            .select()
            .eq('user_id', user.id)
            .maybeSingle();
        
        if (response != null) {
          return UserStats.fromJson(response);
        }
      } catch (e) {
        // Supabase fetch failed, falling back to local
      }
    }

    // Local Fallback
    if (kIsWeb) {
      return UserStats(
        viewedIds: {},
        streakCount: 0,
        lastActivityDate: DateTime.now(),
      );
    }

    try {
      final file = await _localFile;
      if (file == null || !await file.exists()) {
        return UserStats(
          viewedIds: {},
          streakCount: 0,
          lastActivityDate: DateTime.now().subtract(const Duration(days: 2)),
        );
      }
      final contents = await file.readAsString();
      return UserStats.fromJson(json.decode(contents));
    } catch (e) {
      return UserStats(
        viewedIds: {},
        streakCount: 0,
        lastActivityDate: DateTime.now(),
      );
    }
  }

  Future<void> saveStats(UserStats stats) async {
    // Save locally
    if (!kIsWeb) {
      try {
        final file = await _localFile;
        if (file != null) {
          await file.writeAsString(json.encode(stats.toJson()));
        }
      } catch (_) {}
    }

    // Save to Supabase if authenticated
    final user = _supabase.auth.currentUser;
    if (user != null) {
      try {
        await _supabase.from('stats').upsert(stats.toJson());
      } catch (e) {
        // Supabase save failed
      }
    }
  }

  Future<void> recordView(String questionId) async {
    final stats = await getStats();
    final now = DateTime.now();
    
    // Update viewed IDs
    stats.viewedIds.add(questionId);
    
    // Update streak
    int newStreak = stats.streakCount;
    final last = stats.lastActivityDate;
    final diff = now.difference(DateTime(last.year, last.month, last.day)).inDays;
    
    if (diff == 1) {
      newStreak++;
    } else if (diff > 1) {
      newStreak = 1;
    } else if (newStreak == 0) {
        newStreak = 1;
    }

    await saveStats(UserStats(
      viewedIds: stats.viewedIds,
      streakCount: newStreak,
      lastActivityDate: now,
    ));
  }
}

final profileStatsProvider = FutureProvider<Map<String, String>>((ref) async {
  final statsService = ref.watch(statsServiceProvider);
  final isarAsync = ref.watch(isarProvider);
  
  final stats = await statsService.getStats();
  
  // Get stored count from Isar
  int storedCount = 0;
  final isar = isarAsync.valueOrNull;
  if (isar != null) {
    storedCount = await isar.cachedQuestions.count();
  }

  return {
    'viewed': stats.viewedIds.length.toString(),
    'stored': storedCount.toString(),
    'streaks': '${stats.streakCount}d',
  };
});
