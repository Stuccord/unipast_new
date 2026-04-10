'use client'

import { useState } from 'react'
import { supabase } from '@/lib/supabase'
import { useRouter } from 'next/navigation'
import { Mail, Lock, Eye, EyeOff, Loader2 } from 'lucide-react'

export default function LoginPage() {
    const [email, setEmail] = useState('')
    const [password, setPassword] = useState('')
    const [showPassword, setShowPassword] = useState(false)
    const [loading, setLoading] = useState(false)
    const [error, setError] = useState<string | null>(null)
    const [debugStep, setDebugStep] = useState<string | null>(null)
    const router = useRouter()

    const handleLogin = async (e: React.FormEvent) => {
        e.preventDefault()
        setLoading(true)
        setError(null)
        setDebugStep('Authenticating...')

        try {
            const { data, error: authError } = await supabase.auth.signInWithPassword({
                email,
                password,
            })

            if (authError) {
                setError(authError.message)
                setLoading(false)
                setDebugStep(null)
                return
            }

            setDebugStep('Checking permissions...')
            const { data: profile, error: profileError } = await supabase
                .from('profiles')
                .select('is_admin, role, is_rep')
                .eq('id', data.user.id)
                .single()

            const isAllowed = profile?.is_admin || profile?.role === 'rep' || profile?.is_rep

            if (profileError || !isAllowed) {
                await supabase.auth.signOut()
                setError('Access denied. Admin or Representative privileges required.')
                setLoading(false)
                setDebugStep(null)
                return
            }

            setDebugStep('Redirecting...')
            window.location.href = '/admin'
        } catch (err: any) {
            setError(err.message || 'An unexpected error occurred')
            setLoading(false)
            setDebugStep(null)
        }
    }

    return (
        <div className="relative min-h-screen flex flex-col items-center justify-center p-4">
            {/* Premium CSS Background */}
            <div className="fixed inset-0 z-0 bg-[#042F2C]">
                {/* Modern Mesh Gradient / "Glassmorphism" feel */}
                <div className="absolute inset-0 opacity-40" 
                    style={{
                        backgroundImage: `
                            radial-gradient(at 0% 0%, #0D9488 0, transparent 50%),
                            radial-gradient(at 50% 0%, #115E59 0, transparent 50%),
                            radial-gradient(at 100% 0%, #0D9488 0, transparent 50%),
                            radial-gradient(at 50% 100%, #134E4A 0, transparent 50%)
                        `
                    }} 
                />
                <div className="absolute inset-0 bg-slate-900/20 backdrop-blur-[2px]" />
                
                {/* Subtle animated overlay */}
                <div className="absolute inset-0 opacity-20 animate-pulse-slow" 
                    style={{
                        backgroundImage: 'radial-gradient(circle at 2px 2px, rgba(255,255,255,0.05) 1px, transparent 0)',
                        backgroundSize: '40px 40px'
                    }}
                />
            </div>

            {/* Login Card */}
            <div className="relative z-10 w-full max-w-[400px] bg-white rounded-2xl shadow-2xl overflow-hidden border border-white/20 transition-all hover:shadow-teal-900/20">
                {/* Card Header */}
                <div className="bg-[#0D9488] p-8 text-white text-center flex flex-col items-center">
                    <div className="w-16 h-16 mb-4 relative drop-shadow-md">
                        {/* Placeholder for UniPast Logo - Using a stylized icon for now */}
                        <div className="w-full h-full bg-white/20 rounded-xl flex items-center justify-center backdrop-blur-md">
                            <span className="text-3xl font-bold tracking-tighter">U</span>
                        </div>
                        <div className="absolute -top-1 -right-1 text-yellow-400">
                            <svg className="w-5 h-5 fill-current" viewBox="0 0 24 24">
                                <path d="M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z" />
                            </svg>
                        </div>
                    </div>
                    <h1 className="text-2xl font-bold tracking-tight">Admin Portal Login</h1>
                    <p className="mt-1 text-teal-50/80 text-sm font-medium">Welcome back! Please sign in to manage UniPast.</p>
                </div>

                {/* Form Section */}
                <form onSubmit={handleLogin} className="p-8 space-y-5">
                    {error && (
                        <div className="bg-red-50 text-red-600 p-3 rounded-xl text-xs font-semibold border border-red-100 animate-in fade-in slide-in-from-top-1 duration-300">
                            {error}
                        </div>
                    )}

                    {debugStep && !error && (
                        <div className="bg-teal-50 text-teal-700 p-3 rounded-xl text-xs font-semibold border border-teal-100 flex items-center gap-2">
                            <Loader2 size={14} className="animate-spin" />
                            {debugStep}
                        </div>
                    )}

                    <div className="space-y-1.5">
                        <label className="text-[13px] font-bold text-slate-700 ml-1">Email Address</label>
                        <div className="relative group">
                            <div className="absolute left-3.5 top-1/2 -translate-y-1/2 text-slate-400 group-focus-within:text-teal-600 transition-colors">
                                <Mail size={18} />
                            </div>
                            <input
                                type="email"
                                required
                                value={email}
                                onChange={(e) => setEmail(e.target.value)}
                                className="w-full pl-11 pr-4 py-3 rounded-xl border border-slate-200 focus:ring-2 focus:ring-teal-600/10 focus:border-teal-600 outline-none transition text-[15px] text-slate-900 bg-slate-50/50 hover:bg-slate-50"
                                placeholder="yourname@email.com"
                            />
                        </div>
                    </div>

                    <div className="space-y-1.5">
                        <label className="text-[13px] font-bold text-slate-700 ml-1">Password</label>
                        <div className="relative group">
                            <div className="absolute left-3.5 top-1/2 -translate-y-1/2 text-slate-400 group-focus-within:text-teal-600 transition-colors">
                                <Lock size={18} />
                            </div>
                            <input
                                type={showPassword ? 'text' : 'password'}
                                required
                                value={password}
                                onChange={(e) => setPassword(e.target.value)}
                                className="w-full pl-11 pr-11 py-3 rounded-xl border border-slate-200 focus:ring-2 focus:ring-teal-600/10 focus:border-teal-600 outline-none transition text-[15px] text-slate-900 bg-slate-50/50 hover:bg-slate-50"
                                placeholder="Enter your password"
                            />
                            <button
                                type="button"
                                onClick={() => setShowPassword(!showPassword)}
                                className="absolute right-3.5 top-1/2 -translate-y-1/2 text-slate-400 hover:text-teal-600 transition-colors"
                            >
                                {showPassword ? <EyeOff size={18} /> : <Eye size={18} />}
                            </button>
                        </div>
                        <div className="flex justify-end pt-1">
                            <button type="button" className="text-[13px] font-bold text-teal-600 hover:text-teal-700 hover:underline">
                                Forgot password?
                            </button>
                        </div>
                    </div>

                    <button
                        type="submit"
                        disabled={loading}
                        className="w-full bg-[#0D9488] hover:bg-teal-700 text-white font-bold py-3.5 rounded-xl shadow-lg shadow-teal-900/20 transition-all transform active:scale-[0.98] disabled:opacity-70 disabled:cursor-not-allowed uppercase tracking-wider text-sm mt-2"
                    >
                        {loading ? 'Sign In...' : 'Sign In'}
                    </button>

                    <div className="flex items-center gap-2 pt-1 ml-1 cursor-pointer group">
                        <input
                            type="checkbox"
                            id="remember"
                            className="w-4 h-4 rounded border-slate-300 text-teal-600 focus:ring-teal-600"
                        />
                        <label htmlFor="remember" className="text-[13px] font-bold text-slate-600 cursor-pointer group-hover:text-slate-800 transition-colors">
                            Remember me
                        </label>
                    </div>
                </form>
            </div>

            {/* Footer */}
            <div className="mt-8 text-center text-slate-600/80">
                <p className="text-[13px] font-medium tracking-tight">
                    © 2024 UniPast Ltd. All rights reserved. | <span className="font-bold cursor-pointer hover:text-slate-900">Terms & Privacy</span>
                </p>
                <p className="text-[12px] font-medium mt-1">
                    Responsive Design | Optimized for Web
                </p>
            </div>

            <style jsx global>{`
                @keyframes pulse-slow {
                    0%, 100% { opacity: 0.95; }
                    50% { opacity: 1; }
                }
                .animate-pulse-slow {
                    animation: pulse-slow 8s ease-in-out infinite;
                }
            `}</style>
        </div>
    )
}
