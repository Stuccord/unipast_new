'use client'

import { useState, useEffect } from 'react'
import { supabase } from '@/lib/supabase'
import { uploadPastQuestion } from './actions'
import { UploadCloud, FileText, CheckCircle2, AlertCircle, ChevronRight, Info, Cpu, Zap, Activity } from 'lucide-react'

export default function UploadPage() {
    const [universities, setUniversities] = useState<any[]>([])
    const [faculties, setFaculties] = useState<any[]>([])
    const [programmes, setProgrammes] = useState<any[]>([])
    const [courses, setCourses] = useState<any[]>([])
    
    const [file, setFile] = useState<File | null>(null)
    const [uploading, setUploading] = useState(false)
    const [status, setStatus] = useState<{ type: 'success' | 'error', message: string } | null>(null)

    const [formData, setFormData] = useState({
        university_id: '',
        faculty_id: '',
        programme_id: '',
        course_id: '',
        year: new Date().getFullYear(),
        semester: 1,
        level: 100,
        title: ''
    })

    const [totalPapers, setTotalPapers] = useState(0)

    useEffect(() => {
        supabase.from('universities').select('id, name').order('name').then(({ data }) => setUniversities(data || []))
        supabase.from('past_questions').select('*', { count: 'exact', head: true }).then(({ count }) => setTotalPapers(count || 0))
    }, [])

    useEffect(() => {
        if (formData.university_id) {
            supabase.from('faculties').select('id, name').eq('university_id', formData.university_id).order('name')
                .then(({ data }) => setFaculties(data || []))
            setFormData(prev => ({ ...prev, faculty_id: '', programme_id: '', course_id: '' }))
        } else {
            setFaculties([])
            setProgrammes([])
            setCourses([])
        }
    }, [formData.university_id])

    useEffect(() => {
        if (formData.faculty_id) {
            supabase.from('programmes').select('id, name').eq('faculty_id', formData.faculty_id).order('name')
                .then(({ data }) => setProgrammes(data || []))
            setFormData(prev => ({ ...prev, programme_id: '', course_id: '' }))
        } else {
            setProgrammes([])
            setCourses([])
        }
    }, [formData.faculty_id])

    useEffect(() => {
        if (formData.programme_id) {
            supabase.from('courses').select('id, title, code, level, semester').eq('programme_id', formData.programme_id).order('title')
                .then(({ data }) => {
                    setCourses(data || [])
                })
            setFormData(prev => ({ ...prev, course_id: '' }))
        } else {
            setCourses([])
        }
    }, [formData.programme_id])

    useEffect(() => {
        if (formData.course_id) {
            const selectedCourse = courses.find(c => c.id === formData.course_id)
            if (selectedCourse) {
                setFormData(prev => ({ 
                    ...prev, 
                    level: selectedCourse.level || prev.level,
                    semester: selectedCourse.semester || prev.semester
                }))
            }
        }
    }, [formData.course_id, courses])

    const handleUpload = async (e: React.FormEvent) => {
        e.preventDefault()
        if (!file || !formData.course_id) return

        setUploading(true)
        setStatus(null)

        try {
            const selectedCourse = courses.find(c => c.id === formData.course_id)
            const finalTitle = formData.title || `${selectedCourse?.code || ''} ${selectedCourse?.title || 'Past Question'} - ${formData.year}`

            const formDataObj = new FormData()
            formDataObj.append('file', file)
            formDataObj.append('course_id', formData.course_id)
            formDataObj.append('year', String(formData.year))
            formDataObj.append('semester', String(formData.semester))
            formDataObj.append('level', String(formData.level))
            formDataObj.append('title', finalTitle)

            const result = await uploadPastQuestion(formDataObj)

            if (result.error) throw new Error(result.error)

            setStatus({ type: 'success', message: 'DATA STREAM INTEGRATED. NODE ACTIVATED.' })
            setFile(null)
            setFormData({ ...formData, title: '', university_id: '', faculty_id: '', programme_id: '', course_id: '' })
        } catch (err: any) {
            setStatus({ type: 'error', message: err.message || 'INJECTION ABORTED. KERNEL REJECTION.' })
        } finally {
            setUploading(false)
        }
    }

    return (
        <div className="max-w-6xl mx-auto space-y-12 py-4 font-orbitron pb-32">
            <div className="flex flex-col space-y-4">
                <div className="flex items-center gap-3">
                    <div className="p-2.5 bg-primary/10 rounded-xl border border-primary/20">
                        <Cpu size={22} className="text-primary" />
                    </div>
                    <span className="text-[10px] font-black text-primary uppercase tracking-[0.4em]">Resource Injection Portal</span>
                </div>
                <h2 className="text-4xl font-black text-white tracking-tight uppercase">System Augmentation</h2>
                <p className="text-white/30 font-black text-[10px] uppercase tracking-[0.3em]">Inject new academic data strands into the UniPast Core</p>
            </div>

            <div className="grid grid-cols-1 lg:grid-cols-3 gap-12">
                <div className="lg:col-span-2">
                    <div className="bg-card/40 backdrop-blur-3xl rounded-[3rem] border border-white/5 overflow-hidden shadow-2xl relative">
                        <div className="absolute top-0 right-0 w-64 h-64 bg-primary/5 rounded-full blur-[100px] pointer-events-none" />
                        
                        <form onSubmit={handleUpload} className="p-10 md:p-14 space-y-10 relative z-10">
                            {status && (
                                <div className={`p-8 rounded-3xl border flex items-start space-x-6 animate-in fade-in slide-in-from-top-4 duration-500 shadow-2xl ${
                                    status.type === 'success' 
                                        ? 'bg-primary/5 border-primary/20 text-primary' 
                                        : 'bg-danger/5 border-danger/20 text-danger'
                                }`}>
                                    <div className={`p-2 rounded-xl border ${status.type === 'success' ? 'bg-primary/20 border-primary/50 text-primary' : 'bg-danger/20 border-danger/50 text-danger'}`}>
                                        {status.type === 'success' ? <CheckCircle2 size={24} /> : <AlertCircle size={24} />}
                                    </div>
                                    <div className="space-y-2">
                                        <p className="font-black uppercase tracking-widest text-sm">{status.type === 'success' ? 'Signal Locked' : 'Interference Detected'}</p>
                                        <p className="text-[10px] font-black uppercase tracking-widest opacity-60 leading-relaxed">{status.message}</p>
                                    </div>
                                </div>
                            )}

                            <div className="grid grid-cols-1 md:grid-cols-2 gap-10">
                                <div className="space-y-4">
                                    <label className="text-[10px] font-black text-white/30 uppercase tracking-[0.34em] px-2">Institution Node</label>
                                    <select
                                        required
                                        className="w-full px-8 py-5 rounded-2xl bg-white/5 border border-white/5 outline-none focus:ring-4 focus:ring-primary/5 focus:border-primary/30 transition-all appearance-none cursor-pointer font-black text-[11px] text-white/60 tracking-widest uppercase hover:bg-white/10"
                                        value={formData.university_id}
                                        onChange={e => setFormData({ ...formData, university_id: e.target.value })}
                                    >
                                        <option value="" className="bg-bg">Select Target</option>
                                        {universities.map(u => (
                                            <option key={u.id} value={u.id} className="bg-bg">{u.name}</option>
                                        ))}
                                    </select>
                                </div>

                                <div className="space-y-4">
                                    <label className="text-[10px] font-black text-white/30 uppercase tracking-[0.34em] px-2">Faculty Sector</label>
                                    <select
                                        required
                                        disabled={!formData.university_id}
                                        className="w-full px-8 py-5 rounded-2xl bg-white/5 border border-white/5 outline-none focus:ring-4 focus:ring-primary/5 focus:border-primary/30 transition-all appearance-none cursor-pointer font-black text-[11px] text-white/60 tracking-widest uppercase disabled:opacity-20 hover:bg-white/10"
                                        value={formData.faculty_id}
                                        onChange={e => setFormData({ ...formData, faculty_id: e.target.value })}
                                    >
                                        <option value="" className="bg-bg">Select Spectrum</option>
                                        {faculties.map(f => (
                                            <option key={f.id} value={f.id} className="bg-bg">{f.name}</option>
                                        ))}
                                    </select>
                                </div>

                                <div className="space-y-4">
                                    <label className="text-[10px] font-black text-white/30 uppercase tracking-[0.34em] px-2">Programme Array</label>
                                    <select
                                        required
                                        disabled={!formData.faculty_id}
                                        className="w-full px-8 py-5 rounded-2xl bg-white/5 border border-white/5 outline-none focus:ring-4 focus:ring-primary/5 focus:border-primary/30 transition-all appearance-none cursor-pointer font-black text-[11px] text-white/60 tracking-widest uppercase disabled:opacity-20 hover:bg-white/10"
                                        value={formData.programme_id}
                                        onChange={e => setFormData({ ...formData, programme_id: e.target.value })}
                                    >
                                        <option value="" className="bg-bg">Select Matrix</option>
                                        {programmes.map(p => (
                                            <option key={p.id} value={p.id} className="bg-bg">{p.name}</option>
                                        ))}
                                    </select>
                                </div>

                                <div className="space-y-4">
                                    <label className="text-[10px] font-black text-white/30 uppercase tracking-[0.34em] px-2">Core Course</label>
                                    <select
                                        required
                                        disabled={!formData.programme_id}
                                        className="w-full px-8 py-5 rounded-2xl bg-white/5 border border-white/5 outline-none focus:ring-4 focus:ring-primary/5 focus:border-primary/30 transition-all appearance-none cursor-pointer font-black text-[11px] text-white/60 tracking-widest uppercase disabled:opacity-20 hover:bg-white/10"
                                        value={formData.course_id}
                                        onChange={e => setFormData({ ...formData, course_id: e.target.value })}
                                    >
                                        <option value="" className="bg-bg">Select Subject</option>
                                        {courses.map(c => (
                                            <option key={c.id} value={c.id} className="bg-bg">
                                                {c.code} - {c.title}
                                            </option>
                                        ))}
                                    </select>
                                </div>

                                <div className="space-y-4">
                                    <label className="text-[10px] font-black text-white/30 uppercase tracking-[0.34em] px-2">Temporal Phase (Year)</label>
                                    <input
                                        type="number"
                                        required
                                        className="w-full px-8 py-5 rounded-2xl bg-white/5 border border-white/5 outline-none focus:ring-4 focus:ring-primary/5 focus:border-primary/30 transition-all font-black text-[11px] text-white/80 tracking-[0.3em] hover:bg-white/10"
                                        value={formData.year}
                                        onChange={e => setFormData({ ...formData, year: parseInt(e.target.value) })}
                                    />
                                </div>

                                <div className="space-y-4">
                                    <label className="text-[10px] font-black text-white/30 uppercase tracking-[0.34em] px-2">Level Grade</label>
                                    <select
                                        required
                                        className="w-full px-8 py-5 rounded-2xl bg-white/5 border border-white/5 outline-none focus:ring-4 focus:ring-primary/5 focus:border-primary/30 transition-all appearance-none cursor-pointer font-black text-[11px] text-white/60 tracking-widest uppercase hover:bg-white/10"
                                        value={formData.level}
                                        onChange={e => setFormData({ ...formData, level: parseInt(e.target.value) })}
                                    >
                                        <option value={100} className="bg-bg">LEVEL 100</option>
                                        <option value={200} className="bg-bg">LEVEL 200</option>
                                        <option value={300} className="bg-bg">LEVEL 300</option>
                                        <option value={400} className="bg-bg">LEVEL 400</option>
                                        <option value={500} className="bg-bg">LEVEL 500</option>
                                        <option value={600} className="bg-bg">LEVEL 600</option>
                                    </select>
                                </div>

                                <div className="space-y-4">
                                    <label className="text-[10px] font-black text-white/30 uppercase tracking-[0.34em] px-2">Semester Cycle</label>
                                    <select
                                        required
                                        className="w-full px-8 py-5 rounded-2xl bg-white/5 border border-white/5 outline-none focus:ring-4 focus:ring-primary/5 focus:border-primary/30 transition-all appearance-none cursor-pointer font-black text-[11px] text-white/60 tracking-widest uppercase hover:bg-white/10"
                                        value={formData.semester}
                                        onChange={e => setFormData({ ...formData, semester: parseInt(e.target.value) })}
                                    >
                                        <option value={1} className="bg-bg">CYCLE ALPHA (1)</option>
                                        <option value={2} className="bg-bg">CYCLE OMEGA (2)</option>
                                    </select>
                                </div>

                                <div className="space-y-4 md:col-span-2">
                                    <label className="text-[10px] font-black text-white/30 uppercase tracking-[0.34em] px-2">Data Strand Title (Optional)</label>
                                    <input
                                        type="text"
                                        placeholder="E.G. END OF SEMESTER EXAM - REGULAR"
                                        className="w-full px-8 py-5 rounded-2xl bg-white/5 border border-white/5 outline-none focus:ring-4 focus:ring-primary/5 focus:border-primary/30 transition-all font-black text-[11px] text-white/80 tracking-[0.3em] hover:bg-white/10 uppercase placeholder:text-white/10"
                                        value={formData.title}
                                        onChange={e => setFormData({ ...formData, title: e.target.value.toUpperCase() })}
                                    />
                                </div>
                            </div>

                            <div className="space-y-4 pt-6">
                                <label className="text-[10px] font-black text-white/30 uppercase tracking-[0.34em] px-2">Data Strand Source (PDF)</label>
                                <div className="relative group">
                                    <input
                                        type="file"
                                        accept=".pdf"
                                        required
                                        onChange={e => setFile(e.target.files?.[0] || null)}
                                        className="absolute inset-0 w-full h-full opacity-0 cursor-pointer z-20"
                                    />
                                    <div className={`p-16 border-2 border-dashed rounded-[3rem] flex flex-col items-center justify-center space-y-6 transition-all duration-700 relative overflow-hidden group-hover:border-primary/50
                                        ${file ? 'border-primary bg-primary/5 shadow-[inset_0_0_30px_rgba(0,255,204,0.1)]' : 'border-white/5 bg-white/[0.02]'}
                                    `}>
                                        <div className={`h-24 w-24 rounded-[2rem] flex items-center justify-center transition-all duration-700 relative z-10 ${file ? 'bg-primary text-card shadow-[0_0_30px_#00FFCC]' : 'bg-white/5 text-white/20 group-hover:text-primary group-hover:border-primary/30 border border-white/5'}`}>
                                            {file ? <CheckCircle2 size={48} className="animate-pulse" /> : <UploadCloud size={48} className="group-hover:animate-bounce" />}
                                        </div>
                                        <div className="text-center relative z-10 w-full px-4 overflow-hidden">
                                            <p className="font-black text-sm text-white tracking-[0.2em] uppercase truncate">{file ? file.name : 'Select Neural Interface'}</p>
                                            <p className="text-[10px] font-black text-white/20 mt-3 tracking-widest uppercase">{file ? `${(file.size / (1024 * 1024)).toFixed(2)} MB DATA DETECTED` : 'Deploy PDF Strand via Terminal'}</p>
                                        </div>
                                        {file && (
                                            <div className="absolute inset-0 z-0 bg-[radial-gradient(circle_at_center,rgba(0,255,204,0.05)_0%,transparent_70%)] animate-pulse" />
                                        )}
                                    </div>
                                </div>
                            </div>

                            <button
                                type="submit"
                                disabled={uploading || !file}
                                className="relative w-full h-[80px] overflow-hidden rounded-[1.5rem] transition-all duration-500 shadow-2xl disabled:opacity-20 active:scale-[0.98] group/submit"
                            >
                                <div className="absolute inset-0 bg-primary group-hover/submit:bg-primary/90 transition-colors" />
                                <div className="absolute inset-0 opacity-0 group-hover/submit:opacity-20 bg-[linear-gradient(45deg,transparent,rgba(255,255,255,0.4),transparent)] -translate-x-full group-hover/submit:translate-x-full transition-all duration-1000" />
                                <div className="relative z-10 flex items-center justify-center gap-4">
                                     <Zap size={24} className="text-card" />
                                     <span className="text-card text-sm font-black uppercase tracking-[0.4em]">{uploading ? 'Injecting Data Strand...' : 'Initiate Matrix Injection'}</span>
                                     <ChevronRight size={22} className="text-card group-hover/submit:translate-x-1 transition-transform" />
                                </div>
                            </button>
                        </form>
                    </div>
                </div>

                <div className="space-y-12">
                    <div className="bg-card/40 backdrop-blur-2xl rounded-[3rem] border border-white/5 p-12 shadow-2xl relative group overflow-hidden">
                        <div className="absolute -top-10 -right-10 w-40 h-40 bg-primary/5 rounded-full blur-3xl group-hover:bg-primary/10 transition-colors" />
                        <div className="flex items-center gap-4 mb-10">
                            <div className="p-3 bg-secondary/10 rounded-2xl border border-secondary/20">
                                <Activity size={20} className="text-secondary" />
                            </div>
                            <h3 className="text-sm font-black text-white tracking-[0.2em] uppercase">Phase Protocols</h3>
                        </div>
                        <ul className="space-y-8 relative z-10">
                            {[
                                "Ensure data strands are high-fidelity digital scans.",
                                "Verify identity of Matrix Node before injection.",
                                "Security check for personal student metadata."
                            ].map((directive, idx) => (
                                <li key={idx} className="flex items-start gap-6 group/item">
                                    <div className="h-8 w-8 rounded-xl bg-white/5 border border-white/10 flex-shrink-0 flex items-center justify-center text-[10px] font-black text-primary group-hover/item:border-primary/50 transition-colors">
                                        {idx + 1}
                                    </div>
                                    <p className="text-[11px] font-black text-white/40 leading-relaxed uppercase tracking-wider group-hover:text-white/70 transition-colors">{directive}</p>
                                </li>
                            ))}
                        </ul>
                    </div>

                    <div className="bg-card/40 backdrop-blur-2xl rounded-[3rem] border border-white/5 p-10 shadow-2xl flex items-center gap-8 group">
                        <div className="relative h-24 w-24">
                            <div className="absolute inset-0 bg-accent/20 rounded-2xl blur-xl group-hover:bg-accent/40 transition-colors" />
                            <div className="relative h-full w-full bg-surface border border-accent/30 rounded-2xl flex items-center justify-center text-accent">
                                <FileText size={40} />
                            </div>
                        </div>
                        <div>
                             <p className="text-4xl font-black text-white font-orbitron tracking-tight mb-1">{totalPapers.toLocaleString()}</p>
                             <div className="flex items-center gap-2">
                                 <div className="w-1.5 h-1.5 rounded-full bg-accent animate-pulse" />
                                 <p className="text-[9px] font-black text-white/20 uppercase tracking-[0.3em]">Total Global Strands</p>
                             </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    )
}
