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
  };

  try {
    final coursesRes = await http.get(
        Uri.parse('$url/rest/v1/courses?select=*&limit=1'),
        headers: headers);
    print("Courses: ${coursesRes.body}");

    final profilesRes = await http.get(
        Uri.parse('$url/rest/v1/profiles?select=*&limit=1'),
        headers: headers);
    print("Profiles: ${profilesRes.body}");

    final pqRes = await http.get(
        Uri.parse('$url/rest/v1/past_questions?select=*&limit=1'),
        headers: headers);
    print("Past Questions: ${pqRes.body}");
  } catch (e) {
    print("Error: $e");
  }
}
