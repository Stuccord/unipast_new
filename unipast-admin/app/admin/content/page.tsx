'use client'

import { useEffect, useState } from 'react'
import { supabase } from '@/lib/supabase'
import { 
    FileText, 
    Search, 
    Trash2, 
    Eye, 
    Download, 
    ChevronLeft, 
    ChevronRight,
    Filter,
    ArrowUpDown,
    Database,
    Zap,
    Cpu,
    Shield
} from 'lucide-react'
import { deletePastQuestion } from '../upload/actions'

export default function ContentManagementPage() {
    const [questions, setQuestions] = useState<any[]>([])
    const [loading, setLoading] = useState(true)
    const [searchQuery, setSearchQuery] = useState('')
    const [page, setPage] = useState(1)
    const [pageSize] = useState(10)
    const [totalCount, setTotalCount] = useState(0)

    useEffect(() => {
        fetchQuestions()
    }, [page, searchQuery])

    const fetchQuestions = async () => {
        setLoading(true)
        try {
            let query = supabase
                .from('past_questions')
                .select('*, courses(title, code, level, semester, programmes(name, faculties(name, universities(name))))', { count: 'exact' })

            if (searchQuery) {
                query = query.or(`title.ilike.%${searchQuery}%,year.eq.${parseInt(searchQuery) || 0}`)
            }

            const { data, count, error } = await query
                .order('created_at', { ascending: false })
                .range((page - 1) * pageSize, page * pageSize - 1)

            if (error) throw error
            setQuestions(data || [])
            setTotalCount(count || 0)
        } catch (error) {
            console.error('Core Database Error:', error)
        } finally {
            setLoading(false)
        }
    }

    const handleDelete = async (id: string, filePath: string) => {
        if (!confirm('INITIATE IRREVERSIBLE SECTOR WIPE? DATA COHERENCE WILL BE LOST.')) return
        
        try {
            const result = await deletePastQuestion(id, filePath)
            if (result.success) {
                setQuestions(prev => prev.filter(q => q.id !== id))
                setTotalCount(prev => prev - 1)
            } else {
                alert('SECURITY BREACH: ' + result.error)
            }
        } catch (err) {
            console.error('Wipe Failure:', err)
            alert('CRITICAL KERNEL ERROR.')
        }
    }

    return (
        <div className="space-y-12 pb-20 font-orbitron">
            <div className="flex flex-col xl:flex-row xl:items-end justify-between gap-8">
                <div className="space-y-4">
                    <div className="flex items-center gap-3">
                        <div className="p-2.5 bg-secondary/10 rounded-xl border border-secondary/20">
                            <Database size={22} className="text-secondary" />
                        </div>
                        <span className="text-[10px] font-black text-secondary uppercase tracking-[0.4em]">Repository Index v4.0</span>
                    </div>
                    <h2 className="text-4xl font-black text-white tracking-tight uppercase">Content Matrix</h2>
                    <p className="text-white/30 font-black text-[10px] uppercase tracking-[0.3em]">Operational Oversight of all Injected Resource Nodes</p>
                </div>
                
                <div className="relative group min-w-[320px] md:min-w-[450px]">
                    <div className="absolute -inset-1 bg-white/5 rounded-[2rem] blur opacity-0 group-focus-within:opacity-100 transition-opacity" />
                    <div className="absolute left-6 top-1/2 -translate-y-1/2 text-white/20 group-focus-within:text-primary transition-colors">
                        <Search size={22} />
                    </div>
                    <input 
                        type="text" 
                        placeholder="SCAN BY TITLE, YEAR, OR CODE..."
                        className="w-full pl-16 pr-8 py-5 rounded-[1.5rem] bg-card/40 backdrop-blur-xl border border-white/5 outline-none focus:ring-4 focus:ring-primary/5 focus:border-primary/30 transition-all font-black text-xs text-white tracking-[0.2em] placeholder:text-white/10 uppercase"
                        value={searchQuery}
                        onChange={(e) => { setSearchQuery(e.target.value); setPage(1); }}
                    />
                </div>
            </div>

            <div className="bg-card/20 backdrop-blur-3xl rounded-[3rem] border border-white/5 overflow-hidden shadow-2xl animate-in fade-in slide-in-from-bottom-8 duration-1000">
                <div className="overflow-x-auto">
                    <table className="w-full text-left">
                        <thead>
                            <tr className="bg-white/[0.02] border-b border-white/5">
                                <th className="px-10 py-8 text-[9px] font-black text-white/30 uppercase tracking-[0.4em]">Resource Signature</th>
                                <th className="px-10 py-8 text-[9px] font-black text-white/30 uppercase tracking-[0.4em]">Institutional Origin</th>
                                <th className="px-10 py-8 text-[9px] font-black text-white/30 uppercase tracking-[0.4em]">Core Tags</th>
                                <th className="px-10 py-8 text-[9px] font-black text-white/30 uppercase tracking-[0.4em] text-right">Operations</th>
                            </tr>
                        </thead>
                        <tbody className="divide-y divide-white/5">
                            {loading ? (
                                <tr><td colSpan={4} className="px-10 py-40 text-center">
                                    <div className="relative w-24 h-24 mx-auto">
                                        <div className="absolute inset-0 border-4 border-primary/20 rounded-full" />
                                        <div className="absolute inset-0 border-4 border-primary rounded-full border-t-transparent animate-spin" />
                                        <div className="absolute inset-0 flex items-center justify-center">
                                            <span className="text-white text-[10px] font-black">SCANNING</span>
                                        </div>
                                    </div>
                                </td></tr>
                            ) : questions.length === 0 ? (
                                <tr><td colSpan={4} className="px-10 py-40 text-center">
                                    <p className="text-white/10 font-black uppercase tracking-[0.8em] text-sm">ZERO DATA DETECTED IN SECTOR</p>
                                </td></tr>
                            ) : questions.map((q) => (
                                <tr key={q.id} className="hover:bg-white/[0.03] transition-colors duration-500 group">
                                    <td className="px-10 py-8">
                                        <div className="flex items-center gap-6">
                                            <div className="relative h-16 w-16 rounded-2xl bg-white/5 flex items-center justify-center text-white/30 border border-white/5 group-hover:border-primary/40 transition-all duration-700">
                                                <div className="absolute inset-0 bg-primary/5 opacity-0 group-hover:opacity-100 transition-opacity rounded-2xl" />
                                                <FileText size={28} className="relative z-10 group-hover:text-primary transition-colors" />
                                            </div>
                                            <div className="flex flex-col space-y-1.5">
                                                <span className="font-black text-white tracking-widest uppercase group-hover:text-primary transition-colors duration-500">{q.title || `Paper ${q.year}`}</span>
                                                <div className="flex items-center gap-2">
                                                    <div className="px-2 py-0.5 bg-primary/10 rounded text-primary text-[8px] font-black border border-primary/20">{q.courses?.code}</div>
                                                    <span className="text-[9px] font-black text-white/20 uppercase tracking-widest">{q.courses?.title}</span>
                                                </div>
                                            </div>
                                        </div>
                                    </td>
                                    <td className="px-10 py-8">
                                        <div className="flex flex-col space-y-1">
                                            <span className="text-[11px] font-black text-white uppercase tracking-widest group-hover:text-secondary transition-colors duration-500">
                                                {q.courses?.programmes?.faculties?.universities?.name}
                                            </span>
                                            <span className="text-[9px] font-black text-white/20 uppercase tracking-[0.2em]">
                                                {q.courses?.programmes?.faculties?.name}
                                            </span>
                                        </div>
                                    </td>
                                    <td className="px-10 py-8">
                                        <div className="flex flex-wrap gap-3">
                                            <div className="px-4 py-2 bg-white/5 border border-white/10 rounded-xl flex items-center gap-2">
                                                <div className="w-1 h-1 rounded-full bg-primary" />
                                                <span className="text-[9px] font-black text-white/40 uppercase tracking-widest">{q.year}</span>
                                            </div>
                                            <div className="px-4 py-2 bg-white/5 border border-white/10 rounded-xl flex items-center gap-2">
                                                <div className="w-1 h-1 rounded-full bg-secondary" />
                                                <span className="text-[9px] font-black text-white/40 uppercase tracking-widest">S{q.semester || q.courses?.semester}</span>
                                            </div>
                                            {(q.level || q.courses?.level) && (
                                                <div className="px-4 py-2 bg-white/5 border border-white/10 rounded-xl flex items-center gap-2">
                                                    <div className="w-1 h-1 rounded-full bg-accent" />
                                                    <span className="text-[9px] font-black text-white/40 uppercase tracking-widest">L{q.level || q.courses?.level}</span>
                                                </div>
                                            )}
                                        </div>
                                    </td>
                                    <td className="px-10 py-8 text-right">
                                        <div className="flex items-center justify-end gap-4 opacity-30 group-hover:opacity-100 transition-opacity duration-500">
                                            <button className="h-12 w-12 bg-white/5 text-white/30 hover:text-primary hover:border-primary/50 border border-white/5 rounded-2xl transition-all flex items-center justify-center group/opt" title="ACCESS">
                                                <Eye size={20} className="group-hover/opt:scale-110 transition-transform" />
                                            </button>
                                            <button 
                                                onClick={() => handleDelete(q.id, q.pdf_url)}
                                                className="h-12 w-12 bg-white/5 text-white/30 hover:text-danger hover:border-danger/50 border border-white/5 rounded-2xl transition-all flex items-center justify-center group/opt" 
                                                title="PURGE"
                                            >
                                                <Trash2 size={20} className="group-hover/opt:rotate-12 transition-transform" />
                                            </button>
                                        </div>
                                    </td>
                                </tr>
                            ))}
                        </tbody>
                    </table>
                </div>

                {/* Pagination */}
                <div className="px-10 py-10 bg-white/[0.02] border-t border-white/5 flex flex-col md:flex-row items-center justify-between gap-8">
                    <p className="text-[9px] font-black text-white/20 uppercase tracking-[0.4em]">
                        Showing <span className="text-primary">{totalCount > 0 ? (page - 1) * pageSize + 1 : 0}</span> to <span className="text-primary">{Math.min(page * pageSize, totalCount)}</span> of <span className="text-primary">{totalCount}</span> Global Nodes
                    </p>
                    <div className="flex items-center gap-4">
                        <button 
                            disabled={page === 1}
                            onClick={() => setPage(p => p - 1)}
                            className="h-14 px-6 rounded-2xl bg-white/5 border border-white/5 text-white/30 hover:text-primary hover:border-primary/30 disabled:opacity-20 transition-all flex items-center gap-3 text-[10px] font-black uppercase tracking-widest group"
                        >
                            <ChevronLeft size={18} className="group-hover:-translate-x-1 transition-transform" />
                            Prev Phase
                        </button>
                        <div className="h-10 w-[1px] bg-white/5" />
                        <button 
                            disabled={page * pageSize >= totalCount}
                            onClick={() => setPage(p => p + 1)}
                            className="h-14 px-6 rounded-2xl bg-white/5 border border-white/5 text-white/30 hover:text-primary hover:border-primary/30 disabled:opacity-20 transition-all flex items-center gap-3 text-[10px] font-black uppercase tracking-widest group"
                        >
                            Next Phase
                            <ChevronRight size={18} className="group-hover:translate-x-1 transition-transform" />
                        </button>
                    </div>
                </div>
            </div>
        </div>
    )
}
