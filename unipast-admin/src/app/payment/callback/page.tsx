'use client'

import { useEffect, useState, Suspense } from 'react'
import { useSearchParams } from 'next/navigation'
import { supabase } from '@/lib/supabase'
import {
  CheckCircle2,
  XCircle,
  Loader2,
  GraduationCap,
  RefreshCw,
  Home,
  ArrowRight,
  AlertCircle,
  Clock,
  Sparkles,
} from 'lucide-react'

type PaymentStatus = 'loading' | 'success' | 'failed' | 'pending' | 'checking' | 'error' | 'check'

function CallbackContent() {
  const searchParams = useSearchParams()
  const status = (searchParams.get('status') || 'loading') as PaymentStatus
  const reference = searchParams.get('reference') || ''
  const activation = searchParams.get('activation') || ''
  const reason = searchParams.get('reason') || ''

  const [subStatus, setSubStatus] = useState<any>(null)
  const [checking, setChecking] = useState(false)

  useEffect(() => {
    if (status === 'success' || status === 'check') {
      checkSubscriptionStatus()
    }
  }, [status])

  const checkSubscriptionStatus = async () => {
    setChecking(true)
    try {
      const { data: { user } } = await supabase.auth.getUser()
      if (!user) { setChecking(false); return }

      const { data: sub } = await supabase
        .from('subscriptions')
        .select('*')
        .eq('user_id', user.id)
        .eq('status', 'active')
        .order('created_at', { ascending: false })
        .limit(1)
        .single()

      setSubStatus(sub)
    } catch {
      setSubStatus(null)
    } finally {
      setChecking(false)
    }
  }

  const config: Record<string, {
    icon: React.ReactNode
    title: string
    subtitle: string
    color: string
    bgColor: string
    borderColor: string
  }> = {
    success: {
      icon: <CheckCircle2 size={56} className="text-emerald-400" />,
      title: 'Payment Successful!',
      subtitle: subStatus
        ? `Your UniPast Premium subscription is now active until ${new Date(subStatus.expires_at).toLocaleDateString('en-GB', { day: 'numeric', month: 'long', year: 'numeric' })}.`
        : activation === 'pending'
          ? 'Your payment was received. Subscription activation may take up to 60 seconds.'
          : 'Your UniPast Premium subscription is now active. Open the app to access all content!',
      color: 'text-emerald-400',
      bgColor: 'bg-emerald-400/10',
      borderColor: 'border-emerald-400/30',
    },
    pending: {
      icon: <Clock size={56} className="text-amber-400" />,
      title: 'Payment Pending',
      subtitle: 'Your payment is being processed. This usually takes a few seconds to a minute. Please check your MoMo wallet.',
      color: 'text-amber-400',
      bgColor: 'bg-amber-400/10',
      borderColor: 'border-amber-400/30',
    },
    failed: {
      icon: <XCircle size={56} className="text-rose-400" />,
      title: 'Payment Failed',
      subtitle: reason === 'no_user'
        ? 'Payment processed but we could not link it to your account. Please contact support with your reference.'
        : 'Your payment could not be completed. No charges were made. Please try again.',
      color: 'text-rose-400',
      bgColor: 'bg-rose-400/10',
      borderColor: 'border-rose-400/30',
    },
    error: {
      icon: <AlertCircle size={56} className="text-orange-400" />,
      title: 'Something Went Wrong',
      subtitle: 'We encountered an issue verifying your payment. If money was deducted, please contact support with your reference number.',
      color: 'text-orange-400',
      bgColor: 'bg-orange-400/10',
      borderColor: 'border-orange-400/30',
    },
    check: {
      icon: <Sparkles size={56} className="text-teal-400" />,
      title: 'Subscription Status',
      subtitle: checking
        ? 'Fetching your subscription...'
        : subStatus
          ? `Active until ${new Date(subStatus.expires_at).toLocaleDateString('en-GB', { day: 'numeric', month: 'long', year: 'numeric' })}.`
          : 'No active subscription found. Subscribe to unlock all features.',
      color: 'text-teal-400',
      bgColor: 'bg-teal-400/10',
      borderColor: 'border-teal-400/30',
    },
    loading: {
      icon: <Loader2 size={56} className="text-teal-400 animate-spin" />,
      title: 'Verifying Payment...',
      subtitle: 'Please wait while we confirm your transaction.',
      color: 'text-teal-400',
      bgColor: 'bg-teal-400/10',
      borderColor: 'border-teal-400/30',
    },
  }

  const current = config[status] || config.error

  return (
    <div className="min-h-screen bg-gradient-to-br from-teal-600 via-teal-700 to-slate-900 flex items-center justify-center px-4 py-12 relative overflow-hidden">
      {/* Ambient */}
      <div className="absolute top-[-20%] left-[-10%] w-[600px] h-[600px] bg-teal-400/20 rounded-full blur-[120px] pointer-events-none" />
      <div className="absolute bottom-[-20%] right-[-10%] w-[500px] h-[500px] bg-cyan-300/10 rounded-full blur-[120px] pointer-events-none" />

      <div className="relative w-full max-w-md bg-white/10 backdrop-blur-xl rounded-[2.5rem] border border-white/20 shadow-2xl overflow-hidden">
        {/* Logo */}
        <div className="flex items-center justify-center pt-10 pb-2">
          <div className="flex items-center space-x-2">
            <div className="bg-teal-400/20 border border-teal-400/30 p-2 rounded-xl">
              <GraduationCap size={24} className="text-teal-300" />
            </div>
            <span className="text-white text-xl font-black tracking-tight">UniPast</span>
          </div>
        </div>

        {/* Status */}
        <div className="px-10 py-8 text-center space-y-4">
          <div className={`inline-flex items-center justify-center w-24 h-24 rounded-3xl ${current.bgColor} border ${current.borderColor} mb-2`}>
            {current.icon}
          </div>

          <h2 className="text-2xl font-black text-white tracking-tight">{current.title}</h2>
          <p className="text-white/70 text-sm leading-relaxed">{current.subtitle}</p>

          {/* Reference badge */}
          {reference && (
            <div className="bg-white/5 border border-white/10 rounded-xl px-4 py-2.5 text-center">
              <p className="text-white/40 text-[10px] uppercase tracking-widest font-bold mb-0.5">Transaction Reference</p>
              <p className="text-white/80 text-sm font-mono font-bold break-all">{reference}</p>
            </div>
          )}

          {/* Check again button for pending/error */}
          {(status === 'pending' || status === 'error' || status === 'check') && (
            <button
              onClick={checkSubscriptionStatus}
              disabled={checking}
              className="inline-flex items-center space-x-2 bg-white/10 hover:bg-white/15 border border-white/20 text-white font-bold px-6 py-3 rounded-2xl transition-all text-sm disabled:opacity-50"
            >
              {checking ? <Loader2 size={16} className="animate-spin" /> : <RefreshCw size={16} />}
              <span>{checking ? 'Checking...' : 'Refresh Status'}</span>
            </button>
          )}
        </div>

        {/* Actions */}
        <div className="px-10 pb-10 space-y-3">
          {status === 'success' || status === 'check' ? (
            <a
              href="/"
              className="w-full bg-amber-400 hover:bg-amber-300 text-slate-900 font-black py-4 rounded-2xl flex items-center justify-center space-x-2 transition-all shadow-xl shadow-amber-400/20 hover:scale-[1.01] active:scale-[0.98]"
            >
              <Home size={20} />
              <span>Go to Dashboard</span>
              <ArrowRight size={20} />
            </a>
          ) : (
            <a
              href="/payment"
              className="w-full bg-amber-400 hover:bg-amber-300 text-slate-900 font-black py-4 rounded-2xl flex items-center justify-center space-x-2 transition-all shadow-xl shadow-amber-400/20 hover:scale-[1.01] active:scale-[0.98]"
            >
              <span>Try Again</span>
              <ArrowRight size={20} />
            </a>
          )}

          <a
            href="/"
            className="w-full text-white/50 hover:text-white/70 font-bold py-3 rounded-2xl flex items-center justify-center transition-colors text-sm"
          >
            Back to Home
          </a>
        </div>
      </div>
    </div>
  )
}

export default function PaymentCallbackPage() {
  return (
    <Suspense>
      <CallbackContent />
    </Suspense>
  )
}
