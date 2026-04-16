'use client'

import { useState, useEffect, Suspense } from 'react'
import { useSearchParams } from 'next/navigation'
import { supabase } from '@/lib/supabase'
import {
  GraduationCap,
  CheckCircle,
  Star,
  Shield,
  Download,
  Wifi,
  BellRing,
  BookOpen,
  Lock,
  Loader2,
  AlertCircle,
  ArrowRight,
  Sparkles,
} from 'lucide-react'

const BENEFITS = [
  { icon: BookOpen, text: 'Unlimited access to all past questions' },
  { icon: Download, text: 'Offline downloads for any exam paper' },
  { icon: Wifi, text: 'AI-powered explanations for every solution' },
  { icon: BellRing, text: 'Instant notifications for new uploads' },
  { icon: Star, text: 'Personalized recommendations by course' },
  { icon: Shield, text: 'Secure & private — your data stays yours' },
]

const AMOUNT_GHS = 30      // Display: GHS 30
const AMOUNT_PESEWAS = 3000 // Paystack: amount in lowest denomination

function PaymentContent() {
  const searchParams = useSearchParams()
  const [user, setUser] = useState<any>(null)
  const [loading, setLoading] = useState(true)
  const [paying, setPaying] = useState(false)
  const [error, setError] = useState<string | null>(null)

  // Pre-fill from query params (deep link from mobile app or direct share)
  const prefillEmail = searchParams.get('email') || ''

  useEffect(() => {
    const getUser = async () => {
      const { data: { user } } = await supabase.auth.getUser()
      setUser(user)
      setLoading(false)
    }
    getUser()
  }, [])

  const handlePayment = async () => {
    const email = user?.email || prefillEmail
    if (!email) {
      setError('Please log in to continue with payment.')
      return
    }

    const userId = user?.id
    if (!userId) {
      setError('User session not found. Please log in.')
      return
    }

    setPaying(true)
    setError(null)

    try {
      const baseUrl = window.location.origin
      const callbackUrl = `${baseUrl}/api/payment/verify`

      const res = await fetch('/api/payment/init', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          email,
          amount: AMOUNT_PESEWAS,
          userId,
          callbackUrl,
        }),
      })

      const data = await res.json()

      if (!res.ok || data.error) {
        throw new Error(data.error || 'Failed to initialize payment. Please try again.')
      }

      // Redirect to Paystack checkout
      window.location.href = data.authorization_url
    } catch (err: any) {
      setError(err.message || 'Something went wrong. Please try again.')
      setPaying(false)
    }
  }

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-teal-600 via-teal-700 to-slate-900">
        <Loader2 className="animate-spin text-white" size={40} />
      </div>
    )
  }

  const displayEmail = user?.email || prefillEmail

  return (
    <div className="min-h-screen bg-gradient-to-br from-teal-600 via-teal-700 to-slate-900 flex items-center justify-center px-4 py-12 relative overflow-hidden">
      {/* Ambient blobs */}
      <div className="absolute top-[-20%] left-[-10%] w-[600px] h-[600px] bg-teal-400/20 rounded-full blur-[120px] pointer-events-none" />
      <div className="absolute bottom-[-20%] right-[-10%] w-[500px] h-[500px] bg-cyan-300/10 rounded-full blur-[120px] pointer-events-none" />

      {/* Card */}
      <div className="relative w-full max-w-lg bg-white/10 backdrop-blur-xl rounded-[2.5rem] border border-white/20 shadow-2xl overflow-hidden">
        {/* Header */}
        <div className="p-10 pb-6 text-center relative">
          <div className="inline-flex items-center justify-center w-20 h-20 rounded-3xl bg-amber-400/20 border border-amber-400/30 mb-6 shadow-lg shadow-amber-400/20">
            <GraduationCap size={40} className="text-amber-300" />
          </div>
          <div className="inline-flex items-center space-x-2 bg-amber-400/20 border border-amber-400/30 rounded-full px-4 py-1.5 mb-4">
            <Sparkles size={14} className="text-amber-300" />
            <span className="text-amber-200 text-xs font-bold uppercase tracking-widest">UniPast Premium</span>
          </div>
          <h1 className="text-3xl font-black text-white tracking-tight leading-tight">
            Unlock All Past<br />Questions
          </h1>
          <p className="text-teal-100/80 mt-3 text-sm leading-relaxed">
            Get full semester access to every past question, solution, and AI explanation on UniPast.
          </p>

          {/* Price badge */}
          <div className="mt-6 inline-flex flex-col items-center">
            <div className="bg-white/10 border border-white/20 rounded-2xl px-8 py-4">
              <span className="text-teal-200 text-sm font-bold">One-time per semester</span>
              <div className="flex items-baseline justify-center space-x-1 mt-1">
                <span className="text-white text-2xl font-bold">GH₵</span>
                <span className="text-white text-5xl font-black tracking-tight">{AMOUNT_GHS}</span>
              </div>
            </div>
          </div>
        </div>

        {/* Divider */}
        <div className="mx-10 border-t border-white/10" />

        {/* Benefits */}
        <div className="px-10 py-6 space-y-3">
          {BENEFITS.map(({ icon: Icon, text }) => (
            <div key={text} className="flex items-center space-x-3">
              <div className="flex-shrink-0 w-8 h-8 rounded-xl bg-teal-400/20 flex items-center justify-center">
                <Icon size={16} className="text-teal-300" />
              </div>
              <span className="text-white/85 text-sm font-medium">{text}</span>
            </div>
          ))}
        </div>

        {/* Divider */}
        <div className="mx-10 border-t border-white/10" />

        {/* CTA */}
        <div className="px-10 py-8 space-y-4">
          {/* Error message */}
          {error && (
            <div className="flex items-start space-x-3 bg-rose-500/20 border border-rose-400/30 rounded-2xl p-4">
              <AlertCircle size={18} className="text-rose-300 flex-shrink-0 mt-0.5" />
              <p className="text-rose-200 text-sm font-medium">{error}</p>
            </div>
          )}

          {/* User session chip */}
          {displayEmail && (
            <div className="flex items-center space-x-2 bg-white/10 border border-white/20 rounded-xl px-4 py-2.5">
              <div className="w-7 h-7 rounded-full bg-teal-400/30 flex items-center justify-center text-teal-200 text-xs font-black uppercase">
                {displayEmail.charAt(0)}
              </div>
              <span className="text-white/80 text-sm font-medium truncate">{displayEmail}</span>
              <CheckCircle size={14} className="text-emerald-400 flex-shrink-0 ml-auto" />
            </div>
          )}

          {!user && !prefillEmail && (
            <div className="bg-amber-400/10 border border-amber-400/20 rounded-2xl p-4 text-center">
              <p className="text-amber-200 text-sm font-medium">
                Please{' '}
                <a href="/login" className="underline font-bold hover:text-amber-100">
                  log in to your UniPast account
                </a>{' '}
                to subscribe.
              </p>
            </div>
          )}

          {/* Subscribe button */}
          <button
            id="subscribe-btn"
            onClick={handlePayment}
            disabled={paying || (!user && !prefillEmail)}
            className="w-full bg-amber-400 hover:bg-amber-300 disabled:opacity-50 disabled:cursor-not-allowed text-slate-900 font-black text-lg py-5 rounded-2xl flex items-center justify-center space-x-3 transition-all shadow-2xl shadow-amber-400/30 active:scale-[0.98] hover:scale-[1.01]"
          >
            {paying ? (
              <>
                <Loader2 size={22} className="animate-spin" />
                <span>Connecting to Paystack...</span>
              </>
            ) : (
              <>
                <Lock size={20} />
                <span>Pay Securely – GH₵{AMOUNT_GHS}</span>
                <ArrowRight size={20} />
              </>
            )}
          </button>

          {/* Trust indicators */}
          <div className="flex items-center justify-center space-x-4 pt-2">
            <div className="flex items-center space-x-1.5 text-white/40 text-xs">
              <Shield size={12} />
              <span>256-bit SSL</span>
            </div>
            <div className="w-px h-3 bg-white/20" />
            <span className="text-white/40 text-xs">Secured by Paystack</span>
            <div className="w-px h-3 bg-white/20" />
            <div className="flex items-center space-x-1.5 text-white/40 text-xs">
              <CheckCircle size={12} />
              <span>Instant Access</span>
            </div>
          </div>

          {/* MoMo tip */}
          <div className="bg-white/5 border border-white/10 rounded-2xl p-4 text-center">
            <p className="text-teal-200/70 text-xs leading-relaxed">
              <strong className="text-amber-300">MoMo Tip:</strong> If you don&apos;t see a payment prompt, dial{' '}
              <strong>*170#</strong> (MTN) or <strong>*110#</strong> (Telecel) and approve under My Wallet / Transactions.
            </p>
          </div>

          {/* Already paid */}
          <p className="text-center text-white/40 text-xs">
            Already paid?{' '}
            <a href="/payment/callback?status=check" className="text-teal-300 hover:underline font-semibold">
              Check subscription status
            </a>
          </p>
        </div>
      </div>
    </div>
  )
}

export default function PaymentPage() {
  return (
    <Suspense>
      <PaymentContent />
    </Suspense>
  )
}
