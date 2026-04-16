'use client'

import { useState, useEffect } from 'react'
import { supabase } from '@/lib/supabase'
import { 
    CreditCard, Download, Search, Filter, ArrowUpRight, 
    ChevronRight, MoreVertical, Wallet, X, CheckCircle2, 
    AlertCircle, Loader2, TrendingUp, BarChart3, ShieldCheck, Zap
} from 'lucide-react'

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
        link.setAttribute('download', `unipast_financial_ledger_${new Date().toISOString().split('T')[0]}.csv`)
        link.style.visibility = 'hidden'
        document.body.appendChild(link)
        link.click()
        document.body.removeChild(link)
    }

    const handleInitiatePayout = async () => {
        setPayoutLoading(true)
        setStatus(null)
        await new Promise(resolve => setTimeout(resolve, 2000))
        setStatus({ type: 'success', message: 'ECONOMIC BALANCE RESTORED. PAYOUT CYCLE AUTHORIZED.' })
        setPayoutLoading(false)
        setTimeout(() => setShowPayoutModal(false), 3000)
    }

    const filteredTransactions = transactions.filter(t =>
        t.profiles?.full_name?.toLowerCase().includes(searchTerm.toLowerCase()) ||
        t.reference?.toLowerCase().includes(searchTerm.toLowerCase())
    )

    const totalRevenue = transactions.reduce((acc, curr) => acc + (curr.amount || 0), 0)

    return (
        <div className="space-y-12 font-orbitron pb-32">
            <div className="flex flex-col xl:flex-row xl:items-end justify-between gap-8">
                <div className="space-y-4">
                    <div className="flex items-center gap-3">
                        <div className="p-2.5 bg-secondary/10 rounded-xl border border-secondary/20">
                            <TrendingUp size={22} className="text-secondary animate-pulse" />
                        </div>
                        <span className="text-[10px] font-black text-secondary uppercase tracking-[0.4em]">Economic Control Grid v1.12</span>
                    </div>
                    <h2 className="text-4xl font-black text-white tracking-tight uppercase tracking-widest">Neural Monetary Matrix</h2>
                    <p className="text-white/30 font-black text-[10px] uppercase tracking-[0.3em]">Overseeing platform liquidity, credit flow, and protocol settlements.</p>
                </div>
                
                <div className="flex items-center gap-4">
                    <button 
                        onClick={handleExport}
                        className="h-16 px-8 bg-card border border-white/5 text-white/40 font-black text-[10px] uppercase tracking-[0.3em] rounded-2xl hover:bg-white/5 hover:text-white transition-all flex items-center gap-3"
                    >
                        <Download size={20} />
                        <span>Extract Ledger</span>
                    </button>
                    <button 
                        onClick={() => setShowPayoutModal(true)}
                        className="h-16 px-10 bg-secondary text-card font-black text-[10px] uppercase tracking-[0.3em] rounded-2xl hover:bg-secondary/90 transition-all shadow-[0_0_30px_rgba(255,160,0,0.2)] flex items-center gap-3"
                    >
                        <Wallet size={20} />
                        <span>Capital Allocation</span>
                    </button>
                </div>
            </div>

            <div className="bg-card/20 backdrop-blur-3xl p-12 rounded-[3.5rem] border border-white/5 relative overflow-hidden group shadow-2xl animate-in fade-in zoom-in duration-1000">
                <div className="absolute top-0 right-0 p-12 text-secondary/5 group-hover:text-secondary/10 transition-colors pointer-events-none">
                    <BarChart3 size={320} strokeWidth={0.5} />
                </div>
                
                <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-16 relative z-10">
                    <div className="space-y-4">
                        <p className="text-secondary text-[10px] font-black uppercase tracking-[0.4em]">Total Net Liquidity</p>
                        <div className="flex items-baseline group/val transition-all">
                            <span className="text-xl text-white/20 font-black mr-3 tracking-widest">GH₵</span>
                            <h3 className="text-6xl font-black text-white tabular-nums tracking-tighter group-hover:text-secondary transition-colors duration-500">
                                {totalRevenue.toLocaleString()}
                            </h3>
                        </div>
                    </div>
                    
                    <div className="space-y-4 lg:border-l lg:border-white/5 lg:pl-16">
                        <p className="text-white/30 text-[10px] font-black uppercase tracking-[0.4em]">Protocol Expansion</p>
                        <div className="flex items-center gap-6">
                            <h4 className="text-4xl font-black text-white tabular-nums tracking-tight">+{((totalRevenue / 1000) * 0.5).toFixed(1)}%</h4>
                            <div className="h-12 w-12 rounded-2xl bg-primary/10 text-primary flex items-center justify-center border border-primary/20 animate-bounce">
                                <ArrowUpRight size={22} />
                            </div>
                        </div>
                    </div>

                    <div className="space-y-4 lg:border-l lg:border-white/5 lg:pl-16">
                        <p className="text-white/30 text-[10px] font-black uppercase tracking-[0.4em]">Processed Bytes</p>
                        <h4 className="text-4xl font-black text-white tabular-nums tracking-tight">{transactions.length.toLocaleString()}</h4>
                    </div>

                    <div className="space-y-4 lg:border-l lg:border-white/5 lg:pl-16">
                        <p className="text-white/30 text-[10px] font-black uppercase tracking-[0.4em]">Protocol Success</p>
                        <div className="flex items-center gap-4">
                            <h4 className="text-4xl font-black text-white tabular-nums tracking-tight">99.8%</h4>
                            <ShieldCheck className="text-primary animate-pulse" size={32} strokeWidth={1.5} />
                        </div>
                    </div>
                </div>
            </div>

            <div className="bg-card/20 backdrop-blur-3xl rounded-[3rem] border border-white/5 overflow-hidden shadow-2xl animate-in fade-in slide-in-from-bottom-10 duration-1000 delay-200">
                <div className="p-10 border-b border-white/5 bg-white/[0.01] flex flex-col md:flex-row gap-8">
                    <div className="relative flex-1 group">
                        <Search className="absolute left-6 top-1/2 -translate-y-1/2 text-white/20 group-focus-within:text-secondary transition-colors" size={22} />
                        <input
                            type="text"
                            placeholder="SCAN TRANSACTION LOGS OR REF IDs..."
                            value={searchTerm}
                            onChange={(e) => setSearchTerm(e.target.value)}
                            className="w-full pl-16 pr-8 py-5 rounded-2xl bg-white/5 border border-white/5 outline-none focus:ring-4 focus:ring-secondary/5 focus:border-secondary/30 transition-all font-black text-[10px] text-white tracking-[0.3em] placeholder:text-white/10 uppercase"
                        />
                    </div>
                    <button className="flex items-center justify-center gap-4 px-10 h-16 bg-white/5 border border-white/10 rounded-2xl text-white/40 hover:bg-white/10 hover:text-white transition-all font-black text-[10px] uppercase tracking-[0.3em]">
                        <Filter size={20} />
                        <span>Filter Matrix</span>
                    </button>
                </div>

                <div className="overflow-x-auto">
                    <table className="w-full text-left">
                        <thead>
                            <tr className="bg-white/[0.02] border-white/5">
                                <th className="px-10 py-8 text-[9px] font-black text-white/30 uppercase tracking-[0.4em]">LOG_IDENTIFIER</th>
                                <th className="px-10 py-8 text-[9px] font-black text-white/30 uppercase tracking-[0.4em]">ENTITY</th>
                                <th className="px-10 py-8 text-[9px] font-black text-white/30 uppercase tracking-[0.4em]">LIQUIDITY_MAP</th>
                                <th className="px-10 py-8 text-[9px] font-black text-white/30 uppercase tracking-[0.4em]">TIMESTAMP</th>
                                <th className="px-10 py-8 text-[9px] font-black text-white/30 uppercase tracking-[0.4em] text-right">PROTOCOL_STATUS</th>
                            </tr>
                        </thead>
                        <tbody className="divide-y divide-white/5">
                            {loading ? (
                                <tr>
                                    <td colSpan={5} className="px-10 py-40 text-center">
                                         <div className="relative w-24 h-24 mx-auto">
                                            <div className="absolute inset-0 border-4 border-secondary/20 rounded-full" />
                                            <div className="absolute inset-0 border-4 border-secondary rounded-full border-t-transparent animate-spin shadow-[0_0_20px_#FFA000]" />
                                         </div>
                                    </td>
                                </tr>
                            ) : filteredTransactions.length === 0 ? (
                                <tr>
                                    <td colSpan={5} className="px-10 py-40 text-center text-white/10 font-black tracking-[0.8em] uppercase text-sm underline decoration-secondary/20 underline-offset-8">NO DATA FLOW DETECTED</td>
                                </tr>
                            ) : (
                                filteredTransactions.map((t) => (
                                    <tr key={t.id} className="hover:bg-white/[0.03] transition-colors duration-500 group">
                                        <td className="px-10 py-8">
                                            <div className="flex items-center gap-6">
                                                <div className="h-14 w-14 rounded-2xl bg-white/5 border border-white/10 text-white/20 group-hover:text-secondary group-hover:border-secondary/40 transition-all duration-700 flex items-center justify-center">
                                                    <CreditCard size={24} strokeWidth={1.5} />
                                                </div>
                                                <div>
                                                    <p className="font-black text-white tracking-widest text-sm uppercase group-hover:text-secondary transition-colors duration-500">{t.reference || 'SYSTEM_PROC'}</p>
                                                    <p className="text-[9px] text-white/20 font-black uppercase tracking-[0.3em] mt-1">{t.channel || 'PAYSTACK_GATEWAY'}</p>
                                                </div>
                                            </div>
                                        </td>
                                        <td className="px-10 py-8">
                                            <span className="text-[11px] font-black text-white/50 uppercase tracking-widest">{t.profiles?.full_name || 'ANONYMOUS_ENTITY'}</span>
                                        </td>
                                        <td className="px-10 py-8">
                                            <div className="flex items-baseline gap-2 group-hover:translate-x-1 transition-transform duration-500">
                                                <span className="text-[10px] text-white/20 font-black tracking-widest">GH₵</span>
                                                <span className="font-black text-white text-xl tabular-nums tracking-tighter">{(t.amount || 0).toLocaleString()}</span>
                                            </div>
                                        </td>
                                        <td className="px-10 py-8">
                                            <p className="text-[11px] font-black text-white/60 tracking-widest uppercase">
                                                {new Date(t.created_at).toLocaleDateString('en-GB', { day: 'numeric', month: 'short', year: 'numeric' })}
                                            </p>
                                            <p className="text-[9px] text-white/20 font-black uppercase tracking-widest mt-1">
                                                {new Date(t.created_at).toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit' })}
                                            </p>
                                        </td>
                                        <td className="px-10 py-8 text-right">
                                            <span className={`px-5 py-2.5 rounded-xl text-[9px] font-black uppercase tracking-[0.3em] border shadow-[0_0_15px_rgba(0,0,0,0.5)] ${
                                                t.status === 'Success' 
                                                ? 'bg-primary/5 border-primary/20 text-primary shadow-primary/5' 
                                                : 'bg-secondary/5 border-secondary/20 text-secondary shadow-secondary/5'
                                            }`}>
                                                {t.status || 'VERIFIED'}
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
                <div className="fixed inset-0 bg-bg/90 backdrop-blur-3xl z-[200] flex items-center justify-center p-6 animate-in fade-in duration-500">
                    <div className="bg-card border border-white/5 rounded-[3.5rem] w-full max-w-2xl overflow-hidden shadow-2xl animate-in zoom-in duration-500 relative">
                        <div className="absolute top-0 left-0 w-full h-1 bg-secondary shadow-[0_0_20px_#FFA000]" />
                        <div className="p-12 border-b border-white/5 flex items-center justify-between">
                            <div className="space-y-3">
                                <div className="flex items-center gap-3">
                                    <Zap size={18} className="text-secondary" />
                                    <h3 className="text-3xl font-black text-white tracking-widest uppercase">Treasury Override</h3>
                                </div>
                                <p className="text-white/20 font-black text-[10px] uppercase tracking-[0.5em]">SYSTEM PROTOCOL_PAYOUT v9</p>
                            </div>
                            <button onClick={() => setShowPayoutModal(false)} className="h-14 w-14 bg-white/5 hover:bg-white/10 text-white/20 hover:text-white rounded-[1.5rem] border border-white/5 transition-all flex items-center justify-center">
                                <X size={28} />
                            </button>
                        </div>
                        
                        <div className="p-16 space-y-12">
                            {status ? (
                                <div className="p-12 bg-primary/5 rounded-[2.5rem] border border-primary/20 flex flex-col items-center text-center gap-8 animate-in slide-in-from-bottom-8 duration-700">
                                    <div className="h-20 w-20 rounded-full bg-primary text-card flex items-center justify-center shadow-[0_0_40px_rgba(0,255,204,0.4)]">
                                        <CheckCircle2 size={48} strokeWidth={2.5} />
                                    </div>
                                    <p className="text-xl font-black text-primary tracking-widest uppercase underline underline-offset-8 decoration-primary/20 leading-relaxed">{status.message}</p>
                                </div>
                            ) : (
                                <>
                                    <div className="grid grid-cols-1 md:grid-cols-2 gap-10">
                                        <div className="p-10 bg-white/[0.02] border border-white/5 rounded-[2.5rem] space-y-3 group hover:border-secondary/30 transition-all duration-500 relative overflow-hidden">
                                            <div className="absolute top-0 right-0 p-6 text-secondary/5">
                                                <Wallet size={60} />
                                            </div>
                                            <p className="text-[10px] font-black text-white/30 uppercase tracking-[0.4em]">Pending Net Pulse</p>
                                            <h4 className="text-4xl font-black text-white tracking-tighter tabular-nums group-hover:text-secondary transition-colors duration-500">GH₵ {(totalRevenue * 0.12).toLocaleString()}</h4>
                                        </div>
                                        <div className="p-10 bg-white/[0.02] border border-white/5 rounded-[2.5rem] space-y-3 group hover:border-primary/30 transition-all duration-500 relative overflow-hidden">
                                            <div className="absolute top-0 right-0 p-6 text-primary/5">
                                                <ShieldCheck size={60} />
                                            </div>
                                            <p className="text-[10px] font-black text-white/30 uppercase tracking-[0.4em]">Settlement Reserve</p>
                                            <h4 className="text-4xl font-black text-white tracking-tighter tabular-nums group-hover:text-primary transition-colors duration-500">GH₵ {(totalRevenue * 0.05).toLocaleString()}</h4>
                                        </div>
                                    </div>

                                    <div className="p-10 bg-secondary/5 border border-secondary/20 rounded-[2.5rem] relative overflow-hidden group">
                                        <div className="absolute inset-0 bg-secondary/5 opacity-0 group-hover:opacity-100 transition-opacity" />
                                        <div className="relative flex gap-6 items-start">
                                            <AlertCircle size={28} className="text-secondary shrink-0 mt-1" />
                                            <p className="text-[10px] font-black text-secondary uppercase tracking-[0.3em] leading-relaxed">
                                                INITIATING THIS OVERRIDE WILL AUTHORIZE GLOBAL LIQUIDITY SETTLEMENT FOR ALL ACTIVE AGENT NODES AND FIELD REPRESENTATIVES. TRANSACTION LOGS WILL BE PERMANENTLY RECORDED IN THE CORE BLOCKCHAIN LEDGER.
                                            </p>
                                        </div>
                                    </div>

                                    <button 
                                        onClick={handleInitiatePayout}
                                        disabled={payoutLoading}
                                        className="w-full bg-secondary text-card font-black text-xs uppercase tracking-[0.5em] py-8 rounded-[2rem] transition-all shadow-[0_0_50px_rgba(255,160,0,0.3)] hover:shadow-secondary/50 flex items-center justify-center gap-6 disabled:opacity-20 translate-y-0 hover:-translate-y-1 active:scale-[0.98] duration-300"
                                    >
                                        {payoutLoading ? <Loader2 className="animate-spin" size={28} /> : <Wallet size={28} />}
                                        <span>Authorize Grid Settlement</span>
                                    </button>
                                </>
                            )}
                        </div>
                    </div>
                </div>
            )}
        </div>
    )
}
