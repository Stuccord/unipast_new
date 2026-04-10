import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.7.1';

const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;

serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: { 'Access-Control-Allow-Origin': '*' } });
  }

  try {
    const signature = req.headers.get('x-paystack-signature');
    const rawBody = await req.text();
    const secret = Deno.env.get('PAYSTACK_SECRET_KEY')!;

    if (!signature) {
      console.error('Missing Paystack signature header');
      return new Response('Unauthorized', { status: 401 });
    }

    // Verify HMAC SHA512
    const key = await crypto.subtle.importKey(
      'raw',
      new TextEncoder().encode(secret),
      { name: 'HMAC', hash: 'SHA-512' },
      false,
      ['sign']
    );
    const hmac = await crypto.subtle.sign('HMAC', key, new TextEncoder().encode(rawBody));
    const hmacHex = Array.from(new Uint8Array(hmac))
      .map((b) => b.toString(16).padStart(2, '0'))
      .join('');

    if (hmacHex !== signature) {
      console.error('Invalid Paystack signature match attempt');
      return new Response('Forbidden', { status: 403 });
    }

    const body = JSON.parse(rawBody);
    console.log('PAYSTACK_WEBHOOK_VERIFIED:', JSON.stringify(body, null, 2));

    const { event, data } = body;

    if (event !== 'charge.success' && event !== 'paymentrequest.success') {
      console.log(`Skipping event type: ${event}`);
      return new Response(JSON.stringify({ received: true }), { status: 200 });
    }

    const { reference, amount, currency, customer } = data;
    const email = customer?.email;

    console.log(`Processing Reference: ${reference}, Email: ${email}, Amount: ${amount}`);

    if (!reference) {
      console.error('CRITICAL: Missing reference in Paystack payload');
      return new Response('Bad Request', { status: 400 });
    }

    // Use service role to bypass RLS
    const supabase = createClient(supabaseUrl, serviceRoleKey);
   
    // Robust Metadata Extraction
    let metadata = data?.metadata;
    if (typeof metadata === 'string' && metadata.trim().startsWith('{')) {
      try { metadata = JSON.parse(metadata); } catch (e) {}
    }
    
    let userId: string | null = metadata?.user_id ?? null;
    console.log(`Extracted userId from metadata: ${userId}`);
 
    if (!userId && email) {
      console.log(`Falling back to email lookup for: ${email}`);
      const { data: authUser } = await supabase.rpc('get_user_id_by_email', {
        user_email: email,
      });
      // The RPC returns a table/array
      userId = Array.isArray(authUser) ? authUser[0]?.id : authUser?.id;
      console.log(`Email lookup result: ${userId}`);
    }

    if (!userId) {
      console.error(`FATAL: Could not identify user for ${email}. Metadata was:`, metadata);
      return new Response(JSON.stringify({ error: 'User not found' }), { status: 404 });
    }

    // Calculate expiration (e.g., 120 days)
    const expiresAt = new Date();
    expiresAt.setDate(expiresAt.getDate() + 120);

    console.log(`Calling activate_subscription RPC for user ${userId}...`);

    const { error: rpcError } = await supabase.rpc('activate_subscription', {
      target_user_id: userId,
      target_ref: reference,
      target_amount_pesewas: amount,
      target_currency: currency || 'GHS',
      target_expires_at: expiresAt.toISOString(),
      target_admin_secret: Deno.env.get('ADMIN_SECRET_KEY') || 'UNIPAST_SECURE_2026',
    });

    if (rpcError) {
      console.error(`DATABASE_ERROR: RPC failed: ${rpcError.message}`);
      return new Response(JSON.stringify({ error: rpcError.message }), { status: 500 });
    }

    console.log(`✅ SUCCESS: Subscription activated for ${userId}`);
    return new Response(JSON.stringify({ success: true }), { status: 200 });
  } catch (err: any) {
    console.error(`INTERNAL_SERVER_ERROR: ${err.message}`);
    return new Response(JSON.stringify({ error: err.message }), { status: 400 });
  }
});
