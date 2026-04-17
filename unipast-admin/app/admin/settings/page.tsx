'use client'



import { useState, useEffect } from 'react'
import { 
    Settings, Bell, Shield, User, Users, Globe, 
    Mail, ChevronRight, Lock, Eye, EyeOff, Loader2, 
    CheckCircle2, AlertCircle, Cpu, Zap, Radio, Activity
} from 'lucide-react'
import { supabase } from '@/lib/supabase'

type SettingsTab = 'account' | 'notifications' | 'security' | 'system'

export default function SettingsPage() {
    const [activeTab, setActiveTab] = useState<SettingsTab>('account')
    const [changingPassword, setChangingPassword] = useState(false)
    const [showPassword, setShowPassword] = useState(false)
    const [status, setStatus] = useState<{ type: 'success' | 'error', message: string } | null>(null)
    const [profile, setProfile] = useState<any>(null)

    useEffect(() => {
        const fetchProfile = async () => {
            const { data: { user } } = await supabase.auth.getUser()
            if (user) {
                const { data } = await supabase.from('profiles').select('*').eq('id', user.id).single()
                if (data) setProfile(data)
            }
        }
        fetchProfile()
    }, [])
    
    // Form states
    const [passwords, setPasswords] = useState({
        new: '',
        confirm: ''
    })

    const [notifications, setNotifications] = useState({
        email_alerts: true,
        user_registrations: true,
        system_updates: false
    })

    const [system, setSystem] = useState({
        language: 'EN-US (Global Terminal)',
        timezone: 'GMT+00:00 (Neural Sync Time)',
        theme: 'dark' as 'light' | 'dark'
    })

    const handleSave = () => {
        setStatus({ type: 'success', message: 'DATA PACKETS SAVED. PROTOCOL SYNCED.' })
        setTimeout(() => setStatus(null), 3000)
    }

    async function handlePasswordChange(e: React.FormEvent) {
        e.preventDefault()
        if (passwords.new !== passwords.confirm) {
            setStatus({ type: 'error', message: 'CIPHER MISMATCH DETECTED.' })
            return
        }
        
        setChangingPassword(true)
        setStatus(null)
        try {
            const { error } = await supabase.auth.updateUser({
                password: passwords.new
            })
            if (error) throw error
            setStatus({ type: 'success', message: 'ACCESS KEY UPDATED. CLEARANCE MAINTAINED.' })
            setPasswords({ new: '', confirm: '' })
        } catch (error: any) {
            setStatus({ type: 'error', message: 'KEY UPDATE FAILURE: ' + (error.message || 'UNKNOWN ERROR') })
        } finally {
            setChangingPassword(false)
        }
    }

    const tabs = [
        { id: 'account', icon: User, label: 'Dossier', desc: 'Identify Identity' },
        { id: 'notifications', icon: Bell, label: 'Neural Uplink', desc: 'Alert Propagation' },
        { id: 'security', icon: Shield, label: 'Access Cipher', desc: 'Security Protocols' },
        { id: 'system', icon: Globe, label: 'Core Registry', desc: 'Linguistic Engine' },
    ]

    return (
        <div className="space-y-12 font-orbitron pb-32">
            <div className="flex flex-col xl:flex-row xl:items-end justify-between gap-8 animate-in fade-in slide-in-from-top-10 duration-1000">
                <div className="space-y-4">
                    <div className="flex items-center gap-3">
                        <div className="p-2.5 bg-primary/10 rounded-xl border border-primary/20">
                            <Settings size={22} className="text-primary animate-spin-[reverse] [animation-duration:10s]" />
                        </div>
                        <span className="text-[10px] font-black text-primary uppercase tracking-[0.4em]">System Config v2.5</span>
                    </div>
                    <h2 className="text-4xl font-black text-white tracking-[0.2em] uppercase">Executive Overrides</h2>
                    <p className="text-white/30 font-black text-[10px] uppercase tracking-[0.3em]">Calibrate the Unified Command Interface and Access Matrix</p>
                </div>
                
                <div className="flex gap-4">
                    <div className="px-5 py-3 bg-white/5 border border-white/10 rounded-2xl flex items-center gap-3">
                        <div className="w-2 h-2 rounded-full bg-secondary animate-pulse shadow-[0_0_10px_#FFA000]" />
                        <span className="text-[10px] font-black text-white/40 tracking-[0.2em] uppercase">Registry Locked</span>
                    </div>
                </div>
            </div>

            <div className="flex flex-col lg:flex-row gap-12">
                {/* Sidebar Navigation */}
                <div className="w-full lg:w-[350px] shrink-0 space-y-4">
                    {tabs.map((tab) => (
                        <button
                            key={tab.id}
                            onClick={() => {
                                setActiveTab(tab.id as SettingsTab)
                                setStatus(null)
                            }}
                            className={`w-full p-8 rounded-[2rem] flex items-center space-x-6 transition-all duration-500 group relative overflow-hidden ${
                                activeTab === tab.id 
                                ? 'bg-primary text-card shadow-[0_0_40px_rgba(0,255,204,0.2)] scale-[1.02]' 
                                : 'bg-card/20 backdrop-blur-xl text-white/30 hover:bg-white/5 border border-white/5'
                            }`}
                        >
                            {activeTab === tab.id && (
                                <div className="absolute inset-0 bg-white/20 animate-pulse" />
                            )}
                            <div className={`p-4 rounded-2xl relative z-10 transition-colors duration-500 ${activeTab === tab.id ? 'bg-card text-primary' : 'bg-white/5'}`}>
                                <tab.icon size={24} />
                            </div>
                            <div className="text-left relative z-10">
                                <p className={`font-black text-sm tracking-widest uppercase transition-colors duration-500 ${activeTab === tab.id ? 'text-card' : 'text-white'}`}>{tab.label}</p>
                                <p className={`text-[9px] font-black uppercase tracking-[0.2em] mt-1 ${activeTab === tab.id ? 'text-card/60' : 'text-white/20'}`}>
                                    {tab.desc}
                                </p>
                            </div>
                            {activeTab === tab.id && (
                                <ChevronRight className="absolute right-8 text-card" size={20} />
                            )}
                        </button>
                    ))}
                </div>

                {/* Content Area */}
                <div className="flex-1 bg-card/20 backdrop-blur-3xl rounded-[3.5rem] border border-white/5 shadow-2xl overflow-hidden min-h-[650px] animate-in fade-in zoom-in duration-700">
                    <div className="p-12 md:p-14 border-b border-white/5 flex flex-col md:flex-row items-center justify-between gap-6 bg-white/[0.02]">
                        <div className="space-y-3 text-center md:text-left">
                            <h3 className="text-2xl md:text-3xl font-black text-white uppercase tracking-[0.2em]">{activeTab} Array</h3>
                            <p className="text-[9px] font-black text-white/20 uppercase tracking-[0.4em]">Protocol Sequence Authorization Required</p>
                        </div>
                        {status && (
                            <div className={`px-6 py-3 rounded-xl border flex items-center space-x-3 text-[10px] font-black uppercase tracking-widest animate-in slide-in-from-top-4 duration-500 ${
                                status.type === 'success' ? 'bg-primary/5 border-primary/20 text-primary shadow-[0_0_20px_rgba(0,255,204,0.1)]' : 'bg-danger/5 border-danger/20 text-danger shadow-[0_0_20px_rgba(255,51,51,0.1)]'
                            }`}>
                                {status.type === 'success' ? <CheckCircle2 size={16} /> : <AlertCircle size={16} />}
                                <span>{status.message}</span>
                            </div>
                        )}
                    </div>

                    <div className="p-12 space-y-12">
                        {activeTab === 'account' && (
                            <div className="space-y-12 animate-in fade-in duration-500">
                                <div className="p-8 md:p-12 bg-white/[0.02] rounded-[3rem] border border-white/5 flex flex-col xl:flex-row items-center justify-between gap-10 hover:border-primary/20 transition-all duration-700">
                                    <div className="flex flex-col md:flex-row items-center gap-10 w-full min-w-0">
                                        <div className="h-28 w-28 shrink-0 bg-card rounded-[2.5rem] flex items-center justify-center text-primary shadow-[0_0_30px_rgba(0,255,204,0.1)] font-black border border-white/10 overflow-hidden relative group/avatar">
                                            {profile?.avatar_url ? (
                                                <img src={profile.avatar_url} alt="Profile" className="h-full w-full object-cover group-hover/avatar:scale-110 transition-transform duration-700" />
                                            ) : (
                                                <span className="text-4xl tracking-tighter">
                                                    {profile?.full_name ? profile.full_name.split(' ').map((n: any) => n[0]).join('') : 'U'}
                                                </span>
                                            )}
                                            <div className="absolute inset-0 bg-primary/20 opacity-0 group-hover/avatar:opacity-100 transition-opacity flex items-center justify-center backdrop-blur-sm">
                                                <Eye size={24} className="text-card" />
                                            </div>
                                        </div>
                                        <div className="space-y-3 text-center md:text-left min-w-0 flex-1">
                                            <p className="font-black text-white text-2xl tracking-[0.1em] uppercase truncate">{profile?.full_name || 'NEURAL_ENTITY'}</p>
                                            <p className="text-[11px] font-black text-primary uppercase tracking-[0.3em] break-all opacity-80">{profile?.email || 'UPLINK_PENDING'}</p>
                                        </div>
                                    </div>
                                    <a href="/admin/profile" className="shrink-0 px-10 py-5 bg-white/5 border border-white/10 text-white font-black rounded-2xl text-[10px] uppercase tracking-[0.3em] hover:bg-primary hover:text-card hover:border-primary transition-all duration-500 shadow-xl">
                                        Reconfigure Dossier
                                    </a>
                                </div>
                                
                                <div className="space-y-8">
                                    <div className="flex items-center gap-4">
                                        <div className="h-[1px] flex-1 bg-white/5" />
                                        <h4 className="text-[10px] font-black text-white/20 uppercase tracking-[0.5em]">Terminal Interface Preferences</h4>
                                        <div className="h-[1px] flex-1 bg-white/5" />
                                    </div>
                                    
                                    <div className="grid grid-cols-1 md:grid-cols-2 gap-10">
                                        <div className="p-8 bg-white/[0.02] border border-white/5 rounded-3xl space-y-6 group hover:border-accent/30 transition-all duration-500">
                                            <div className="flex items-center justify-between">
                                                <p className="text-[11px] font-black text-white/60 uppercase tracking-widest">Neural Visual Sync (Theme)</p>
                                                <Cpu className="text-accent/40" size={18} />
                                            </div>
                                            <div className="flex bg-card/60 p-1.5 rounded-2xl w-fit border border-white/5">
                                                <button 
                                                    onClick={() => setSystem({...system, theme: 'light'})}
                                                    className={`px-6 py-2.5 text-[10px] font-black uppercase tracking-widest rounded-xl transition-all duration-500 ${system.theme === 'light' ? 'bg-accent text-card shadow-lg' : 'text-white/20 hover:text-white/40'}`}
                                                >
                                                    Optical (Light)
                                                </button>
                                                <button 
                                                    onClick={() => setSystem({...system, theme: 'dark'})}
                                                    className={`px-6 py-2.5 text-[10px] font-black uppercase tracking-widest rounded-xl transition-all duration-500 ${system.theme === 'dark' ? 'bg-accent text-card shadow-lg' : 'text-white/20 hover:text-white/40'}`}
                                                >
                                                    Neural (Dark)
                                                </button>
                                            </div>
                                        </div>
                                        <div className="p-8 bg-white/[0.02] border border-white/5 rounded-3xl space-y-6 group hover:border-secondary/30 transition-all duration-500">
                                            <div className="flex items-center justify-between">
                                                <p className="text-[11px] font-black text-white/60 uppercase tracking-widest">Data Propagation (Refresh)</p>
                                                <Zap className="text-secondary/40" size={18} />
                                            </div>
                                            <select className="bg-card/60 border border-white/5 rounded-2xl px-6 py-3.5 text-[10px] font-black outline-none text-white/50 w-full appearance-none cursor-pointer tracking-widest uppercase hover:text-white transition-colors">
                                                <option>Manual Uplink</option>
                                                <option>5M Sequence Pulse</option>
                                                <option>Real-time Warp Sync</option>
                                            </select>
                                        </div>
                                    </div>
                                </div>
                                <div className="flex justify-end pt-8">
                                    <button 
                                        onClick={handleSave}
                                        className="bg-primary text-card font-black py-5 px-12 rounded-[1.5rem] transition-all duration-500 shadow-[0_0_30px_rgba(0,255,204,0.2)] hover:shadow-primary/40 uppercase text-xs tracking-[0.3em] active:scale-[0.98]"
                                    >
                                        Commit Changes
                                    </button>
                                </div>
                            </div>
                        )}

                        {activeTab === 'security' && (
                            <form onSubmit={handlePasswordChange} className="space-y-12 animate-in fade-in duration-500 max-w-2xl mx-auto">
                                <div className="space-y-10">
                                    <div className="flex items-center gap-4 justify-center">
                                        <div className="p-4 bg-primary/10 rounded-2xl border border-primary/20">
                                            <Lock size={24} className="text-primary" />
                                        </div>
                                        <h3 className="text-xl font-black text-white uppercase tracking-[0.3em]">Access Cipher Update</h3>
                                    </div>
                                    
                                    <div className="space-y-8">
                                        <div className="space-y-4">
                                            <label className="text-[10px] font-black text-white/30 uppercase tracking-[0.4em] px-2">New Access Key</label>
                                            <div className="relative group">
                                                <input 
                                                    type={showPassword ? 'text' : 'password'}
                                                    value={passwords.new}
                                                    onChange={e => setPasswords({...passwords, new: e.target.value})}
                                                    placeholder="ENTER SECURE CIPHER..."
                                                    className="w-full bg-white/5 border border-white/10 rounded-[1.5rem] py-6 px-8 text-white font-black text-xs tracking-[0.4em] focus:ring-4 focus:ring-primary/5 focus:border-primary/30 transition-all outline-none placeholder:text-white/5 uppercase"
                                                />
                                                <button 
                                                    type="button"
                                                    onClick={() => setShowPassword(!showPassword)}
                                                    className="absolute right-8 top-1/2 -translate-y-1/2 text-white/10 hover:text-primary transition-colors"
                                                >
                                                    {showPassword ? <EyeOff size={22} /> : <Eye size={22} />}
                                                </button>
                                            </div>
                                        </div>
                                        <div className="space-y-4">
                                            <label className="text-[10px] font-black text-white/30 uppercase tracking-[0.4em] px-2">Validate Access Key</label>
                                            <input 
                                                type="password"
                                                value={passwords.confirm}
                                                onChange={e => setPasswords({...passwords, confirm: e.target.value})}
                                                placeholder="RE-ENTER SECURE CIPHER..."
                                                className="w-full bg-white/5 border border-white/10 rounded-[1.5rem] py-6 px-8 text-white font-black text-xs tracking-[0.4em] focus:ring-4 focus:ring-primary/5 focus:border-primary/30 transition-all outline-none placeholder:text-white/5 uppercase"
                                            />
                                        </div>
                                    </div>

                                    <div className="p-8 bg-secondary/5 rounded-3xl border border-secondary/20 flex items-start space-x-6 relative overflow-hidden group">
                                        <div className="absolute inset-0 bg-secondary/5 opacity-0 group-hover:opacity-100 transition-opacity" />
                                        <AlertCircle size={28} className="text-secondary shrink-0 mt-1 relative z-10" />
                                        <p className="text-[10px] font-black text-secondary uppercase tracking-[0.2em] leading-relaxed relative z-10">
                                            ALTERING THE SYSTEM ACCESS KEY WILL INITIATE A GLOBAL LOGOUT SEQUENCE FOR ALL ACTIVE TERMINALS. ENSURE KEY COHERENCE BEFORE COMMITMENT.
                                        </p>
                                    </div>
                                </div>

                                <div className="flex justify-end pt-4">
                                    <button 
                                        type="submit"
                                        disabled={changingPassword || !passwords.new}
                                        className="w-full bg-primary hover:bg-primary/90 text-card font-black py-6 px-10 rounded-[1.5rem] transition-all duration-500 shadow-[0_0_30px_rgba(0,255,204,0.2)] flex items-center justify-center space-x-4 disabled:opacity-20 uppercase tracking-[0.4em] text-xs"
                                    >
                                        {changingPassword ? <Loader2 className="animate-spin" size={20} /> : <Shield size={20} />}
                                        <span>Rotate Security Key</span>
                                    </button>
                                </div>
                            </form>
                        )}

                        {activeTab === 'notifications' && (
                            <div className="space-y-10 animate-in fade-in duration-500">
                                <div className="space-y-6">
                                    <div className="p-10 bg-white/[0.02] rounded-[2.5rem] flex items-center justify-between border border-white/5 hover:border-primary/20 hover:bg-white/[0.04] transition-all duration-700 group">
                                        <div className="flex items-center space-x-8">
                                            <div className="p-5 bg-card rounded-2xl border border-white/10 group-hover:text-primary transition-colors"><Mail size={28} /></div>
                                            <div>
                                                <p className="font-black text-white text-lg tracking-widest uppercase">Global Echo (Email)</p>
                                                <p className="text-[10px] font-black text-white/20 uppercase tracking-[0.3em] mt-1">Status: Operational Broadcasts</p>
                                            </div>
                                        </div>
                                        <button 
                                            onClick={() => setNotifications({...notifications, email_alerts: !notifications.email_alerts})}
                                            className={`w-16 h-10 rounded-2xl transition-all relative overflow-hidden ${notifications.email_alerts ? 'bg-primary' : 'bg-white/5 border border-white/10'}`}
                                        >
                                            <div className={`absolute top-2 w-6 h-6 rounded-lg transition-all duration-500 ${notifications.email_alerts ? 'right-2 bg-card shadow-lg' : 'left-2 bg-white/10'}`} />
                                        </button>
                                    </div>

                                    <div className="p-10 bg-white/[0.02] rounded-[2.5rem] flex items-center justify-between border border-white/5 hover:border-secondary/20 hover:bg-white/[0.04] transition-all duration-700 group">
                                        <div className="flex items-center space-x-8">
                                            <div className="p-5 bg-card rounded-2xl border border-white/10 group-hover:text-secondary transition-colors"><Radio size={28} /></div>
                                            <div>
                                                <p className="font-black text-white text-lg tracking-widest uppercase">Node Registrations</p>
                                                <p className="text-[10px] font-black text-white/20 uppercase tracking-[0.3em] mt-1">Alert on new student ingress</p>
                                            </div>
                                        </div>
                                        <button 
                                            onClick={() => setNotifications({...notifications, user_registrations: !notifications.user_registrations})}
                                            className={`w-16 h-10 rounded-2xl transition-all relative overflow-hidden ${notifications.user_registrations ? 'bg-secondary' : 'bg-white/5 border border-white/10'}`}
                                        >
                                            <div className={`absolute top-2 w-6 h-6 rounded-lg transition-all duration-500 ${notifications.user_registrations ? 'right-2 bg-card shadow-lg' : 'left-2 bg-white/10'}`} />
                                        </button>
                                    </div>
                                </div>

                                <div className="flex justify-end pt-8">
                                    <button 
                                        onClick={handleSave}
                                        className="bg-primary text-card font-black py-5 px-12 rounded-[1.5rem] transition-all duration-500 shadow-[0_0_30px_rgba(0,255,204,0.2)] uppercase text-xs tracking-[0.4em]"
                                    >
                                        Update Propagation
                                    </button>
                                </div>
                            </div>
                        )}

                        {activeTab === 'system' && (
                            <div className="space-y-12 animate-in fade-in duration-500">
                                <div className="grid grid-cols-1 md:grid-cols-2 gap-12">
                                    <div className="space-y-4">
                                        <label className="text-[10px] font-black text-white/30 uppercase tracking-[0.4em] px-2">Interface Dialect</label>
                                        <div className="relative">
                                            <select 
                                                value={system.language}
                                                onChange={e => setSystem({...system, language: e.target.value})}
                                                className="w-full bg-white/5 border border-white/10 rounded-[1.5rem] py-6 px-8 text-white font-black text-xs tracking-[0.3em] outline-none appearance-none cursor-pointer hover:bg-white/10 transition-all uppercase"
                                            >
                                                <option className="bg-bg">EN-US (Global Terminal)</option>
                                                <option className="bg-bg">EN-UK (Satellite Node)</option>
                                                <option className="bg-bg">FR-FR (Direct Uplink)</option>
                                            </select>
                                            <div className="absolute right-8 top-1/2 -translate-y-1/2 pointer-events-none text-white/20">
                                                <ChevronRight size={20} className="rotate-90" />
                                            </div>
                                        </div>
                                    </div>
                                    <div className="space-y-4">
                                        <label className="text-[10px] font-black text-white/30 uppercase tracking-[0.4em] px-2">Temporal Sync Zone</label>
                                        <div className="relative">
                                            <select 
                                                value={system.timezone}
                                                onChange={e => setSystem({...system, timezone: e.target.value})}
                                                className="w-full bg-white/5 border border-white/10 rounded-[1.5rem] py-6 px-8 text-white font-black text-xs tracking-[0.3em] outline-none appearance-none cursor-pointer hover:bg-white/10 transition-all uppercase"
                                            >
                                                <option className="bg-bg">GMT+00:00 (Neural Sync Time)</option>
                                                <option className="bg-bg">GMT+01:00 (Central Pulse)</option>
                                                <option className="bg-bg">GMT-05:00 (Western Proxy)</option>
                                            </select>
                                            <div className="absolute right-8 top-1/2 -translate-y-1/2 pointer-events-none text-white/20">
                                                <ChevronRight size={20} className="rotate-90" />
                                            </div>
                                        </div>
                                    </div>
                                </div>
                                <div className="p-16 border-2 border-dashed border-white/5 rounded-[3rem] bg-white/[0.01] flex flex-col items-center justify-center text-center space-y-8 group hover:border-primary/20 transition-all duration-700">
                                     <div className="p-6 bg-card text-white/20 rounded-2xl border border-white/10 group-hover:text-primary transition-all group-hover:scale-110 duration-500 shadow-xl overflow-hidden relative">
                                        <div className="absolute inset-0 bg-primary/5 blur-xl group-hover:bg-primary/20 transition-colors" />
                                        <Globe size={48} className="relative z-10" />
                                     </div>
                                     <div className="space-y-3">
                                         <p className="font-black text-white text-xl uppercase tracking-[0.3em]">Localization Algorithm Active</p>
                                         <p className="text-[10px] font-black text-white/20 uppercase tracking-[0.4em] max-w-sm">Additional regional harmonics will be deployed in subsequent system epochs.</p>
                                     </div>
                                </div>
                                <div className="flex justify-end pt-8">
                                    <button 
                                        onClick={handleSave}
                                        className="bg-primary text-card font-black py-5 px-12 rounded-[1.5rem] transition-all duration-500 shadow-[0_0_30px_rgba(0,255,204,0.2)] uppercase text-xs tracking-[0.4em]"
                                    >
                                        Synchronize Registry
                                    </button>
                                </div>
                            </div>
                        )}
                    </div>
                </div>
            </div>
        </div>
    )
}
