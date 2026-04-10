
class Activity {
  final String id;
  final String? userId;
  final String eventType;
  final String description;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final String? userName; // Joined from profiles

  Activity({
    required this.id,
    this.userId,
    required this.eventType,
    required this.description,
    required this.metadata,
    required this.createdAt,
    this.userName,
  });

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      id: json['id'],
      userId: json['user_id'],
      eventType: json['event_type'],
      description: json['description'],
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      createdAt: DateTime.parse(json['created_at']),
      userName: json['profiles']?['full_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'event_type': eventType,
      'description': description,
      'metadata': metadata,
    };
  }
}
