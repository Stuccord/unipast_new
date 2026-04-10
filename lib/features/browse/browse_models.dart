class University {
  final String id;
  final String name;
  final String category;

  University({required this.id, required this.name, required this.category});

  factory University.fromJson(Map<String, dynamic> json) {
    return University(
      id: json['id'],
      name: json['name'],
      category: json['category'],
    );
  }
}

class Faculty {
  final String id;
  final String universityId;
  final String name;

  Faculty({required this.id, required this.universityId, required this.name});

  factory Faculty.fromJson(Map<String, dynamic> json) {
    return Faculty(
      id: json['id'],
      universityId: json['university_id'],
      name: json['name'],
    );
  }
}

class Programme {
  final String id;
  final String facultyId;
  final String name;
  final int durationYears;

  Programme({
    required this.id,
    required this.facultyId,
    required this.name,
    required this.durationYears,
  });

  factory Programme.fromJson(Map<String, dynamic> json) {
    return Programme(
      id: json['id'],
      facultyId: json['faculty_id'],
      name: json['name'],
      durationYears: json['duration_years'],
    );
  }
}
