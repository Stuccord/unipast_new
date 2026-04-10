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
    MoreHorizontal,
    FileText,
    Download,
    Eye,
    ChevronRight,
    PlusCircle,
    UserPlus,
    FileCheck,
    Clock
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

    useEffect(() => {
        const fetchDashboardData = async () => {
            setLoading(true)
            try {
                // 1. Fetch Total Users
                const { count: userCount } = await supabase
                    .from('profiles')
                    .select('*', { count: 'exact', head: true })
                
                // 2. Fetch Total Revenue from Transactions
                const { data: transData } = await supabase
                    .from('transactions')
                    .select('amount')
                const totalRev = transData?.reduce((acc, curr) => acc + (curr.amount || 0), 0) || 0

                // 3. Fetch Recent Uploads Count
                const { count: uploadCount } = await supabase
                    .from('past_questions')
                    .select('*', { count: 'exact', head: true })

                // 4. Fetch Recent Uploads for Table
                const { data: uploads } = await supabase
                    .from('past_questions')
                    .select('*, courses(name, faculties(name)), profiles(full_name)')
                    .order('created_at', { ascending: false })
                    .limit(7)

                setStats({
                    users: userCount || 0,
                    revenue: totalRev,
                    uploads: uploadCount || 0,
                    subscriptions: Math.floor((userCount || 0) * 0.15) // Mocking sub rate as 15% of users for now
                })

                if (uploads) {
                    setRecentUploads(uploads.map(u => ({
                        name: u.title || `Paper ${u.year}`,
                        type: 'pdf',
                        uploader: u.profiles?.full_name || 'System',
                        dept: u.courses?.faculties?.name || 'Academic',
                        date: new Date(u.created_at).toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' }),
                        status: 'Published'
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

    const statCards = [
        { 
            name: 'Total Users', 
            value: stats.users.toLocaleString(), 
            change: '+6.2%', 
            isUp: true,
            icon: Users, 
            color: 'text-[#0D9488]', 
            bg: 'bg-[#0D9488]/10',
            sparkline: (
                <svg className="w-full h-12" viewBox="0 0 100 40" preserveAspectRatio="none">
                    <path d="M0,35 Q20,30 40,32 T80,10 T100,5" fill="none" stroke="#0D9488" strokeWidth="2" />
                </svg>
            )
        },
        { 
            name: 'Total Revenue', 
            value: `GH₵ ${stats.revenue.toLocaleString()}`, 
            change: '+14.8%', 
            isUp: true,
            icon: DollarSign, 
            color: 'text-orange-500', 
            bg: 'bg-orange-50',
            sparkline: (
                <svg className="w-full h-12" viewBox="0 0 100 40" preserveAspectRatio="none">
                    <path d="M0,38 Q25,35 50,30 T75,15 T100,2" fill="none" stroke="#F59E0B" strokeWidth="2" />
                </svg>
            )
        },
        { 
            name: 'Recent Uploads', 
            value: stats.uploads.toLocaleString(), 
            change: '+21.1%', 
            isUp: true,
            icon: UploadCloud, 
            color: 'text-teal-500', 
            bg: 'bg-teal-50',
            sparkline: (
                <svg className="w-full h-12" viewBox="0 0 100 40" preserveAspectRatio="none">
                    <path d="M0,30 Q20,32 40,25 T80,15 T100,8" fill="none" stroke="#14B8A6" strokeWidth="2" />
                </svg>
            )
        },
        { 
            name: 'Active Subscriptions', 
            value: stats.subscriptions.toLocaleString(), 
            change: '+8.5%', 
            isUp: true,
            icon: Star, 
            color: 'text-yellow-500', 
            bg: 'bg-yellow-50',
            sparkline: (
                <svg className="w-full h-12" viewBox="0 0 100 40" preserveAspectRatio="none">
                    <path d="M0,35 Q30,32 50,33 T80,25 T100,20" fill="none" stroke="#EAB308" strokeWidth="2" />
                </svg>
            )
        },
    ]

    return (
        <div className="space-y-10">
            {/* Header section */}
            <div className="flex flex-col space-y-2">
                <h2 className="text-3xl font-bold text-slate-800 tracking-tight">Welcome Back, Admin! (UniPast Overview)</h2>
                <div className="flex items-center space-x-2 text-slate-400 font-bold text-xs uppercase tracking-widest">
                    <Clock size={14} className="text-[#0D9488]" />
                    <span>Real-time platform activity monitored</span>
                </div>
            </div>

            {/* Stats Grid */}
            <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-4 gap-6">
                {statCards.map((stat) => (
                    <div key={stat.name} className="bg-white p-6 rounded-2xl shadow-sm border border-slate-100 flex flex-col justify-between group hover:shadow-xl hover:shadow-slate-200/50 transition-all duration-300">
                        <div className="flex items-start justify-between mb-4">
                            <div className={`p-3.5 rounded-xl ${stat.bg} ${stat.color} group-hover:scale-110 transition-transform`}>
                                <stat.icon size={24} />
                            </div>
                            <div className="text-right">
                                <p className="text-sm font-semibold text-slate-400 mb-1">{stat.name}</p>
                                <h3 className="text-3xl font-black text-slate-800 tracking-tight">{stat.value}</h3>
                            </div>
                        </div>
                        <div className="flex items-end justify-between mt-2">
                            <div className="flex flex-col">
                                <span className={`text-sm font-bold flex items-center ${stat.isUp ? 'text-emerald-500' : 'text-rose-500'}`}>
                                    {stat.change} <span className="text-slate-400 font-normal ml-1 text-xs whitespace-nowrap">vs last month</span>
                                </span>
                            </div>
                            <div className="w-1/2">
                                {stat.sparkline}
                            </div>
                        </div>
                    </div>
                ))}
            </div>

            <div className="grid grid-cols-1 xl:grid-cols-4 gap-10">
                {/* Recent Uploads Table */}
                <div className="xl:col-span-3 bg-white rounded-[2.5rem] shadow-sm border border-slate-100 overflow-hidden">
                    <div className="p-8 border-b border-slate-100 flex items-center justify-between">
                        <h3 className="text-2xl font-black text-slate-800 tracking-tight">Recent Activity</h3>
                        <a href="/admin/upload" className="text-[#0D9488] font-black text-sm uppercase tracking-widest hover:underline">View All</a>
                    </div>
                    <div className="overflow-x-auto">
                        <table className="w-full text-left">
                            <thead className="bg-slate-50/50">
                                <tr className="text-slate-400 font-black text-xs uppercase tracking-[0.2em]">
                                    <th className="px-8 py-5">Source Material</th>
                                    <th className="px-8 py-5">Contributor</th>
                                    <th className="px-8 py-5">Academic Dept</th>
                                    <th className="px-8 py-5">Timestamp</th>
                                    <th className="px-8 py-5">Verification</th>
                                    <th className="px-8 py-5 text-right">Actions</th>
                                </tr>
                            </thead>
                            <tbody className="divide-y divide-slate-100">
                                {loading ? (
                                    <tr><td colSpan={6} className="px-8 py-24 text-center"><div className="animate-spin rounded-full h-12 w-12 border-b-2 border-[#0D9488] mx-auto"></div></td></tr>
                                ) : recentUploads.length === 0 ? (
                                    <tr><td colSpan={6} className="px-8 py-24 text-center text-slate-400 font-bold uppercase tracking-widest text-xs">No recent uploads found</td></tr>
                                ) : recentUploads.map((file, i) => (
                                    <tr key={i} className="hover:bg-slate-50/50 transition duration-150 group">
                                        <td className="px-8 py-6">
                                            <div className="flex items-center space-x-3">
                                                <div className={`h-11 w-11 rounded-2xl flex items-center justify-center text-white shadow-sm ${file.type === 'pdf' ? 'bg-rose-50 text-rose-500 border border-rose-100' : 'bg-blue-50 text-blue-500 border border-blue-100'}`}>
                                                    <FileText size={20} />
                                                </div>
                                                <span className="font-black text-slate-800 tracking-tight">{file.name}</span>
                                            </div>
                                        </td>
                                        <td className="px-8 py-6">
                                            <div className="flex items-center space-x-3">
                                                <div className="h-9 w-9 rounded-full bg-slate-100 border-2 border-white flex items-center justify-center text-[#0D9488] text-[10px] font-black">
                                                     {file.uploader[0]}
                                                </div>
                                                <span className="text-sm font-bold text-slate-600 tracking-tight">{file.uploader}</span>
                                            </div>
                                        </td>
                                        <td className="px-8 py-6 font-bold text-slate-500 text-sm whitespace-nowrap">{file.dept}</td>
                                        <td className="px-8 py-6 font-bold text-slate-400 text-xs tracking-widest uppercase">{file.date}</td>
                                        <td className="px-8 py-6">
                                            <span className={`px-4 py-2 rounded-xl text-[10px] font-black uppercase tracking-widest ring-1 ring-inset ${
                                                file.status === 'Published' ? 'bg-emerald-50 text-emerald-600 ring-emerald-600/20' : 
                                                file.status === 'Pending' ? 'bg-amber-50 text-amber-600 ring-amber-600/20' : 
                                                'bg-slate-50 text-slate-400 ring-slate-400/20'
                                            }`}>
                                                {file.status}
                                            </span>
                                        </td>
                                        <td className="px-8 py-6 text-right">
                                            <div className="flex items-center justify-end space-x-4">
                                                <button className="p-3 bg-slate-50 text-slate-400 hover:text-[#0D9488] hover:bg-[#0D9488]/10 rounded-xl transition-all" title="View"><Eye size={18} /></button>
                                                <button className="p-3 bg-slate-50 text-slate-400 hover:text-blue-500 hover:bg-blue-50 rounded-xl transition-all" title="Download"><Download size={18} /></button>
                                            </div>
                                        </td>
                                    </tr>
                                ))}
                            </tbody>
                        </table>
                    </div>
                </div>

                {/* Quick Actions Sidebar Area */}
                <div className="space-y-8">
                    <div className="bg-white rounded-[2.5rem] shadow-sm border border-slate-100 overflow-hidden">
                         <div className="p-10 space-y-10">
                             <div>
                                <h3 className="text-xl font-black text-slate-800 tracking-tight mb-2">Management</h3>
                                <p className="text-slate-400 font-bold text-xs uppercase tracking-widest">Rapid platform shortcuts</p>
                             </div>
                             
                             <div className="space-y-4">
                                 <a 
                                    href="/admin/upload"
                                    className="w-full bg-[#0D9488] hover:bg-teal-700 text-white font-black py-5 px-6 rounded-2xl flex items-center justify-between transition-all shadow-xl shadow-teal-700/20 group"
                                 >
                                     <span>New Resource</span>
                                     <PlusCircle size={20} className="group-hover:rotate-90 transition-transform" />
                                 </a>
                                 <a 
                                    href="/admin/reps"
                                    className="w-full bg-white border-2 border-slate-100 hover:border-[#0D9488]/30 text-slate-600 hover:text-[#0D9488] font-black py-5 px-6 rounded-2xl flex items-center justify-between transition-all group"
                                  >
                                     <span>Enroll Campus Rep</span>
                                     <UserPlus size={20} className="group-hover:translate-x-1 transition-transform" />
                                 </a>
                             </div>

                             <div className="pt-6 space-y-4 border-t border-slate-100">
                                 <button className="w-full text-left flex items-center space-x-4 text-slate-400 hover:text-slate-800 font-black text-xs uppercase tracking-[0.2em] transition-colors group">
                                     <div className="p-2 bg-slate-50 rounded-lg group-hover:bg-[#0D9488]/10 group-hover:text-[#0D9488] transition-colors"><FileCheck size={16} /></div>
                                     <span>Generate Reports</span>
                                 </button>
                                 <button className="w-full text-left flex items-center space-x-4 text-slate-400 hover:text-slate-800 font-black text-xs uppercase tracking-[0.2em] transition-colors group">
                                     <div className="p-2 bg-slate-50 rounded-lg group-hover:bg-amber-100 group-hover:text-amber-600 transition-colors"><Clock size={16} /></div>
                                     <span>Pending Reviews</span>
                                 </button>
                             </div>
                         </div>
                    </div>
                </div>
            </div>
        </div>
    )
}
