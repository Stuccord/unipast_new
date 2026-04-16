import { NextRequest, NextResponse } from 'next/server'
import { createClient } from '@supabase/supabase-js'

export async function GET(req: NextRequest) {
  const { searchParams } = new URL(req.url)
  const reference = searchParams.get('reference')
  const trxref = searchParams.get('trxref')

  const ref = reference || trxref

  if (!ref) {
    return NextResponse.redirect(new URL('/payment?status=error&message=missing_reference', req.url))
  }

  try {
    const secretKey = process.env.PAYSTACK_SECRET_KEY
    if (!secretKey) throw new Error('Payment gateway not configured')

    // Verify with Paystack
    const verifyRes = await fetch(
      `https://api.paystack.co/transaction/verify/${encodeURIComponent(ref)}`,
      {
        headers: { Authorization: `Bearer ${secretKey}` },
      }
    )
    const verifyData = await verifyRes.json()

    if (!verifyData.status || verifyData.data?.status !== 'success') {
      return NextResponse.redirect(
        new URL(`/payment/callback?status=failed&reference=${ref}`, req.url)
      )
    }

    const userId = verifyData.data?.metadata?.user_id
    if (!userId) {
      return NextResponse.redirect(
        new URL(`/payment/callback?status=failed&reference=${ref}&reason=no_user`, req.url)
      )
    }

    // Activate subscription via Supabase service role
    const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!
    const serviceKey = process.env.SUPABASE_SERVICE_ROLE_KEY!
    const supabase = createClient(supabaseUrl, serviceKey)

    const expiresAt = new Date()
    expiresAt.setDate(expiresAt.getDate() + 120) // ~1 semester

    const { error: rpcError } = await supabase.rpc('activate_subscription', {
      target_user_id: userId,
      target_ref: ref,
      target_amount_pesewas: verifyData.data.amount,
      target_currency: verifyData.data.currency || 'GHS',
      target_expires_at: expiresAt.toISOString(),
      target_admin_secret: process.env.ADMIN_SECRET_KEY || 'UNIPAST_SECURE_2026',
    })

    if (rpcError) {
      console.error('RPC Error activating subscription:', rpcError)
      // Still redirect as success since payment went through; webhook may handle it
      return NextResponse.redirect(
        new URL(`/payment/callback?status=success&reference=${ref}&activation=pending`, req.url)
      )
    }

    return NextResponse.redirect(
      new URL(`/payment/callback?status=success&reference=${ref}`, req.url)
    )
  } catch (err: any) {
    console.error('Payment verify error:', err)
    return NextResponse.redirect(
      new URL(`/payment/callback?status=error&reference=${ref}`, req.url)
    )
  }
}
