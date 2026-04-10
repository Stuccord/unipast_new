'use client'

import { useState, useEffect } from 'react'
import { supabase } from '@/lib/supabase'
import { 
    Users, 
    UserPlus, 
    Search, 
    MessageSquare, 
    Shield, 
    MoreVertical, 
    CheckCircle2, 
    XCircle, 
    Mail, 
    MapPin,
    X,
    Loader2,
    ShieldCheck,
    AlertCircle
} from 'lucide-react'

export default function RepsPage() {
    const [reps, setReps] = useState<any[]>([])
    const [loading, setLoading] = useState(false)
    const [searchTerm, setSearchTerm] = useState('')
    const [showInviteModal, setShowInviteModal] = useState(false)
    const [inviteFormData, setInviteFormData] = useState({
        email: '',
        university: '',
        role: 'Representative'
    })
    const [inviting, setInviting] = useState(false)
    const [status, setStatus] = useState<{ type: 'success' | 'error', message: string } | null>(null)

    useEffect(() => {
        fetchReps()
    }, [])

    async function fetchReps() {
        setLoading(true)
        const { data } = await supabase
            .from('profiles')
            .select('*')
            .in('role', ['Representative', 'Campus Lead'])
            .order('full_name')
        
        setReps(data || [])
        setLoading(false)
    }

    async function handleInvite(e: React.FormEvent) {
        e.preventDefault()
        setInviting(true)
        setStatus(null)

        // Simulate invitation logic
        await new Promise(resolve => setTimeout(resolve, 1500))
        
        setStatus({ 
            type: 'success', 
            message: `Invitation successfully sent to ${inviteFormData.email}. They will receive an onboarding link shortly.` 
        })
        
        setInviting(false)
        setInviteFormData({ email: '', university: '', role: 'Representative' })
        setTimeout(() => setShowInviteModal(false), 3000)
    }

    const filteredReps = reps.filter(rep => 
        rep.full_name?.toLowerCase().includes(searchTerm.toLowerCase()) ||
        rep.email?.toLowerCase().includes(searchTerm.toLowerCase())
    )

    return (
        <div className="space-y-10">
            <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-6">
                <div className="space-y-1">
                    <h2 className="text-3xl font-black text-slate-800 tracking-tight">Campus Representatives</h2>
                    <p className="text-slate-500 font-medium tracking-tight">Manage and monitor the performance of your onsite campus leads.</p>
                </div>
                <button 
                    onClick={() => setShowInviteModal(true)}
                    className="bg-[#0D9488] hover:bg-teal-700 text-white font-bold py-4 px-8 rounded-2xl flex items-center space-x-3 transition-all shadow-xl shadow-teal-700/20"
                >
                    <UserPlus size={20} />
                    <span>Invite New Rep</span>
                </button>
            </div>

            {/* Reps Grid */}
            <div className="bg-white rounded-[2.5rem] border border-slate-100 shadow-sm overflow-hidden">
                <div className="p-8 bg-slate-50/50 border-b border-slate-100/50 flex flex-col md:flex-row gap-6">
                    <div className="relative flex-1 max-w-xl">
                        <Search className="absolute left-5 top-1/2 -translate-y-1/2 text-slate-400" size={20} />
                        <input
                            type="text"
                            placeholder="Search by name, email or university..."
                            value={searchTerm}
                            onChange={(e) => setSearchTerm(e.target.value)}
                            className="w-full pl-14 pr-6 py-4 rounded-2xl bg-white border-none outline-none focus:ring-2 focus:ring-[#0D9488]/20 transition-all font-medium text-slate-700 shadow-sm"
                        />
                    </div>
                </div>

                <div className="overflow-x-auto">
                    <table className="w-full text-left">
                        <thead>
                            <tr className="text-slate-400 font-black text-xs uppercase tracking-[0.2em]">
                                <th className="px-10 py-6">Representative</th>
                                <th className="px-10 py-6">Location</th>
                                <th className="px-10 py-6">Access Level</th>
                                <th className="px-10 py-6">Status</th>
                                <th className="px-10 py-6 text-right">Actions</th>
                            </tr>
                        </thead>
                        <tbody className="divide-y divide-slate-100">
                            {loading ? (
                                <tr>
                                    <td colSpan={5} className="px-10 py-24 text-center">
                                         <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-[#0D9488] mx-auto"></div>
                                    </td>
                                </tr>
                            ) : filteredReps.length === 0 ? (
                                <tr>
                                    <td colSpan={5} className="px-10 py-24 text-center text-slate-400 font-bold tracking-widest uppercase text-xs">No representatives found</td>
                                </tr>
                            ) : (
                                filteredReps.map((rep) => (
                                    <tr key={rep.id} className="hover:bg-slate-50/50 transition duration-150 group">
                                        <td className="px-10 py-8">
                                            <div className="flex items-center space-x-4">
                                                <div className="h-14 w-14 rounded-2xl bg-slate-100 border-2 border-white shadow-sm flex items-center justify-center overflow-hidden">
                                                     {rep.avatar_url ? (
                                                        <img src={rep.avatar_url} alt="" className="h-full w-full object-cover" />
                                                     ) : (
                                                        <span className="font-black text-slate-400">{rep.full_name?.charAt(0)}</span>
                                                     )}
                                                </div>
                                                <div>
                                                    <p className="font-black text-slate-800 tracking-tight">{rep.full_name}</p>
                                                    <p className="text-xs text-slate-400 font-bold">{rep.email}</p>
                                                </div>
                                            </div>
                                        </td>
                                        <td className="px-10 py-8">
                                            <div className="flex items-center space-x-2 text-slate-500 font-bold text-sm">
                                                <MapPin size={14} className="text-slate-400" />
                                                <span>{rep.level || 'University of Ghana'}</span>
                                            </div>
                                        </td>
                                        <td className="px-10 py-8">
                                            <div className="flex items-center space-x-2">
                                                <Shield size={16} className={rep.role === 'Campus Lead' ? 'text-amber-500' : 'text-slate-400'} />
                                                <span className="font-bold text-slate-700 text-sm">{rep.role}</span>
                                            </div>
                                        </td>
                                        <td className="px-10 py-8">
                                            <div className="flex items-center space-x-2">
                                                <div className={`h-2 w-2 rounded-full ${rep.status === 'Active' ? 'bg-emerald-500' : 'bg-slate-300'}`}></div>
                                                <span className="text-[10px] font-black uppercase tracking-widest text-slate-500">{rep.status || 'Active'}</span>
                                            </div>
                                        </td>
                                        <td className="px-10 py-8 text-right">
                                            <div className="flex items-center justify-end space-x-3 opacity-0 group-hover:opacity-100 transition-opacity">
                                                <button className="p-3 bg-white text-slate-400 hover:text-[#0D9488] hover:bg-[#0D9488]/10 rounded-xl transition-all shadow-sm">
                                                    <MessageSquare size={18} />
                                                </button>
                                                <button className="p-3 bg-white text-slate-400 hover:text-amber-500 hover:bg-amber-50 rounded-xl transition-all shadow-sm">
                                                    <ShieldCheck size={18} />
                                                </button>
                                                <button className="p-3 bg-white text-slate-400 hover:text-rose-500 hover:bg-rose-50 rounded-xl transition-all shadow-sm">
                                                    <XCircle size={18} />
                                                </button>
                                            </div>
                                            <div className="group-hover:hidden text-slate-300">
                                                <MoreVertical size={20} />
                                            </div>
                                        </td>
                                    </tr>
                                ))
                            )}
                        </tbody>
                    </table>
                </div>
            </div>

            {/* Invite Modal */}
            {showInviteModal && (
                <div className="fixed inset-0 bg-slate-900/60 backdrop-blur-sm z-50 flex items-center justify-center p-6">
                    <div className="bg-white rounded-[2.5rem] w-full max-w-lg overflow-hidden shadow-2xl animate-in zoom-in duration-300">
                        <div className="p-10 bg-[#0D9488] text-white relative">
                            <button onClick={() => setShowInviteModal(false)} className="absolute top-8 right-8 text-white/50 hover:text-white transition-colors">
                                <X size={24} />
                            </button>
                            <h3 className="text-3xl font-black tracking-tight">Invite Representative</h3>
                            <p className="text-teal-100 font-medium mt-2">Grant administrative access to a new campus representative.</p>
                        </div>
                        
                        <form onSubmit={handleInvite} className="p-10 space-y-8">
                            {status && (
                                <div className={`p-6 rounded-2xl border flex items-center space-x-4 ${
                                    status.type === 'success' ? 'bg-emerald-50 border-emerald-100 text-emerald-700' : 'bg-rose-50 border-rose-100 text-rose-700'
                                }`}>
                                    {status.type === 'success' ? <CheckCircle2 size={24} /> : <AlertCircle size={24} />}
                                    <p className="font-bold text-sm">{status.message}</p>
                                </div>
                            )}

                            <div className="space-y-3">
                                <label className="text-xs font-black text-slate-400 uppercase tracking-widest px-1">Email Address</label>
                                <div className="relative">
                                    <Mail className="absolute left-5 top-1/2 -translate-y-1/2 text-slate-400" size={18} />
                                    <input 
                                        type="email" required
                                        value={inviteFormData.email}
                                        onChange={(e) => setInviteFormData({ ...inviteFormData, email: e.target.value })}
                                        placeholder="rep@example.com"
                                        className="w-full pl-14 pr-6 py-4 bg-slate-50 border-none rounded-2xl outline-none focus:ring-2 focus:ring-[#0D9488]/20 font-bold text-slate-700"
                                    />
                                </div>
                            </div>

                            <div className="space-y-3">
                                <label className="text-xs font-black text-slate-400 uppercase tracking-widest px-1">University Assignment</label>
                                <div className="relative">
                                    <MapPin className="absolute left-5 top-1/2 -translate-y-1/2 text-slate-400" size={18} />
                                    <input 
                                        type="text" required
                                        value={inviteFormData.university}
                                        onChange={(e) => setInviteFormData({ ...inviteFormData, university: e.target.value })}
                                        placeholder="e.g. University of Ghana"
                                        className="w-full pl-14 pr-6 py-4 bg-slate-50 border-none rounded-2xl outline-none focus:ring-2 focus:ring-[#0D9488]/20 font-bold text-slate-700"
                                    />
                                </div>
                            </div>

                            <div className="space-y-3">
                                <label className="text-xs font-black text-slate-400 uppercase tracking-widest px-1">Access Tier</label>
                                <select 
                                    value={inviteFormData.role}
                                    onChange={(e) => setInviteFormData({ ...inviteFormData, role: e.target.value })}
                                    className="w-full px-6 py-4 bg-slate-50 border-none rounded-2xl outline-none focus:ring-2 focus:ring-[#0D9488]/20 font-bold text-slate-700 appearance-none"
                                >
                                    <option value="Representative">Standard Representative</option>
                                    <option value="Campus Lead">Campus Lead (Manager)</option>
                                </select>
                            </div>

                            <div className="pt-4 flex space-x-4">
                                <button 
                                    type="button" 
                                    onClick={() => setShowInviteModal(false)}
                                    className="flex-1 py-5 border-2 border-slate-100 text-slate-400 font-black rounded-2xl hover:bg-slate-50 transition-colors"
                                >
                                    Cancel
                                </button>
                                <button 
                                    type="submit"
                                    disabled={inviting}
                                    className="flex-1 bg-[#0D9488] text-white font-black rounded-2xl py-5 hover:bg-teal-700 transition-all shadow-lg shadow-teal-700/20 disabled:opacity-50 flex items-center justify-center space-x-2"
                                >
                                    {inviting && <Loader2 className="animate-spin" size={20} />}
                                    <span>{inviting ? 'Sending...' : 'Send Invitation'}</span>
                                </button>
                            </div>
                        </form>
                    </div>
                </div>
            )}
        </div>
    )
}
