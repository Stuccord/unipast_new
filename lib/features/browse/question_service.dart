import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unipast/core/supabase_config.dart';
import 'package:unipast/features/browse/question_model.dart';

final questionServiceProvider = Provider<QuestionService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return QuestionService(client);
});

class QuestionService {
  final SupabaseClient _client;
  QuestionService(this._client);

  Future<List<PastQuestion>> getQuestionsByCourse(String courseId) async {
    final List<dynamic> response = await _client
        .from('past_questions')
        .select()
        .eq('course_id', courseId)
        .order('year', ascending: false);
    
    if (response.isEmpty) return [];

    return response.map((json) {
      final question = PastQuestion.fromJson(json as Map<String, dynamic>);
      final publicUrl = getFileUrl(question.pdfUrl);
      return PastQuestion(
        id: question.id,
        courseId: question.courseId,
        year: question.year,
        semester: question.semester,
        pdfUrl: publicUrl,
        answerUrl: question.answerUrl,
        createdAt: question.createdAt,
      );
    }).toList();
  }

  Future<List<PastQuestion>> getQuestionsByProgramme(String programmeId) async {
    final List<dynamic> response = await _client
        .from('past_questions')
        .select('*, courses!inner(*)')
        .eq('courses.programme_id', programmeId)
        .order('year', ascending: false);

    if (response.isEmpty) return [];

    return response.map((json) {
      final question = PastQuestion.fromJson(json as Map<String, dynamic>);
      final publicUrl = getFileUrl(question.pdfUrl);
      return PastQuestion(
        id: question.id,
        courseId: question.courseId,
        year: question.year,
        semester: question.semester,
        pdfUrl: publicUrl,
        answerUrl: question.answerUrl,
        createdAt: question.createdAt,
      );
    }).toList();
  }

  String getFileUrl(String path) {
    if (path.startsWith('http')) return path;
    return _client.storage.from('questions').getPublicUrl(path);
  }

  Future<String> getSignedUrl(String path) async {
    // For public buckets, we can just return the public URL
    return getFileUrl(path);
  }
}

final questionsByCourseProvider =
    FutureProvider.family<List<PastQuestion>, String>((ref, courseId) {
  return ref.read(questionServiceProvider).getQuestionsByCourse(courseId);
});

final questionsByProgrammeProvider =
    FutureProvider.family<List<PastQuestion>, String>((ref, programmeId) {
  return ref.read(questionServiceProvider).getQuestionsByProgramme(programmeId);
});
