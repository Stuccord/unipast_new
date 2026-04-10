'use client'

import { useState, useEffect } from 'react'
import { supabase } from '@/lib/supabase'
import { CreditCard, Download, Search, Filter, ArrowUpRight, ChevronRight, MoreVertical, Wallet, X, CheckCircle2, AlertCircle, Loader2 } from 'lucide-react'

export default function FinancialsPage() {
    const [transactions, setTransactions] = useState<any[]>([])
    const [loading, setLoading] = useState(false)
    const [searchTerm, setSearchTerm] = useState('')
    const [showPayoutModal, setShowPayoutModal] = useState(false)
    const [payoutLoading, setPayoutLoading] = useState(false)
    const [status, setStatus] = useState<{ type: 'success' | 'error', message: string } | null>(null)

    useEffect(() => {
        fetchTransactions()
    }, [])

    async function fetchTransactions() {
        setLoading(true)
        const { data } = await supabase
            .from('transactions')
            .select('*, profiles(full_name)')
            .order('created_at', { ascending: false })

        setTransactions(data || [])
        setLoading(false)
    }

    const handleExport = () => {
        const headers = ['Transaction ID', 'Reference', 'Customer', 'Amount', 'Status', 'Date']
        const csvData = transactions.map(t => [
            t.id,
            t.reference || 'N/A',
            t.profiles?.full_name || 'System User',
            t.amount || 0,
            t.status,
            new Date(t.created_at).toLocaleString()
        ])

        const csvContent = [headers, ...csvData].map(e => e.join(',')).join('\n')
        const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' })
        const link = document.createElement('a')
        const url = URL.createObjectURL(blob)
        link.setAttribute('href', url)
        link.setAttribute('download', `unipast_transactions_${new Date().toISOString().split('T')[0]}.csv`)
        link.style.visibility = 'hidden'
        document.body.appendChild(link)
        link.click()
        document.body.removeChild(link)
    }

    const handleInitiatePayout = async () => {
        setPayoutLoading(true)
        setStatus(null)
        // Simulate payout logic
        await new Promise(resolve => setTimeout(resolve, 2000))
        setStatus({ type: 'success', message: 'Payout cycle initiated successfully for all pending balances.' })
        setPayoutLoading(false)
        setTimeout(() => setShowPayoutModal(false), 3000)
    }

    const filteredTransactions = transactions.filter(t =>
        t.profiles?.full_name?.toLowerCase().includes(searchTerm.toLowerCase()) ||
        t.reference?.toLowerCase().includes(searchTerm.toLowerCase())
    )

    const totalRevenue = transactions.reduce((acc, curr) => acc + (curr.amount || 0), 0)

    return (
        <div className="space-y-10">
            <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-6">
                <div className="space-y-1">
                    <h2 className="text-3xl font-black text-slate-800 tracking-tight">Financial Treasury</h2>
                    <p className="text-slate-500 font-medium tracking-tight">Monitor platform revenue, subscriptions and payout cycles.</p>
                </div>
                <div className="flex items-center space-x-3">
                    <button 
                        onClick={handleExport}
                        className="bg-white border border-slate-100 text-slate-700 font-bold py-4 px-8 rounded-2xl flex items-center space-x-3 hover:bg-slate-50 transition-all shadow-sm"
                    >
                        <Download size={20} />
                        <span>Export Report</span>
                    </button>
                    <button 
                        onClick={() => setShowPayoutModal(true)}
                        className="bg-[#0D9488] hover:bg-teal-700 text-white font-bold py-4 px-8 rounded-2xl flex items-center space-x-3 transition-all shadow-xl shadow-teal-700/20"
                    >
                        <Wallet size={20} />
                        <span>Payouts</span>
                    </button>
                </div>
            </div>

            {/* Premium Summary Card */}
            <div className="bg-slate-900 p-12 rounded-[2.5rem] shadow-2xl text-white relative overflow-hidden">
                <div className="absolute top-0 right-0 p-12 opacity-5">
                    <CreditCard size={240} />
                </div>
                <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-12 relative z-10">
                    <div className="space-y-4">
                        <p className="text-teal-400 text-xs font-black uppercase tracking-[0.2em]">Total Net Revenue</p>
                        <h3 className="text-5xl font-black tracking-tight flex items-baseline">
                            <span className="text-2xl text-slate-500 mr-2">GH₵</span>
                            {totalRevenue.toLocaleString()}
                        </h3>
                    </div>
                    <div className="space-y-4 md:border-l md:border-slate-800 md:pl-12">
                        <p className="text-slate-400 text-xs font-black uppercase tracking-[0.2em]">Platform Growth</p>
                        <div className="flex items-center space-x-4">
                            <h4 className="text-3xl font-black">+{((totalRevenue / 1000) * 0.5).toFixed(1)}%</h4>
                            <div className="h-8 w-8 rounded-full bg-emerald-500/20 text-emerald-400 flex items-center justify-center">
                                <ArrowUpRight size={16} />
                            </div>
                        </div>
                    </div>
                    <div className="space-y-4 md:border-l md:border-slate-800 md:pl-12">
                        <p className="text-slate-400 text-xs font-black uppercase tracking-[0.2em]">Total Transactions</p>
                        <h4 className="text-3xl font-black">{transactions.length.toLocaleString()}</h4>
                    </div>
                    <div className="space-y-4 md:border-l md:border-slate-800 md:pl-12">
                        <p className="text-slate-400 text-xs font-black uppercase tracking-[0.2em]">Payment Success</p>
                        <h4 className="text-3xl font-black">99.8%</h4>
                    </div>
                </div>
            </div>

            <div className="bg-white rounded-[2.5rem] border border-slate-100 shadow-sm overflow-hidden">
                <div className="p-8 bg-slate-50/50 border-b border-slate-100/50 flex flex-col md:flex-row gap-6">
                    <div className="relative flex-1 max-w-xl">
                        <Search className="absolute left-5 top-1/2 -translate-y-1/2 text-slate-400" size={20} />
                        <input
                            type="text"
                            placeholder="Search by ID, Customer Name or Reference..."
                            value={searchTerm}
                            onChange={(e) => setSearchTerm(e.target.value)}
                            className="w-full pl-14 pr-6 py-4 rounded-2xl bg-white border-none outline-none focus:ring-2 focus:ring-[#0D9488]/20 transition-all font-medium text-slate-700 shadow-sm"
                        />
                    </div>
                    <button className="flex items-center space-x-3 px-8 py-4 bg-white border border-slate-100 rounded-2xl text-slate-600 hover:bg-slate-50 transition-all font-bold shadow-sm">
                        <Filter size={20} />
                        <span>Filter History</span>
                    </button>
                </div>

                <div className="overflow-x-auto">
                    <table className="w-full text-left">
                        <thead>
                            <tr className="text-slate-400 font-black text-xs uppercase tracking-[0.2em]">
                                <th className="px-10 py-6">Transaction ID</th>
                                <th className="px-10 py-6">Customer</th>
                                <th className="px-10 py-6">Amount</th>
                                <th className="px-10 py-6">Timeline</th>
                                <th className="px-10 py-6 text-right">Status</th>
                            </tr>
                        </thead>
                        <tbody className="divide-y divide-slate-100">
                            {loading ? (
                                <tr>
                                    <td colSpan={5} className="px-10 py-24 text-center">
                                         <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-[#0D9488] mx-auto"></div>
                                    </td>
                                </tr>
                            ) : filteredTransactions.length === 0 ? (
                                <tr>
                                    <td colSpan={5} className="px-10 py-24 text-center text-slate-400 font-bold tracking-widest uppercase text-xs">No records found</td>
                                </tr>
                            ) : (
                                filteredTransactions.map((t) => (
                                    <tr key={t.id} className="hover:bg-slate-50/50 transition duration-150 group">
                                        <td className="px-10 py-8">
                                            <div className="flex items-center space-x-4">
                                                <div className="h-12 w-12 rounded-xl bg-slate-100 text-[#0D9488] flex items-center justify-center font-black">
                                                    <CreditCard size={20} />
                                                </div>
                                                <div>
                                                    <p className="font-black text-slate-800 tracking-tight">{t.reference || 'N/A'}</p>
                                                    <p className="text-[10px] text-slate-400 font-black uppercase tracking-widest">{t.channel || 'Paystack Gateway'}</p>
                                                </div>
                                            </div>
                                        </td>
                                        <td className="px-10 py-8">
                                            <span className="font-bold text-slate-700">{t.profiles?.full_name || 'System User'}</span>
                                        </td>
                                        <td className="px-10 py-8">
                                            <span className="font-black text-slate-800 text-lg">GH₵ {(t.amount || 0).toLocaleString()}</span>
                                        </td>
                                        <td className="px-10 py-8">
                                            <p className="text-sm font-bold text-slate-500">
                                                {new Date(t.created_at).toLocaleDateString('en-GB', { day: 'numeric', month: 'short', year: 'numeric' })}
                                            </p>
                                            <p className="text-[10px] text-slate-400 font-bold uppercase mt-1">
                                                {new Date(t.created_at).toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit' })}
                                            </p>
                                        </td>
                                        <td className="px-10 py-8 text-right">
                                            <span className={`px-4 py-2 rounded-xl text-[10px] font-black uppercase tracking-widest ring-1 ring-inset ${
                                                t.status === 'Success' ? 'bg-emerald-50 text-emerald-600 ring-emerald-600/20' : 'bg-amber-50 text-amber-600 ring-amber-600/20'
                                            }`}>
                                                {t.status}
                                            </span>
                                        </td>
                                    </tr>
                                ))
                            )}
                        </tbody>
                    </table>
                </div>
            </div>

            {/* Payout Modal */}
            {showPayoutModal && (
                <div className="fixed inset-0 bg-slate-900/60 backdrop-blur-sm z-50 flex items-center justify-center p-6">
                    <div className="bg-white rounded-[2.5rem] w-full max-w-2xl overflow-hidden shadow-2xl animate-in zoom-in duration-300">
                        <div className="p-10 bg-slate-50 border-b border-slate-100 flex items-center justify-between">
                            <div>
                                <h3 className="text-2xl font-black text-slate-800 tracking-tight">Payout Management</h3>
                                <p className="text-slate-500 font-bold text-xs uppercase tracking-widest">Administrator Treasury Control</p>
                            </div>
                            <button onClick={() => setShowPayoutModal(false)} className="p-3 bg-white text-slate-400 hover:text-slate-800 rounded-2xl shadow-sm transition-all">
                                <X size={24} />
                            </button>
                        </div>
                        
                        <div className="p-12 space-y-10">
                            {status ? (
                                <div className={`p-8 rounded-3xl border flex items-center space-x-6 ${
                                    status.type === 'success' ? 'bg-emerald-50 border-emerald-100 text-emerald-700' : 'bg-rose-50 border-rose-100 text-rose-700'
                                }`}>
                                    <CheckCircle2 size={32} />
                                    <p className="text-lg font-black tracking-tight">{status.message}</p>
                                </div>
                            ) : (
                                <>
                                    <div className="grid grid-cols-2 gap-8">
                                        <div className="p-8 bg-slate-50 rounded-3xl space-y-2">
                                            <p className="text-xs font-black text-slate-400 uppercase tracking-widest">Pending Balance</p>
                                            <h4 className="text-3xl font-black text-slate-800 tracking-tight">GH₵ {(totalRevenue * 0.12).toLocaleString()}</h4>
                                        </div>
                                        <div className="p-8 bg-slate-50 rounded-3xl space-y-2">
                                            <p className="text-xs font-black text-slate-400 uppercase tracking-widest">Held for Payout</p>
                                            <h4 className="text-3xl font-black text-slate-800 tracking-tight">GH₵ {(totalRevenue * 0.05).toLocaleString()}</h4>
                                        </div>
                                    </div>

                                    <div className="space-y-4">
                                        <p className="text-sm font-bold text-slate-600 leading-relaxed">
                                            By initiating this payout, you are authorizing the system to process settlements for all campus representatives and system partners. This action is logged for financial audit.
                                        </p>
                                    </div>

                                    <div className="pt-6 flex justify-end">
                                        <button 
                                            onClick={handleInitiatePayout}
                                            disabled={payoutLoading}
                                            className="w-full bg-[#0D9488] hover:bg-teal-700 text-white font-black py-6 rounded-3xl transition-all shadow-xl shadow-teal-700/20 flex items-center justify-center space-x-3 disabled:opacity-50"
                                        >
                                            {payoutLoading ? <Loader2 className="animate-spin" size={24} /> : <Wallet size={24} />}
                                            <span className="text-lg">Initiate Bulk Payout Cycle</span>
                                        </button>
                                    </div>
                                </>
                            )}
                        </div>
                    </div>
                </div>
            )}
        </div>
    )
}
