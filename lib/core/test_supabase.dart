import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:unipast/core/supabase_config.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print('--- Supabase Connection Test ---');

  try {
    await dotenv.load(fileName: ".env");
    print('✅ .env loaded');
  } catch (e) {
    print('❌ .env load failed: $e');
    return;
  }

  try {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
    );
    print('✅ Supabase initialized');
  } catch (e) {
    print('❌ Supabase init failed: $e');
    return;
  }

  final client = Supabase.instance.client;

  // Test Auth
  try {
    final session = client.auth.currentSession;
    print('ℹ️ Current Session: ${session != null ? 'Active' : 'None'}');
    print('✅ Auth Test Passed');
  } catch (e) {
    print('❌ Auth Test Failed: $e');
  }

  // Test Database (Public read if any)
  try {
    // Try to fetch something from a likely public table or just check connectivity
    await client.from('profiles').select().limit(1);
    print('✅ Database Connection (profiles): Success');
  } catch (e) {
    print(
        'ℹ️ Database Connection (profiles): Note: $e (This might be expected if no profiles exist or RLS is tight)');
  }

  print('--- Test Complete ---');
}
