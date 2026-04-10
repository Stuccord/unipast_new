import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

abstract class SupabaseConfig {
  static String get url => dotenv.maybeGet('SUPABASE_URL') ?? '';
  static String get anonKey => dotenv.maybeGet('SUPABASE_ANON_KEY') ?? '';
}

abstract class PaystackConfig {
  /// Live public key — safe to embed in the client app.
  static String get publicKey =>
      dotenv.maybeGet('PAYSTACK_PUBLIC_KEY') ?? '';
}
