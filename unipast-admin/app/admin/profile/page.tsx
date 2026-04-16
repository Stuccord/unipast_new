'use client'

import { useState, useEffect } from 'react'
import { User, Mail, Shield, Camera, Edit2, Loader2, CheckCircle2, AlertCircle, Cpu, Zap, Activity, Monitor } from 'lucide-react'
import { supabase } from '@/lib/supabase'
import { updateProfileFull, uploadProfilePicture } from './actions'

export default function ProfilePage() {
    const [profile, setProfile] = useState<any>(null)
    const [loading, setLoading] = useState(true)
    const [updating, setUpdating] = useState(false)
    const [uploadingImage, setUploadingImage] = useState(false)
    const [status, setStatus] = useState<{ type: 'success' | 'error', message: string } | null>(null)

    const [formData, setFormData] = useState({
        full_name: '',
        email: '',
        current_level: 100,
        current_semester: 1
    })

    useEffect(() => {
        fetchProfile()
    }, [])

    async function fetchProfile() {
        setLoading(true)
        try {
            const { data: { user } } = await supabase.auth.getUser()
            if (user) {
                const { data, error } = await supabase
                    .from('profiles')
                    .select('*')
                    .eq('id', user.id)
                    .single()
                
                if (data) {
                    setProfile(data)
                    setFormData({
                        full_name: data.full_name || '',
                        email: data.email || user.email || '',
                        current_level: data.current_level || 100,
                        current_semester: data.current_semester || 1
                    })
                }
            }
        } catch (error) {
            console.error('Error fetching profile:', error)
        } finally {
            setLoading(false)
        }
    }

    async function handleUpdate(e: React.FormEvent) {
        e.preventDefault()
        setUpdating(true)
        setStatus(null)
        try {
            const { data: { user } } = await supabase.auth.getUser()
            if (!user) throw new Error('No user found')

            const formDataObj = new FormData()
            formDataObj.append('full_name', formData.full_name)
            formDataObj.append('email', formData.email)
            formDataObj.append('current_level', String(formData.current_level))
            formDataObj.append('current_semester', String(formData.current_semester))

            const result = await updateProfileFull(user.id, formDataObj)
            if (result.error) throw new Error(result.error)
            
            setStatus({ type: 'success', message: 'DATA STREAM SYNCED. DOSSIER UPDATED.' })
            fetchProfile()
        } catch (error: any) {
            setStatus({ type: 'error', message: error.message || 'DOSSIER UPDATE FAILURE' })
        } finally {
            setUpdating(false)
        }
    }

    async function handleImageUpload(e: React.ChangeEvent<HTMLInputElement>) {
        const file = e.target.files?.[0]
        if (!file) return

        setUploadingImage(true)
        setStatus(null)

        try {
            const { data: { user } } = await supabase.auth.getUser()
            if (!user) throw new Error('No user found')

            const formDataObj = new FormData()
            formDataObj.append('file', file)

            const result = await uploadProfilePicture(user.id, formDataObj)
            if (result.error) throw new Error(result.error)

            setStatus({ type: 'success', message: 'NEURAL INTERFACE UPDATED.' })
            fetchProfile()
        } catch (error: any) {
            setStatus({ type: 'error', message: error.message || 'INTERFACE UPDATE FAILURE' })
        } finally {
            setUploadingImage(false)
        }
    }

    if (loading) {
        return (
            <div className="flex h-[60vh] items-center justify-center">
                <div className="relative w-24 h-24 mx-auto">
                    <div className="absolute inset-0 border-4 border-primary/20 rounded-full" />
                    <div className="absolute inset-0 border-4 border-primary rounded-full border-t-transparent animate-spin" />
                    <div className="absolute inset-0 flex items-center justify-center">
                        <span className="text-white text-[10px] font-black font-orbitron">SCANNING</span>
                    </div>
                </div>
            </div>
        )
    }

    return (
        <div className="space-y-12 font-orbitron max-w-6xl mx-auto pb-32">
            <div className="flex flex-col space-y-4 animate-in fade-in slide-in-from-top-10 duration-1000">
                <div className="flex items-center gap-3">
                    <div className="p-2.5 bg-primary/10 rounded-xl border border-primary/20">
                        <Monitor size={22} className="text-primary" />
                    </div>
                    <span className="text-[10px] font-black text-primary uppercase tracking-[0.4em]">Personal Node Profile</span>
                </div>
                <h2 className="text-4xl font-black text-white tracking-[0.2em] uppercase">Identity Dossier</h2>
                <p className="text-white/30 font-black text-[10px] uppercase tracking-[0.3em]">Configure administrative credentials and visual interface</p>
            </div>

            <div className="bg-card/20 backdrop-blur-3xl rounded-[3.5rem] border border-white/5 shadow-2xl overflow-hidden animate-in fade-in zoom-in duration-700">
                <div className="p-12 md:p-16 flex flex-col md:flex-row items-center space-y-12 md:space-y-0 md:space-x-16 bg-white/[0.02] border-b border-white/5">
                    <div className="relative group shrink-0">
                        <div className="absolute -inset-1 bg-primary/20 rounded-full blur opacity-0 group-hover:opacity-100 transition-opacity" />
                        <div className="h-44 w-44 rounded-[2.5rem] bg-card border-4 border-white/5 shadow-2xl flex items-center justify-center overflow-hidden relative group-hover:border-primary/50 transition-all duration-700">
                             {profile?.avatar_url ? (
                                <img src={profile.avatar_url} alt="Profile" className="h-full w-full object-cover group-hover:scale-110 transition-transform duration-700" />
                             ) : (
                                <div className="text-6xl font-black text-white/10 tracking-tighter">
                                    {formData.full_name ? formData.full_name.split(' ').map((n: string) => n[0]).join('') : 'U'}
                                </div>
                             )}
                        </div>
                        <label className="absolute -bottom-2 -right-2 p-4 bg-primary text-card rounded-2xl shadow-[0_0_30px_rgba(0,255,204,0.4)] hover:scale-110 active:scale-95 transition-all cursor-pointer z-10">
                            {uploadingImage ? <Loader2 className="animate-spin" size={20} /> : <Camera size={20} />}
                            <input type="file" className="hidden" accept="image/*" onChange={handleImageUpload} disabled={uploadingImage} />
                        </label>
                    </div>
                    <div className="text-center md:text-left space-y-5 min-w-0 flex-1">
                        <h3 className="text-3xl md:text-5xl font-black text-white tracking-[0.05em] uppercase truncate">{formData.full_name || 'Administrator'}</h3>
                        <p className="text-primary font-black text-[10px] md:text-xs uppercase tracking-[0.5em] flex items-center justify-center md:justify-start gap-3">
                            <Shield size={16} className="opacity-50" />
                            {profile?.role || 'Lead Administrator'}
                        </p>
                        <div className="flex items-center justify-center md:justify-start space-x-3 text-white/30 font-black text-[9px] md:text-[11px] uppercase tracking-[0.2em] pt-2">
                            <Mail size={14} className="text-white/10 shrink-0" />
                            <span className="break-all">{formData.email}</span>
                        </div>
                    </div>
                </div>

                <div className="p-10 md:p-16 space-y-12">
                    {status && (
                        <div className={`p-8 rounded-3xl border flex items-center space-x-6 animate-in slide-in-from-top-4 duration-500 shadow-2xl ${
                            status.type === 'success' ? 'bg-primary/5 border-primary/20 text-primary shadow-[0_0_20px_rgba(0,255,204,0.1)]' : 'bg-rose-500/5 border-rose-500/20 text-rose-500 shadow-[0_0_20px_rgba(244,63,94,0.1)]'
                        }`}>
                            <div className={`p-2 rounded-xl border ${status.type === 'success' ? 'bg-primary/20 border-primary/50 text-primary' : 'bg-rose-500/20 border-rose-500/50 text-rose-500'}`}>
                                {status.type === 'success' ? <CheckCircle2 size={24} /> : <AlertCircle size={24} />}
                            </div>
                            <p className="font-black text-xs uppercase tracking-[0.25em]">{status.message}</p>
                        </div>
                    )}

                    <form onSubmit={handleUpdate} className="grid grid-cols-1 md:grid-cols-2 gap-12">
                        <div className="space-y-4">
                            <label className="text-[10px] font-black text-white/30 uppercase tracking-[0.4em] px-2">Core Identity Name</label>
                            <input 
                                type="text" 
                                value={formData.full_name}
                                onChange={(e) => setFormData({ ...formData, full_name: e.target.value })}
                                className="w-full bg-white/5 border border-white/5 rounded-[1.5rem] py-6 px-8 text-white font-black text-xs tracking-[0.2em] focus:ring-4 focus:ring-primary/5 focus:border-primary/30 transition-all outline-none uppercase placeholder:text-white/5" 
                                placeholder="ENTER NAME..."
                            />
                        </div>
                        <div className="space-y-4">
                            <label className="text-[10px] font-black text-white/30 uppercase tracking-[0.4em] px-2">Communication Uplink (Email)</label>
                            <input 
                                type="email" 
                                value={formData.email}
                                onChange={(e) => setFormData({ ...formData, email: e.target.value })}
                                className="w-full bg-white/5 border border-white/5 rounded-[1.5rem] py-6 px-8 text-white font-black text-xs tracking-[0.2em] focus:ring-4 focus:ring-primary/5 focus:border-primary/30 transition-all outline-none uppercase placeholder:text-white/5" 
                                placeholder="ENTER EMAIL..."
                            />
                        </div>
                        <div className="space-y-4">
                            <label className="text-[10px] font-black text-white/30 uppercase tracking-[0.4em] px-2">Academic Stratum (Level)</label>
                            <div className="relative">
                                <select
                                    className="w-full bg-white/5 border border-white/5 rounded-[1.5rem] py-6 px-8 text-white font-black text-xs tracking-[0.3em] focus:ring-4 focus:ring-primary/5 focus:border-primary/30 transition-all outline-none appearance-none cursor-pointer uppercase hover:bg-white/10"
                                    value={formData.current_level}
                                    onChange={(e) => setFormData({ ...formData, current_level: parseInt(e.target.value) })}
                                >
                                    <option value={100} className="bg-bg">LEVEL 100 (STRATUM I)</option>
                                    <option value={200} className="bg-bg">LEVEL 200 (STRATUM II)</option>
                                    <option value={300} className="bg-bg">LEVEL 300 (STRATUM III)</option>
                                    <option value={400} className="bg-bg">LEVEL 400 (STRATUM IV)</option>
                                    <option value={500} className="bg-bg">LEVEL 500 (STRATUM V)</option>
                                    <option value={600} className="bg-bg">LEVEL 600 (STRATUM VI)</option>
                                </select>
                                <div className="absolute right-8 top-1/2 -translate-y-1/2 pointer-events-none text-white/20">
                                    <Activity size={18} />
                                </div>
                            </div>
                        </div>
                        <div className="space-y-4">
                            <label className="text-[10px] font-black text-white/30 uppercase tracking-[0.4em] px-2">Temporal Cycle (Semester)</label>
                            <div className="relative">
                                <select
                                    className="w-full bg-white/5 border border-white/5 rounded-[1.5rem] py-6 px-8 text-white font-black text-xs tracking-[0.3em] focus:ring-4 focus:ring-primary/5 focus:border-primary/30 transition-all outline-none appearance-none cursor-pointer uppercase hover:bg-white/10"
                                    value={formData.current_semester}
                                    onChange={(e) => setFormData({ ...formData, current_semester: parseInt(e.target.value) })}
                                >
                                    <option value={1} className="bg-bg">CYCLE ALPHA (SEM I)</option>
                                    <option value={2} className="bg-bg">CYCLE OMEGA (SEM II)</option>
                                </select>
                                <div className="absolute right-8 top-1/2 -translate-y-1/2 pointer-events-none text-white/20">
                                    <Zap size={18} />
                                </div>
                            </div>
                        </div>

                        <div className="md:col-span-2 pt-10 border-t border-white/5 flex flex-col md:flex-row justify-end items-center gap-8">
                            <button 
                                type="button"
                                onClick={() => fetchProfile()}
                                className="text-white/20 font-black text-[10px] uppercase tracking-[0.4em] hover:text-white transition-colors"
                            >
                                ABORT RECONFIGURATION
                            </button>
                            <button 
                                type="submit"
                                disabled={updating}
                                className="w-full md:w-auto bg-primary hover:bg-primary/90 text-card font-black py-6 px-16 rounded-[1.5rem] transition-all duration-500 shadow-[0_0_30px_rgba(0,255,204,0.3)] disabled:opacity-20 flex items-center justify-center space-x-4 uppercase tracking-[0.4em] text-xs active:scale-[0.98]"
                            >
                                {updating ? <Loader2 className="animate-spin" size={20} /> : <Cpu size={20} />}
                                <span>{updating ? 'SYNCING DATA...' : 'INITIATE SYNC'}</span>
                            </button>
                        </div>
                    </form>
                </div>
            </div>
        </div>
    )
}

