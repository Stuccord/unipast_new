import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unipast/core/supabase_config.dart';
import 'package:unipast/features/auth/profile_service.dart';
import 'package:unipast/features/browse/browse_models.dart';
import 'package:flutter/foundation.dart';

final browseServiceProvider = Provider<BrowseService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return BrowseService(client);
});

class BrowseService {
  final SupabaseClient _client;
  BrowseService(this._client);

  Future<List<University>> getUniversities() async {
    final response = await _client.from('universities').select().order('name');
    return (response as List).map((json) => University.fromJson(json)).toList();
  }

  Future<List<Faculty>> getFaculties(String universityId) async {
    final response = await _client
        .from('faculties')
        .select()
        .eq('university_id', universityId)
        .order('name');
    return (response as List).map((json) => Faculty.fromJson(json)).toList();
  }

  Future<List<Programme>> getProgrammes(String facultyId) async {
    try {
      final response = await _client
          .from('programmes')
          .select()
          .eq('faculty_id', facultyId)
          .order('name');
      
      final list = response as List;
      
      return list.map((json) {
        final Map<String, dynamic> data = Map<String, dynamic>.from(json);
        data['duration_years'] = data['duration_years'] ?? 4; 
        return Programme.fromJson(data);
      }).toList();
    } catch (e) {
      // Fallback: This allows the app to work even if the user hasn't 
      // fully set up the new table yet (queries courses as programmes)
      try {
        final fallbackResponse = await _client
            .from('courses')
            .select()
            .eq('faculty_id', facultyId)
            .order('title'); // Courses use 'title' in the new schema
        
        final list = fallbackResponse as List;
        
        return list.map((json) {
          return Programme(
            id: json['id'],
            facultyId: json['faculty_id'],
            name: json['title'] ?? json['name'] ?? 'Unknown Course',
            durationYears: 4,
          );
        }).toList();
      } catch (e2) {
        debugPrint('[BROWSE] Fallback also failed: $e2');
        return []; // Return empty list instead of throwing to avoid "Error" UI
      }
    }
  }
}

final universitiesProvider = FutureProvider<List<University>>((ref) async {
  final service = ref.read(browseServiceProvider);
  final profileAsync = ref.watch(myProfileProvider);

  final allUnis = await service.getUniversities();

  return profileAsync.maybeWhen(
    data: (profile) {
      if (profile == null) return allUnis;
      // Filter only for the user's university
      return allUnis.where((u) => u.id == profile.universityId).toList();
    },
    orElse: () => allUnis,
  );
});

final facultiesProvider =
    FutureProvider.family<List<Faculty>, String>((ref, universityId) async {
  final service = ref.read(browseServiceProvider);
  final profileAsync = ref.watch(myProfileProvider);
  final allFacs = await service.getFaculties(universityId);

  return profileAsync.maybeWhen(
    data: (profile) {
      if (profile == null) return allFacs;
      // Filter only for the user's faculty
      return allFacs.where((f) => f.id == profile.facultyId).toList();
    },
    orElse: () => allFacs,
  );
});

final programmesProvider =
    FutureProvider.family<List<Programme>, String>((ref, facultyId) async {
  final service = ref.read(browseServiceProvider);
  final allProgs = await service.getProgrammes(facultyId);

  // We only filter by profile if it's actually loaded and available.
  // During signup, it will likely be null or in error state, which is fine.
  final profileAsync = ref.watch(myProfileProvider);
  
  return profileAsync.maybeWhen(
    data: (profile) {
      if (profile == null || profile.programmeId.isEmpty) return allProgs;
      // Filter only for the user's programme if they have one assigned
      final filtered = allProgs.where((p) => p.id == profile.programmeId).toList();
      return filtered.isEmpty ? allProgs : filtered;
    },
    orElse: () => allProgs,
  );
});
