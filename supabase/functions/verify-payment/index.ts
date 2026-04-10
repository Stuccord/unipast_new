import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.7.1';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const { reference, user_id } = await req.json();

    if (!reference || !user_id) {
      return new Response(
        JSON.stringify({ error: 'Missing reference or user_id' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    const paystackSecret = Deno.env.get('PAYSTACK_SECRET_KEY');
    if (!paystackSecret) {
      throw new Error('PAYSTACK_SECRET_KEY not configured');
    }

    // 1. Verify with Paystack API
    console.log(`Verifying reference: ${reference} for user: ${user_id}`);
    const verifyRes = await fetch(`https://api.paystack.co/transaction/verify/${encodeURIComponent(reference)}`, {
      headers: {
        Authorization: `Bearer ${paystackSecret}`,
      },
    });

    const verifyData = await verifyRes.json();

    if (!verifyData.status || verifyData.data.status !== 'success') {
      console.error('Paystack verification failed:', verifyData);
      return new Response(
        JSON.stringify({ error: 'Payment not verified or failed', detail: verifyData.message }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // 2. Security Check: Ensure the metadata user_id matches the requested user_id
    // This prevents one user from using another user's successful reference.
    const paystackUserId = verifyData.data.metadata?.user_id;
    if (paystackUserId !== user_id) {
      console.error(`Fraud Attempt: User ${user_id} tried to use reference belonging to ${paystackUserId}`);
      return new Response(
        JSON.stringify({ error: 'Transaction reference does not belong to this user' }),
        { status: 403, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // 3. Activate via RPC using service role
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    const supabase = createClient(supabaseUrl, serviceRoleKey);

    const expiresAt = new Date();
    expiresAt.setDate(expiresAt.getDate() + 120);

    const { error: rpcError } = await supabase.rpc('activate_subscription', {
      target_user_id: user_id,
      target_ref: reference,
      target_amount_pesewas: verifyData.data.amount,
      target_currency: verifyData.data.currency || 'GHS',
      target_expires_at: expiresAt.toISOString(),
      target_admin_secret: Deno.env.get('ADMIN_SECRET_KEY') || 'UNIPAST_SECURE_2026',
    });

    if (rpcError) {
      console.error('RPC Error:', rpcError);
      return new Response(
        JSON.stringify({ error: 'Failed to update database', details: rpcError.message }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    return new Response(
      JSON.stringify({ success: true, message: 'Subscription activated' }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );

  } catch (err: any) {
    console.error('Internal Error:', err.message);
    return new Response(
      JSON.stringify({ error: err.message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }
});
