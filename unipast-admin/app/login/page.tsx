'use client'

import { useState } from 'react'
import { supabase } from '@/lib/supabase'
import { useRouter } from 'next/navigation'
import { Mail, Lock, Eye, EyeOff, Loader2, ShieldCheck, Zap } from 'lucide-react'

export default function LoginPage() {
    const [email, setEmail] = useState('')
    const [password, setPassword] = useState('')
    const [showPassword, setShowPassword] = useState(false)
    const [loading, setLoading] = useState(false)
    const [error, setError] = useState<string | null>(null)
    const [debugStep, setDebugStep] = useState<string | null>(null)
    const [mode, setMode] = useState<'login' | 'reset'>('login')
    const [resetSent, setResetSent] = useState(false)
    const router = useRouter()

    const handleResetPassword = async (e: React.FormEvent) => {
        e.preventDefault()
        setLoading(true)
        setError(null)
        setDebugStep('Initiating Recovery...')

        try {
            const { error: resetError } = await supabase.auth.resetPasswordForEmail(email, {
                redirectTo: `${window.location.origin}/login/update-password`,
            })

            if (resetError) {
                setError(resetError.message)
            } else {
                setResetSent(true)
            }
        } catch (err: any) {
            setError(err.message || 'Recovery failed')
        } finally {
            setLoading(false)
            setDebugStep(null)
        }
    }

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
        <div className="relative min-h-screen flex flex-col items-center justify-center p-4 bg-bg overflow-hidden font-inter">
            {/* Animated Neural Background Effect */}
            <div className="absolute inset-0 z-0">
                <div className="absolute top-[-10%] left-[-10%] w-[40%] h-[40%] bg-primary/20 rounded-full blur-[120px] animate-pulse" />
                <div className="absolute bottom-[-10%] right-[-10%] w-[40%] h-[40%] bg-secondary/20 rounded-full blur-[120px] animate-pulse" style={{ animationDelay: '2s' }} />
                <div className="absolute inset-0 opacity-[0.03]" 
                    style={{
                        backgroundImage: `radial-gradient(circle at 2px 2px, #00FFCC 1px, transparent 0)`,
                        backgroundSize: '32px 32px'
                    }}
                />
            </div>

            {/* Login Card */}
            <div className="relative z-10 w-full max-w-[450px] animate-in fade-in slide-in-from-bottom-8 duration-700">
                {/* Logo Section */}
                <div className="flex flex-col items-center mb-10">
                    <div className="relative w-24 h-24 mb-6">
                        <div className="absolute inset-0 bg-primary/20 rounded-2xl blur-xl animate-pulse" />
                        <div className="relative w-full h-full bg-card/80 backdrop-blur-xl border-2 border-primary/50 rounded-2xl flex items-center justify-center shadow-[0_0_30px_rgba(0,255,204,0.3)]">
                            <div className="relative">
                                <span className="text-4xl font-black font-orbitron text-primary tracking-tighter">U</span>
                                <div className="absolute -top-1 -right-4 w-3 h-3 bg-accent rounded-full animate-bounce shadow-[0_0_10px_#FFB800]" />
                            </div>
                        </div>
                    </div>
                    <h1 className="text-3xl font-black font-orbitron text-white tracking-[0.2em] mb-2 uppercase">UniPast</h1>
                    <div className="flex items-center gap-2">
                        <div className="h-[1px] w-8 bg-primary/30" />
                        <p className="text-primary/70 text-[10px] font-black uppercase tracking-[0.3em] font-orbitron">Admin Portal</p>
                        <div className="h-[1px] w-8 bg-primary/30" />
                    </div>
                </div>

                {/* Glass Card */}
                <div className="bg-card/40 backdrop-blur-2xl rounded-3xl border border-white/10 shadow-[0_20px_50px_rgba(0,0,0,0.5)] overflow-hidden">
                    <div className="p-10">
                        <div className="mb-10 text-center">
                            <h2 className="text-xl font-bold font-orbitron text-white mb-2 uppercase tracking-wide">
                                {mode === 'login' ? 'Initialize Connection' : 'Neural Recovery'}
                            </h2>
                            <p className="text-white/50 text-xs font-medium uppercase tracking-widest leading-relaxed">
                                {mode === 'login' 
                                    ? 'AUTHENTICATE YOUR CREDENTIALS TO ACCESS THE CORE' 
                                    : 'SUPPLY YOUR NEURO-ADDRESS TO RESET THE SECURITY CIPHER'}
                            </p>
                        </div>

                        {resetSent ? (
                            <div className="space-y-8 py-4 animate-in fade-in zoom-in duration-500">
                                <div className="bg-primary/10 border border-primary/20 p-8 rounded-3xl text-center">
                                    <div className="w-16 h-16 bg-primary/20 rounded-2xl flex items-center justify-center mx-auto mb-6 shadow-[0_0_20px_rgba(0,255,204,0.2)]">
                                        <Mail className="text-primary" size={28} />
                                    </div>
                                    <h3 className="text-white font-bold font-orbitron uppercase tracking-widest mb-3">Signal Dispatched</h3>
                                    <p className="text-white/40 text-[10px] leading-relaxed uppercase tracking-wider">
                                        AN ENCRYPTED RECOVERY UPLINK HAS BEEN SENT TO <br/>
                                        <span className="text-primary">{email.toUpperCase()}</span>
                                    </p>
                                </div>
                                <button 
                                    onClick={() => { setMode('login'); setResetSent(false); }}
                                    className="w-full py-4 text-[10px] font-black text-white/30 hover:text-white uppercase tracking-[0.3em] font-orbitron transition-all"
                                >
                                    Return to Authentication
                                </button>
                            </div>
                        ) : (
                            <form onSubmit={mode === 'login' ? handleLogin : handleResetPassword} className="space-y-6">
                            {error && (
                                <div className="bg-danger/10 text-danger p-4 rounded-xl text-xs font-bold border border-danger/20 flex items-center gap-3 animate-shake">
                                    <div className="w-1.5 h-1.5 rounded-full bg-danger animate-ping" />
                                    {error.toUpperCase()}
                                </div>
                            )}

                            {debugStep && !error && (
                                <div className="bg-primary/10 text-primary p-4 rounded-xl text-xs font-bold border border-primary/20 flex items-center gap-3 transition-all">
                                    <Loader2 size={16} className="animate-spin" />
                                    {debugStep.toUpperCase()}
                                </div>
                            )}

                            <div className="space-y-2">
                                <label className="text-[10px] font-black text-white/40 uppercase tracking-[0.2em] font-orbitron ml-1">Neuro-Address</label>
                                <div className="relative group">
                                    <div className="absolute left-4 top-1/2 -translate-y-1/2 text-white/30 group-focus-within:text-primary transition-all duration-300">
                                        <Mail size={18} />
                                    </div>
                                    <input
                                        type="email"
                                        required
                                        value={email}
                                        onChange={(e) => setEmail(e.target.value)}
                                        className="w-full pl-12 pr-4 py-4 rounded-2xl border border-white/5 bg-white/5 focus:bg-white/10 focus:ring-4 focus:ring-primary/5 focus:border-primary outline-none transition-all duration-300 text-[15px] font-medium text-white placeholder:text-white/20"
                                        placeholder="user@unipast.core"
                                    />
                                </div>
                            </div>

                            {mode === 'login' && (
                                <div className="space-y-2">
                                    <label className="text-[10px] font-black text-white/40 uppercase tracking-[0.2em] font-orbitron ml-1">Security Cipher</label>
                                    <div className="relative group">
                                        <div className="absolute left-4 top-1/2 -translate-y-1/2 text-white/30 group-focus-within:text-primary transition-all duration-300">
                                            <Lock size={18} />
                                        </div>
                                        <input
                                            type={showPassword ? 'text' : 'password'}
                                            required
                                            value={password}
                                            onChange={(e) => setPassword(e.target.value)}
                                            className="w-full pl-12 pr-12 py-4 rounded-2xl border border-white/5 bg-white/5 focus:bg-white/10 focus:ring-4 focus:ring-primary/5 focus:border-primary outline-none transition-all duration-300 text-[15px] font-medium text-white placeholder:text-white/20"
                                            placeholder="••••••••••••"
                                        />
                                        <button
                                            type="button"
                                            onClick={() => setShowPassword(!showPassword)}
                                            className="absolute right-4 top-1/2 -translate-y-1/2 text-white/30 hover:text-primary transition-colors"
                                        >
                                            {showPassword ? <EyeOff size={18} /> : <Eye size={18} />}
                                        </button>
                                    </div>
                                </div>
                            )}

                            <button
                                type="submit"
                                disabled={loading}
                                className="group relative w-full h-[60px] mt-4 flex items-center justify-center overflow-hidden rounded-2xl transition-all duration-500 disabled:opacity-50"
                            >
                                <div className="absolute inset-0 bg-primary group-hover:bg-primary/90 transition-colors" />
                                <div className="absolute inset-0 opacity-0 group-hover:opacity-20 bg-[linear-gradient(45deg,transparent,rgba(255,255,255,0.4),transparent)] -translate-x-full group-hover:translate-x-full transition-all duration-1000" />
                                <span className="relative text-card text-sm font-black font-orbitron uppercase tracking-[0.3em] flex items-center gap-3">
                                    {loading ? (
                                        <Loader2 size={18} className="animate-spin" />
                                    ) : (
                                        <>
                                            Authenticate
                                            <Zap size={16} className="fill-current" />
                                        </>
                                    )}
                                </span>
                            </button>

                            <div className="pt-6 flex flex-col items-center gap-4">
                                <button 
                                    type="button" 
                                    onClick={() => setMode(mode === 'login' ? 'reset' : 'login')}
                                    className="text-[10px] font-black text-white/30 hover:text-primary uppercase tracking-[0.2em] font-orbitron transition-colors"
                                >
                                    {mode === 'login' ? 'Forgot security cipher?' : 'Return to Authentication'}
                                </button>
                                {mode === 'login' && (
                                    <>
                                        <div className="h-[1px] w-12 bg-white/5" />
                                        <div className="flex items-center gap-3 py-1 cursor-pointer group">
                                            <div className="w-4 h-4 rounded-md border-2 border-white/10 group-hover:border-primary/50 transition-all flex items-center justify-center overflow-hidden">
                                                <input
                                                    type="checkbox"
                                                    id="remember"
                                                    className="opacity-0 absolute w-4 h-4 cursor-pointer"
                                                />
                                                <ShieldCheck size={12} className="text-primary translate-y-4 group-hover:translate-y-0 transition-all duration-300" />
                                            </div>
                                            <label htmlFor="remember" className="text-[10px] font-black text-white/30 cursor-pointer group-hover:text-white transition-colors uppercase tracking-widest">
                                                Persist Connection
                                            </label>
                                        </div>
                                    </>
                                )}
                            </div>
                        </form>
                      )}
                    </div>
                </div>

                <div className="mt-12 text-center">
                    <p className="text-[10px] font-black text-white/10 uppercase tracking-[0.4em] font-orbitron">
                        UniPast Operational Terminal v4.0.2
                    </p>
                </div>
            </div>

            <style jsx global>{`
                @keyframes shake {
                    0%, 100% { transform: translateX(0); }
                    25% { transform: translateX(-4px); }
                    75% { transform: translateX(4px); }
                }
                .animate-shake {
                    animation: shake 0.2s ease-in-out infinite alternate;
                    animation-iteration-count: 2;
                }
            `}</style>
        </div>
    )
}

