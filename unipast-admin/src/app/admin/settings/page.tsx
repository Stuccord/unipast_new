'use client'

import { useState, useEffect } from 'react'
import { Settings, Bell, Shield, User, Users, Globe, Mail, ChevronRight, Lock, Eye, EyeOff, Loader2, CheckCircle2, AlertCircle, Save } from 'lucide-react'
import { supabase } from '@/lib/supabase'

type SettingsTab = 'account' | 'notifications' | 'security' | 'system'

export default function SettingsPage() {
    const [activeTab, setActiveTab] = useState<SettingsTab>('account')
    const [changingPassword, setChangingPassword] = useState(false)
    const [showPassword, setShowPassword] = useState(false)
    const [status, setStatus] = useState<{ type: 'success' | 'error', message: string } | null>(null)
    const [profile, setProfile] = useState<any>(null)
    const [loading, setLoading] = useState(true)

    useEffect(() => {
        const fetchProfile = async () => {
            const { data: { user } } = await supabase.auth.getUser()
            if (user) {
                const { data } = await supabase.from('profiles').select('*').eq('id', user.id).single()
                if (data) setProfile(data)
            }
            setLoading(false)
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
        language: 'English (United States)',
        timezone: 'GMT+00:00 (Greenwich Mean Time)',
        theme: 'light' as 'light' | 'dark'
    })

    const handleSave = () => {
        setStatus({ type: 'success', message: 'Settings saved successfully!' })
        setTimeout(() => setStatus(null), 3000)
    }

    async function handlePasswordChange(e: React.FormEvent) {
        e.preventDefault()
        if (passwords.new !== passwords.confirm) {
            setStatus({ type: 'error', message: 'Passwords do not match' })
            return
        }
        
        setChangingPassword(true)
        setStatus(null)
        try {
            const { error } = await supabase.auth.updateUser({
                password: passwords.new
            })
            if (error) throw error
            setStatus({ type: 'success', message: 'Password updated successfully!' })
            setPasswords({ new: '', confirm: '' })
        } catch (error: any) {
            setStatus({ type: 'error', message: error.message || 'Error updating password' })
        } finally {
            setChangingPassword(false)
        }
    }

    const tabs = [
        { id: 'account', icon: User, label: 'Account', desc: 'Manage profile information' },
        { id: 'notifications', icon: Bell, label: 'Notifications', desc: 'Alert preferences' },
        { id: 'security', icon: Shield, label: 'Security', desc: 'Password & access' },
        { id: 'system', icon: Globe, label: 'System', desc: 'Language & region' },
    ]

    if (loading) {
        return (
            <div className="flex h-[60vh] items-center justify-center">
                <Loader2 className="animate-spin text-[#0D9488]" size={48} />
            </div>
        )
    }

    return (
        <div className="space-y-10 max-w-5xl">
            <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-6">
                <div className="space-y-1">
                    <h2 className="text-3xl font-black text-slate-800 tracking-tight">Platform Settings</h2>
                    <p className="text-slate-500 font-medium tracking-tight">Configure your administrative workspace and platform preferences.</p>
                </div>
                <button 
                    onClick={handleSave}
                    className="bg-[#0D9488] hover:bg-teal-700 text-white font-bold py-4 px-10 rounded-2xl flex items-center space-x-3 transition-all shadow-xl shadow-teal-700/20"
                >
                    <Save size={20} />
                    <span>Save Changes</span>
                </button>
            </div>

            <div className="flex flex-col lg:flex-row gap-10">
                {/* Sidebar Navigation */}
                <div className="w-full lg:w-80 shrink-0 space-y-2">
                    {tabs.map((tab) => (
                        <button
                            key={tab.id}
                            onClick={() => {
                                setActiveTab(tab.id as SettingsTab)
                                setStatus(null)
                            }}
                            className={`w-full p-6 rounded-3xl flex items-center space-x-4 transition-all ${
                                activeTab === tab.id 
                                ? 'bg-[#0D9488] text-white shadow-xl shadow-teal-700/20' 
                                : 'bg-white text-slate-500 hover:bg-slate-50'
                            }`}
                        >
                            <div className={`p-3 rounded-2xl ${activeTab === tab.id ? 'bg-white/10' : 'bg-slate-100'}`}>
                                <tab.icon size={20} />
                            </div>
                            <div className="text-left">
                                <p className="font-black text-sm tracking-tight">{tab.label}</p>
                                <p className={`text-[10px] font-bold uppercase tracking-widest ${activeTab === tab.id ? 'text-teal-100' : 'text-slate-400'}`}>
                                    {tab.desc}
                                </p>
                            </div>
                        </button>
                    ))}
                </div>

                {/* Content Area */}
                <div className="flex-1 bg-white rounded-[2.5rem] border border-slate-100 shadow-sm overflow-hidden min-h-[500px]">
                    <div className="p-10 border-b border-slate-50 flex items-center justify-between">
                        <h3 className="text-xl font-black text-slate-800 capitalize tracking-tight">{activeTab} Configuration</h3>
                        {status && (
                            <div className={`px-4 py-2 rounded-xl border flex items-center space-x-2 text-xs font-bold ${
                                status.type === 'success' ? 'bg-emerald-50 border-emerald-100 text-emerald-600' : 'bg-rose-50 border-rose-100 text-rose-600'
                            }`}>
                                {status.type === 'success' ? <CheckCircle2 size={14} /> : <AlertCircle size={14} />}
                                <span>{status.message}</span>
                            </div>
                        )}
                    </div>

                    <div className="p-10">
                        {activeTab === 'account' && (
                            <div className="space-y-8 animate-in fade-in duration-300">
                                <div className="p-8 bg-slate-50 rounded-3xl border border-slate-100 flex items-center justify-between">
                                    <div className="flex items-center space-x-6">
                                        <div className="h-16 w-16 bg-white rounded-2xl flex items-center justify-center text-[#0D9488] shadow-sm font-black border border-slate-100 overflow-hidden">
                                            {profile?.avatar_url ? (
                                                <img src={profile.avatar_url} alt="Profile" className="h-full w-full object-cover" />
                                            ) : (
                                                profile?.full_name ? profile.full_name.split(' ').map((n: any) => n[0]).join('') : 'A'
                                            )}
                                        </div>
                                        <div>
                                            <p className="font-black text-slate-800">{profile?.full_name || 'Administrator'}</p>
                                            <p className="text-sm font-medium text-slate-500">{profile?.email || 'Loading...'}</p>
                                        </div>
                                    </div>
                                    <a href="/admin/profile" className="px-6 py-3 bg-white border border-slate-200 text-slate-600 font-bold rounded-xl text-sm hover:bg-slate-50 transition-colors">
                                        Edit Profile
                                    </a>
                                </div>
                                <div className="space-y-6">
                                    <h4 className="text-xs font-black text-slate-400 uppercase tracking-widest">Workspace Preferences</h4>
                                    <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                                        <div className="p-6 bg-slate-50 rounded-2xl space-y-2">
                                            <p className="text-sm font-bold text-slate-700">Interface Mode</p>
                                            <div className="flex bg-white p-1 rounded-xl w-fit border border-slate-200">
                                                <button 
                                                    onClick={() => setSystem({...system, theme: 'light'})}
                                                    className={`px-4 py-2 text-xs font-bold rounded-lg transition-all ${system.theme === 'light' ? 'bg-[#0D9488] text-white shadow-sm' : 'text-slate-400 hover:text-slate-600'}`}
                                                >
                                                    Light
                                                </button>
                                                <button 
                                                    onClick={() => setSystem({...system, theme: 'dark'})}
                                                    className={`px-4 py-2 text-xs font-bold rounded-lg transition-all ${system.theme === 'dark' ? 'bg-[#0D9488] text-white shadow-sm' : 'text-slate-400 hover:text-slate-600'}`}
                                                >
                                                    Dark
                                                </button>
                                            </div>
                                        </div>
                                        <div className="p-6 bg-slate-50 rounded-2xl space-y-2">
                                            <p className="text-sm font-bold text-slate-700">Refresh Rate</p>
                                            <select className="bg-white border border-slate-200 rounded-xl px-4 py-2 text-xs font-bold outline-none text-slate-600 w-full">
                                                <option>Manual Refresh</option>
                                                <option>Every 5 Minutes</option>
                                                <option>Real-time (Warp)</option>
                                            </select>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        )}

                        {activeTab === 'security' && (
                            <form onSubmit={handlePasswordChange} className="space-y-8 animate-in fade-in duration-300">
                                <div className="space-y-6">
                                    <div className="flex items-center space-x-3 text-slate-800 font-bold">
                                        <Lock size={18} className="text-[#0D9488]" />
                                        <span>Update Security Credentials</span>
                                    </div>
                                    
                                    <div className="space-y-4">
                                        <div className="space-y-2 text-left">
                                            <label className="text-[10px] font-black text-slate-400 uppercase tracking-widest px-1">New Password</label>
                                            <div className="relative">
                                                <input 
                                                    type={showPassword ? 'text' : 'password'}
                                                    value={passwords.new}
                                                    onChange={e => setPasswords({...passwords, new: e.target.value})}
                                                    placeholder="••••••••"
                                                    className="w-full bg-slate-50 border-none rounded-2xl py-4 px-6 text-slate-800 font-bold focus:ring-2 focus:ring-[#0D9488]/20 transition-all outline-none"
                                                />
                                                <button 
                                                    type="button"
                                                    onClick={() => setShowPassword(!showPassword)}
                                                    className="absolute right-6 top-1/2 -translate-y-1/2 text-slate-300 hover:text-slate-500"
                                                >
                                                    {showPassword ? <EyeOff size={18} /> : <Eye size={18} />}
                                                </button>
                                            </div>
                                        </div>
                                        <div className="space-y-2 text-left">
                                            <label className="text-[10px] font-black text-slate-400 uppercase tracking-widest px-1">Confirm New Password</label>
                                            <input 
                                                type="password"
                                                value={passwords.confirm}
                                                onChange={e => setPasswords({...passwords, confirm: e.target.value})}
                                                placeholder="••••••••"
                                                className="w-full bg-slate-50 border-none rounded-2xl py-4 px-6 text-slate-800 font-bold focus:ring-2 focus:ring-[#0D9488]/20 transition-all outline-none"
                                            />
                                        </div>
                                    </div>

                                    <div className="p-6 bg-amber-50 rounded-2xl border border-amber-100 flex items-start space-x-4">
                                        <AlertCircle size={20} className="text-amber-500 flex-shrink-0 mt-0.5" />
                                        <p className="text-xs font-medium text-amber-700 leading-relaxed">
                                            Changing your password will log you out of all other sessions to ensure workspace integrity. Keep your credentials secure.
                                        </p>
                                    </div>
                                </div>

                                <div className="flex justify-end pt-4">
                                    <button 
                                        type="submit"
                                        disabled={changingPassword || !passwords.new}
                                        className="bg-[#0D9488] hover:bg-teal-700 text-white font-black py-4 px-10 rounded-2xl transition-all shadow-lg shadow-teal-700/20 flex items-center space-x-3 disabled:opacity-50"
                                    >
                                        {changingPassword && <Loader2 className="animate-spin" size={20} />}
                                        <span>Update Credentials</span>
                                    </button>
                                </div>
                            </form>
                        )}

                        {activeTab === 'notifications' && (
                            <div className="space-y-8 animate-in fade-in duration-300">
                                <div className="space-y-4">
                                    <div className="p-6 bg-slate-50 rounded-3xl flex items-center justify-between border border-transparent hover:border-slate-200 transition-all">
                                        <div className="flex items-center space-x-4">
                                            <div className="p-3 bg-white rounded-xl shadow-sm"><Mail size={20} className="text-slate-400" /></div>
                                            <div>
                                                <p className="font-black text-slate-800 tracking-tight">Email Notifications</p>
                                                <p className="text-xs font-bold text-slate-400 uppercase tracking-widest">Daily system digests</p>
                                            </div>
                                        </div>
                                        <button 
                                            onClick={() => setNotifications({...notifications, email_alerts: !notifications.email_alerts})}
                                            className={`w-14 h-8 rounded-full transition-all relative ${notifications.email_alerts ? 'bg-[#0D9488]' : 'bg-slate-200'}`}
                                        >
                                            <div className={`absolute top-1 w-6 h-6 bg-white rounded-full shadow-sm transition-all ${notifications.email_alerts ? 'right-1' : 'left-1'}`} />
                                        </button>
                                    </div>

                                    <div className="p-6 bg-slate-50 rounded-3xl flex items-center justify-between border border-transparent hover:border-slate-200 transition-all">
                                        <div className="flex items-center space-x-4">
                                            <div className="p-3 bg-white rounded-xl shadow-sm"><Users size={20} className="text-slate-400" /></div>
                                            <div>
                                                <p className="font-black text-slate-800 tracking-tight">New Registrations</p>
                                                <p className="text-xs font-bold text-slate-400 uppercase tracking-widest">Alert on new student signups</p>
                                            </div>
                                        </div>
                                        <button 
                                            onClick={() => setNotifications({...notifications, user_registrations: !notifications.user_registrations})}
                                            className={`w-14 h-8 rounded-full transition-all relative ${notifications.user_registrations ? 'bg-[#0D9488]' : 'bg-slate-200'}`}
                                        >
                                            <div className={`absolute top-1 w-6 h-6 bg-white rounded-full shadow-sm transition-all ${notifications.user_registrations ? 'right-1' : 'left-1'}`} />
                                        </button>
                                    </div>
                                </div>
                            </div>
                        )}

                        {activeTab === 'system' && (
                            <div className="space-y-8 animate-in fade-in duration-300">
                                <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
                                    <div className="space-y-3">
                                        <label className="text-[10px] font-black text-slate-400 uppercase tracking-widest px-1">Global Language</label>
                                        <select 
                                            value={system.language}
                                            onChange={e => setSystem({...system, language: e.target.value})}
                                            className="w-full bg-slate-50 border-none rounded-2xl py-4 px-6 text-slate-800 font-bold outline-none border border-transparent transition-all focus:ring-2 focus:ring-[#0D9488]/20"
                                        >
                                            <option>English (United States)</option>
                                            <option>English (United Kingdom)</option>
                                            <option>French (France)</option>
                                            <option>Spanish (Spain)</option>
                                        </select>
                                    </div>
                                    <div className="space-y-3">
                                        <label className="text-[10px] font-black text-slate-400 uppercase tracking-widest px-1">System Timezone</label>
                                        <select 
                                            value={system.timezone}
                                            onChange={e => setSystem({...system, timezone: e.target.value})}
                                            className="w-full bg-slate-50 border-none rounded-2xl py-4 px-6 text-slate-800 font-bold outline-none border border-transparent transition-all focus:ring-2 focus:ring-[#0D9488]/20"
                                        >
                                            <option>GMT+00:00 (Greenwich Mean Time)</option>
                                            <option>GMT+01:00 (Central European Time)</option>
                                            <option>GMT-05:00 (Eastern Standard Time)</option>
                                            <option>GMT+08:00 (China Standard Time)</option>
                                        </select>
                                    </div>
                                </div>
                                <div className="p-10 border-2 border-dashed border-slate-100 rounded-[2rem] flex flex-col items-center justify-center text-center space-y-4">
                                     <div className="p-4 bg-slate-50 text-slate-300 rounded-2xl"><Globe size={32} /></div>
                                     <div className="space-y-1">
                                         <p className="font-extrabold text-slate-700">Localization Engine Active</p>
                                         <p className="text-xs font-bold text-slate-400">Additional regions will be available in future releases.</p>
                                     </div>
                                </div>
                            </div>
                        )}
                    </div>
                </div>
            </div>
        </div>
    )
}
