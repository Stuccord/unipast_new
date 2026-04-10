import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unipast/core/supabase_config.dart';
import 'package:unipast/features/auth/auth_service.dart';
import 'package:unipast/features/auth/profile_model.dart';
export 'package:unipast/features/auth/profile_model.dart';
import 'package:flutter/foundation.dart';

import 'package:isar/isar.dart';
import 'package:unipast/features/offline/offline_service.dart';

final profileServiceProvider = Provider<ProfileService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final isar = ref.watch(isarProvider).value;
  return ProfileService(client, isar);
});

class ProfileService {
  final SupabaseClient _client;
  final Isar? _isar;
  ProfileService(this._client, this._isar);

  Future<UserProfile?> getMyProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    // 1. Try Cache First
    final isar = _isar;
    if (isar != null) {
      final cached =
          await isar.userProfiles.filter().idEqualTo(user.id).findFirst();
      if (cached != null) {
        debugPrint(
            '[PROFILE] Returning cached profile for ${user.id} (ID: ${cached.id}, Prog: ${cached.programmeId})');
        // Background refresh
        _refreshProfileInBackground(user.id);
        return cached;
      }
    }

    // 2. Fetch from Supabase if not in cache
    return await _fetchAndCacheProfile(user.id);
  }

  Future<UserProfile?> _fetchAndCacheProfile(String userId) async {
    // NOTE: This intentionally does NOT catch exceptions.
    // If we return null silently on error, the router mistakes it for
    // "profile not completed" and redirects the user to /signup.
    // Instead, let the error propagate so profileAsync.hasError is true
    // and the router's hasError guard returns null (stay put).
    final response =
        await _client.from('profiles').select().eq('id', userId).maybeSingle();

    if (response == null) {
      return null;
    }

    final profile = UserProfile.fromJson(response);

    // Save to cache
    final isar = _isar;
    if (isar != null) {
      await isar.writeTxn(() async {
        await isar.userProfiles.put(profile);
      });
    }

    return profile;
  }

  void _refreshProfileInBackground(String userId) async {
    try {
      final response = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
      final isar = _isar;
      if (response != null && isar != null) {
        final profile = UserProfile.fromJson(response);
        await isar.writeTxn(() async {
          await isar.userProfiles.put(profile);
        });
      }
    } catch (e) {
      // Background refresh failed, but not critical for foreground operation
    }
  }

  Future<void> updateProfile(Map<String, dynamic> updates,
      {String? userId}) async {
    final effectiveId = userId ?? _client.auth.currentUser?.id;
    if (effectiveId == null) {
      throw Exception('Cannot update profile: No authenticated user ID found.');
    }

    try {
      // 1. Update Supabase
      await _client.from('profiles').upsert({
        'id': effectiveId,
        ...updates,
      });

      // 2. Update Cache
      final isar = _isar;
      if (isar != null) {
        // Fetch full fresh profile to ensure cache is correct
        final freshResponse = await _client
            .from('profiles')
            .select()
            .eq('id', effectiveId)
            .single();
        final freshProfile = UserProfile.fromJson(freshResponse);

        await isar.writeTxn(() async {
          await isar.userProfiles.put(freshProfile);
        });
      }
    } catch (e) {
      if (e is PostgrestException) {
        if (e.code == '42501') {
          // RLS VIOLATION DETECTED: The user does not have permission to insert/update this row.
        }
      } else {
        // Update failed
      }
      rethrow;
    }
  }

  Future<void> updateSemester(int semester) async {
    await updateProfile({'current_semester': semester});
  }
}

final myProfileProvider = FutureProvider<UserProfile?>((ref) async {
  // Watch auth state to ensure this provider refreshes when user logs in/out
  ref.watch(authStateChangesProvider);
  return ref.watch(profileServiceProvider).getMyProfile();
});
