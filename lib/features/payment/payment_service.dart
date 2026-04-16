import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unipast/core/supabase_config.dart';
import 'package:unipast/features/auth/auth_service.dart';
import 'package:unipast/features/payment/subscription_model.dart';
import 'package:unipast/features/admin/activity_service.dart';

class PaymentService {
  final SupabaseClient _client;
  final ActivityService _activityService;
  PaymentService(this._client, this._activityService);

  /// Initializes a Paystack transaction via the Supabase Edge Function
  /// `paystack-init`.
  Future<Map<String, String>?> initializeTransaction({
    required String email,
    required int amountPesewas,
    required String userId,
  }) async {
    try {
      // On web, Paystack redirects back to the Next.js web app which verifies
      // & activates the subscription server-side.
      // On mobile, we use the app's deep link; verification is handled in-app.
      final callbackUrl = kIsWeb
          ? SupabaseConfig.webPaymentCallbackUrl
          : 'https://unipast.app/payment/callback';

      final response = await _client.functions.invoke('paystack-init', body: {
        'email': email,
        'amount': amountPesewas,
        'currency': 'GHS',
        'user_id': userId,
        'callback_url': callbackUrl,
      }, headers: {
        'apikey': SupabaseConfig.anonKey,
      });
 
      if (response.status != 200) {
        final data = response.data as Map<String, dynamic>?;
        throw Exception(data?['error'] ?? 'Function failed with status ${response.status}');
      }
 
      final data = response.data as Map<String, dynamic>?;
      final url = data?['authorization_url'] as String?;
      final reference = data?['reference'] as String?;
      
      if (url == null || reference == null) throw Exception('Incomplete response from gateway');
      
      return {
        'url': url,
        'reference': reference,
      };
    } catch (e) {
      rethrow;
    }
  }

  Future<void> verifySubscription(String reference, String userId) async {
    try {
      // Secure verification via Edge Function instead of direct DB RPC
      final response = await _client.functions.invoke('verify-payment', body: {
        'reference': reference,
        'user_id': userId,
      });

      if (response.status != 200) {
        final data = response.data as Map<String, dynamic>?;
        throw Exception(data?['error'] ?? 'Verification failed with status ${response.status}');
      }

      await _activityService.recordActivity(
        eventType: 'payment',
        description: 'Subscription activation requested (Ref: $reference)',
        userId: userId,
        metadata: {'reference': reference, 'amount': 3000},
      );
    } catch (e) {
      // Log error but don't block the UI if the webhook might still succeed
      print('Fallback activation failed: $e');
    }
  }
}

final paymentServiceProvider = Provider<PaymentService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final activityService = ref.watch(activityServiceProvider);
  return PaymentService(client, activityService);
});

final mySubscriptionProvider = StreamProvider<Subscription?>((ref) {
  // Watch auth state changes so this provider rebuilds when a user logs in/out
  ref.watch(authStateChangesProvider);
  
  final client = ref.watch(supabaseClientProvider);
  final user = client.auth.currentUser;
  
  if (user == null) return Stream.value(null);

  // SECURE & PROFESSIONAL: Only stream rows belonging to THIS user.
  // This reduces data usage and ensures privacy.
  return client
      .from('subscriptions')
      .stream(primaryKey: ['id'])
      .eq('user_id', user.id)
      .map((data) {
        if (data.isEmpty) return null;
        
        // Find the most recent active/inactive subscription
        final activeSub = data.firstWhere(
          (row) => row['status'] == 'active', 
          orElse: () => data.first
        );
        
        return Subscription.fromJson(activeSub);
      });
});
