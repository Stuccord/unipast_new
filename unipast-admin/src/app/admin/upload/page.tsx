'use client'

import { useState, useEffect } from 'react'
import { supabase } from '@/lib/supabase'
import { UploadCloud, FileText, CheckCircle2, AlertCircle, ChevronRight, Info } from 'lucide-react'

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
        title: ''
    })

    const [totalPapers, setTotalPapers] = useState(0)

    useEffect(() => {
        // Initial fetch: Universities and Total Stats
        supabase.from('universities').select('id, name').order('name').then(({ data }) => setUniversities(data || []))
        supabase.from('past_questions').select('*', { count: 'exact', head: true }).then(({ count }) => setTotalPapers(count || 0))
    }, [])

    // Fetch Faculties when University changes
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

    // Fetch Programmes when Faculty changes
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

    // Fetch Courses when Programme changes
    useEffect(() => {
        if (formData.programme_id) {
            supabase.from('courses').select('id, title, code').eq('programme_id', formData.programme_id).order('title')
                .then(({ data }) => setCourses(data || []))
            setFormData(prev => ({ ...prev, course_id: '' }))
        } else {
            setCourses([])
        }
    }, [formData.programme_id])

    const handleUpload = async (e: React.FormEvent) => {
        e.preventDefault()
        if (!file || !formData.course_id) return

        setUploading(true)
        setStatus(null)

        try {
            const fileExt = file.name.split('.').pop()
            const fileName = `${formData.course_id}/${Date.now()}.${fileExt}`
            const filePath = fileName

            const { error: uploadError } = await supabase.storage
                .from('questions')
                .upload(filePath, file)

            if (uploadError) throw uploadError

            const selectedCourse = courses.find(c => c.id === formData.course_id)
            const { error: dbError } = await supabase.from('past_questions').insert({
                course_id: formData.course_id,
                year: formData.year,
                semester: formData.semester,
                file_path: filePath,
                title: formData.title || `${selectedCourse?.code || ''} ${selectedCourse?.title || 'Past Question'} - ${formData.year}`
            })

            if (dbError) throw dbError

            // Create notification for users
            await supabase.from('notifications').insert({
                title: 'New Past Question',
                message: `A new past question for ${selectedCourse?.title || 'a course'} has been uploaded.`,
                type: 'upload'
            })

            setStatus({ type: 'success', message: 'The past question has been successfully uploaded to the repository.' })
            setFile(null)
            setFormData({ ...formData, title: '', university_id: '', faculty_id: '', programme_id: '', course_id: '' })
        } catch (err: any) {
            setStatus({ type: 'error', message: err.message || 'An unexpected error occurred during upload. Please try again.' })
        } finally {
            setUploading(false)
        }
    }

    return (
        <div className="max-w-4xl mx-auto space-y-10 py-4">
            <div className="flex flex-col space-y-2">
                <h2 className="text-3xl font-bold text-slate-800">Upload New Resource</h2>
                <p className="text-slate-500 font-medium tracking-tight">Add past examination questions and course materials to the database.</p>
            </div>

            <div className="grid grid-cols-1 lg:grid-cols-3 gap-10">
                <div className="lg:col-span-2">
                    <div className="bg-white rounded-[2.5rem] shadow-sm border border-slate-100 overflow-hidden">
                        <form onSubmit={handleUpload} className="p-10 space-y-8">
                            {status && (
                                <div className={`p-6 rounded-2xl border flex items-start space-x-4 animate-in fade-in slide-in-from-top-4 duration-300 ${
                                    status.type === 'success' ? 'bg-emerald-50 border-emerald-100 text-emerald-700' : 'bg-rose-50 border-rose-100 text-rose-700'
                                }`}>
                                    <div className={`p-1 rounded-full ${status.type === 'success' ? 'bg-emerald-500 text-white' : 'bg-rose-500 text-white'}`}>
                                        {status.type === 'success' ? <CheckCircle2 size={16} /> : <AlertCircle size={16} />}
                                    </div>
                                    <div className="space-y-1">
                                        <p className="font-bold tracking-tight">{status.type === 'success' ? 'Upload Successful' : 'Upload Failed'}</p>
                                        <p className="text-sm font-medium opacity-90">{status.message}</p>
                                    </div>
                                </div>
                            )}

                            <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
                                <div className="space-y-3">
                                    <label className="text-xs font-black text-slate-400 uppercase tracking-[0.15em] px-1">University / School</label>
                                    <select
                                        required
                                        className="w-full px-6 py-4 rounded-2xl bg-slate-50 border-none outline-none focus:ring-2 focus:ring-[#0D9488]/20 transition-all appearance-none cursor-pointer font-bold text-slate-700"
                                        value={formData.university_id}
                                        onChange={e => setFormData({ ...formData, university_id: e.target.value })}
                                    >
                                        <option value="">Select University</option>
                                        {universities.map(u => (
                                            <option key={u.id} value={u.id}>{u.name}</option>
                                        ))}
                                    </select>
                                </div>

                                <div className="space-y-3">
                                    <label className="text-xs font-black text-slate-400 uppercase tracking-[0.15em] px-1">Faculty</label>
                                    <select
                                        required
                                        disabled={!formData.university_id}
                                        className="w-full px-6 py-4 rounded-2xl bg-slate-50 border-none outline-none focus:ring-2 focus:ring-[#0D9488]/20 transition-all appearance-none cursor-pointer font-bold text-slate-700 disabled:opacity-50"
                                        value={formData.faculty_id}
                                        onChange={e => setFormData({ ...formData, faculty_id: e.target.value })}
                                    >
                                        <option value="">Select Faculty</option>
                                        {faculties.map(f => (
                                            <option key={f.id} value={f.id}>{f.name}</option>
                                        ))}
                                    </select>
                                </div>

                                <div className="space-y-3">
                                    <label className="text-xs font-black text-slate-400 uppercase tracking-[0.15em] px-1">Programme</label>
                                    <select
                                        required
                                        disabled={!formData.faculty_id}
                                        className="w-full px-6 py-4 rounded-2xl bg-slate-50 border-none outline-none focus:ring-2 focus:ring-[#0D9488]/20 transition-all appearance-none cursor-pointer font-bold text-slate-700 disabled:opacity-50"
                                        value={formData.programme_id}
                                        onChange={e => setFormData({ ...formData, programme_id: e.target.value })}
                                    >
                                        <option value="">Select Programme</option>
                                        {programmes.map(p => (
                                            <option key={p.id} value={p.id}>{p.name}</option>
                                        ))}
                                    </select>
                                </div>

                                <div className="space-y-3">
                                    <label className="text-xs font-black text-slate-400 uppercase tracking-[0.15em] px-1">Course</label>
                                    <select
                                        required
                                        disabled={!formData.programme_id}
                                        className="w-full px-6 py-4 rounded-2xl bg-slate-50 border-none outline-none focus:ring-2 focus:ring-[#0D9488]/20 transition-all appearance-none cursor-pointer font-bold text-slate-700 disabled:opacity-50"
                                        value={formData.course_id}
                                        onChange={e => setFormData({ ...formData, course_id: e.target.value })}
                                    >
                                        <option value="">Select Course</option>
                                        {courses.map(c => (
                                            <option key={c.id} value={c.id}>
                                                {c.code} - {c.title}
                                            </option>
                                        ))}
                                    </select>
                                </div>

                                <div className="space-y-3">
                                    <label className="text-xs font-black text-slate-400 uppercase tracking-[0.15em] px-1">Academic Year</label>
                                    <input
                                        type="number"
                                        required
                                        className="w-full px-6 py-4 rounded-2xl bg-slate-50 border-none outline-none focus:ring-2 focus:ring-[#0D9488]/20 transition-all font-bold text-slate-700"
                                        value={formData.year}
                                        onChange={e => setFormData({ ...formData, year: parseInt(e.target.value) })}
                                    />
                                </div>

                                <div className="space-y-3">
                                    <label className="text-xs font-black text-slate-400 uppercase tracking-[0.15em] px-1">Semester</label>
                                    <select
                                        required
                                        className="w-full px-6 py-4 rounded-2xl bg-slate-50 border-none outline-none focus:ring-2 focus:ring-[#0D9488]/20 transition-all appearance-none cursor-pointer font-bold text-slate-700"
                                        value={formData.semester}
                                        onChange={e => setFormData({ ...formData, semester: parseInt(e.target.value) })}
                                    >
                                        <option value={1}>Semester One</option>
                                        <option value={2}>Semester Two</option>
                                    </select>
                                </div>
                            </div>

                            <div className="space-y-3">
                                <label className="text-xs font-black text-slate-400 uppercase tracking-[0.15em] px-1">Document File (PDF)</label>
                                <div className="relative group">
                                    <input
                                        type="file"
                                        accept=".pdf"
                                        required
                                        onChange={e => setFile(e.target.files?.[0] || null)}
                                        className="absolute inset-0 w-full h-full opacity-0 cursor-pointer z-10"
                                    />
                                    <div className={`p-16 border-2 border-dashed rounded-[2rem] flex flex-col items-center justify-center space-y-4 transition-all duration-300
                                        ${file ? 'border-[#0D9488] bg-[#0D9488]/5 shadow-inner' : 'border-slate-100 group-hover:border-[#0D9488]/50 bg-slate-50/50'}
                                    `}>
                                        <div className={`h-20 w-20 rounded-[1.5rem] flex items-center justify-center transition-all duration-300 ${file ? 'bg-[#0D9488] text-white shadow-lg' : 'bg-white text-slate-300 group-hover:text-[#0D9488] shadow-sm'}`}>
                                            {file ? <CheckCircle2 size={40} /> : <UploadCloud size={40} />}
                                        </div>
                                        <div className="text-center">
                                            <p className="font-extrabold text-lg text-slate-700 tracking-tight">{file ? file.name : 'Select PDF Document'}</p>
                                            <p className="text-sm font-bold text-slate-400 mt-1">{file ? `${(file.size / (1024 * 1024)).toFixed(2)} MB` : 'Drag and drop or click to browse'}</p>
                                        </div>
                                    </div>
                                </div>
                            </div>

                            <button
                                type="submit"
                                disabled={uploading || !file}
                                className="w-full bg-[#0D9488] hover:bg-teal-700 text-white font-black text-lg py-5 rounded-[1.25rem] shadow-xl shadow-teal-700/20 transition-all transform active:scale-[0.98] disabled:opacity-50 flex items-center justify-center space-x-3"
                            >
                                <span>{uploading ? 'Uploading Paper...' : 'Complete Contribution'}</span>
                                {!uploading && <ChevronRight size={20} />}
                            </button>
                        </form>
                    </div>
                </div>

                <div className="space-y-8">
                    <div className="bg-slate-900 rounded-[2.5rem] p-10 text-white shadow-2xl relative overflow-hidden">
                        <div className="absolute top-0 right-0 p-8 opacity-10">
                            <Info size={120} />
                        </div>
                        <h3 className="text-xl font-black mb-6 relative z-10 tracking-tight">Upload Guidelines</h3>
                        <ul className="space-y-6 relative z-10">
                            <li className="flex items-start space-x-4">
                                <div className="h-6 w-6 rounded-full bg-[#0D9488] flex-shrink-0 flex items-center justify-center text-[10px] font-black">1</div>
                                <p className="text-sm font-medium text-slate-300 leading-relaxed">Ensure the document is a high-quality PDF scan or digital copy.</p>
                            </li>
                            <li className="flex items-start space-x-4">
                                <div className="h-6 w-6 rounded-full bg-[#0D9488] flex-shrink-0 flex items-center justify-center text-[10px] font-black">2</div>
                                <p className="text-sm font-medium text-slate-300 leading-relaxed">Verify that the course code and title match the document content.</p>
                            </li>
                            <li className="flex items-start space-x-4">
                                <div className="h-6 w-6 rounded-full bg-[#0D9488] flex-shrink-0 flex items-center justify-center text-[10px] font-black">3</div>
                                <p className="text-sm font-medium text-slate-300 leading-relaxed">Remove any personal student identification from the pages.</p>
                            </li>
                        </ul>
                    </div>

                    <div className="bg-white rounded-[2.5rem] p-8 border border-slate-100 shadow-sm flex items-center space-x-6">
                        <div className="h-16 w-16 bg-orange-100 text-orange-500 rounded-2xl flex items-center justify-center">
                            <FileText size={32} />
                        </div>
                        <div>
                             <p className="text-2xl font-black text-slate-800">{totalPapers.toLocaleString()}</p>
                             <p className="text-sm font-bold text-slate-400 uppercase tracking-widest">Total Papers</p>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    )
}
