'use client'



import { useEffect, useState } from 'react'
import { supabase } from '@/lib/supabase'
import {
    Users,
    DollarSign,
    UploadCloud,
    Star,
    ArrowUpRight,
    ArrowDownRight,
    FileText,
    Download,
    Eye,
    ChevronRight,
    PlusCircle,
    UserPlus,
    FileCheck,
    Clock,
    Trash2,
    Activity,
    Shield,
    TrendingUp,
    Zap
} from 'lucide-react'

export default function DashboardPage() {
    const [stats, setStats] = useState({
        users: 0,
        subscriptions: 0,
        revenue: 0,
        uploads: 0
    })
    const [recentUploads, setRecentUploads] = useState<any[]>([])
    const [loading, setLoading] = useState(true)
    const [profile, setProfile] = useState<any>(null)

    useEffect(() => {
        const fetchDashboardData = async () => {
            setLoading(true)
            try {
                const { data: { user } } = await supabase.auth.getUser()
                let userRole = 'user'
                if (user) {
                    const { data: profileData } = await supabase.from('profiles').select('*').eq('id', user.id).single()
                    if (profileData) {
                        setProfile(profileData)
                        userRole = profileData.role || (profileData.is_admin ? 'admin' : (profileData.is_rep ? 'rep' : 'user'))
                    }
                }

                let userCount = 0
                if (userRole === 'admin') {
                    const { count } = await supabase
                        .from('profiles')
                        .select('*', { count: 'exact', head: true })
                    userCount = count || 0
                }
                
                let totalRev = 0
                if (userRole === 'admin') {
                    const { data: transData } = await supabase
                        .from('transactions')
                        .select('amount')
                    totalRev = transData?.reduce((acc, curr) => acc + (curr.amount || 0), 0) || 0
                }

                const { count: uploadCount } = await supabase
                    .from('past_questions')
                    .select('*', { count: 'exact', head: true })

                const { data: uploads } = await supabase
                    .from('past_questions')
                    .select('*, courses(title, faculties(name)), profiles(full_name)')
                    .order('created_at', { ascending: false })
                    .limit(7)

                const { count: subCount } = await supabase
                    .from('subscriptions')
                    .select('*', { count: 'exact', head: true })
                    .eq('status', 'active')

                setStats({
                    users: userCount || 0,
                    revenue: totalRev,
                    uploads: uploadCount || 0,
                    subscriptions: subCount || 0
                })

                if (uploads) {
                    setRecentUploads(uploads.map(u => ({
                        id: u.id,
                        filePath: u.pdf_url,
                        name: u.title || `Paper ${u.year}`,
                        type: 'pdf',
                        uploader: u.profiles?.full_name || 'Root-System',
                        dept: u.courses?.faculties?.name || 'Central-Hub',
                        date: new Date(u.created_at).toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' }),
                        status: 'DEPLOYED'
                    })))
                }

            } catch (error) {
                console.error('Error fetching dashboard data:', error)
            } finally {
                setLoading(false)
            }
        }

        fetchDashboardData()
    }, [])

    const handleDelete = async (id: string, filePath: string) => {
        if (!confirm('INITIATE SECURITY WIPE? THIS DATA CANNOT BE RECOVERED.')) return
        
        try {
            const { deletePastQuestion } = await import('./upload/actions')
            const result = await deletePastQuestion(id, filePath)
            if (result.success) {
                setRecentUploads(prev => prev.filter(u => u.id !== id))
                setStats(prev => ({ ...prev, uploads: prev.uploads - 1 }))
            } else {
                alert('CRITICAL ERROR: ' + result.error)
            }
        } catch (err) {
            console.error('Deletion error:', err)
            alert('UNEXPECTED CORE FAILURE.')
        }
    }

    const handleView = (url: string) => {
        if (!url) return
        window.open(url, '_blank')
    }

    const handleDownload = async (url: string, filename: string) => {
        if (!url) return
        try {
            const response = await fetch(url)
            const blob = await response.blob()
            const blobUrl = window.URL.createObjectURL(blob)
            const link = document.createElement('a')
            link.href = blobUrl
            link.download = filename || 'document.pdf'
            document.body.appendChild(link)
            link.click()
            document.body.removeChild(link)
            window.URL.revokeObjectURL(blobUrl)
        } catch (error) {
            console.error('DOWNLOAD FAILURE:', error)
            alert('EXTRACTION FAILED. SOURCE NODE UNREACHABLE.')
        }
    }

    const statCards = [
        { 
            name: 'Network Nodes', 
            label: 'TOTAL REGISTERED USERS',
            value: stats.users.toLocaleString(), 
            change: '+6.2%', 
            isUp: true,
            icon: Users, 
            color: 'text-primary', 
            glow: 'shadow-[0_0_20px_rgba(0,255,204,0.3)]',
            sparkline: (
                <svg className="w-full h-12" viewBox="0 0 100 40" preserveAspectRatio="none">
                    <path d="M0,35 Q20,30 40,32 T80,10 T100,5" fill="none" stroke="#00FFCC" strokeWidth="2" strokeDasharray="2,2" />
                    <path d="M0,35 Q20,30 40,32 T80,10 T100,5" fill="none" stroke="#00FFCC" strokeWidth="2" className="animate-pulse" />
                </svg>
            )
        },
        { 
            name: 'Resource Flow', 
            label: 'TOTAL REVENUE GENERATED',
            value: `GH₵ ${stats.revenue.toLocaleString()}`, 
            change: '+14.8%', 
            isUp: true,
            icon: DollarSign, 
            color: 'text-accent', 
            glow: 'shadow-[0_0_20px_rgba(255,184,0,0.3)]',
            sparkline: (
                <svg className="w-full h-12" viewBox="0 0 100 40" preserveAspectRatio="none">
                    <path d="M0,38 Q25,35 50,30 T75,15 T100,2" fill="none" stroke="#FFB800" strokeWidth="2" className="animate-pulse" />
                </svg>
            )
        },
        { 
            name: 'Data Inflow', 
            label: 'PAPERS INJECTED INTO CORE',
            value: stats.uploads.toLocaleString(), 
            change: '+21.1%', 
            isUp: true,
            icon: UploadCloud, 
            color: 'text-secondary', 
            glow: 'shadow-[0_0_20px_rgba(176,38,255,0.3)]',
            sparkline: (
                <svg className="w-full h-12" viewBox="0 0 100 40" preserveAspectRatio="none">
                    <path d="M0,30 Q20,32 40,25 T80,15 T100,8" fill="none" stroke="#B026FF" strokeWidth="2" className="animate-pulse" />
                </svg>
            )
        },
        { 
            name: 'Active Syncs', 
            label: 'PREMIUM SUBSCRIPTIONS',
            value: stats.subscriptions.toLocaleString(), 
            change: '+8.5%', 
            isUp: true,
            icon: Zap, 
            color: 'text-primary', 
            glow: 'shadow-[0_0_20px_rgba(0,255,204,0.3)]',
            sparkline: (
                <svg className="w-full h-12" viewBox="0 0 100 40" preserveAspectRatio="none">
                    <path d="M0,35 Q30,32 50,33 T80,25 T100,20" fill="none" stroke="#00FFCC" strokeWidth="2" className="animate-pulse" />
                </svg>
            )
        },
    ]

    const isAdmin = profile?.is_admin
    const isRep = profile?.role === 'rep' || profile?.is_rep

    const visibleStats = statCards.filter(stat => {
        if (isRep) return stat.name === 'Data Inflow'
        return true
    })

    return (
        <div className="space-y-12 pb-20">
            {/* Header section */}
            <div className="flex flex-col md:flex-row md:items-end justify-between gap-6">
                <div className="space-y-3">
                    <div className="flex items-center gap-3">
                        <div className="w-2 h-2 rounded-full bg-primary animate-ping" />
                        <span className="text-[10px] font-black text-primary uppercase tracking-[0.4em] font-orbitron">Neural Signal Stable</span>
                    </div>
                    <h2 className="text-4xl font-black text-white tracking-tight font-orbitron uppercase">
                        {isRep ? `Welcome, ${profile?.full_name?.split(' ')[0] || 'Agent'}` : 'Global Terminal Oversight'}
                    </h2>
                    <p className="text-white/30 text-xs font-black uppercase tracking-[0.2em] font-orbitron">SYSTEM TIME: {new Date().toLocaleTimeString()} | ENCRYPTION: AES-256V</p>
                </div>
                
                <div className="flex gap-4">
                    <button className="px-6 py-3 bg-white/5 border border-white/10 rounded-2xl flex items-center gap-3 text-[10px] font-black uppercase tracking-widest font-orbitron hover:bg-white/10 hover:border-primary/30 transition-all">
                        <Activity size={16} className="text-primary" />
                        Diagnostic Run
                    </button>
                    <button className="px-6 py-3 bg-primary text-card rounded-2xl flex items-center gap-3 text-[10px] font-black uppercase tracking-widest font-orbitron hover:bg-primary/90 transition-all shadow-[0_0_20px_rgba(0,255,204,0.3)]">
                        <TrendingUp size={16} />
                        Network Flux
                    </button>
                </div>
            </div>

            {/* Stats Grid */}
            <div className={`grid grid-cols-1 gap-8 ${isRep ? 'md:grid-cols-1 max-w-md' : 'md:grid-cols-2 xl:grid-cols-4'}`}>
                {visibleStats.map((stat) => (
                    <div key={stat.name} className="relative group">
                        <div className={`absolute inset-0 bg-card rounded-[2.5rem] opacity-40 transition-all duration-500 group-hover:opacity-100 ${stat.glow}`} />
                        <div className="relative bg-white/5 backdrop-blur-xl p-8 rounded-[2.5rem] border border-white/5 flex flex-col justify-between h-full hover:border-white/10 transition-all duration-500">
                            <div className="flex items-start justify-between mb-8">
                                <div className={`p-4 rounded-2xl bg-white/5 ${stat.color} border border-white/10 group-hover:scale-110 transition-transform duration-500`}>
                                    <stat.icon size={28} />
                                </div>
                                <div className="text-right">
                                    <p className="text-[9px] font-black text-white/30 mb-2 uppercase tracking-[0.2em] font-orbitron">{stat.label}</p>
                                    <h3 className="text-3xl font-black text-white tracking-tight font-orbitron">{stat.value}</h3>
                                </div>
                            </div>
                            <div className="flex items-end justify-between">
                                <div className="flex flex-col">
                                    <span className={`text-[10px] font-black flex items-center gap-1 font-orbitron ${stat.isUp ? 'text-primary' : 'text-danger'}`}>
                                        {stat.isUp ? <ArrowUpRight size={12} /> : <ArrowDownRight size={12} />}
                                        {stat.change} 
                                        <span className="text-white/10 font-black ml-1 uppercase tracking-widest">vs previous epoch</span>
                                    </span>
                                </div>
                                <div className="w-[80px]">
                                    {stat.sparkline}
                                </div>
                            </div>
                        </div>
                    </div>
                ))}
            </div>

            <div className="grid grid-cols-1 xl:grid-cols-4 gap-12">
                {/* Recent Uploads Table */}
                <div className="xl:col-span-3">
                    <div className="bg-card/40 backdrop-blur-2xl rounded-[3rem] border border-white/5 overflow-hidden shadow-2xl">
                        <div className="p-10 border-b border-white/5 flex items-center justify-between">
                            <div className="flex items-center gap-4">
                                <div className="p-3 bg-secondary/10 rounded-2xl border border-secondary/20">
                                    <Shield size={20} className="text-secondary" />
                                </div>
                                <div>
                                    <h3 className="text-xl font-black text-white tracking-widest font-orbitron uppercase">Resource Manifest</h3>
                                    <p className="text-white/20 text-[9px] font-black uppercase tracking-[0.3em] font-orbitron mt-1">REAL-TIME INJECTION MONITORING</p>
                                </div>
                            </div>
                            <a href="/admin/content" className="p-4 bg-white/5 rounded-2xl text-primary font-black text-[10px] uppercase tracking-[0.2em] font-orbitron hover:bg-white/10 transition-all border border-white/5 flex items-center gap-3">
                                FULL REPOSITORY
                                <ChevronRight size={14} />
                            </a>
                        </div>
                        <div className="overflow-x-auto">
                            <table className="w-full text-left">
                                <thead>
                                    <tr className="border-b border-white/5 bg-white/[0.02]">
                                        <th className="px-10 py-6 text-[9px] font-black text-white/30 uppercase tracking-[0.4em] font-orbitron">Data Stream</th>
                                        <th className="px-10 py-6 text-[9px] font-black text-white/30 uppercase tracking-[0.4em] font-orbitron">Source Agent</th>
                                        <th className="px-10 py-6 text-[9px] font-black text-white/30 uppercase tracking-[0.4em] font-orbitron">Core Sector</th>
                                        <th className="px-10 py-6 text-[9px] font-black text-white/30 uppercase tracking-[0.4em] font-orbitron">Timestamp</th>
                                        <th className="px-10 py-6 text-[9px] font-black text-white/30 uppercase tracking-[0.4em] font-orbitron">Status</th>
                                        <th className="px-10 py-6 text-[9px] font-black text-white/30 uppercase tracking-[0.4em] font-orbitron text-right">Operations</th>
                                    </tr>
                                </thead>
                                <tbody className="divide-y divide-white/5">
                                    {loading ? (
                                        <tr><td colSpan={6} className="px-10 py-32 text-center">
                                            <div className="relative w-16 h-16 mx-auto">
                                                <div className="absolute inset-0 border-4 border-primary/10 rounded-full" />
                                                <div className="absolute inset-0 border-4 border-primary rounded-full border-t-transparent animate-spin" />
                                            </div>
                                        </td></tr>
                                    ) : recentUploads.length === 0 ? (
                                        <tr><td colSpan={6} className="px-10 py-32 text-center">
                                            <p className="text-white/10 font-black uppercase tracking-[0.5em] font-orbitron text-xs">NO NEW DATA DETECTED</p>
                                        </td></tr>
                                    ) : recentUploads.map((file, i) => (
                                        <tr key={i} className="hover:bg-white/[0.03] transition-colors duration-300 group">
                                            <td className="px-10 py-8">
                                                <div className="flex items-center space-x-6 min-w-0 flex-1">
                                                    <div className="relative h-14 w-14 rounded-2xl bg-white/5 flex items-center justify-center text-white/40 border border-white/10 group-hover:border-primary/50 transition-all duration-500 overflow-hidden shrink-0">
                                                        <div className="absolute inset-0 bg-primary/5 opacity-0 group-hover:opacity-100 transition-opacity" />
                                                        <FileText size={24} className="relative z-10 group-hover:text-primary transition-colors" />
                                                    </div>
                                                    <span className="font-black text-white tracking-widest font-orbitron text-sm uppercase group-hover:text-primary transition-colors truncate">{file.name}</span>
                                                </div>
                                            </td>
                                            <td className="px-10 py-8">
                                                <div className="flex items-center space-x-4 min-w-0">
                                                    <div className="h-10 w-10 rounded-xl bg-surface border border-white/10 flex items-center justify-center text-primary font-black font-orbitron text-[10px] uppercase shrink-0">
                                                         {file.uploader[0]}
                                                    </div>
                                                    <span className="text-[11px] font-black text-white/60 tracking-widest font-orbitron uppercase truncate">{file.uploader}</span>
                                                </div>
                                            </td>
                                            <td className="px-10 py-8 max-w-[150px]">
                                                <span className="text-[11px] font-black text-white/40 tracking-widest font-orbitron uppercase truncate block">{file.dept}</span>
                                            </td>
                                            <td className="px-10 py-8 text-[10px] font-black text-white/20 tracking-widest font-orbitron uppercase">{file.date}</td>
                                            <td className="px-10 py-8">
                                                <div className="flex items-center gap-3">
                                                    <div className="w-1.5 h-1.5 rounded-full bg-primary shadow-[0_0_8px_#00FFCC]" />
                                                    <span className="text-[10px] font-black text-primary uppercase tracking-[0.2em] font-orbitron">
                                                        {file.status}
                                                    </span>
                                                </div>
                                            </td>
                                            <td className="px-10 py-8 text-right">
                                                <div className="flex items-center justify-end space-x-4 opacity-40 group-hover:opacity-100 transition-opacity">
                                                    <button 
                                                        onClick={() => handleView(file.filePath)}
                                                        className="p-3.5 bg-white/5 text-white/30 hover:text-primary hover:border-primary/50 border border-white/5 rounded-2xl transition-all" 
                                                        title="ACCESS SOURCE"
                                                    >
                                                        <Eye size={18} />
                                                    </button>
                                                    <button 
                                                        onClick={() => handleDownload(file.filePath, file.name)}
                                                        className="p-3.5 bg-white/5 text-white/30 hover:text-secondary hover:border-secondary/50 border border-white/5 rounded-2xl transition-all" 
                                                        title="EXTRACT"
                                                    >
                                                        <Download size={18} />
                                                    </button>
                                                    <button 
                                                        onClick={() => handleDelete(file.id, file.filePath)}
                                                        className="p-3.5 bg-white/5 text-white/30 hover:text-danger hover:border-danger/50 border border-white/5 rounded-2xl transition-all" 
                                                        title="WIPE"
                                                    >
                                                        <Trash2 size={18} />
                                                    </button>
                                                </div>
                                            </td>
                                        </tr>
                                    ))}
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>

                {/* Operations Sidebar */}
                <div className="space-y-10">
                    <div className="bg-card/40 backdrop-blur-2xl rounded-[3rem] border border-white/5 shadow-2xl overflow-hidden relative group">
                        <div className="absolute inset-0 bg-primary/2 rounded-[3.5rem] opacity-0 group-hover:opacity-100 transition-opacity duration-700" />
                        <div className="p-10 space-y-12 relative z-10">
                             <div>
                                <h3 className="text-xl font-black text-white tracking-widest font-orbitron uppercase mb-2">Central Ops</h3>
                                <p className="text-white/20 font-black text-[9px] uppercase tracking-[0.4em] font-orbitron">Rapid Response Unit</p>
                             </div>
                             
                             <div className="space-y-5">
                                 <a 
                                    href="/admin/upload"
                                    className="group/btn relative w-full h-[70px] flex items-center justify-center overflow-hidden rounded-[1.5rem] transition-all duration-500 shadow-[0_20px_40px_rgba(0,0,0,0.3)]"
                                 >
                                     <div className="absolute inset-0 bg-primary group-hover/btn:bg-primary/90 transition-colors" />
                                     <div className="absolute inset-0 opacity-0 group-hover/btn:opacity-20 bg-[linear-gradient(45deg,transparent,rgba(255,255,255,0.4),transparent)] -translate-x-full group-hover/btn:translate-x-full transition-all duration-1000" />
                                     <div className="relative z-10 flex items-center justify-between w-full px-8">
                                         <span className="text-card text-[11px] font-black font-orbitron uppercase tracking-[0.3em]">Resource Injection</span>
                                         <PlusCircle size={22} className="text-card group-hover/btn:rotate-90 transition-transform duration-500" />
                                     </div>
                                 </a>
                                 
                                 {isAdmin && (
                                     <a 
                                        href="/admin/reps"
                                        className="w-full h-[70px] bg-white/5 border-2 border-white/5 hover:border-primary/20 text-white/50 hover:text-white font-black rounded-[1.5rem] flex items-center justify-between px-8 transition-all duration-500 group/rep"
                                      >
                                         <span className="text-[11px] font-orbitron uppercase tracking-[0.2em]">Deploy Agent</span>
                                         <UserPlus size={20} className="group-hover/rep:translate-x-1 transition-transform" />
                                     </a>
                                 )}
                             </div>

                             <div className="pt-10 space-y-6 border-t border-white/5">
                                 <button 
                                    onClick={() => alert('SYNTHESIZING NEURAL ANALYTICS REPORT...')}
                                    className="w-full text-left flex items-center gap-6 text-white/30 hover:text-primary transition-all duration-300 group/nav"
                                  >
                                      <div className="p-3 bg-white/5 rounded-xl border border-white/5 group-hover/nav:border-primary/30 transition-all"><FileCheck size={18} /></div>
                                      <span className="text-[10px] font-black uppercase tracking-[0.2em] font-orbitron">Compile Core Intelligence</span>
                                  </button>
                                  <button 
                                    onClick={() => alert('SCANNING VERIFICATION QUEUE...')}
                                    className="w-full text-left flex items-center gap-6 text-white/30 hover:text-accent transition-all duration-300 group/nav"
                                  >
                                      <div className="p-3 bg-white/5 rounded-xl border border-white/5 group-hover/nav:border-accent/30 transition-all text-white/30 group-hover/nav:text-accent"><Clock size={18} /></div>
                                      <span className="text-[10px] font-black uppercase tracking-[0.2em] font-orbitron">Pending Neural Audits</span>
                                  </button>
                             </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    )
}
