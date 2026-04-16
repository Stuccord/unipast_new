'use client'

import { useState, useEffect } from 'react'
import { supabase } from '@/lib/supabase'
import { useRouter } from 'next/navigation'
import { Lock, Loader2, ShieldCheck, Zap, CheckCircle2 } from 'lucide-react'

export default function UpdatePasswordPage() {
    const [password, setPassword] = useState('')
    const [confirmPassword, setConfirmPassword] = useState('')
    const [loading, setLoading] = useState(false)
    const [error, setError] = useState<string | null>(null)
    const [success, setSuccess] = useState(false)
    const router = useRouter()

    useEffect(() => {
        // Check if we have a recovery session
        const checkSession = async () => {
            const { data: { session } } = await supabase.auth.getSession()
            if (!session) {
                // If no session, they shouldn't be here (unless they just finished)
                if (!success) router.push('/login')
            }
        }
        checkSession()
    }, [router, success])

    const handleUpdate = async (e: React.FormEvent) => {
        e.preventDefault()
        if (password !== confirmPassword) {
            setError('NEURAL MISMATCH: PASSWORDS DO NOT ALIGN.')
            return
        }
        if (password.length < 8) {
            setError('SECURITY BREACH: CIPHER TOO WEAK (MIN 8 CHARS).')
            return
        }

        setLoading(true)
        setError(null)

        try {
            const { error: updateError } = await supabase.auth.updateUser({
                password: password
            })

            if (updateError) {
                setError(updateError.message.toUpperCase())
            } else {
                setSuccess(true)
                setTimeout(() => {
                    router.push('/admin')
                }, 3000)
            }
        } catch (err: any) {
            setError(err.message || 'CRITICAL SYSTEM FAILURE')
        } finally {
            setLoading(false)
        }
    }

    return (
        <div className="relative min-h-screen flex flex-col items-center justify-center p-4 bg-bg overflow-hidden font-inter text-white">
            {/* Background Effect */}
            <div className="absolute inset-0 z-0">
                <div className="absolute top-[-10%] right-[-10%] w-[40%] h-[40%] bg-accent/10 rounded-full blur-[120px]" />
                <div className="absolute bottom-[-10%] left-[-10%] w-[40%] h-[40%] bg-primary/10 rounded-full blur-[120px]" />
            </div>

            <div className="relative z-10 w-full max-w-[450px]">
                <div className="bg-card/40 backdrop-blur-2xl rounded-[2.5rem] border border-white/5 shadow-2xl overflow-hidden p-10">
                    <div className="text-center mb-10">
                        <div className="w-20 h-20 bg-primary/10 rounded-3xl flex items-center justify-center mx-auto mb-6 border border-primary/20 shadow-[0_0_20px_rgba(0,255,204,0.1)]">
                            <ShieldCheck size={32} className="text-primary" />
                        </div>
                        <h1 className="text-2xl font-black font-orbitron uppercase tracking-widest mb-2">Cipher Update</h1>
                        <p className="text-white/30 text-[10px] uppercase tracking-[0.3em]">Redefining Security Protocol</p>
                    </div>

                    {success ? (
                        <div className="py-8 text-center animate-in zoom-in duration-500">
                            <div className="w-16 h-16 bg-success/20 rounded-full flex items-center justify-center mx-auto mb-6 border border-success/30">
                                <CheckCircle2 className="text-success" size={28} />
                            </div>
                            <h3 className="text-lg font-bold font-orbitron text-success uppercase tracking-widest mb-4">Update Successful</h3>
                            <p className="text-white/40 text-[10px] uppercase tracking-wider mb-8">NEURAL SYNCHRONIZATION COMPLETE. REDIRECTING TO TERMINAL...</p>
                            <Loader2 className="animate-spin text-primary mx-auto" size={24} />
                        </div>
                    ) : (
                        <form onSubmit={handleUpdate} className="space-y-6">
                            {error && (
                                <div className="p-4 bg-danger/10 border border-danger/20 rounded-2xl text-[10px] font-black text-danger uppercase tracking-widest animate-shake">
                                    {error}
                                </div>
                            )}

                            <div className="space-y-2">
                                <label className="text-[10px] font-black text-white/40 uppercase tracking-[0.2em] font-orbitron ml-1">New Cipher</label>
                                <div className="relative group">
                                    <div className="absolute left-4 top-1/2 -translate-y-1/2 text-white/20 group-focus-within:text-primary transition-colors">
                                        <Lock size={18} />
                                    </div>
                                    <input
                                        type="password"
                                        required
                                        value={password}
                                        onChange={(e) => setPassword(e.target.value)}
                                        className="w-full bg-white/5 border border-white/5 rounded-2xl pl-12 pr-4 py-4 text-sm font-medium focus:ring-4 focus:ring-primary/5 focus:border-primary outline-none transition-all"
                                        placeholder="••••••••••••"
                                    />
                                </div>
                            </div>

                            <div className="space-y-2">
                                <label className="text-[10px] font-black text-white/40 uppercase tracking-[0.2em] font-orbitron ml-1">Confirm Cipher</label>
                                <div className="relative group">
                                    <div className="absolute left-4 top-1/2 -translate-y-1/2 text-white/20 group-focus-within:text-primary transition-colors">
                                        <Lock size={18} />
                                    </div>
                                    <input
                                        type="password"
                                        required
                                        value={confirmPassword}
                                        onChange={(e) => setConfirmPassword(e.target.value)}
                                        className="w-full bg-white/5 border border-white/5 rounded-2xl pl-12 pr-4 py-4 text-sm font-medium focus:ring-4 focus:ring-primary/5 focus:border-primary outline-none transition-all"
                                        placeholder="••••••••••••"
                                    />
                                </div>
                            </div>

                            <button
                                type="submit"
                                disabled={loading}
                                className="w-full h-[60px] bg-primary rounded-2xl text-card font-black font-orbitron uppercase tracking-[0.3em] text-sm flex items-center justify-center gap-3 hover:bg-primary/90 transition-all shadow-[0_0_20px_rgba(0,255,204,0.3)] disabled:opacity-50"
                            >
                                {loading ? <Loader2 size={18} className="animate-spin" /> : (
                                    <>
                                        Update Protocol
                                        <Zap size={16} className="fill-current" />
                                    </>
                                )}
                            </button>
                        </form>
                    )}
                </div>
            </div>
        </div>
    )
}
