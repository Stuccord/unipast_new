class PastQuestion {
  final String id;
  final String courseId;
  final String? title;
  final int year;
  final int semester;
  final String pdfUrl;
  final String? answerUrl;
  final DateTime createdAt;

  PastQuestion({
    required this.id,
    required this.courseId,
    this.title,
    required this.year,
    required this.semester,
    required this.pdfUrl,
    this.answerUrl,
    required this.createdAt,
  });

  factory PastQuestion.fromJson(Map<String, dynamic> json) {
    return PastQuestion(
      id: json['id'],
      courseId: json['course_id'],
      title: json['title'],
      year: json['year'],
      semester: json['semester'],
      pdfUrl: json['pdf_url'] ?? json['file_path'] ?? '',
      answerUrl: json['answer_url'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
