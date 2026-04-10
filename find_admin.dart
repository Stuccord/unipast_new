import 'package:http/http.dart' as http;
import 'dart:io';


Future<void> main() async {
  final envFile = File('.env');
  final lines = await envFile.readAsLines();
  String? url;
  String? serviceRoleKey;
  for (final line in lines) {
    if (line.startsWith('SUPABASE_URL=')) url = line.substring(13).trim();
  }

  // Get service role key from unipast-admin/.env.local
  final adminEnvFile = File('unipast-admin/.env.local');
  if (await adminEnvFile.exists()) {
    final adminLines = await adminEnvFile.readAsLines();
    for (final line in adminLines) {
      if (line.startsWith('SUPABASE_SERVICE_ROLE_KEY=')) {
        serviceRoleKey = line.substring(26).trim();
      }
    }
  }

  if (url == null || serviceRoleKey == null) {
    print("Error: URL or Service Role Key not found");
    return;
  }

  final headers = {
    'apikey': serviceRoleKey,
    'Authorization': 'Bearer $serviceRoleKey',
    'Content-Type': 'application/json',
  };

  try {
    final res = await http.get(
        Uri.parse('$url/rest/v1/profiles?is_admin=eq.true&select=full_name,id'),
        headers: headers);
    print("Admin Profiles: ${res.body}");
  } catch (e) {
    print("Error: $e");
  }
}
