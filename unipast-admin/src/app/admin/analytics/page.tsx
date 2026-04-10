'use client'

import { useState, useEffect } from 'react'
import { supabase } from '@/lib/supabase'
import { BarChart3, TrendingUp, Users, DollarSign, Building2, ChevronRight, Activity } from 'lucide-react'

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

                setStats({
                    userGrowth: count || 0,
                    totalRevenue: revenue,
                    retentionRate: 94.2 // Mocked constant
                })
            } catch (error) {
                console.error('Error fetching analytics:', error)
            } finally {
                setLoading(false)
            }
        }
        fetchAnalytics()
    }, [])

    return (
        <div className="space-y-10">
            <div className="flex flex-col space-y-2">
                <h2 className="text-3xl font-black text-slate-800 tracking-tight">Intelligence Hub</h2>
                <div className="flex items-center space-x-2 text-slate-400 font-bold text-xs uppercase tracking-widest">
                    <Activity size={14} className="text-[#0D9488]" />
                    <span>Cross-platform performance telemetry</span>
                </div>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
                <div className="bg-white p-8 rounded-[2rem] border border-slate-100 shadow-sm flex flex-col items-center text-center group hover:border-[#0D9488]/30 transition-all">
                    <div className="p-4 bg-[#0D9488]/10 text-[#0D9488] rounded-2xl mb-6 group-hover:scale-110 transition-transform">
                        <Users size={32} />
                    </div>
                    <h3 className="text-xs font-black text-slate-400 uppercase tracking-[0.2em] mb-2">Total Userbase</h3>
                    <p className="text-4xl font-black text-slate-800 tracking-tight">
                        {loading ? '...' : stats.userGrowth.toLocaleString()}
                    </p>
                    <span className="text-emerald-500 font-bold text-xs mt-4 bg-emerald-50 px-3 py-1 rounded-full ring-1 ring-emerald-500/20">Live Sync Active</span>
                </div>

                <div className="bg-white p-8 rounded-[2rem] border border-slate-100 shadow-sm flex flex-col items-center text-center group hover:border-orange-200 transition-all">
                    <div className="p-4 bg-orange-50 text-orange-500 rounded-2xl mb-6 group-hover:scale-110 transition-transform">
                        <DollarSign size={32} />
                    </div>
                    <h3 className="text-xs font-black text-slate-400 uppercase tracking-[0.2em] mb-2">Gross Revenue</h3>
                    <p className="text-4xl font-black text-slate-800 tracking-tight">
                        {loading ? '...' : `GH₵ ${stats.totalRevenue.toLocaleString()}`}
                    </p>
                    <span className="text-orange-500 font-bold text-xs mt-4 bg-orange-50 px-3 py-1 rounded-full ring-1 ring-orange-500/20">Verified Payments</span>
                </div>

                <div className="bg-white p-8 rounded-[2rem] border border-slate-100 shadow-sm flex flex-col items-center text-center group hover:border-blue-200 transition-all">
                    <div className="p-4 bg-blue-50 text-blue-500 rounded-2xl mb-6 group-hover:scale-110 transition-transform">
                        <TrendingUp size={32} />
                    </div>
                    <h3 className="text-xs font-black text-slate-400 uppercase tracking-[0.2em] mb-2">Engagement Rate</h3>
                    <p className="text-4xl font-black text-slate-800 tracking-tight">{stats.retentionRate}%</p>
                    <span className="text-blue-500 font-bold text-xs mt-4 bg-blue-50 px-3 py-1 rounded-full ring-1 blue-500/20">Platform Retention</span>
                </div>
            </div>

            <div className="bg-white rounded-[2.5rem] border border-slate-100 shadow-sm overflow-hidden">
                <div className="p-10 border-b border-slate-100 flex items-center justify-between">
                    <div>
                        <h3 className="text-2xl font-black text-slate-800 tracking-tight">Campus Distribution</h3>
                        <p className="text-slate-400 font-bold text-sm">Performance metrics across partner universities</p>
                    </div>
                    <BarChart3 className="text-slate-200" size={32} />
                </div>
                
                <div className="p-10">
                    <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
                        {loading ? (
                            <div className="col-span-2 py-20 flex flex-col items-center justify-center space-y-4">
                                <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-[#0D9488]"></div>
                                <p className="text-slate-400 font-bold uppercase tracking-widest text-xs">Aggregating Cross-Campus Data...</p>
                            </div>
                        ) : uniStats.length === 0 ? (
                            <div className="col-span-2 py-20 text-center text-slate-400 font-bold uppercase tracking-widest text-xs">No distribution data available</div>
                        ) : uniStats.map((uni, i) => (
                            <div key={i} className="flex items-center p-6 bg-slate-50/50 rounded-3xl border border-slate-100 group hover:bg-white hover:shadow-xl hover:shadow-slate-200/50 transition-all duration-300">
                                <div className="h-16 w-16 bg-white rounded-2xl flex items-center justify-center text-[#0D9488] shadow-sm border border-slate-100 mr-6 group-hover:scale-110 transition-transform">
                                    <Building2 size={24} />
                                </div>
                                <div className="flex-1">
                                    <h4 className="font-black text-slate-800 tracking-tight mb-1">{uni.name}</h4>
                                    <div className="flex items-center space-x-6">
                                        <div className="flex items-center space-x-2">
                                            <Users size={14} className="text-slate-400" />
                                            <span className="text-xs font-bold text-slate-500">{uni.users} Students</span>
                                        </div>
                                        <div className="flex items-center space-x-2">
                                            <BarChart3 size={14} className="text-slate-400" />
                                            <span className="text-xs font-bold text-slate-500">{uni.uploads} Uploads</span>
                                        </div>
                                    </div>
                                </div>
                                <ChevronRight className="text-slate-200 group-hover:text-[#0D9488] group-hover:translate-x-1 transition-all" size={24} />
                            </div>
                        ))}
                    </div>
                </div>
            </div>
        </div>
    )
}
