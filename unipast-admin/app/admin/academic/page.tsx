'use client'



import { useState, useEffect } from 'react'
import { useSearchParams } from 'next/navigation'
import { supabase } from '@/lib/supabase'
import { addAcademicItem, updateAcademicItem, deleteAcademicItem, bulkAddCourses, bulkAddProgrammes } from './actions'
import { 
    Plus, Pencil, Trash2, Search, Building2, MoreVertical, 
    X, GraduationCap, BookOpen, Filter, Loader2, ListPlus, 
    Database, Cpu, Globe, Zap, Shield, LayoutGrid 
} from 'lucide-react'

type University = {
    id: string
    name: string
    category: string
}

type Faculty = {
    id: string
    name: string
    university_id: string
    university_name?: string
}

type Course = {
    id: string
    title: string
    code: string
    programme_id: string
    level: number
    semester: number
    programme_name?: string
    faculty_name?: string
    university_name?: string
}

type Programme = {
    id: string
    name: string
    faculty_id: string
    faculty_name?: string
    university_name?: string
}

type ActiveTab = 'university' | 'faculty' | 'programme' | 'course'

export default function AcademicPage() {
    const [activeTab, setActiveTab] = useState<ActiveTab>('university')
    const [unis, setUnis] = useState<University[]>([])
    const [faculties, setFaculties] = useState<Faculty[]>([])
    const [programmes, setProgrammes] = useState<Programme[]>([])
    const [courses, setCourses] = useState<Course[]>([])

    const [loading, setLoading] = useState(false)
    const [searchTerm, setSearchTerm] = useState('')
    const [showModal, setShowModal] = useState(false)
    const [modalType, setModalType] = useState<ActiveTab>('university')
    
    // Form States
    const [newUni, setNewUni] = useState({ name: '', category: 'Public' })
    const [newFaculty, setNewFaculty] = useState({ name: '', university_id: '' })
    const [newProgramme, setNewProgramme] = useState({ name: '', faculty_id: '', duration_years: 4 })
    const [newCourse, setNewCourse] = useState({ title: '', code: '', programme_id: '', level: 100, semester: 1 })
    const [isAdmin, setIsAdmin] = useState(false)
    const [userUniId, setUserUniId] = useState<string | null>(null)
    
    // Bulk Form State
    const [isBulkEntry, setIsBulkEntry] = useState(false)
    const [bulkText, setBulkText] = useState('')

    const [editingItem, setEditingItem] = useState<any>(null)
    const [saving, setSaving] = useState(false)

    const searchParams = useSearchParams()
    
    useEffect(() => {
        const checkRole = async () => {
            const { data: { user } } = await supabase.auth.getUser()
            if (user) {
                const { data } = await supabase.from('profiles').select('isAdmin, role, is_rep, university_id').eq('id', user.id).single()
                setIsAdmin(data?.isAdmin || data?.role === 'admin')
                setUserUniId(data?.university_id || null)
            }
        }
        checkRole()
        
        const queryUni = searchParams.get('university')
        if (queryUni) {
            setSearchTerm(queryUni)
            setActiveTab('university')
        }
        fetchAllData()
    }, [searchParams])

    async function fetchAllData() {
        setLoading(true)
        try {
            const { data: { user } } = await supabase.auth.getUser()
            if (!user) return

            const { data: profile } = await supabase.from('profiles').select('isAdmin, role, university_id').eq('id', user.id).single()
            const isRoot = profile?.isAdmin || profile?.role === 'admin'
            const uniId = profile?.university_id

            // Fetch Unis
            let uniQuery = supabase.from('universities').select('*').order('name')
            if (!isRoot && uniId) uniQuery = uniQuery.eq('id', uniId)
            const { data: u } = await uniQuery
            if (u) setUnis(u)
            
            // Fetch Faculties
            let facQuery = supabase.from('faculties').select('*, universities(name)').order('name')
            if (!isRoot && uniId) facQuery = facQuery.eq('university_id', uniId)
            const { data: f } = await facQuery
            if (f) setFaculties(f.map(item => ({ ...item, university_name: (item.universities as any)?.name })))
            
            // Fetch Programmes
            let progQuery = supabase.from('programmes').select('*, faculties!inner(*, universities(name))').order('name')
            if (!isRoot && uniId) progQuery = progQuery.eq('faculties.university_id', uniId)
            const { data: p } = await progQuery
            if (p) setProgrammes(p.map(item => ({ 
                ...item, 
                faculty_name: (item.faculties as any)?.name,
                university_name: (item.faculties as any)?.universities?.name
            })))

            // Fetch Courses
            let courseQuery = supabase.from('courses').select('*, programmes!inner(*, faculties!inner(*, universities(name)))').order('title')
            if (!isRoot && uniId) courseQuery = courseQuery.eq('programmes.faculties.university_id', uniId)
            const { data: c } = await courseQuery
            if (c) setCourses(c.map(item => ({ 
                ...item, 
                programme_name: (item.programmes as any)?.name,
                faculty_name: (item.programmes as any)?.faculties?.name,
                university_name: (item.programmes as any)?.faculties?.universities?.name
            })))
        } catch (error) {
            console.error('Error fetching academic data:', error)
        } finally {
            setLoading(false)
        }
    }

    async function handleAdd(e: React.FormEvent) {
        e.preventDefault()
        setSaving(true)
        let table = ''
        let payload = {}

        if (modalType === 'university') {
            if (!isAdmin) {
                alert('Restricted: Only administrators can initialize Institutional Nodes.')
                setSaving(false)
                return
            }
            table = 'universities'
            payload = newUni
        } else if (modalType === 'faculty') {
            table = 'faculties'
            payload = newFaculty
        } else if (modalType === 'programme') {
            table = 'programmes'
            
            if (isBulkEntry) {
                const lines = bulkText.split('\n').filter(l => l.trim() !== '')
                const progsToInsert = lines.map(line => ({
                    name: line.trim(),
                    faculty_id: newProgramme.faculty_id,
                    duration_years: newProgramme.duration_years
                }))

                if (progsToInsert.length === 0) {
                    alert('No valid programmes found to parse.')
                    setSaving(false)
                    return
                }

                const result = await bulkAddProgrammes(progsToInsert)
                if (!result.error) {
                    setShowModal(false)
                    setBulkText('')
                    setIsBulkEntry(false)
                    setNewProgramme({ name: '', faculty_id: '', duration_years: 4 })
                    fetchAllData()
                } else {
                    alert('Error adding bulk programmes: ' + result.error)
                }
                setSaving(false)
                return
            }
            
            payload = newProgramme
        } else {
            table = 'courses'
            
            if (isBulkEntry) {
                // Parse bulk entries
                const lines = bulkText.split('\n').filter(l => l.trim() !== '')
                const coursesToInsert = lines.map(line => {
                    const parts = line.split('-')
                    const code = parts[0]?.trim() || ''
                    const title = parts.slice(1).join('-').trim() || ''
                    return {
                        code,
                        title: title || code, // Fallback if no dash
                        programme_id: newCourse.programme_id,
                        level: newCourse.level,
                        semester: newCourse.semester
                    }
                })

                if (coursesToInsert.length === 0) {
                    alert('No valid courses found to parse.')
                    setSaving(false)
                    return
                }

                const result = await bulkAddCourses(coursesToInsert)
                if (!result.error) {
                    setShowModal(false)
                    setBulkText('')
                    setIsBulkEntry(false)
                    setNewCourse({ title: '', code: '', programme_id: '', level: 100, semester: 1 })
                    fetchAllData()
                } else {
                    alert('Error adding bulk items: ' + result.error)
                }
                setSaving(false)
                return
            } else {
                payload = newCourse
            }
        }

        const result = await addAcademicItem(table, payload)
        if (!result.error) {
            setShowModal(false)
            setNewUni({ name: '', category: 'Public' })
            setNewFaculty({ name: '', university_id: '' })
            setNewProgramme({ name: '', faculty_id: '', duration_years: 4 })
            setNewCourse({ title: '', code: '', programme_id: '', level: 100, semester: 1 })
            fetchAllData()
        } else {
            alert('Error adding item: ' + result.error)
        }
        setSaving(false)
    }

    async function handleDelete(id: string, table: string) {
        if (table === 'universities' && !isAdmin) {
            alert('Restricted: Deletion of Institutional Nodes is restricted to root administrators.')
            return
        }
        if (!confirm('Are you sure you want to delete this item? This action cannot be undone.')) return
        
        const result = await deleteAcademicItem(table, id)
        if (!result.error) {
            fetchAllData()
        } else {
            alert('Error deleting item: ' + result.error)
        }
    }

    async function handleEdit(e: React.FormEvent) {
        e.preventDefault()
        if (!editingItem) return
        setSaving(true)

        let table = ''
        let payload = {}

        if (modalType === 'university') {
            if (!isAdmin) {
                alert('Restricted: Reconfiguration of Institutional Nodes is restricted to root administrators.')
                setSaving(false)
                return
            }
            table = 'universities'
            payload = { name: editingItem.name, category: editingItem.category }
        } else if (modalType === 'faculty') {
            table = 'faculties'
            payload = { name: editingItem.name, university_id: editingItem.university_id }
        } else if (modalType === 'programme') {
            table = 'programmes'
            payload = { name: editingItem.name, faculty_id: editingItem.faculty_id }
        } else {
            table = 'courses'
            payload = { 
                title: editingItem.title, 
                code: editingItem.code, 
                programme_id: editingItem.programme_id,
                level: editingItem.level,
                semester: editingItem.semester
            }
        }

        const result = await updateAcademicItem(table, editingItem.id, payload)
        if (!result.error) {
            setShowModal(false)
            setEditingItem(null)
            fetchAllData()
        } else {
            alert('Error updating item: ' + result.error)
        }
        setSaving(false)
    }

    const filteredData = () => {
        if (activeTab === 'university') {
            return unis.filter(u => u.name.toLowerCase().includes(searchTerm.toLowerCase()))
        } else if (activeTab === 'faculty') {
            return faculties.filter(f => f.name.toLowerCase().includes(searchTerm.toLowerCase()) || f.university_name?.toLowerCase().includes(searchTerm.toLowerCase()))
        } else if (activeTab === 'programme') {
            return programmes.filter(p => p.name.toLowerCase().includes(searchTerm.toLowerCase()) || p.faculty_name?.toLowerCase().includes(searchTerm.toLowerCase()))
        } else {
            return courses.filter(c => c.title.toLowerCase().includes(searchTerm.toLowerCase()) || c.code.toLowerCase().includes(searchTerm.toLowerCase()) || c.programme_name?.toLowerCase().includes(searchTerm.toLowerCase()))
        }
    }

    const getTabTitle = () => {
        switch(activeTab) {
            case 'university': return 'Institutional Nodes';
            case 'faculty': return 'Faculty Sectors';
            case 'programme': return 'Programme Arrays';
            case 'course': return 'Course Core Units';
            default: return 'Core Setup';
        }
    }

    return (
        <div className="space-y-12 font-orbitron pb-32">
            <div className="flex flex-col xl:flex-row xl:items-end justify-between gap-8">
                <div className="space-y-4">
                    <div className="flex items-center gap-3">
                        <div className="p-2.5 bg-accent/10 rounded-xl border border-accent/20">
                            <Globe size={22} className="text-accent" />
                        </div>
                        <span className="text-[10px] font-black text-accent uppercase tracking-[0.4em]">Structure Architecture v9.2</span>
                    </div>
                    <h2 className="text-4xl font-black text-white tracking-tight uppercase">{getTabTitle()}</h2>
                    <p className="text-white/30 font-black text-[10px] uppercase tracking-[0.3em]">Configure the Global Academic Hierarchy of the UniPast Web</p>
                </div>
                
                {(activeTab !== 'university' || isAdmin) && (
                    <button
                        onClick={() => {
                            setModalType(activeTab)
                            // Auto-select parent if only one exists for non-admins
                            if (!isAdmin) {
                                if (activeTab === 'faculty' && unis.length === 1) {
                                    setNewFaculty({ ...newFaculty, university_id: unis[0].id })
                                } else if (activeTab === 'programme' && faculties.length === 1) {
                                    setNewProgramme({ ...newProgramme, faculty_id: faculties[0].id })
                                } else if (activeTab === 'course' && programmes.length === 1) {
                                    setNewCourse({ ...newCourse, programme_id: programmes[0].id })
                                }

                                // If userUniId is available but unis length logic above didn't catch it
                                if (activeTab === 'faculty' && userUniId && !newFaculty.university_id) {
                                    setNewFaculty({ ...newFaculty, university_id: userUniId })
                                }
                            }
                            setShowModal(true)
                        }}
                        className="relative px-10 py-5 rounded-[1.5rem] bg-primary text-card font-black text-xs uppercase tracking-[0.3em] overflow-hidden group/btn shadow-[0_0_30px_rgba(0,255,204,0.2)] hover:shadow-primary/40 transition-all duration-500 flex items-center gap-3"
                    >
                        <div className="absolute inset-0 bg-white/20 -translate-x-full group-hover/btn:translate-x-full transition-transform duration-700 skew-x-12" />
                        <Plus size={20} className="relative z-10" />
                        <span className="relative z-10">Deploy New {activeTab}</span>
                    </button>
                )}
            </div>

            <div className="flex flex-wrap gap-4 p-1.5 bg-card/20 backdrop-blur-3xl rounded-[2rem] border border-white/5 w-fit">
                {(['university', 'faculty', 'programme', 'course'] as ActiveTab[]).map(tab => (
                    <button
                        key={tab}
                        onClick={() => {
                            setActiveTab(tab)
                            setSearchTerm('')
                        }}
                        className={`px-10 py-4 rounded-[1.5rem] font-black text-[10px] uppercase tracking-[0.3em] transition-all duration-500 relative ${
                            activeTab === tab 
                                ? 'bg-primary text-card shadow-lg' 
                                : 'text-white/30 hover:text-white hover:bg-white/5'
                        }`}
                    >
                        {tab}s
                    </button>
                ))}
            </div>

            <div className="bg-card/20 backdrop-blur-3xl rounded-[3rem] border border-white/5 overflow-hidden shadow-2xl animate-in fade-in duration-1000">
                <div className="p-10 border-b border-white/5 flex flex-col md:flex-row md:items-center justify-between gap-6">
                    <div className="relative max-w-lg w-full group">
                        <div className="absolute left-6 top-1/2 -translate-y-1/2 text-white/20 group-focus-within:text-primary transition-colors">
                            <Search size={22} />
                        </div>
                        <input
                            type="text"
                            placeholder={`SCAN ${activeTab.toUpperCase()} ARCHIVES...`}
                            value={searchTerm}
                            onChange={(e) => setSearchTerm(e.target.value)}
                            className="w-full pl-16 pr-8 py-5 rounded-2xl bg-white/5 border border-white/5 outline-none focus:ring-4 focus:ring-primary/5 focus:border-primary/20 transition-all font-black text-[10px] text-white tracking-[0.2em] placeholder:text-white/10 uppercase"
                        />
                    </div>
                </div>

                <div className="overflow-x-auto">
                    <table className="w-full text-left">
                        <thead>
                            <tr className="bg-white/[0.02] border-white/5">
                                <th className="px-10 py-8 text-[9px] font-black text-white/30 uppercase tracking-[0.4em]">{activeTab.toUpperCase()} IDENTIFIER</th>
                                <th className="px-10 py-8 text-[9px] font-black text-white/30 uppercase tracking-[0.4em]">AFFILIATION SECTOR</th>
                                <th className="px-10 py-8 text-[9px] font-black text-white/30 uppercase tracking-[0.4em]">CONNECTIVITY</th>
                                <th className="px-10 py-8 text-[9px] font-black text-white/30 uppercase tracking-[0.4em] text-right">SYSTEM OPS</th>
                            </tr>
                        </thead>
                        <tbody className="divide-y divide-white/5">
                            {loading ? (
                                <tr>
                                    <td colSpan={4} className="px-10 py-40 text-center">
                                         <div className="relative w-24 h-24 mx-auto animate-spin">
                                            <div className="absolute inset-0 border-4 border-primary/20 rounded-full" />
                                            <div className="absolute inset-0 border-4 border-primary rounded-full border-t-transparent shadow-[0_0_20px_#00FFCC]" />
                                         </div>
                                    </td>
                                </tr>
                            ) : filteredData().length === 0 ? (
                                <tr>
                                    <td colSpan={4} className="px-10 py-40 text-center text-white/10 font-black tracking-[0.8em] uppercase text-sm">ARCHIVE PORTAL EMPTY</td>
                                </tr>
                            ) : (
                                filteredData().map((item: any) => (
                                    <tr key={item.id} className="hover:bg-white/[0.03] transition-colors duration-500 group">
                                        <td className="px-10 py-8">
                                            <div className="flex items-center gap-6">
                                                <div className="h-16 w-16 rounded-2xl bg-white/5 border border-white/5 flex items-center justify-center text-white/20 group-hover:text-primary group-hover:border-primary/40 transition-all duration-700">
                                                    {activeTab === 'university' && <Building2 size={28} />}
                                                    {activeTab === 'faculty' && <GraduationCap size={28} />}
                                                    {activeTab === 'programme' && <LayoutGrid size={28} />}
                                                    {activeTab === 'course' && <BookOpen size={28} />}
                                                </div>
                                                <div className="flex flex-col space-y-1 min-w-0 flex-1">
                                                    <span className="font-black text-white text-sm tracking-widest uppercase group-hover:text-primary transition-colors duration-500 truncate">{item.name || item.title}</span>
                                                    {item.code && (
                                                        <div className="flex items-center gap-2">
                                                            <div className="px-2 py-0.5 bg-primary/10 rounded text-primary text-[8px] font-black border border-primary/20 shrink-0">{item.code}</div>
                                                            <span className="text-[10px] text-white/20 font-black tracking-widest uppercase truncate">L{item.level} Cycle {item.semester}</span>
                                                        </div>
                                                    )}
                                                </div>
                                            </div>
                                        </td>
                                        <td className="px-10 py-8">
                                            {activeTab === 'university' ? (
                                                <div className="px-4 py-2 bg-secondary/10 border border-secondary/20 rounded-xl w-fit">
                                                    <span className="text-secondary text-[10px] font-black uppercase tracking-widest">{item.category || 'GENERIC'}</span>
                                                </div>
                                            ) : (
                                                <div className="flex flex-col space-y-1 min-w-0">
                                                    <span className="text-white/60 font-black text-[11px] uppercase tracking-widest truncate">{activeTab === 'faculty' ? item.university_name : activeTab === 'programme' ? item.faculty_name : item.programme_name}</span>
                                                    {item.university_name && (activeTab === 'course' || activeTab === 'programme') && <span className="text-[9px] text-white/20 font-black uppercase tracking-[0.2em] truncate">{item.university_name}</span>}
                                                </div>
                                            )}
                                        </td>
                                        <td className="px-10 py-8">
                                            <div className="flex items-center gap-3">
                                                <div className="w-2 h-2 rounded-full bg-primary shadow-[0_0_10px_#00FFCC]" />
                                                <span className="text-[9px] font-black text-white/20 uppercase tracking-[0.3em]">Operational</span>
                                            </div>
                                        </td>
                                        <td className="px-10 py-8 text-right">
                                            <div className="flex items-center justify-end gap-4 opacity-0 group-hover:opacity-100 transition-all duration-500 translate-x-4 group-hover:translate-x-0">
                                                {(activeTab !== 'university' || isAdmin) && (
                                                    <>
                                                        <button 
                                                            onClick={() => {
                                                                setEditingItem(item)
                                                                setModalType(activeTab)
                                                                setShowModal(true)
                                                            }}
                                                            className="h-12 w-12 bg-white/5 text-white/30 hover:text-primary hover:bg-primary/10 border border-white/5 hover:border-primary/40 rounded-2xl transition-all flex items-center justify-center group/opt"
                                                        >
                                                            <Pencil size={20} className="group-hover/opt:scale-110 transition-transform" />
                                                        </button>
                                                        <button 
                                                            onClick={() => handleDelete(item.id, activeTab === 'university' ? 'universities' : activeTab === 'faculty' ? 'faculties' : activeTab === 'programme' ? 'programmes' : 'courses')}
                                                            className="h-12 w-12 bg-white/5 text-white/30 hover:text-danger hover:bg-danger/10 border border-white/5 hover:border-danger/40 rounded-2xl transition-all flex items-center justify-center group/opt"
                                                        >
                                                            <Trash2 size={20} className="group-hover/opt:scale-110 transition-transform" />
                                                        </button>
                                                    </>
                                                )}
                                            </div>
                                            <div className="group-hover:hidden text-white/10">
                                                <MoreVertical size={22} />
                                            </div>
                                        </td>
                                    </tr>
                                ))
                            )}
                        </tbody>
                    </table>
                </div>
            </div>

            {/* Implementation Modal */}
            {showModal && (
                <div className="fixed inset-0 bg-bg/80 backdrop-blur-2xl flex items-center justify-center p-6 z-[200] animate-in fade-in duration-500">
                    <div className="bg-card border border-white/5 rounded-[3rem] max-w-2xl w-full shadow-[0_0_100px_rgba(0,0,0,0.5)] overflow-hidden animate-in zoom-in-95 duration-500 relative">
                        <div className="absolute top-0 left-0 w-full h-1 bg-primary" />
                        <div className="p-12 md:p-16 space-y-12">
                            <div className="flex items-center justify-between">
                                <div className="space-y-4">
                                    <div className="flex items-center gap-2">
                                        <Shield size={16} className="text-primary" />
                                        <span className="text-[10px] font-black text-primary uppercase tracking-[0.4em]">Node Configuration</span>
                                    </div>
                                    <h3 className="text-4xl font-black text-white tracking-tight uppercase">{editingItem ? 'Reconfigure' : 'Initialize'} {modalType}</h3>
                                </div>
                                <button 
                                    onClick={() => {
                                        setShowModal(false)
                                        setEditingItem(null)
                                    }}
                                    className="h-14 w-14 bg-white/5 hover:bg-white/10 text-white/20 hover:text-white rounded-2xl border border-white/5 transition-all flex items-center justify-center"
                                >
                                    <X size={28} />
                                </button>
                            </div>

                            <form onSubmit={editingItem ? handleEdit : handleAdd} className="space-y-10">
                                {modalType === 'university' && (
                                    <div className="space-y-8">
                                        <div className="space-y-4">
                                            <label className="text-[10px] font-black text-white/30 uppercase tracking-[0.3em] px-2">Institution Identity</label>
                                            <input
                                                type="text" required placeholder="IDENTIFIER NAME..."
                                                className="w-full px-8 py-6 bg-white/5 border border-white/5 rounded-2xl outline-none focus:ring-4 focus:ring-primary/5 focus:border-primary/30 font-black text-xs text-white tracking-widest uppercase placeholder:text-white/5"
                                                value={editingItem ? editingItem.name : newUni.name}
                                                onChange={e => editingItem ? setEditingItem({...editingItem, name: e.target.value}) : setNewUni({ ...newUni, name: e.target.value })}
                                            />
                                        </div>
                                        <div className="space-y-4">
                                            <label className="text-[10px] font-black text-white/30 uppercase tracking-[0.3em] px-2">Classification</label>
                                            <select
                                                required
                                                className="w-full px-8 py-6 bg-white/5 border border-white/5 rounded-2xl outline-none focus:ring-4 focus:ring-primary/5 focus:border-primary/30 font-black text-xs text-white/60 tracking-widest uppercase appearance-none"
                                                value={editingItem ? editingItem.category : newUni.category}
                                                onChange={e => editingItem ? setEditingItem({...editingItem, category: e.target.value}) : setNewUni({ ...newUni, category: e.target.value })}
                                            >
                                                <option value="Public" className="bg-bg">PUBLIC SECTOR</option>
                                                <option value="Private" className="bg-bg">PRIVATE SECTOR</option>
                                                <option value="Technical" className="bg-bg">TECHNICAL SECTOR</option>
                                                <option value="College" className="bg-bg">COLLEGE SECTOR</option>
                                            </select>
                                        </div>
                                    </div>
                                )}

                                {modalType === 'faculty' && (
                                    <div className="space-y-8">
                                        <div className="space-y-4">
                                            <label className="text-[10px] font-black text-white/30 uppercase tracking-[0.3em] px-2">Faculty Identification</label>
                                            <input
                                                type="text" required placeholder="SECTOR NAME..."
                                                className="w-full px-8 py-6 bg-white/5 border border-white/5 rounded-2xl outline-none focus:ring-4 focus:ring-primary/5 focus:border-primary/30 font-black text-xs text-white tracking-widest uppercase placeholder:text-white/5"
                                                value={editingItem ? editingItem.name : newFaculty.name}
                                                onChange={e => editingItem ? setEditingItem({...editingItem, name: e.target.value}) : setNewFaculty({ ...newFaculty, name: e.target.value })}
                                            />
                                        </div>
                                        <div className="space-y-4">
                                            <label className="text-[10px] font-black text-white/30 uppercase tracking-[0.3em] px-2">Primary Node Affiliation</label>
                                            <select
                                                required
                                                className="w-full px-8 py-6 bg-white/5 border border-white/5 rounded-2xl outline-none focus:ring-4 focus:ring-primary/5 focus:border-primary/30 font-black text-xs text-white/60 tracking-widest uppercase appearance-none"
                                                value={editingItem ? editingItem.university_id : newFaculty.university_id}
                                                onChange={e => editingItem ? setEditingItem({...editingItem, university_id: e.target.value}) : setNewFaculty({ ...newFaculty, university_id: e.target.value })}
                                            >
                                                <option value="" className="bg-bg">SELECT TARGET NODE</option>
                                                {unis.map(u => <option key={u.id} value={u.id} className="bg-bg">{u.name}</option>)}
                                            </select>
                                        </div>
                                    </div>
                                )}

                                {modalType === 'programme' && (
                                    <div className="space-y-8">
                                        {!editingItem && (
                                            <div className="flex justify-end">
                                                <button
                                                    type="button"
                                                    onClick={() => setIsBulkEntry(!isBulkEntry)}
                                                    className="px-5 py-2 rounded-xl bg-white/5 border border-white/10 text-[9px] font-black text-primary uppercase tracking-[0.2em] hover:bg-primary/10 transition-colors flex items-center gap-2"
                                                >
                                                    <ListPlus size={14} />
                                                    {isBulkEntry ? 'Standard Entry' : 'Bulk Uplink'}
                                                </button>
                                            </div>
                                        )}

                                        {!isBulkEntry ? (
                                            <div className="space-y-4">
                                                <label className="text-[10px] font-black text-white/30 uppercase tracking-[0.3em] px-2">Programme Signature</label>
                                                <input
                                                    type="text" required placeholder="ARRAY NAME..."
                                                    className="w-full px-8 py-6 bg-white/5 border border-white/5 rounded-2xl outline-none focus:ring-4 focus:ring-primary/5 focus:border-primary/30 font-black text-xs text-white tracking-widest uppercase placeholder:text-white/5"
                                                    value={editingItem ? editingItem.name : newProgramme.name}
                                                    onChange={e => editingItem ? setEditingItem({...editingItem, name: e.target.value}) : setNewProgramme({ ...newProgramme, name: e.target.value })}
                                                />
                                            </div>
                                        ) : (
                                            <div className="space-y-4">
                                                <label className="text-[10px] font-black text-white/30 uppercase tracking-[0.3em] px-2">Batch Metadata (One per line)</label>
                                                <textarea
                                                    required
                                                    placeholder="NAME_1&#10;NAME_2&#10;NAME_3..."
                                                    className="w-full h-48 px-8 py-6 bg-white/5 border border-white/5 rounded-2xl outline-none focus:ring-4 focus:ring-primary/5 focus:border-primary/30 font-black text-xs text-white tracking-widest uppercase placeholder:text-white/5 resize-none shadow-inner"
                                                    value={bulkText}
                                                    onChange={e => setBulkText(e.target.value)}
                                                />
                                            </div>
                                        )}

                                        {!editingItem && (
                                            <div className="space-y-4">
                                                <label className="text-[10px] font-black text-white/30 uppercase tracking-[0.3em] px-2">Cycle Duration (Years)</label>
                                                <input
                                                    type="number" required min={1} max={7}
                                                    className="w-full px-8 py-6 bg-white/5 border border-white/5 rounded-2xl outline-none focus:ring-4 focus:ring-primary/5 focus:border-primary/30 font-black text-xs text-white tracking-widest uppercase"
                                                    value={newProgramme.duration_years}
                                                    onChange={e => setNewProgramme({ ...newProgramme, duration_years: parseInt(e.target.value) })}
                                                />
                                            </div>
                                        )}
                                        <div className="space-y-4">
                                            <label className="text-[10px] font-black text-white/30 uppercase tracking-[0.3em] px-2">Sector Parent</label>
                                            <select
                                                required
                                                className="w-full px-8 py-6 bg-white/5 border border-white/5 rounded-2xl outline-none focus:ring-4 focus:ring-primary/5 focus:border-primary/30 font-black text-xs text-white/60 tracking-widest uppercase appearance-none"
                                                value={editingItem ? editingItem.faculty_id : newProgramme.faculty_id}
                                                onChange={e => editingItem ? setEditingItem({...editingItem, faculty_id: e.target.value}) : setNewProgramme({ ...newProgramme, faculty_id: e.target.value })}
                                            >
                                                <option value="" className="bg-bg">SELECT PARENT SECTOR</option>
                                                {faculties.map(f => <option key={f.id} value={f.id} className="bg-bg">{f.name} ({f.university_name})</option>)}
                                            </select>
                                        </div>
                                    </div>
                                )}

                                {modalType === 'course' && (
                                    <div className="space-y-8">
                                        {!editingItem && (
                                            <div className="flex justify-end">
                                                <button
                                                    type="button"
                                                    onClick={() => setIsBulkEntry(!isBulkEntry)}
                                                    className="px-5 py-2 rounded-xl bg-white/5 border border-white/10 text-[9px] font-black text-primary uppercase tracking-[0.2em] hover:bg-primary/10 transition-colors flex items-center gap-2"
                                                >
                                                    <ListPlus size={14} />
                                                    {isBulkEntry ? 'Standard Entry' : 'Bulk Uplink'}
                                                </button>
                                            </div>
                                        )}

                                        {!isBulkEntry ? (
                                            <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
                                                <div className="space-y-4">
                                                    <label className="text-[10px] font-black text-white/30 uppercase tracking-[0.3em] px-2">Unit Cipher (Code)</label>
                                                    <input
                                                        type="text" required placeholder="CS101..."
                                                        className="w-full px-8 py-6 bg-white/5 border border-white/5 rounded-2xl outline-none focus:ring-4 focus:ring-primary/5 focus:border-primary/30 font-black text-xs text-white tracking-widest uppercase placeholder:text-white/5"
                                                        value={editingItem ? editingItem.code : newCourse.code}
                                                        onChange={e => editingItem ? setEditingItem({...editingItem, code: e.target.value}) : setNewCourse({ ...newCourse, code: e.target.value })}
                                                    />
                                                </div>
                                                <div className="space-y-4">
                                                    <label className="text-[10px] font-black text-white/30 uppercase tracking-[0.3em] px-2">Unit Identifier (Title)</label>
                                                    <input
                                                        type="text" required placeholder="TITLE..."
                                                        className="w-full px-8 py-6 bg-white/5 border border-white/5 rounded-2xl outline-none focus:ring-4 focus:ring-primary/5 focus:border-primary/30 font-black text-xs text-white tracking-widest uppercase placeholder:text-white/5"
                                                        value={editingItem ? editingItem.title : newCourse.title}
                                                        onChange={e => editingItem ? setEditingItem({...editingItem, title: e.target.value}) : setNewCourse({ ...newCourse, title: e.target.value })}
                                                    />
                                                </div>
                                            </div>
                                        ) : (
                                            <div className="space-y-4">
                                                <label className="text-[10px] font-black text-white/30 uppercase tracking-[0.3em] px-2">Course Manifest (CODE - TITLE)</label>
                                                <textarea
                                                    required
                                                    placeholder="CS101 - INTRO&#10;CS102 - DATA..."
                                                    className="w-full h-48 px-8 py-6 bg-white/5 border border-white/5 rounded-2xl outline-none focus:ring-4 focus:ring-primary/5 focus:border-primary/30 font-black text-xs text-white tracking-widest uppercase placeholder:text-white/5 resize-none"
                                                    value={bulkText}
                                                    onChange={e => setBulkText(e.target.value)}
                                                />
                                            </div>
                                        )}

                                        <div className="grid grid-cols-2 gap-8">
                                            <div className="space-y-4">
                                                <label className="text-[10px] font-black text-white/30 uppercase tracking-[0.3em] px-2">Matrix Level</label>
                                                <select
                                                    required
                                                    className="w-full px-8 py-6 bg-white/5 border border-white/5 rounded-2xl outline-none focus:ring-4 focus:ring-primary/5 focus:border-primary/30 font-black text-xs text-white/60 tracking-widest uppercase appearance-none"
                                                    value={editingItem ? editingItem.level : newCourse.level}
                                                    onChange={e => editingItem ? setEditingItem({...editingItem, level: parseInt(e.target.value)}) : setNewCourse({ ...newCourse, level: parseInt(e.target.value) })}
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
                                                <label className="text-[10px] font-black text-white/30 uppercase tracking-[0.3em] px-2">Operational Cycle</label>
                                                <select
                                                    required
                                                    className="w-full px-8 py-6 bg-white/5 border border-white/5 rounded-2xl outline-none focus:ring-4 focus:ring-primary/5 focus:border-primary/30 font-black text-xs text-white/60 tracking-widest uppercase appearance-none"
                                                    value={editingItem ? editingItem.semester : newCourse.semester}
                                                    onChange={e => editingItem ? setEditingItem({...editingItem, semester: parseInt(e.target.value)}) : setNewCourse({ ...newCourse, semester: parseInt(e.target.value) })}
                                                >
                                                    <option value={1} className="bg-bg">CYCLE 1</option>
                                                    <option value={2} className="bg-bg">CYCLE 2</option>
                                                </select>
                                            </div>
                                        </div>

                                        <div className="space-y-4">
                                            <label className="text-[10px] font-black text-white/30 uppercase tracking-[0.3em] px-2">Array Parent</label>
                                            <select
                                                required
                                                className="w-full px-8 py-6 bg-white/5 border border-white/5 rounded-2xl outline-none focus:ring-4 focus:ring-primary/5 focus:border-primary/30 font-black text-xs text-white/60 tracking-widest uppercase appearance-none"
                                                value={editingItem ? editingItem.programme_id : newCourse.programme_id}
                                                onChange={e => editingItem ? setEditingItem({...editingItem, programme_id: e.target.value}) : setNewCourse({ ...newCourse, programme_id: e.target.value })}
                                            >
                                                <option value="" className="bg-bg">SELECT PARENT ARRAY</option>
                                                {programmes.map(p => <option key={p.id} value={p.id} className="bg-bg">{p.name} ({p.university_name})</option>)}
                                            </select>
                                        </div>
                                    </div>
                                )}

                                <div className="flex gap-6 pt-10">
                                    <button 
                                        type="button" 
                                        onClick={() => {
                                            setShowModal(false)
                                            setEditingItem(null)
                                        }} 
                                        className="flex-1 px-8 py-6 bg-white/5 border border-white/5 text-white/30 font-black text-[10px] uppercase tracking-[0.3em] rounded-2xl hover:bg-white/10 transition-colors"
                                    >
                                        Cancel Phase
                                    </button>
                                    <button 
                                        type="submit" 
                                        disabled={saving}
                                        className="flex-1 bg-primary text-card font-black text-[10px] uppercase tracking-[0.3em] rounded-2xl py-6 hover:bg-primary/90 transition-all shadow-[0_0_30px_rgba(0,255,204,0.2)] disabled:opacity-20 flex items-center justify-center gap-3"
                                    >
                                        {saving ? <Loader2 className="animate-spin" size={18} /> : <Zap size={18} />}
                                        <span>{saving ? 'Processing...' : 'Execute Commit'}</span>
                                    </button>
                                </div>
                            </form>
                        </div>
                    </div>
                </div>
            )}
        </div>
    )
}
