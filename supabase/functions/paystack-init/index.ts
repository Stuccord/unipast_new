// @ts-nocheck — Deno Edge Function (not Node.js/TypeScript)
// Supabase Edge Function: paystack-init
// Deploy via: Supabase Dashboard → Edge Functions → New Function
//
// Required secret (set in Supabase Dashboard → Edge Functions → Secrets):
//   PAYSTACK_SECRET_KEY

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

serve(async (req: Request) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const { email, amount, currency, user_id, callback_url } = await req.json();

    if (!email || !amount) {
      return new Response(
        JSON.stringify({ error: 'Missing required fields: email, amount' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    // Secret key is stored securely in Supabase — never in the app
    const secretKey = Deno.env.get('PAYSTACK_SECRET_KEY');
    if (!secretKey) {
      return new Response(
        JSON.stringify({ error: 'PAYSTACK_SECRET_KEY secret not configured' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    // Initialize transaction with Paystack
    const paystackRes = await fetch('https://api.paystack.co/transaction/initialize', {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${secretKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        email,
        amount,                        // in pesewas (GHS 30.00 = 3000)
        currency: currency ?? 'GHS',
        callback_url: callback_url ?? 'https://unipast.app/payment/callback',
        metadata: {
          user_id: user_id, // Store Supabase ID in Paystack for instant webhook identification
        },
      }),
    });

    const paystackData = await paystackRes.json();

    if (!paystackData.status) {
      return new Response(
        JSON.stringify({ error: paystackData.message ?? 'Paystack error' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    // Return the checkout URL to the Flutter app
    return new Response(
      JSON.stringify({
        authorization_url: paystackData.data.authorization_url,
        access_code: paystackData.data.access_code,
        reference: paystackData.data.reference,
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    );
  } catch (err) {
    return new Response(
      JSON.stringify({ error: String(err) }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    );
  }
});
