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

  Future<int> getQuestionCount() async {
    final response = await _client
        .from('past_questions')
        .select()
        .count(CountOption.exact);
    return response.count;
  }

  Future<int> getUniversityCount() async {
    final response = await _client
        .from('universities')
        .select()
        .count(CountOption.exact);
    return response.count;
  }
}

final questionCountProvider = FutureProvider<int>((ref) {
  return ref.watch(courseServiceProvider).getQuestionCount();
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
