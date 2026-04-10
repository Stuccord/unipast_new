import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:unipast/core/supabase_config.dart';
import 'package:unipast/features/admin/activity_service.dart';

final adminServiceProvider = Provider<AdminService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final activityService = ref.watch(activityServiceProvider);
  return AdminService(client, activityService);
});

class AdminService {
  final SupabaseClient _client;
  final ActivityService _activityService;
  AdminService(this._client, this._activityService);

  // Stats
  Future<Map<String, dynamic>> getStats() async {
    final signupRes =
        await _client.from('profiles').select().count(CountOption.exact);

    final subscriptionRes = await _client
        .from('subscriptions')
        .select()
        .eq('status', 'active')
        .count(CountOption.exact);

    final List<dynamic> transactions =
        await _client.from('transactions').select('amount');
    final totalRevenue = transactions.fold<double>(
        0, (sum, item) => sum + (item['amount'] as num).toDouble());

    return {
      'total_signups': signupRes.count,
      'active_subscriptions': subscriptionRes.count,
      'total_revenue': totalRevenue,
    };
  }

  // University CRUD
  Future<List<Map<String, dynamic>>> getUniversities() async {
    final List<dynamic> data = await _client.from('universities').select();
    return data.cast<Map<String, dynamic>>();
  }

  Future<void> addUniversity(String name, String category) async {
    await _client.from('universities').insert({
      'name': name,
      'category': category,
    });

    await _activityService.recordActivity(
      eventType: 'update',
      description: 'Added university: $name ($category)',
    );
  }

  Future<void> deleteUniversity(String id) async {
    await _client.from('universities').delete().eq('id', id);
    await _activityService.recordActivity(
      eventType: 'delete',
      description: 'Deleted university ID: $id',
    );
  }

  // Faculty CRUD
  Future<List<Map<String, dynamic>>> getFaculties(String universityId) async {
    final List<dynamic> data = await _client
        .from('faculties')
        .select()
        .eq('university_id', universityId);
    return data.cast<Map<String, dynamic>>();
  }

  Future<void> addFaculty(String universityId, String name) async {
    await _client.from('faculties').insert({
      'university_id': universityId,
      'name': name,
    });
  }

  // Programme CRUD
  Future<List<Map<String, dynamic>>> getProgrammes(String facultyId) async {
    final List<dynamic> data =
        await _client.from('programmes').select().eq('faculty_id', facultyId);
    return data.cast<Map<String, dynamic>>();
  }

  Future<void> addProgramme(String facultyId, String name, int duration) async {
    await _client.from('programmes').insert({
      'faculty_id': facultyId,
      'name': name,
      'duration_years': duration,
    });
  }

  // Course CRUD
  Future<List<Map<String, dynamic>>> getCourses(String programmeId) async {
    final List<dynamic> data =
        await _client.from('courses').select().eq('programme_id', programmeId);
    return data.cast<Map<String, dynamic>>();
  }

  Future<void> addCourse(String programmeId, String code, String name) async {
    await _client.from('courses').insert({
      'programme_id': programmeId,
      'code': code,
      'name': name,
    });
  }

  // Content Upload
  Future<void> uploadPastQuestion({
    required String courseId,
    required int year,
    required int semester,
    required String fileName,
    required List<int> fileBytes,
  }) async {
    final path = '$courseId/$year/$semester/$fileName';

    // 1. Upload to storage
    await _client.storage
        .from('questions')
        .uploadBinary(path, Uint8List.fromList(fileBytes));

    // 2. Insert record
    await _client.from('past_questions').insert({
      'course_id': courseId,
      'year': year,
      'semester': semester,
      'pdf_url': path,
    });

    await _activityService.recordActivity(
      eventType: 'upload',
      description: 'Uploaded past question: $fileName',
      metadata: {'course_id': courseId, 'year': year, 'semester': semester},
    );
  }

  // Rep Management
  Future<void> assignRep(String userId, bool isRep) async {
    await _client.from('profiles').update({'is_rep': isRep}).eq('id', userId);
  }

  // Payment History
  Future<List<Map<String, dynamic>>> getPaymentHistory() async {
    return await _client
        .from('transactions')
        .select('*, profiles(full_name)')
        .order('created_at', ascending: false);
  }
}
