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
    ArrowUpDown
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
            console.error('Error fetching questions:', error)
        } finally {
            setLoading(false)
        }
    }

    const handleDelete = async (id: string, filePath: string) => {
        if (!confirm('Are you sure you want to permanently delete this past question? This action cannot be undone.')) return
        
        try {
            const result = await deletePastQuestion(id, filePath)
            if (result.success) {
                setQuestions(prev => prev.filter(q => q.id !== id))
                setTotalCount(prev => prev - 1)
            } else {
                alert('Error: ' + result.error)
            }
        } catch (err) {
            console.error('Deletion error:', err)
            alert('An unexpected error occurred.')
        }
    }

    return (
        <div className="space-y-8 py-4">
            <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
                <div className="space-y-1">
                    <h2 className="text-3xl font-black text-slate-800 tracking-tight">Content Management</h2>
                    <p className="text-slate-500 font-bold text-sm uppercase tracking-widest">Manage all uploaded repository resources</p>
                </div>
                
                <div className="relative group">
                    <Search className="absolute left-4 top-1/2 -translate-y-1/2 text-slate-400 group-focus-within:text-[#0D9488] transition-colors" size={20} />
                    <input 
                        type="text" 
                        placeholder="Search by title, year or code..."
                        className="pl-12 pr-6 py-4 rounded-2xl bg-white border border-slate-100 outline-none focus:ring-4 focus:ring-[#0D9488]/10 focus:border-[#0D9488] transition-all w-full md:w-[350px] font-bold text-slate-700 shadow-sm"
                        value={searchQuery}
                        onChange={(e) => { setSearchQuery(e.target.value); setPage(1); }}
                    />
                </div>
            </div>

            <div className="bg-white rounded-[2.5rem] shadow-sm border border-slate-100 overflow-hidden">
                <div className="overflow-x-auto">
                    <table className="w-full text-left">
                        <thead className="bg-slate-50/50">
                            <tr className="text-slate-400 font-black text-[10px] uppercase tracking-[0.2em]">
                                <th className="px-8 py-6">Material Details</th>
                                <th className="px-8 py-6">Institution / Faculty</th>
                                <th className="px-8 py-6">Metadata</th>
                                <th className="px-8 py-6 text-right">Actions</th>
                            </tr>
                        </thead>
                        <tbody className="divide-y divide-slate-100">
                            {loading ? (
                                <tr><td colSpan={4} className="px-8 py-24 text-center"><div className="animate-spin rounded-full h-12 w-12 border-b-2 border-[#0D9488] mx-auto"></div></td></tr>
                            ) : questions.length === 0 ? (
                                <tr><td colSpan={4} className="px-8 py-24 text-center text-slate-400 font-bold uppercase tracking-widest text-xs">No questions found</td></tr>
                            ) : questions.map((q) => (
                                <tr key={q.id} className="hover:bg-slate-50/50 transition duration-150">
                                    <td className="px-8 py-6">
                                        <div className="flex items-center space-x-4">
                                            <div className="h-12 w-12 rounded-2xl bg-rose-50 text-rose-500 flex items-center justify-center border border-rose-100 shadow-sm">
                                                <FileText size={24} />
                                            </div>
                                            <div className="flex flex-col">
                                                <span className="font-black text-slate-800 tracking-tight">{q.title || `Paper ${q.year}`}</span>
                                                <span className="text-xs font-bold text-slate-400 uppercase tracking-widest">{q.courses?.code} - {q.courses?.title}</span>
                                            </div>
                                        </div>
                                    </td>
                                    <td className="px-8 py-6">
                                        <div className="flex flex-col">
                                            <span className="text-sm font-black text-slate-700 truncate max-w-[200px]">
                                                {q.courses?.programmes?.faculties?.universities?.name}
                                            </span>
                                            <span className="text-xs font-bold text-slate-400">
                                                {q.courses?.programmes?.faculties?.name}
                                            </span>
                                        </div>
                                    </td>
                                    <td className="px-8 py-6">
                                        <div className="flex flex-wrap gap-2">
                                            <span className="px-3 py-1 bg-slate-100 text-slate-600 rounded-lg text-[10px] font-black uppercase tracking-widest">{q.year}</span>
                                            <span className="px-3 py-1 bg-teal-50 text-[#0D9488] rounded-lg text-[10px] font-black uppercase tracking-widest">Sem {q.semester || q.courses?.semester}</span>
                                            {(q.level || q.courses?.level) && <span className="px-3 py-1 bg-blue-50 text-blue-600 rounded-lg text-[10px] font-black uppercase tracking-widest">L{q.level || q.courses?.level}</span>}
                                        </div>
                                    </td>
                                    <td className="px-8 py-6 text-right">
                                        <div className="flex items-center justify-end space-x-2">
                                            <button className="p-3 bg-slate-50 text-slate-400 hover:text-[#0D9488] hover:bg-[#0D9488]/10 rounded-xl transition-all" title="View"><Eye size={18} /></button>
                                            <button 
                                                onClick={() => handleDelete(q.id, q.pdf_url)}
                                                className="p-3 bg-slate-50 text-slate-400 hover:text-rose-500 hover:bg-rose-50 rounded-xl transition-all" 
                                                title="Delete"
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

                {/* Pagination */}
                <div className="p-8 bg-slate-50/50 border-t border-slate-100 flex items-center justify-between">
                    <p className="text-xs font-bold text-slate-400 uppercase tracking-widest">
                        Showing <span className="text-slate-800">{totalCount > 0 ? (page - 1) * pageSize + 1 : 0}</span> to <span className="text-slate-800">{Math.min(page * pageSize, totalCount)}</span> of <span className="text-slate-800">{totalCount}</span> results
                    </p>
                    <div className="flex items-center space-x-2">
                        <button 
                            disabled={page === 1}
                            onClick={() => setPage(p => p - 1)}
                            className="p-2 rounded-xl bg-white border border-slate-200 text-slate-400 hover:text-[#0D9488] disabled:opacity-50 transition-all shadow-sm"
                        >
                            <ChevronLeft size={20} />
                        </button>
                        <button 
                            disabled={page * pageSize >= totalCount}
                            onClick={() => setPage(p => p + 1)}
                            className="p-2 rounded-xl bg-white border border-slate-200 text-slate-400 hover:text-[#0D9488] disabled:opacity-50 transition-all shadow-sm"
                        >
                            <ChevronRight size={20} />
                        </button>
                    </div>
                </div>
            </div>
        </div>
    )
}
