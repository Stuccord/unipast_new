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
    final body = jsonEncode({
      'title': 'Test Course',
      'code': 'TST101',
      'programme_id': 'Computer Science',
      'level': 100,
      'semester': 1
    });

    final res = await http.post(Uri.parse('$url/rest/v1/courses'),
        headers: headers, body: body);
    print("Insert Course: ${res.statusCode} ${res.body}");
  } catch (e) {
    print("Error: $e");
  }
}
