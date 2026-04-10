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
    // 1. Insert University
    final uniBody = jsonEncode({'name': 'Koforidua Technical University'});
    final uniRes = await http.post(Uri.parse('$url/rest/v1/universities'),
        headers: headers, body: uniBody);
    print("Uni: ${uniRes.statusCode} ${uniRes.body}");

    // 2. Insert Faculty
    final facBody = jsonEncode({'name': 'Engineering'});
    final facRes = await http.post(Uri.parse('$url/rest/v1/faculties'),
        headers: headers, body: facBody);
    print("Fac: ${facRes.statusCode} ${facRes.body}");

    // If successful, we can get the IDs and insert a programme
    if (uniRes.statusCode == 201 && facRes.statusCode == 201) {
      final facId = jsonDecode(facRes.body)[0]['id'];

      final progBody =
          jsonEncode({'name': 'Computer Science', 'faculty_id': facId});
      final progRes = await http.post(Uri.parse('$url/rest/v1/programmes'),
          headers: headers, body: progBody);
      print("Prog: ${progRes.statusCode} ${progRes.body}");
    }
  } catch (e) {
    print("Error: $e");
  }
}
