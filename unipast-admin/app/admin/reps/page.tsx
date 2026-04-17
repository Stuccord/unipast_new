'use client'



import { useState, useEffect } from 'react'
import { supabase } from '@/lib/supabase'
import { 
    UserPlus, Mail, Shield, Trash2, Search, ChevronRight, 
    MoreVertical, MapPin, X, User, GraduationCap, Building2, 
    Send, Loader2, CheckCircle2, Globe, Zap, Radio, Lock, Activity
} from 'lucide-react'
import { inviteRep } from './actions'

export default function RepsPage() {
    const [reps, setReps] = useState<any[]>([])
    const [loading, setLoading] = useState(false)
    const [searchTerm, setSearchTerm] = useState('')
    const [showInviteModal, setShowInviteModal] = useState(false)
    const [showMessageModal, setShowMessageModal] = useState(false)
    const [showPermissionsModal, setShowPermissionsModal] = useState(false)
    const [selectedRep, setSelectedRep] = useState<any>(null)
    const [processing, setProcessing] = useState(false)
    const [status, setStatus] = useState<{ type: 'success' | 'error', message: string } | null>(null)

    const [unis, setUnis] = useState<any[]>([])
    const [faculties, setFaculties] = useState<any[]>([])

    const [formData, setFormData] = useState({
        full_name: '',
        email: '',
        password: '',
        university_id: '',
        faculty_id: '',
        current_level: 100
    })

    const [messageData, setMessageData] = useState({
        subject: '',
        body: ''
    })

    useEffect(() => {
        fetchReps()
        fetchAcademicStats()
    }, [])

    async function fetchAcademicStats() {
        const { data: u } = await supabase.from('universities').select('id, name').order('name')
        if (u) setUnis(u)
        
        const { data: f } = await supabase.from('faculties').select('id, name, university_id').order('name')
        if (f) setFaculties(f)
    }

    async function fetchReps() {
        setLoading(true)
        try {
            const { data } = await supabase
                .from('profiles')
                .select('*, faculties(name, universities(name))')
                .eq('is_rep', true)
                .order('full_name')
            
            if (data) {
                setReps(data.map(r => ({
                    ...r,
                    university: (r.faculties as any)?.universities?.name || 'N/A',
                    faculty_name: (r.faculties as any)?.name || 'N/A',
                    level: r.current_level || 'N/A',
                    status: 'Active'
                })))
            }
        } catch (error) {
            console.error('Network Interface Failure:', error)
        } finally {
            setLoading(false)
        }
    }

    async function handleInvite(e: React.FormEvent) {
        e.preventDefault()
        setProcessing(true)
        
        const result = await inviteRep(formData)
        
        if (result.success) {
            setShowInviteModal(false)
            setFormData({ full_name: '', email: '', password: '', university_id: '', faculty_id: '', current_level: 100 })
            fetchReps()
            alert('AGENT DEPLOYED. ENCRYPTED CREDENTIALS GENERATED.')
        } else {
            alert('DEPLOYMENT FAILURE: ' + result.error)
        }
        setProcessing(false)
    }

    async function handleSendMessage(e: React.FormEvent) {
        e.preventDefault()
        setProcessing(true)
        setStatus(null)
        await new Promise(resolve => setTimeout(resolve, 1500))
        setStatus({ type: 'success', message: `TRANSMISSION UPLINK TO ${selectedRep.full_name} ESTABLISHED.` })
        setProcessing(false)
        setTimeout(() => setShowMessageModal(false), 2000)
    }

    async function handleUpdatePermissions(newRole: string, newLevel?: number) {
        setProcessing(true)
        const updateData: any = {}
        if (newRole === 'admin') {
            updateData.is_admin = true;
            updateData.is_rep = false;
        } else if (newRole === 'rep') {
            updateData.is_admin = false;
            updateData.is_rep = true;
        }
        
        if (newLevel) updateData.current_level = newLevel
        
        const { error } = await supabase
            .from('profiles')
            .update(updateData)
            .eq('id', selectedRep.id)
        
        if (!error) {
            fetchReps()
            setShowPermissionsModal(false)
        } else {
            alert('SECURITY OVERRIDE FAILED: ' + error.message)
        }
        setProcessing(false)
    }

    async function handleRemove(id: string) {
        if (!confirm('INITIATE AGENT TERMINATION? THIS ACTION IS PERMANENT.')) return
        
        const { error } = await supabase.from('profiles').delete().eq('id', id)
        if (!error) {
            fetchReps()
        } else {
            alert('DECOMMISSION FAILED: ' + error.message)
        }
    }

    const filteredReps = reps.filter(r =>
        r.full_name?.toLowerCase().includes(searchTerm.toLowerCase()) ||
        r.id.toLowerCase().includes(searchTerm.toLowerCase())
    )

    const filteredFaculties = faculties.filter(f => f.university_id === formData.university_id)

    return (
        <div className="space-y-12 font-orbitron pb-32">
            <div className="flex flex-col xl:flex-row xl:items-end justify-between gap-8">
                <div className="space-y-4">
                    <div className="flex items-center gap-3">
                        <div className="p-2.5 bg-accent/10 rounded-xl border border-accent/20">
                            <Radio size={22} className="text-accent animate-pulse" />
                        </div>
                        <span className="text-[10px] font-black text-accent uppercase tracking-[0.4em]">Intelligence Matrix v2.0</span>
                    </div>
                    <h2 className="text-4xl font-black text-white tracking-tight uppercase">Agent Intelligence Network</h2>
                    <p className="text-white/30 font-black text-[10px] uppercase tracking-[0.3em]">Overseeing Tactical Student Representatives Across Global Nodes</p>
                </div>
                
                <button 
                    onClick={() => setShowInviteModal(true)}
                    className="relative px-10 py-5 rounded-[1.5rem] bg-primary text-card font-black text-xs uppercase tracking-[0.3em] overflow-hidden group/btn shadow-[0_0_30px_rgba(0,255,204,0.2)] hover:shadow-primary/40 transition-all duration-500 flex items-center gap-3"
                >
                    <div className="absolute inset-0 bg-white/20 -translate-x-full group-hover/btn:translate-x-full transition-transform duration-700 skew-x-12" />
                    <UserPlus size={20} className="relative z-10" />
                    <span className="relative z-10">Deploy New Agent</span>
                </button>
            </div>

            <div className="bg-card/20 backdrop-blur-3xl rounded-[3rem] border border-white/5 overflow-hidden shadow-2xl animate-in fade-in duration-1000">
                <div className="p-10 border-b border-white/5 flex flex-col md:flex-row md:items-center justify-between gap-6">
                    <div className="relative max-w-lg w-full group">
                        <div className="absolute left-6 top-1/2 -translate-y-1/2 text-white/20 group-focus-within:text-primary transition-colors">
                            <Search size={22} />
                        </div>
                        <input
                            type="text"
                            placeholder="SCAN AGENT DATABASE..."
                            value={searchTerm}
                            onChange={(e) => setSearchTerm(e.target.value)}
                            className="w-full pl-16 pr-8 py-5 rounded-2xl bg-white/5 border border-white/5 outline-none focus:ring-4 focus:ring-primary/5 focus:border-primary/20 transition-all font-black text-[10px] text-white tracking-[0.2em] placeholder:text-white/10 uppercase"
                        />
                    </div>
                    
                    <div className="flex items-center gap-4">
                        <div className="px-5 py-3 bg-white/5 border border-white/5 rounded-2xl flex items-center gap-3">
                            <Activity size={16} className="text-primary" />
                            <span className="text-[10px] font-black text-white tracking-[0.2em] uppercase">{reps.length} Nodes Active</span>
                        </div>
                    </div>
                </div>

                <div className="overflow-x-auto">
                    <table className="w-full text-left">
                        <thead>
                            <tr className="bg-white/[0.02] border-white/5">
                                <th className="px-10 py-8 text-[9px] font-black text-white/30 uppercase tracking-[0.4em]">AGENT DOSSIER</th>
                                <th className="px-10 py-8 text-[9px] font-black text-white/30 uppercase tracking-[0.4em]">NODE ASSIGNMENT</th>
                                <th className="px-10 py-8 text-[9px] font-black text-white/30 uppercase tracking-[0.4em]">SYNC STATUS</th>
                                <th className="px-10 py-8 text-[9px] font-black text-white/30 uppercase tracking-[0.4em] text-right">OPERATIONS</th>
                            </tr>
                        </thead>
                        <tbody className="divide-y divide-white/5">
                            {loading ? (
                                <tr>
                                    <td colSpan={4} className="px-10 py-40 text-center">
                                         <div className="relative w-24 h-24 mx-auto animate-spin">
                                            <div className="absolute inset-0 border-4 border-primary/20 rounded-full" />
                                            <div className="absolute inset-0 border-4 border-primary rounded-full border-t-transparent shadow-[0_0_20px_#00FFCC]" />
                                         </div>
                                    </td>
                                </tr>
                            ) : filteredReps.length === 0 ? (
                                <tr>
                                    <td colSpan={4} className="px-10 py-40 text-center text-white/10 font-black tracking-[0.8em] uppercase text-sm">NO AGENTS DETECTED</td>
                                </tr>
                            ) : (
                                filteredReps.map((rep) => (
                                    <tr key={rep.id} className="hover:bg-white/[0.03] transition-colors duration-500 group">
                                        <td className="px-10 py-8">
                                            <div className="flex items-center gap-6">
                                                <div className="h-16 w-16 rounded-2xl bg-white/5 border border-white/5 flex items-center justify-center text-white/20 group-hover:text-primary group-hover:border-primary/40 transition-all duration-700 font-black text-xl">
                                                    {rep.full_name?.[0] || 'U'}
                                                </div>
                                                <div className="flex flex-col space-y-1 min-w-0 flex-1">
                                                     <span className="font-black text-white text-sm tracking-widest uppercase group-hover:text-primary transition-colors duration-500 truncate">{rep.full_name || 'UNNAMED_AGENT'}</span>
                                                     <span className="text-[10px] text-white/20 font-black tracking-widest uppercase break-all">{rep.email || 'N/A'}</span>
                                                 </div>
                                            </div>
                                        </td>
                                        <td className="px-10 py-8">
                                            <div className="flex flex-col space-y-2">
                                                <div className="flex items-center gap-2 text-white/60 font-black uppercase tracking-widest text-[11px] min-w-0">
                                                     <MapPin size={12} className="text-primary shrink-0" />
                                                     <span className="truncate">{rep.university || 'GLOBAL_NODE'}</span>
                                                 </div>
                                                <div className="px-3 py-1 bg-white/5 rounded-lg border border-white/5 w-fit">
                                                    <span className="text-[9px] text-white/30 font-black uppercase tracking-[0.2em]">Level {rep.level} Authorization</span>
                                                </div>
                                            </div>
                                        </td>
                                        <td className="px-10 py-8">
                                            <div className="flex items-center gap-3">
                                                <div className={`w-2 h-2 rounded-full shadow-[0_0_10px_currentColor] animate-pulse ${
                                                    rep.status === 'Active' ? 'text-primary bg-primary' : 'text-secondary bg-secondary'
                                                }`} />
                                                <span className={`text-[9px] font-black uppercase tracking-[0.3em] ${
                                                    rep.status === 'Active' ? 'text-primary/60' : 'text-secondary/60'
                                                }`}>
                                                    {rep.status || 'SYNCED'}
                                                </span>
                                            </div>
                                        </td>
                                        <td className="px-10 py-8 text-right">
                                            <div className="flex items-center justify-end gap-4 opacity-0 group-hover:opacity-100 transition-all duration-500 translate-x-4 group-hover:translate-x-0">
                                                <button 
                                                    onClick={() => { setSelectedRep(rep); setShowMessageModal(true); setStatus(null); }}
                                                    className="h-12 w-12 bg-white/5 text-white/30 hover:text-accent hover:bg-accent/10 border border-white/5 hover:border-accent/40 rounded-2xl transition-all flex items-center justify-center group/opt" title="Message"
                                                >
                                                    <Mail size={18} className="group-hover/opt:scale-110 transition-transform" />
                                                </button>
                                                <button 
                                                    onClick={() => { setSelectedRep(rep); setShowPermissionsModal(true); }}
                                                    className="h-12 w-12 bg-white/5 text-white/30 hover:text-primary hover:bg-primary/10 border border-white/5 hover:border-primary/40 rounded-2xl transition-all flex items-center justify-center group/opt" title="Permissions"
                                                >
                                                    <Shield size={18} className="group-hover/opt:scale-110 transition-transform" />
                                                </button>
                                                <button 
                                                    onClick={() => handleRemove(rep.id)}
                                                    className="h-12 w-12 bg-white/5 text-white/30 hover:text-danger hover:bg-danger/10 border border-white/5 hover:border-danger/40 rounded-2xl transition-all flex items-center justify-center group/opt" title="Remove"
                                                >
                                                    <Trash2 size={18} className="group-hover/opt:scale-110 transition-transform" />
                                                </button>
                                            </div>
                                            <div className="group-hover:hidden text-white/10">
                                                <MoreVertical size={22} />
                                            </div>
                                        </td>
                                    </tr>
                                ))
                            )}
                        </tbody>
                    </table>
                </div>
            </div>

            {/* Invite Rep Modal */}
            {showInviteModal && (
                <div className="fixed inset-0 bg-bg/80 backdrop-blur-2xl flex items-center justify-center p-6 z-[200] animate-in fade-in duration-500">
                    <div className="bg-card border border-white/5 rounded-[3rem] max-w-4xl w-full shadow-[0_0_100px_rgba(0,0,0,0.5)] overflow-hidden animate-in zoom-in-95 duration-500 relative">
                        <div className="absolute top-0 left-0 w-full h-1 bg-primary" />
                        <div className="p-12 md:p-16 space-y-12">
                            <div className="flex items-center justify-between">
                                <div className="space-y-4">
                                    <div className="flex items-center gap-2">
                                        <Zap size={16} className="text-primary" />
                                        <span className="text-[10px] font-black text-primary uppercase tracking-[0.4em]">Deployment Sequence</span>
                                    </div>
                                    <h3 className="text-4xl font-black text-white tracking-tight uppercase">Initiate Agent Deployment</h3>
                                </div>
                                <button 
                                    onClick={() => setShowInviteModal(false)}
                                    className="h-14 w-14 bg-white/5 hover:bg-white/10 text-white/20 hover:text-white rounded-2xl border border-white/5 transition-all flex items-center justify-center"
                                >
                                    <X size={28} />
                                </button>
                            </div>
                            
                            <form onSubmit={handleInvite} className="space-y-10">
                                <div className="grid grid-cols-1 md:grid-cols-2 gap-10">
                                    <div className="space-y-4">
                                        <label className="text-[10px] font-black text-white/30 uppercase tracking-[0.3em] px-2">Agent Identity</label>
                                        <div className="relative group">
                                            <User className="absolute left-6 top-1/2 -translate-y-1/2 text-white/10 group-focus-within:text-primary transition-colors" size={22} />
                                            <input
                                                type="text" required placeholder="FULL NAME..."
                                                className="w-full pl-16 pr-8 py-6 bg-white/5 border border-white/5 rounded-2xl outline-none focus:ring-4 focus:ring-primary/5 focus:border-primary/30 font-black text-xs text-white tracking-widest uppercase placeholder:text-white/5"
                                                value={formData.full_name}
                                                onChange={e => setFormData({ ...formData, full_name: e.target.value })}
                                            />
                                        </div>
                                    </div>
                                    <div className="space-y-4">
                                        <label className="text-[10px] font-black text-white/30 uppercase tracking-[0.3em] px-2">Comm Channel (Email)</label>
                                        <div className="relative group">
                                            <Mail className="absolute left-6 top-1/2 -translate-y-1/2 text-white/10 group-focus-within:text-primary transition-colors" size={22} />
                                            <input
                                                type="email" required placeholder="ENCRYPTED EMAIL..."
                                                className="w-full pl-16 pr-8 py-6 bg-white/5 border border-white/5 rounded-2xl outline-none focus:ring-4 focus:ring-primary/5 focus:border-primary/30 font-black text-xs text-white tracking-widest uppercase placeholder:text-white/5"
                                                value={formData.email}
                                                onChange={e => setFormData({ ...formData, email: e.target.value })}
                                            />
                                        </div>
                                    </div>

                                    <div className="space-y-4">
                                        <label className="text-[10px] font-black text-white/30 uppercase tracking-[0.3em] px-2">Access Cipher (Password)</label>
                                        <div className="relative group">
                                            <Lock className="absolute left-6 top-1/2 -translate-y-1/2 text-white/10 group-focus-within:text-primary transition-colors" size={22} />
                                            <input
                                                type="text" required placeholder="SECRET CIPHER..."
                                                className="w-full pl-16 pr-8 py-6 bg-white/5 border border-white/5 rounded-2xl outline-none focus:ring-4 focus:ring-primary/5 focus:border-primary/30 font-black text-xs text-white tracking-widest uppercase placeholder:text-white/5"
                                                value={formData.password}
                                                onChange={e => setFormData({ ...formData, password: e.target.value })}
                                            />
                                        </div>
                                    </div>
                                    
                                    <div className="space-y-4">
                                        <label className="text-[10px] font-black text-white/30 uppercase tracking-[0.3em] px-2">Target Node (University)</label>
                                        <div className="relative group">
                                            <Building2 className="absolute left-6 top-1/2 -translate-y-1/2 text-white/10 group-focus-within:text-primary transition-colors" size={22} />
                                            <select
                                                required
                                                className="w-full pl-16 pr-8 py-6 bg-white/5 border border-white/5 rounded-2xl outline-none focus:ring-4 focus:ring-primary/5 focus:border-primary/30 font-black text-xs text-white/60 tracking-widest uppercase appearance-none cursor-pointer"
                                                value={formData.university_id}
                                                onChange={e => setFormData({ ...formData, university_id: e.target.value, faculty_id: '' })}
                                            >
                                                <option value="" className="bg-bg">SELECT TARGET NODE</option>
                                                {unis.map(u => <option key={u.id} value={u.id} className="bg-bg">{u.name}</option>)}
                                            </select>
                                        </div>
                                    </div>
                                    
                                    <div className="space-y-4">
                                        <label className="text-[10px] font-black text-white/30 uppercase tracking-[0.3em] px-2">Sector Unit (Faculty)</label>
                                        <div className="relative group">
                                            <GraduationCap className="absolute left-6 top-1/2 -translate-y-1/2 text-white/10 group-focus-within:text-primary transition-colors" size={22} />
                                            <select
                                                required
                                                disabled={!formData.university_id}
                                                className="w-full pl-16 pr-8 py-6 bg-white/5 border border-white/5 rounded-2xl outline-none focus:ring-4 focus:ring-primary/5 focus:border-primary/30 font-black text-xs text-white/60 tracking-widest uppercase appearance-none cursor-pointer disabled:opacity-20"
                                                value={formData.faculty_id}
                                                onChange={e => setFormData({ ...formData, faculty_id: e.target.value })}
                                            >
                                                <option value="" className="bg-bg">SELECT SECTOR</option>
                                                {filteredFaculties.map(f => <option key={f.id} value={f.id} className="bg-bg">{f.name}</option>)}
                                            </select>
                                        </div>
                                    </div>

                                    <div className="space-y-4">
                                        <label className="text-[10px] font-black text-white/30 uppercase tracking-[0.3em] px-2">Auth Level</label>
                                        <select
                                            required
                                            className="w-full px-8 py-6 bg-white/5 border border-white/5 rounded-2xl outline-none focus:ring-4 focus:ring-primary/5 focus:border-primary/30 font-black text-xs text-white/60 tracking-widest uppercase appearance-none cursor-pointer"
                                            value={formData.current_level}
                                            onChange={e => setFormData({ ...formData, current_level: parseInt(e.target.value) })}
                                        >
                                            <option value={100} className="bg-bg">LEVEL 100 ALPHA</option>
                                            <option value={200} className="bg-bg">LEVEL 200 BETA</option>
                                            <option value={300} className="bg-bg">LEVEL 300 GAMMA</option>
                                            <option value={400} className="bg-bg">LEVEL 400 DELTA</option>
                                            <option value={500} className="bg-bg">LEVEL 500 EPSILON</option>
                                            <option value={600} className="bg-bg">LEVEL 600 OMEGA</option>
                                        </select>
                                    </div>
                                </div>

                                <div className="flex gap-6 pt-10">
                                    <button type="button" onClick={() => setShowInviteModal(false)} className="flex-1 px-8 py-6 bg-white/5 border border-white/5 text-white/30 font-black text-[10px] uppercase tracking-[0.3em] rounded-2xl hover:bg-white/10 transition-colors">Abort Mission</button>
                                    <button type="submit" disabled={processing} className="flex-1 bg-primary text-card font-black text-[10px] uppercase tracking-[0.3em] rounded-2xl py-6 hover:bg-primary/90 transition-all shadow-[0_0_30px_rgba(0,255,204,0.2)] flex items-center justify-center gap-3 disabled:opacity-20">
                                        {processing ? <Loader2 className="animate-spin" size={20} /> : <Send size={20} />}
                                        <span>Execute Deployment</span>
                                    </button>
                                </div>
                            </form>
                        </div>
                    </div>
                </div>
            )}

            {/* Message Modal */}
            {showMessageModal && selectedRep && (
                <div className="fixed inset-0 bg-bg/90 backdrop-blur-3xl z-[200] flex items-center justify-center p-6">
                    <div className="bg-card border border-white/5 rounded-[3rem] w-full max-w-2xl overflow-hidden shadow-2xl animate-in zoom-in duration-300 relative">
                        <div className="absolute top-0 left-0 w-full h-1 bg-accent" />
                        <div className="p-12 border-b border-white/5 flex items-center justify-between">
                            <div className="space-y-2">
                                <div className="flex items-center gap-2">
                                    <Radio size={14} className="text-accent" />
                                    <h3 className="text-2xl font-black text-white tracking-tight uppercase">Direct Uplink</h3>
                                </div>
                                <p className="text-white/20 font-black text-[10px] uppercase tracking-[0.3em]">RECIPIENT: {selectedRep.full_name}</p>
                            </div>
                            <button onClick={() => setShowMessageModal(false)} className="h-12 w-12 bg-white/5 hover:bg-white/10 text-white/20 hover:text-white rounded-2xl border border-white/5 transition-colors flex items-center justify-center">
                                <X size={24} />
                            </button>
                        </div>
                        <form onSubmit={handleSendMessage} className="p-12 space-y-10">
                            {status ? (
                                <div className="p-10 bg-accent/5 rounded-3xl border border-accent/20 flex items-center gap-6 animate-in slide-in-from-bottom-4 duration-500">
                                    <CheckCircle2 size={32} className="text-accent" />
                                    <p className="font-black text-accent text-xs uppercase tracking-[0.2em]">{status.message}</p>
                                </div>
                            ) : (
                                <>
                                    <div className="space-y-4">
                                        <label className="text-[10px] font-black text-white/30 uppercase tracking-[0.3em] px-2">Transmission Subject</label>
                                        <input 
                                            type="text" required placeholder="TACTICAL UPDATE..."
                                            className="w-full bg-white/5 border border-white/5 rounded-2xl py-6 px-8 text-white font-black text-xs uppercase tracking-widest outline-none focus:ring-4 focus:ring-accent/5 focus:border-accent/30 placeholder:text-white/5"
                                            value={messageData.subject}
                                            onChange={e => setMessageData({...messageData, subject: e.target.value})}
                                        />
                                    </div>
                                    <div className="space-y-4">
                                        <label className="text-[10px] font-black text-white/30 uppercase tracking-[0.3em] px-2">Message Payload</label>
                                        <textarea 
                                            required rows={5} placeholder="ENTER DATA..."
                                            className="w-full bg-white/5 border border-white/5 rounded-2xl py-6 px-8 text-white font-black text-xs uppercase tracking-widest outline-none focus:ring-4 focus:ring-accent/5 focus:border-accent/30 resize-none placeholder:text-white/5"
                                            value={messageData.body}
                                            onChange={e => setMessageData({...messageData, body: e.target.value})}
                                        />
                                    </div>
                                    <button 
                                        type="submit" disabled={processing}
                                        className="w-full bg-accent text-card font-black text-[10px] uppercase tracking-[0.3em] py-6 rounded-2xl transition-all shadow-[0_0_30px_rgba(176,38,255,0.2)] flex items-center justify-center gap-3 disabled:opacity-20"
                                    >
                                        {processing ? <Loader2 className="animate-spin" size={20} /> : <Zap size={20} />}
                                        <span>Dispatch Transmission</span>
                                    </button>
                                </>
                            )}
                        </form>
                    </div>
                </div>
            )}

            {/* Permissions Modal */}
            {showPermissionsModal && selectedRep && (
                <div className="fixed inset-0 bg-bg/90 backdrop-blur-3xl z-[150] flex items-center justify-center p-6">
                    <div className="bg-card border border-white/5 rounded-[3rem] w-full max-w-xl overflow-hidden shadow-2xl animate-in zoom-in duration-300 relative">
                        <div className="absolute top-0 left-0 w-full h-1 bg-primary" />
                        <div className="p-12 border-b border-white/5 flex items-center justify-between">
                            <div className="space-y-2">
                                <div className="flex items-center gap-2">
                                    <Lock size={14} className="text-primary" />
                                    <h3 className="text-2xl font-black text-white tracking-tight uppercase">Clearance Level</h3>
                                </div>
                                <p className="text-white/20 font-black text-[10px] uppercase tracking-[0.3em]">AGENT: {selectedRep.full_name}</p>
                            </div>
                            <button onClick={() => setShowPermissionsModal(false)} className="h-12 w-12 bg-white/5 hover:bg-white/10 text-white/20 hover:text-white rounded-2xl border border-white/5 transition-colors flex items-center justify-center">
                                <X size={24} />
                            </button>
                        </div>
                        <div className="p-12 space-y-10">
                            <p className="text-[10px] font-black text-white/30 uppercase tracking-[0.3em] text-center">Modify Security Credentials</p>
                            <div className="space-y-6">
                                <button 
                                    onClick={() => handleUpdatePermissions('rep')}
                                    className={`w-full p-8 rounded-[2rem] border-2 flex items-center justify-between transition-all duration-500 group/role ${
                                        selectedRep.is_rep && !selectedRep.is_admin ? 'border-primary bg-primary/5' : 'border-white/5 hover:border-white/10 bg-white/[0.02]'
                                    }`}
                                >
                                    <div className="flex items-center gap-6">
                                        <div className={`p-4 rounded-2xl transition-all duration-500 ${
                                            selectedRep.is_rep && !selectedRep.is_admin ? 'bg-primary text-card' : 'bg-white/5 text-white/30 group-hover/role:bg-white/10'
                                        }`}><User size={24} /></div>
                                        <div className="text-left">
                                            <p className="font-black text-white tracking-widest uppercase text-sm">CAMPUS_AGENT</p>
                                            <p className="text-[9px] text-white/20 font-black uppercase tracking-[0.2em] mt-1">Limited Data Ingress/Egress</p>
                                        </div>
                                    </div>
                                    {selectedRep.is_rep && !selectedRep.is_admin && <CheckCircle2 className="text-primary shadow-[0_0_10px_#00FFCC]" size={24} />}
                                </button>

                                <button 
                                    onClick={() => handleUpdatePermissions('admin')}
                                    className={`w-full p-8 rounded-[2rem] border-2 flex items-center justify-between transition-all duration-500 group/role ${
                                        selectedRep.is_admin ? 'border-primary bg-primary/5' : 'border-white/5 hover:border-white/10 bg-white/[0.02]'
                                    }`}
                                >
                                    <div className="flex items-center gap-6">
                                        <div className={`p-4 rounded-2xl transition-all duration-500 ${
                                            selectedRep.is_admin ? 'bg-primary text-card' : 'bg-white/5 text-white/30 group-hover/role:bg-white/10'
                                        }`}><Shield size={24} /></div>
                                        <div className="text-left">
                                            <p className="font-black text-white tracking-widest uppercase text-sm">LEAD_OVERSEER</p>
                                            <p className="text-[9px] text-white/20 font-black uppercase tracking-[0.2em] mt-1">Full System Authorization</p>
                                        </div>
                                    </div>
                                    {selectedRep.is_admin && <CheckCircle2 className="text-primary shadow-[0_0_10px_#00FFCC]" size={24} />}
                                </button>
                            </div>

                            <div className="space-y-4">
                                <label className="text-[10px] font-black text-white/30 uppercase tracking-[0.3em] px-2 block text-center">Update Field Authorization</label>
                                <select
                                    className="w-full px-8 py-6 bg-white/5 border border-white/5 rounded-2xl outline-none focus:ring-4 focus:ring-primary/5 focus:border-primary/30 font-black text-xs text-white/60 tracking-widest uppercase appearance-none cursor-pointer"
                                    value={selectedRep.current_level || 100}
                                    onChange={e => handleUpdatePermissions(selectedRep.role, parseInt(e.target.value))}
                                >
                                    <option value={100} className="bg-bg">LEVEL 100 ALPHA</option>
                                    <option value={200} className="bg-bg">LEVEL 200 BETA</option>
                                    <option value={300} className="bg-bg">LEVEL 300 GAMMA</option>
                                    <option value={400} className="bg-bg">LEVEL 400 DELTA</option>
                                    <option value={500} className="bg-bg">LEVEL 500 EPSILON</option>
                                    <option value={600} className="bg-bg">LEVEL 600 OMEGA</option>
                                </select>
                            </div>
                        </div>
                    </div>
                </div>
            )}
        </div>
    )
}
