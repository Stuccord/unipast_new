import { NextRequest, NextResponse } from 'next/server'

const CORS_HEADERS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization',
}

export async function OPTIONS() {
  return new NextResponse(null, { headers: CORS_HEADERS })
}

export async function POST(req: NextRequest) {
  try {
    const body = await req.json()
    const { email, amount, userId, callbackUrl } = body

    if (!email || !amount || !userId) {
      return NextResponse.json(
        { error: 'Missing required fields: email, amount, userId' },
        { status: 400, headers: CORS_HEADERS }
      )
    }

    const secretKey = process.env.PAYSTACK_SECRET_KEY
    if (!secretKey) {
      console.error('PAYSTACK_SECRET_KEY is not set in environment variables')
      return NextResponse.json(
        { error: 'Payment gateway not configured. Contact support.' },
        { status: 500, headers: CORS_HEADERS }
      )
    }

    const baseUrl = process.env.NEXT_PUBLIC_APP_URL || 'http://localhost:3000'
    const finalCallbackUrl = callbackUrl || `${baseUrl}/payment/callback`

    const paystackRes = await fetch('https://api.paystack.co/transaction/initialize', {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${secretKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        email,
        amount,           // in pesewas: GHS 30.00 = 3000
        currency: 'GHS',
        callback_url: finalCallbackUrl,
        metadata: {
          user_id: userId,
          source: 'web',
        },
      }),
    })

    const paystackData = await paystackRes.json()

    if (!paystackData.status) {
      return NextResponse.json(
        { error: paystackData.message || 'Paystack error. Please try again.' },
        { status: 400, headers: CORS_HEADERS }
      )
    }

    return NextResponse.json(
      {
        authorization_url: paystackData.data.authorization_url,
        access_code: paystackData.data.access_code,
        reference: paystackData.data.reference,
      },
      { headers: CORS_HEADERS }
    )
  } catch (err: any) {
    console.error('Payment init error:', err)
    return NextResponse.json(
      { error: 'Internal server error. Please try again.' },
      { status: 500, headers: CORS_HEADERS }
    )
  }
}
