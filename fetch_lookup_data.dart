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
    final uniRes = await http.get(
        Uri.parse('$url/rest/v1/universities?select=id,name'),
        headers: headers);
    print("Universities: ${uniRes.body}");

    final facRes = await http.get(
        Uri.parse('$url/rest/v1/faculties?select=id,name'),
        headers: headers);
    print("Faculties: ${facRes.body}");

    final progRes = await http.get(
        Uri.parse('$url/rest/v1/programmes?select=id,name,faculty_id'),
        headers: headers);
    print("Programmes: ${progRes.body}");
  } catch (e) {
    print("Error: $e");
  }
}
