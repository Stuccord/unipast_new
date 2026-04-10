class Course {
  final String id;
  final String code;
  final String title;
  final int level;
  final int semester;
  final String programmeId;

  Course({
    required this.id,
    required this.code,
    required this.title,
    required this.level,
    required this.semester,
    required this.programmeId,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['id'],
      code: json['code'],
      title: json['title'],
      level: json['level'],
      semester: json['semester'],
      programmeId: json['programme_id'],
    );
  }
}
