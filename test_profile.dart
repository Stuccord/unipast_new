import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io';

Future<void> main() async {
  final envFile = File('.env');
  final lines = await envFile.readAsLines();
  String? url;
  String? anonKey;
  for (final line in lines) {
    if (line.startsWith('SUPABASE_URL=')) url = line.substring(13).trim();
    if (line.startsWith('SUPABASE_ANON_KEY='))
      anonKey = line.substring(18).trim();
  }

  final headers = {
    'apikey': anonKey!,
    'Authorization': 'Bearer $anonKey',
    'Content-Type': 'application/json',
    'Prefer': 'return=representation'
  };

  try {
    // Generate a random UUID-like string for ID
    final fakeId = '123e4567-e89b-12d3-a456-426614174000';

    final body = jsonEncode({
      'id': fakeId,
      'full_name': 'Test User',
      'university_id': '223e4567-e89b-12d3-a456-426614174001',
      'faculty_id': '323e4567-e89b-12d3-a456-426614174002',
      'programme_id': '423e4567-e89b-12d3-a456-426614174003',
      'current_level': 100,
      'current_semester': 1
    });

    final res = await http.post(Uri.parse('$url/rest/v1/profiles'),
        headers: headers, body: body);
    print("Insert Profile: ${res.statusCode} ${res.body}");
  } catch (e) {
    print("Error: $e");
  }
}
