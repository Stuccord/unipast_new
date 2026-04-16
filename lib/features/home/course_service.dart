import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unipast/core/supabase_config.dart';
import 'package:unipast/features/home/course_model.dart';
import 'package:unipast/features/auth/profile_service.dart';

final courseServiceProvider = Provider<CourseService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return CourseService(client);
});

class CourseService {
  final SupabaseClient _client;
  CourseService(this._client);

  Future<List<Course>> getMyCourses({
    required String programmeId,
    required int level,
    required int semester,
  }) async {
    final response = await _client
        .from('courses')
        .select()
        .eq('programme_id', programmeId)
        .eq('level', level)
        .eq('semester', semester);

    return (response as List).map((json) => Course.fromJson(json)).toList();
  }

  Future<List<Course>> getProgrammeCourses(String programmeId) async {
    final response = await _client
        .from('courses')
        .select()
        .eq('programme_id', programmeId)
        .order('level', ascending: true)
        .order('semester', ascending: true);

    return (response as List).map((json) => Course.fromJson(json)).toList();
  }

  Future<int> getMyQuestionCount({
    required String programmeId,
    required int level,
    required int semester,
  }) async {
    // 1. Get courses for this programme, level, and semester
    final coursesResponse = await _client
        .from('courses')
        .select('id')
        .eq('programme_id', programmeId)
        .eq('level', level)
        .eq('semester', semester);

    final courseIds = (coursesResponse as List).map((c) => c['id'] as String).toList();
    if (courseIds.isEmpty) return 0;

    // 2. Count questions belonging to those courses
    final response = await _client
        .from('past_questions')
        .select('id')
        .inFilter('course_id', courseIds);

    return (response as List).length;
  }

  Future<int> getUniversityCount() async {
    final response = await _client
        .from('universities')
        .select()
        .count(CountOption.exact);
    return response.count;
  }
}

final questionCountProvider = FutureProvider<int>((ref) async {
  final profile = await ref.watch(myProfileProvider.future);
  if (profile == null || profile.programmeId.isEmpty) return 0;

  return ref.read(courseServiceProvider).getMyQuestionCount(
        programmeId: profile.programmeId,
        level: profile.currentLevel,
        semester: profile.currentSemester,
      );
});

final universityCountProvider = FutureProvider<int>((ref) {
  return ref.watch(courseServiceProvider).getUniversityCount();
});

final myCoursesProvider = FutureProvider<List<Course>>((ref) async {
  final profile = await ref.watch(myProfileProvider.future);
  if (profile == null || profile.programmeId.isEmpty) return [];

  return ref.read(courseServiceProvider).getMyCourses(
        programmeId: profile.programmeId,
        level: profile.currentLevel,
        semester: profile.currentSemester,
      );
});

final programmeCoursesProvider = FutureProvider<List<Course>>((ref) async {
  final profile = await ref.watch(myProfileProvider.future);
  if (profile == null || profile.programmeId.isEmpty) return [];

  return ref.read(courseServiceProvider).getProgrammeCourses(profile.programmeId);
});
