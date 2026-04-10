import 'package:http/http.dart' as http;
import 'dart:io';

Future<void> main() async {
  // Load .env values
  final envFile = File('.env');
  final lines = await envFile.readAsLines();
  String? url;
  String? anonKey;
  for (final line in lines) {
    if (line.startsWith('SUPABASE_URL=')) url = line.substring(13).trim();
    if (line.startsWith('SUPABASE_ANON_KEY='))
      anonKey = line.substring(18).trim();
  }

  if (url == null || anonKey == null) {
    print("❌ Could not find SUPABASE_URL or SUPABASE_ANON_KEY");
    return;
  }

  print("🔗 Supabase URL: $url");
  final headers = {
    'apikey': anonKey,
    'Authorization': 'Bearer $anonKey',
    'Content-Type': 'application/json',
  };

  try {
    // Check if `profiles` table exists by doing a select limit 1
    final profileRes = await http.get(
        Uri.parse('$url/rest/v1/profiles?select=*&limit=1'),
        headers: headers);
    if (profileRes.statusCode == 200) {
      print("✅ Profiles table is responsive. Data: ${profileRes.body}");
    } else {
      print(
          "❌ Profiles table error: ${profileRes.statusCode} - ${profileRes.body}");
    }

    // Check `courses` table
    final coursesRes = await http.get(
        Uri.parse('$url/rest/v1/courses?select=*&limit=1'),
        headers: headers);
    if (coursesRes.statusCode == 200) {
      print("✅ Courses table is responsive.");
    } else {
      print(
          "❌ Courses table error: ${coursesRes.statusCode} - ${coursesRes.body}");
    }

    // Check `past_questions` table
    final pqRes = await http.get(
        Uri.parse('$url/rest/v1/past_questions?select=*&limit=1'),
        headers: headers);
    if (pqRes.statusCode == 200) {
      print("✅ Past questions table is responsive.");
    } else {
      print(
          "❌ Past questions table error: ${pqRes.statusCode} - ${pqRes.body}");
    }
  } catch (e) {
    print("❌ Connection error: $e");
  }
}
