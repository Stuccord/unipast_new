'use client'



import { useState, useEffect } from 'react'
import Link from 'next/link'
import { supabase } from '@/lib/supabase'
import { 
    BarChart3, TrendingUp, Users, DollarSign, Building2, 
    ChevronRight, Activity, Zap, Globe, Cpu, Shield, ArrowUpRight
} from 'lucide-react'

export default function AnalyticsPage() {
    const [stats, setStats] = useState({
        userGrowth: 0,
        totalRevenue: 0,
        retentionRate: 94.2
    })
    const [uniStats, setUniStats] = useState<any[]>([])
    const [loading, setLoading] = useState(true)

    useEffect(() => {
        const fetchAnalytics = async () => {
            setLoading(true)
            try {
                // 1. Fetch User Growth (Total Profiles)
                const { count } = await supabase.from('profiles').select('*', { count: 'exact', head: true })
                
                // 2. Fetch Total Revenue
                const { data: trans } = await supabase.from('transactions').select('amount')
                const revenue = trans?.reduce((acc, curr) => acc + (curr.amount || 0), 0) || 0

                // 3. Fetch Uni Stats (Profiles per Uni)
                const { data: unis } = await supabase.from('universities').select('id, name')
                if (unis) {
                    const uniCounts = await Promise.all(unis.map(async (u) => {
                        const { count: pCount } = await supabase
                            .from('profiles')
                            .select('*', { count: 'exact', head: true })
                            .eq('university_id', u.id)
                        
                        const { count: uCount } = await supabase
                            .from('past_questions')
                            .select('*, courses!inner(faculties!inner(university_id))', { count: 'exact', head: true })
                            .eq('courses.faculties.university_id', u.id)

                        return {
                            name: u.name,
                            users: pCount || 0,
                            uploads: uCount || 0
                        }
                    }))
                    setUniStats(uniCounts.sort((a,b) => b.users - a.users))
                }

                // 4. Fetch Active Pulse (Activity in last 30 days)
                const thirtyDaysAgo = new Date()
                thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30)
                const { data: activeData } = await supabase
                    .from('activities')
                    .select('user_id')
                    .gte('created_at', thirtyDaysAgo.toISOString())
                
                const activeUsers = new Set(activeData?.map(a => a.user_id)).size

                setStats({
                    userGrowth: count || 0,
                    totalRevenue: revenue,
                    retentionRate: activeUsers || 0
                })
            } catch (error) {
                console.error('Core Telemetry Failure:', error)
            } finally {
                setLoading(false)
            }
        }
        fetchAnalytics()
    }, [])

    return (
        <div className="space-y-12 font-orbitron pb-32">
            <div className="flex flex-col xl:flex-row xl:items-end justify-between gap-8 animate-in fade-in slide-in-from-top-10 duration-1000">
                <div className="space-y-4">
                    <div className="flex items-center gap-3">
                        <div className="p-2.5 bg-accent/10 rounded-xl border border-accent/20">
                            <Activity size={22} className="text-accent animate-pulse" />
                        </div>
                        <span className="text-[10px] font-black text-accent uppercase tracking-[0.4em]">Neural Telemetry v4.5</span>
                    </div>
                    <h2 className="text-4xl font-black text-white tracking-tight uppercase tracking-widest">Platform Core Analytics</h2>
                    <p className="text-white/30 font-black text-[10px] uppercase tracking-[0.3em]">Real-time synchronization with global UniPast data nodes</p>
                </div>
                
                <div className="flex gap-4">
                    <div className="px-5 py-3 bg-white/5 border border-white/5 rounded-2xl flex items-center gap-3">
                        <div className="w-2 h-2 rounded-full bg-primary animate-ping" />
                        <span className="text-[10px] font-black text-white/40 tracking-[0.2em] uppercase tracking-widest">Live Uplink Active</span>
                    </div>
                </div>
            </div>

            <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
                <div className="bg-card/20 backdrop-blur-3xl p-10 rounded-[3rem] border border-white/5 relative overflow-hidden group hover:border-primary/40 transition-all duration-700 animate-in fade-in zoom-in duration-1000 delay-100">
                    <div className="absolute top-0 right-0 p-8 text-primary/10 group-hover:text-primary/20 transition-colors">
                        <Users size={80} strokeWidth={1} />
                    </div>
                    <div className="relative z-10 space-y-6">
                        <div className="p-4 bg-primary/10 text-primary w-fit rounded-2xl border border-primary/20 group-hover:scale-110 transition-transform duration-500">
                            <Users size={32} />
                        </div>
                        <div className="space-y-1">
                            <h3 className="text-[10px] font-black text-white/30 uppercase tracking-[0.4em]">Global Userbase</h3>
                            <p className="text-5xl font-black text-white tabular-nums tracking-tighter">
                                {loading ? '---' : stats.userGrowth.toLocaleString()}
                            </p>
                        </div>
                        <div className="flex items-center gap-2 text-primary font-black text-[9px] uppercase tracking-widest">
                            <ArrowUpRight size={14} />
                            <span>Neural Growth Stable</span>
                        </div>
                    </div>
                </div>

                <div className="bg-card/20 backdrop-blur-3xl p-10 rounded-[3rem] border border-white/5 relative overflow-hidden group hover:border-secondary/40 transition-all duration-700 animate-in fade-in zoom-in duration-1000 delay-200">
                    <div className="absolute top-0 right-0 p-8 text-secondary/10 group-hover:text-secondary/20 transition-colors">
                        <DollarSign size={80} strokeWidth={1} />
                    </div>
                    <div className="relative z-10 space-y-6">
                        <div className="p-4 bg-secondary/10 text-secondary w-fit rounded-2xl border border-secondary/20 group-hover:scale-110 transition-transform duration-500">
                            <DollarSign size={32} />
                        </div>
                        <div className="space-y-1">
                            <h3 className="text-[10px] font-black text-white/30 uppercase tracking-[0.4em]">Platform Revenue</h3>
                            <p className="text-5xl font-black text-white tabular-nums tracking-tighter">
                                {loading ? '---' : `GH₵${stats.totalRevenue.toLocaleString()}`}
                            </p>
                        </div>
                        <div className="flex items-center gap-2 text-secondary font-black text-[9px] uppercase tracking-widest">
                            <Shield size={14} />
                            <span>Transactions Verified</span>
                        </div>
                    </div>
                </div>

                <div className="bg-card/20 backdrop-blur-3xl p-10 rounded-[3rem] border border-white/5 relative overflow-hidden group hover:border-accent/40 transition-all duration-700 animate-in fade-in zoom-in duration-1000 delay-300">
                    <div className="absolute top-0 right-0 p-8 text-accent/10 group-hover:text-accent/20 transition-colors">
                        <Activity size={80} strokeWidth={1} />
                    </div>
                    <div className="relative z-10 space-y-6">
                        <div className="p-4 bg-accent/10 text-accent w-fit rounded-2xl border border-accent/20 group-hover:scale-110 transition-transform duration-500">
                            <TrendingUp size={32} />
                        </div>
                        <div className="space-y-1">
                            <h3 className="text-[10px] font-black text-white/30 uppercase tracking-[0.4em]">Active Users (30d)</h3>
                            <p className="text-5xl font-black text-white tabular-nums tracking-tighter">{stats.retentionRate}</p>
                        </div>
                        <div className="flex items-center gap-2 text-accent font-black text-[9px] uppercase tracking-widest">
                            <Zap size={14} className="animate-pulse" />
                            <span>Pulse Frequency High</span>
                        </div>
                    </div>
                </div>
            </div>

            <div className="bg-card/20 backdrop-blur-3xl rounded-[3.5rem] border border-white/5 overflow-hidden shadow-2xl animate-in fade-in slide-in-from-bottom-10 duration-1000 delay-400">
                <div className="p-12 border-b border-white/5 flex flex-col md:flex-row md:items-center justify-between gap-8">
                    <div className="space-y-2">
                        <h3 className="text-3xl font-black text-white tracking-widest uppercase">Node Distribution</h3>
                        <p className="text-white/20 font-black text-[10px] uppercase tracking-[0.4em]">Resource allocation across academic hubs</p>
                    </div>
                    <div className="h-16 w-16 bg-white/5 border border-white/5 rounded-[1.5rem] flex items-center justify-center text-white/20">
                        <BarChart3 size={32} strokeWidth={1.5} />
                    </div>
                </div>
                
                <div className="p-12">
                    <div className="grid grid-cols-1 xl:grid-cols-2 gap-8">
                        {loading ? (
                            <div className="col-span-full py-40 flex flex-col items-center justify-center gap-8">
                                <div className="relative w-24 h-24">
                                    <div className="absolute inset-0 border-4 border-primary/20 rounded-full" />
                                    <div className="absolute inset-0 border-4 border-primary rounded-full border-t-transparent animate-spin shadow-[0_0_20px_#00FFCC]" />
                                </div>
                                <p className="text-white/20 font-black uppercase tracking-[0.6em] text-xs">Aggregating Grid Data...</p>
                            </div>
                        ) : uniStats.length === 0 ? (
                            <div className="col-span-full py-40 text-center text-white/10 font-black uppercase tracking-[0.8em] text-sm underline-offset-8 underline decoration-primary/20">NO HUB CONNECTIVITY</div>
                        ) : uniStats.map((uni, i) => (
                            <Link 
                                key={i} 
                                href={`/admin/academic?university=${encodeURIComponent(uni.name)}`}
                                className="group relative"
                            >
                                <div className="absolute inset-0 bg-gradient-to-r from-primary/10 to-transparent opacity-0 group-hover:opacity-100 transition-opacity rounded-[2.5rem] blur-xl" />
                                <div className="relative flex items-center p-8 bg-white/5 border border-white/5 rounded-[2.5rem] group-hover:bg-white/[0.08] group-hover:border-primary/30 transition-all duration-500 overflow-hidden">
                                    <div className="absolute top-0 right-0 -mr-16 -mt-16 w-48 h-48 bg-primary/5 rounded-full blur-3xl group-hover:bg-primary/10 transition-colors" />
                                    
                                    <div className="h-20 w-20 bg-white/5 border border-white/10 rounded-2xl flex items-center justify-center text-white/30 group-hover:text-primary group-hover:border-primary/40 group-hover:scale-110 transition-all duration-500 mr-8 relative z-10">
                                        <Building2 size={36} strokeWidth={1.5} />
                                    </div>
                                    <div className="flex-1 relative z-10">
                                        <h4 className="font-black text-white text-lg tracking-widest uppercase group-hover:text-primary transition-colors duration-500">{uni.name}</h4>
                                        <div className="flex items-center gap-8 mt-4">
                                            <div className="flex items-center gap-3">
                                                <div className="w-1.5 h-1.5 rounded-full bg-primary" />
                                                <span className="text-[10px] font-black text-white/30 uppercase tracking-widest">{uni.users} Users</span>
                                            </div>
                                            <div className="flex items-center gap-3">
                                                <div className="w-1.5 h-1.5 rounded-full bg-accent" />
                                                <span className="text-[10px] font-black text-white/30 uppercase tracking-widest">{uni.uploads} Data Units</span>
                                            </div>
                                        </div>
                                    </div>
                                    <div className="h-12 w-12 bg-white/5 rounded-full flex items-center justify-center text-white/10 group-hover:bg-primary group-hover:text-card transition-all duration-500 group-hover:rotate-45 relative z-10">
                                        <ChevronRight size={24} />
                                    </div>
                                </div>
                            </Link>
                        ))}
                    </div>
                </div>
            </div>
        </div>
    )
}
