'use client'

import { useState, useEffect } from 'react'
import { supabase } from '@/lib/supabase'
import { UserPlus, Mail, Shield, Trash2, Search, ChevronRight, MoreVertical, MapPin, X, User, GraduationCap, Building2, Send, Loader2, CheckCircle2 } from 'lucide-react'
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

    // Selection Data
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
                .eq('role', 'rep')
                .order('full_name')
            
            if (data) {
                setReps(data.map(r => ({
                    ...r,
                    university: (r.faculties as any)?.universities?.name || 'N/A',
                    faculty_name: (r.faculties as any)?.name || 'N/A',
                    level: r.current_level || 'N/A'
                })))
            }
        } catch (error) {
            console.error('Error fetching reps:', error)
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
            alert('Representative account created successfully! They can now log in with the email and password you provided.')
        } else {
            alert('Error inviting representative: ' + result.error)
        }
        setProcessing(false)
    }

    async function handleSendMessage(e: React.FormEvent) {
        e.preventDefault()
        setProcessing(true)
        setStatus(null)
        // Simulate message sending
        await new Promise(resolve => setTimeout(resolve, 1500))
        setStatus({ type: 'success', message: `Message sent to ${selectedRep.full_name} successfully.` })
        setProcessing(false)
        setTimeout(() => setShowMessageModal(false), 2000)
    }

    async function handleUpdatePermissions(newRole: string, newLevel?: number) {
        setProcessing(true)
        const updateData: any = { role: newRole }
        if (newLevel) updateData.current_level = newLevel
        
        const { error } = await supabase
            .from('profiles')
            .update(updateData)
            .eq('id', selectedRep.id)
        
        if (!error) {
            fetchReps()
            setShowPermissionsModal(false)
        } else {
            alert('Error updating permissions: ' + error.message)
        }
        setProcessing(false)
    }

    async function handleRemove(id: string) {
        if (!confirm('Are you sure you want to remove this representative?')) return
        
        const { error } = await supabase.from('profiles').delete().eq('id', id)
        if (!error) {
            fetchReps()
        } else {
            alert('Error removing rep: ' + error.message)
        }
    }

    const filteredReps = reps.filter(r =>
        r.full_name?.toLowerCase().includes(searchTerm.toLowerCase()) ||
        r.id.toLowerCase().includes(searchTerm.toLowerCase())
    )

    const filteredFaculties = faculties.filter(f => f.university_id === formData.university_id)

    return (
        <div className="space-y-10">
            <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-6">
                <div className="space-y-1">
                    <h2 className="text-3xl font-black text-slate-800 tracking-tight">Campus Representatives</h2>
                    <p className="text-slate-500 font-medium tracking-tight">Manage and oversee all active student representatives across campuses.</p>
                </div>
                <button 
                    onClick={() => setShowInviteModal(true)}
                    className="bg-[#0D9488] hover:bg-teal-700 text-white font-bold py-4 px-8 rounded-2xl flex items-center space-x-3 transition-all shadow-xl shadow-teal-700/20"
                >
                    <UserPlus size={20} />
                    <span>Invite New Rep</span>
                </button>
            </div>

            <div className="bg-white rounded-[2.5rem] border border-slate-100 shadow-sm overflow-hidden">
                <div className="p-8 bg-slate-50/50 border-b border-slate-100/50">
                    <div className="relative max-w-md">
                        <Search className="absolute left-5 top-1/2 -translate-y-1/2 text-slate-400" size={20} />
                        <input
                            type="text"
                            placeholder="Search by name, ID or campus..."
                            value={searchTerm}
                            onChange={(e) => setSearchTerm(e.target.value)}
                            className="w-full pl-14 pr-6 py-4 rounded-2xl bg-white border-none outline-none focus:ring-2 focus:ring-[#0D9488]/20 transition-all font-medium text-slate-700 shadow-sm"
                        />
                    </div>
                </div>

                <div className="overflow-x-auto">
                    <table className="w-full text-left border-collapse">
                        <thead>
                            <tr className="text-slate-400 font-black text-xs uppercase tracking-[0.2em]">
                                <th className="px-10 py-6">Representative</th>
                                <th className="px-10 py-6">Campus & Assignment</th>
                                <th className="px-10 py-6">Account Status</th>
                                <th className="px-10 py-6 text-right">Actions</th>
                            </tr>
                        </thead>
                        <tbody className="divide-y divide-slate-100">
                            {loading ? (
                                <tr>
                                    <td colSpan={4} className="px-10 py-24 text-center">
                                         <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-[#0D9488] mx-auto"></div>
                                    </td>
                                </tr>
                            ) : filteredReps.length === 0 ? (
                                <tr>
                                    <td colSpan={4} className="px-10 py-24 text-center text-slate-400 font-bold tracking-widest uppercase text-xs">No results matched your search</td>
                                </tr>
                            ) : (
                                filteredReps.map((rep) => (
                                    <tr key={rep.id} className="hover:bg-slate-50/50 transition duration-150 group">
                                        <td className="px-10 py-8">
                                            <div className="flex items-center space-x-4">
                                                <div className="h-14 w-14 rounded-2xl bg-slate-100 flex items-center justify-center text-[#0D9488] font-black text-xl border-2 border-white shadow-sm group-hover:scale-105 transition-transform duration-300">
                                                    {rep.full_name?.[0] || 'U'}
                                                </div>
                                                <div>
                                                    <p className="font-black text-slate-800 text-lg tracking-tight">{rep.full_name || 'Unnamed User'}</p>
                                                    <p className="text-sm text-slate-400 font-bold">{rep.email || 'N/A'}</p>
                                                </div>
                                            </div>
                                        </td>
                                        <td className="px-10 py-8">
                                            <div className="flex flex-col space-y-1">
                                                <div className="flex items-center space-x-2 text-slate-700 font-black">
                                                    <MapPin size={14} className="text-[#0D9488]" />
                                                    <span className="text-sm">{rep.university || 'N/A'}</span>
                                                </div>
                                                <span className="text-xs text-slate-400 font-bold ml-5">Level {rep.level || 'N/A'}</span>
                                            </div>
                                        </td>
                                        <td className="px-10 py-8">
                                            <span className={`px-4 py-2 rounded-xl text-xs font-black uppercase tracking-widest ring-1 ring-inset ${
                                                rep.status === 'Active' ? 'bg-emerald-50 text-emerald-600 ring-emerald-600/20' : 'bg-amber-50 text-amber-600 ring-amber-600/20'
                                            }`}>
                                                {rep.status || 'Active'}
                                            </span>
                                        </td>
                                        <td className="px-10 py-8 text-right">
                                            <div className="flex items-center justify-end space-x-3 opacity-0 group-hover:opacity-100 transition-opacity">
                                                <button 
                                                    onClick={() => { setSelectedRep(rep); setShowMessageModal(true); setStatus(null); }}
                                                    className="p-3 bg-slate-50 text-slate-400 hover:text-[#0D9488] hover:bg-[#0D9488]/10 rounded-xl transition-all" title="Message"
                                                >
                                                    <Mail size={18} />
                                                </button>
                                                <button 
                                                    onClick={() => { setSelectedRep(rep); setShowPermissionsModal(true); }}
                                                    className="p-3 bg-slate-50 text-slate-400 hover:text-orange-500 hover:bg-orange-50 rounded-xl transition-all" title="Permissions"
                                                >
                                                    <Shield size={18} />
                                                </button>
                                                <button 
                                                    onClick={() => handleRemove(rep.id)}
                                                    className="p-3 bg-slate-50 text-slate-400 hover:text-rose-500 hover:bg-rose-50 rounded-xl transition-all" 
                                                    title="Remove"
                                                >
                                                    <Trash2 size={18} />
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

            {/* Invite Rep Modal */}
            {showInviteModal && (
                <div className="fixed inset-0 bg-slate-900/40 backdrop-blur-md flex items-center justify-center p-6 z-50 animate-in fade-in duration-300">
                    <div className="bg-white rounded-[2.5rem] max-w-2xl w-full shadow-2xl overflow-hidden animate-in zoom-in-95 duration-300">
                        <div className="bg-[#0D9488] p-10 text-white relative">
                            <button 
                                onClick={() => setShowInviteModal(false)}
                                className="absolute top-8 right-8 text-white/50 hover:text-white transition-colors"
                            >
                                <X size={24} />
                            </button>
                            <div className="flex items-center space-x-4 mb-2">
                                <div className="p-3 bg-white/10 rounded-2xl backdrop-blur-sm">
                                    <UserPlus size={24} />
                                </div>
                                <h3 className="text-3xl font-black tracking-tight">Invite Representative</h3>
                            </div>
                            <p className="text-teal-100 font-medium">Assign a new student representative to a specific academic context.</p>
                        </div>
                        
                        <form onSubmit={handleInvite} className="p-10 space-y-8">
                            <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
                                <div className="space-y-3">
                                    <label className="text-xs font-black text-slate-400 uppercase tracking-widest px-1">Full Name</label>
                                    <div className="relative">
                                        <User className="absolute left-5 top-1/2 -translate-y-1/2 text-slate-300" size={18} />
                                        <input
                                            type="text" required placeholder="e.g. John Mensah"
                                            className="w-full pl-14 pr-6 py-4 bg-slate-50 border-none rounded-2xl outline-none focus:ring-2 focus:ring-[#0D9488]/20 font-bold text-slate-700 transition-all"
                                            value={formData.full_name}
                                            onChange={e => setFormData({ ...formData, full_name: e.target.value })}
                                        />
                                    </div>
                                </div>
                                <div className="space-y-3">
                                    <label className="text-xs font-black text-slate-400 uppercase tracking-widest px-1">Email Address</label>
                                    <div className="relative">
                                        <Mail className="absolute left-5 top-1/2 -translate-y-1/2 text-slate-300" size={18} />
                                        <input
                                            type="email" required placeholder="e.g. john@university.edu"
                                            className="w-full pl-14 pr-6 py-4 bg-slate-50 border-none rounded-2xl outline-none focus:ring-2 focus:ring-[#0D9488]/20 font-bold text-slate-700 transition-all"
                                            value={formData.email}
                                            onChange={e => setFormData({ ...formData, email: e.target.value })}
                                        />
                                    </div>
                                </div>

                                <div className="space-y-3">
                                    <label className="text-xs font-black text-slate-400 uppercase tracking-widest px-1">Login Password</label>
                                    <div className="relative">
                                        <Shield className="absolute left-5 top-1/2 -translate-y-1/2 text-slate-300" size={18} />
                                        <input
                                            type="text" required placeholder="e.g. TempPass123!"
                                            className="w-full pl-14 pr-6 py-4 bg-slate-50 border-none rounded-2xl outline-none focus:ring-2 focus:ring-[#0D9488]/20 font-bold text-slate-700 transition-all"
                                            value={formData.password}
                                            onChange={e => setFormData({ ...formData, password: e.target.value })}
                                        />
                                    </div>
                                </div>
                                
                                <div className="space-y-3">
                                    <label className="text-xs font-black text-slate-400 uppercase tracking-widest px-1">University</label>
                                    <div className="relative">
                                        <Building2 className="absolute left-5 top-1/2 -translate-y-1/2 text-slate-300" size={18} />
                                        <select
                                            required
                                            className="w-full pl-14 pr-6 py-4 bg-slate-50 border-none rounded-2xl outline-none focus:ring-2 focus:ring-[#0D9488]/20 font-bold text-slate-700 appearance-none cursor-pointer"
                                            value={formData.university_id}
                                            onChange={e => setFormData({ ...formData, university_id: e.target.value, faculty_id: '' })}
                                        >
                                            <option value="">Select University</option>
                                            {unis.map(u => <option key={u.id} value={u.id}>{u.name}</option>)}
                                        </select>
                                    </div>
                                </div>
                                
                                <div className="space-y-3">
                                    <label className="text-xs font-black text-slate-400 uppercase tracking-widest px-1">Faculty / School</label>
                                    <div className="relative">
                                        <GraduationCap className="absolute left-5 top-1/2 -translate-y-1/2 text-slate-300" size={18} />
                                        <select
                                            required
                                            disabled={!formData.university_id}
                                            className="w-full pl-14 pr-6 py-4 bg-slate-50 border-none rounded-2xl outline-none focus:ring-2 focus:ring-[#0D9488]/20 font-bold text-slate-700 appearance-none cursor-pointer disabled:opacity-50"
                                            value={formData.faculty_id}
                                            onChange={e => setFormData({ ...formData, faculty_id: e.target.value })}
                                        >
                                            <option value="">Select Faculty</option>
                                            {filteredFaculties.map(f => <option key={f.id} value={f.id}>{f.name}</option>)}
                                        </select>
                                    </div>
                                </div>

                                <div className="space-y-3">
                                    <label className="text-xs font-black text-slate-400 uppercase tracking-widest px-1">Level</label>
                                    <select
                                        required
                                        className="w-full px-6 py-4 bg-slate-50 border-none rounded-2xl outline-none focus:ring-2 focus:ring-[#0D9488]/20 font-bold text-slate-700 appearance-none cursor-pointer"
                                        value={formData.current_level}
                                        onChange={e => setFormData({ ...formData, current_level: parseInt(e.target.value) })}
                                    >
                                        <option value={100}>100 (Level 1)</option>
                                        <option value={200}>200 (Level 2)</option>
                                        <option value={300}>300 (Level 3)</option>
                                        <option value={400}>400 (Level 4)</option>
                                        <option value={500}>500 (Level 5)</option>
                                        <option value={600}>600 (Level 6)</option>
                                    </select>
                                </div>
                            </div>

                            <div className="flex space-x-4 pt-4">
                                <button type="button" onClick={() => setShowInviteModal(false)} className="flex-1 px-8 py-5 border-2 border-slate-100 text-slate-400 font-black rounded-2xl hover:bg-slate-50 transition-colors">Cancel</button>
                                <button type="submit" disabled={processing} className="flex-1 bg-[#0D9488] text-white font-black rounded-2xl py-5 hover:bg-teal-700 transition-all shadow-lg shadow-teal-700/20 flex items-center justify-center space-x-3 disabled:opacity-50">
                                    {processing ? <Loader2 className="animate-spin" size={20} /> : <Send size={20} />}
                                    <span>Send Invitation</span>
                                </button>
                            </div>
                        </form>
                    </div>
                </div>
            )}

            {/* Message Modal */}
            {showMessageModal && selectedRep && (
                <div className="fixed inset-0 bg-slate-900/60 backdrop-blur-sm z-50 flex items-center justify-center p-6">
                    <div className="bg-white rounded-[2.5rem] w-full max-w-xl overflow-hidden shadow-2xl animate-in zoom-in duration-300">
                        <div className="p-8 border-b border-slate-100 flex items-center justify-between bg-slate-50">
                            <div>
                                <h3 className="text-xl font-black text-slate-800 tracking-tight">Direct Message</h3>
                                <p className="text-slate-400 font-bold text-[10px] uppercase tracking-widest">To: {selectedRep.full_name}</p>
                            </div>
                            <button onClick={() => setShowMessageModal(false)} className="p-2 text-slate-400 hover:text-slate-800 transition-colors">
                                <X size={20} />
                            </button>
                        </div>
                        <form onSubmit={handleSendMessage} className="p-10 space-y-6">
                            {status ? (
                                <div className="p-6 bg-emerald-50 text-emerald-700 rounded-3xl border border-emerald-100 flex items-center space-x-4">
                                    <CheckCircle2 size={24} />
                                    <p className="font-bold">{status.message}</p>
                                </div>
                            ) : (
                                <>
                                    <div className="space-y-2">
                                        <label className="text-[10px] font-black text-slate-400 uppercase tracking-widest px-1">Subject</label>
                                        <input 
                                            type="text" required placeholder="Academic Update..."
                                            className="w-full bg-slate-50 rounded-2xl py-4 px-6 text-slate-800 font-bold outline-none focus:ring-2 focus:ring-[#0D9488]/20"
                                            value={messageData.subject}
                                            onChange={e => setMessageData({...messageData, subject: e.target.value})}
                                        />
                                    </div>
                                    <div className="space-y-2">
                                        <label className="text-[10px] font-black text-slate-400 uppercase tracking-widest px-1">Message Body</label>
                                        <textarea 
                                            required rows={5} placeholder="Type your message here..."
                                            className="w-full bg-slate-50 rounded-2xl py-4 px-6 text-slate-800 font-bold outline-none focus:ring-2 focus:ring-[#0D9488]/20 resize-none"
                                            value={messageData.body}
                                            onChange={e => setMessageData({...messageData, body: e.target.value})}
                                        />
                                    </div>
                                    <button 
                                        type="submit" disabled={processing}
                                        className="w-full bg-[#0D9488] hover:bg-teal-700 text-white font-black py-4 rounded-2xl transition-all shadow-lg flex items-center justify-center space-x-3 disabled:opacity-50"
                                    >
                                        {processing ? <Loader2 className="animate-spin" size={20} /> : <Send size={20} />}
                                        <span>Dispatch Message</span>
                                    </button>
                                </>
                            )}
                        </form>
                    </div>
                </div>
            )}

            {/* Permissions Modal */}
            {showPermissionsModal && selectedRep && (
                <div className="fixed inset-0 bg-slate-900/60 backdrop-blur-sm z-50 flex items-center justify-center p-6">
                    <div className="bg-white rounded-[2.5rem] w-full max-w-lg overflow-hidden shadow-2xl animate-in zoom-in duration-300">
                        <div className="p-8 border-b border-slate-100 flex items-center justify-between bg-white">
                            <div>
                                <h3 className="text-xl font-black text-slate-800 tracking-tight">Access Control</h3>
                                <p className="text-slate-400 font-bold text-[10px] uppercase tracking-widest">{selectedRep.full_name}</p>
                            </div>
                            <button onClick={() => setShowPermissionsModal(false)} className="p-2 text-slate-400 hover:text-slate-800 transition-colors">
                                <X size={20} />
                            </button>
                        </div>
                        <div className="p-10 space-y-6">
                            <p className="text-sm font-bold text-slate-500 text-center">Select the administrative role for this representative.</p>
                            <div className="space-y-4">
                                <button 
                                    onClick={() => handleUpdatePermissions('rep')}
                                    className={`w-full p-6 rounded-3xl border-2 flex items-center justify-between transition-all ${selectedRep.role === 'rep' ? 'border-[#0D9488] bg-teal-50/50' : 'border-slate-50 hover:border-slate-200'}`}
                                >
                                    <div className="flex items-center space-x-4">
                                        <div className={`p-3 rounded-2xl ${selectedRep.role === 'rep' ? 'bg-[#0D9488] text-white' : 'bg-slate-100 text-slate-400'}`}><User size={20} /></div>
                                        <div className="text-left">
                                            <p className="font-black text-slate-800 tracking-tight">Campus Rep</p>
                                            <p className="text-[10px] text-slate-400 font-bold uppercase">Basic Material Collection</p>
                                        </div>
                                    </div>
                                    {selectedRep.role === 'rep' && <CheckCircle2 className="text-[#0D9488]" size={20} />}
                                </button>

                                <button 
                                    onClick={() => handleUpdatePermissions('admin')}
                                    className={`w-full p-6 rounded-3xl border-2 flex items-center justify-between transition-all ${selectedRep.role === 'admin' ? 'border-[#0D9488] bg-teal-50/50' : 'border-slate-50 hover:border-slate-200'}`}
                                >
                                    <div className="flex items-center space-x-4">
                                        <div className={`p-3 rounded-2xl ${selectedRep.role === 'admin' ? 'bg-[#0D9488] text-white' : 'bg-slate-100 text-slate-400'}`}><Shield size={20} /></div>
                                        <div className="text-left">
                                            <p className="font-black text-slate-800 tracking-tight">Lead Admin</p>
                                            <p className="text-[10px] text-slate-400 font-bold uppercase">Full Platform Control</p>
                                        </div>
                                    </div>
                                    {selectedRep.role === 'admin' && <CheckCircle2 className="text-[#0D9488]" size={20} />}
                                </button>
                            </div>

                            <div className="space-y-3">
                                <label className="text-xs font-black text-slate-400 uppercase tracking-widest px-1 text-center block">Update Level Assignment</label>
                                <select
                                    className="w-full px-6 py-4 bg-slate-50 border-none rounded-2xl outline-none focus:ring-2 focus:ring-[#0D9488]/20 font-bold text-slate-700 appearance-none cursor-pointer"
                                    value={selectedRep.current_level || 100}
                                    onChange={e => handleUpdatePermissions(selectedRep.role, parseInt(e.target.value))}
                                >
                                    <option value={100}>100 (Level 1)</option>
                                    <option value={200}>200 (Level 2)</option>
                                    <option value={300}>300 (Level 3)</option>
                                    <option value={400}>400 (Level 4)</option>
                                    <option value={500}>500 (Level 5)</option>
                                    <option value={600}>600 (Level 6)</option>
                                </select>
                            </div>
                        </div>
                    </div>
                </div>
            )}
        </div>
    )
}
