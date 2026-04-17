import 'package:isar/isar.dart';

part 'profile_model.g.dart';

@collection
class UserProfile {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true, name: 'uid')
  final String id;

  final String fullName;
  final String universityId;
  final String facultyId;
  final String programmeId;
  final int currentLevel;
  final int currentSemester;
  final DateTime? notificationsClearedAt;
  final bool isRep;
  final bool isAdmin;

  UserProfile({
    required this.id,
    required this.fullName,
    required this.universityId,
    required this.facultyId,
    required this.programmeId,
    required this.currentLevel,
    required this.currentSemester,
    this.notificationsClearedAt,
    this.isRep = false,
    this.isAdmin = false,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '',
      universityId: json['university_id'] as String? ?? '',
      facultyId: json['faculty_id'] as String? ?? '',
      programmeId: json['programme_id'] as String? ?? '',
      currentLevel: json['current_level'] as int? ?? 0,
      currentSemester: json['current_semester'] as int? ?? 0,
      notificationsClearedAt: json['notifications_cleared_at'] != null 
          ? DateTime.parse(json['notifications_cleared_at'] as String) 
          : null,
      isRep: json['is_rep'] as bool? ?? false,
      isAdmin: json['is_admin'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'university_id': universityId,
      'faculty_id': facultyId,
      'programme_id': programmeId,
      'current_level': currentLevel,
      'current_semester': currentSemester,
      'notifications_cleared_at': notificationsClearedAt?.toIso8601String(),
      'is_rep': isRep,
      'is_admin': isAdmin,
    };
  }
}
