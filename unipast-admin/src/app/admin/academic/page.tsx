'use client'

import { useState, useEffect } from 'react'
import { supabase } from '@/lib/supabase'
import { addAcademicItem, updateAcademicItem, deleteAcademicItem } from './actions'
import { Plus, Pencil, Trash2, Search, Building2, MoreVertical, MapPin, X, GraduationCap, BookOpen, Filter, Loader2 } from 'lucide-react'

type University = {
    id: string
    name: string
}

type Faculty = {
    id: string
    name: string
    university_id: string
    university_name?: string
}

type Course = {
    id: string
    name: string
    code: string
    faculty_id: string
    faculty_name?: string
    university_name?: string
}

type ActiveTab = 'university' | 'faculty' | 'course'

export default function AcademicPage() {
    const [activeTab, setActiveTab] = useState<ActiveTab>('university')
    const [unis, setUnis] = useState<University[]>([])
    const [faculties, setFaculties] = useState<Faculty[]>([])
    const [courses, setCourses] = useState<Course[]>([])

    const [loading, setLoading] = useState(false)
    const [searchTerm, setSearchTerm] = useState('')
    const [showModal, setShowModal] = useState(false)
    const [modalType, setModalType] = useState<ActiveTab>('university')
    
    // Form States
    const [newUni, setNewUni] = useState({ name: '' })
    const [newFaculty, setNewFaculty] = useState({ name: '', university_id: '' })
    const [newCourse, setNewCourse] = useState({ name: '', code: '', faculty_id: '' })

    const [editingItem, setEditingItem] = useState<any>(null)
    const [saving, setSaving] = useState(false)

    useEffect(() => {
        fetchAllData()
    }, [])

    async function fetchAllData() {
        setLoading(true)
        try {
            const { data: u } = await supabase.from('universities').select('*').order('name')
            if (u) setUnis(u)
            
            const { data: f } = await supabase.from('faculties').select('*, universities(name)').order('name')
            if (f) setFaculties(f.map(item => ({ ...item, university_name: (item.universities as any)?.name })))
            
            const { data: c } = await supabase.from('courses').select('*, faculties(*, universities(name))').order('name')
            if (c) setCourses(c.map(item => ({ 
                ...item, 
                faculty_name: (item.faculties as any)?.name,
                university_name: (item.faculties as any)?.universities?.name
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
            table = 'universities'
            payload = newUni
        } else if (modalType === 'faculty') {
            table = 'faculties'
            payload = newFaculty
        } else {
            table = 'courses'
            payload = newCourse
        }

        const result = await addAcademicItem(table, payload)
        if (!result.error) {
            setShowModal(false)
            setNewUni({ name: '' })
            setNewFaculty({ name: '', university_id: '' })
            setNewCourse({ name: '', code: '', faculty_id: '' })
            fetchAllData()
        } else {
            alert('Error adding item: ' + result.error)
        }
        setSaving(false)
    }

    async function handleDelete(id: string, table: string) {
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
            table = 'universities'
            payload = { name: editingItem.name }
        } else if (modalType === 'faculty') {
            table = 'faculties'
            payload = { name: editingItem.name, university_id: editingItem.university_id }
        } else {
            table = 'courses'
            payload = { name: editingItem.name, code: editingItem.code, faculty_id: editingItem.faculty_id }
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
        } else {
            return courses.filter(c => c.name.toLowerCase().includes(searchTerm.toLowerCase()) || c.code.toLowerCase().includes(searchTerm.toLowerCase()) || c.faculty_name?.toLowerCase().includes(searchTerm.toLowerCase()))
        }
    }

    return (
        <div className="space-y-10">
            <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-6">
                <div className="space-y-1">
                    <h2 className="text-3xl font-black text-slate-800 tracking-tight">Academic Management</h2>
                    <p className="text-slate-500 font-medium tracking-tight">Manage the academic hierarchy of institutions, faculties, and courses.</p>
                </div>
                <button
                    onClick={() => {
                        setModalType(activeTab)
                        setShowModal(true)
                    }}
                    className="bg-[#0D9488] hover:bg-teal-700 text-white font-bold py-4 px-8 rounded-2xl flex items-center space-x-3 transition-all shadow-xl shadow-teal-700/20"
                >
                    <Plus size={20} />
                    <span>Add {activeTab.charAt(0).toUpperCase() + activeTab.slice(1)}</span>
                </button>
            </div>

            {/* Tabs */}
            <div className="flex space-x-2 p-1 bg-slate-100 rounded-[1.5rem] w-fit">
                {(['university', 'faculty', 'course'] as ActiveTab[]).map(tab => (
                    <button
                        key={tab}
                        onClick={() => {
                            setActiveTab(tab)
                            setSearchTerm('')
                        }}
                        className={`px-8 py-3 rounded-xl font-black text-xs uppercase tracking-widest transition-all ${
                            activeTab === tab 
                                ? 'bg-white text-[#0D9488] shadow-sm' 
                                : 'text-slate-400 hover:text-slate-600'
                        }`}
                    >
                        {tab}s
                    </button>
                ))}
            </div>

            <div className="bg-white rounded-[2.5rem] border border-slate-100 shadow-sm overflow-hidden">
                <div className="p-8 bg-slate-50/50 border-b border-slate-100/50 flex flex-col md:flex-row md:items-center justify-between gap-4">
                    <div className="relative max-w-md w-full">
                        <Search className="absolute left-5 top-1/2 -translate-y-1/2 text-slate-400" size={20} />
                        <input
                            type="text"
                            placeholder={`Search ${activeTab}s...`}
                            value={searchTerm}
                            onChange={(e) => setSearchTerm(e.target.value)}
                            className="w-full pl-14 pr-6 py-4 rounded-2xl bg-white border-none outline-none focus:ring-2 focus:ring-[#0D9488]/20 transition-all font-medium text-slate-700 shadow-sm"
                        />
                    </div>
                </div>

                <div className="overflow-x-auto">
                    <table className="w-full text-left">
                        <thead>
                            <tr className="text-slate-400 font-black text-xs uppercase tracking-[0.2em]">
                                <th className="px-10 py-6">{activeTab === 'university' ? 'Institution' : activeTab === 'faculty' ? 'Faculty' : 'Course'}</th>
                                <th className="px-10 py-6">{activeTab === 'university' ? '' : 'Affiliation'}</th>
                                <th className="px-10 py-6">Status</th>
                                <th className="px-10 py-6 text-right">Actions</th>
                            </tr>
                        </thead>
                        <tbody className="divide-y divide-slate-100">
                            {loading ? (
                                <tr>
                                    <td colSpan={4} className="px-10 py-24 text-center">
                                         <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-[#0D9488] mx-auto"></div>
                                    </td>
                                </tr>
                            ) : filteredData().length === 0 ? (
                                <tr>
                                    <td colSpan={4} className="px-10 py-24 text-center text-slate-400 font-bold tracking-widest uppercase text-xs">No {activeTab}s found</td>
                                </tr>
                            ) : (
                                filteredData().map((item: any) => (
                                    <tr key={item.id} className="hover:bg-slate-50/50 transition duration-150 group">
                                        <td className="px-10 py-8">
                                            <div className="flex items-center space-x-4">
                                                <div className="h-14 w-14 rounded-2xl bg-[#0D9488]/5 flex items-center justify-center text-[#0D9488] border-2 border-white shadow-sm group-hover:scale-110 transition-transform duration-300">
                                                    {activeTab === 'university' && <Building2 size={24} />}
                                                    {activeTab === 'faculty' && <GraduationCap size={24} />}
                                                    {activeTab === 'course' && <BookOpen size={24} />}
                                                </div>
                                                <div>
                                                    <span className="font-black text-slate-800 text-lg tracking-tight">{item.name}</span>
                                                    {item.code && <p className="text-xs text-slate-400 font-bold">{item.code}</p>}
                                                </div>
                                            </div>
                                        </td>
                                        <td className="px-10 py-8">
                                            {activeTab === 'university' ? (
                                                <div className="flex items-center space-x-2 text-slate-500 font-bold text-sm">
                                                    <span>N/A</span>
                                                </div>
                                            ) : (
                                                <div className="flex flex-col">
                                                    <span className="text-slate-700 font-black text-sm">{activeTab === 'faculty' ? item.university_name : item.faculty_name}</span>
                                                    {item.university_name && activeTab === 'course' && <span className="text-xs text-slate-400 font-bold">{item.university_name}</span>}
                                                </div>
                                            )}
                                        </td>
                                        <td className="px-10 py-8">
                                            <span className="px-4 py-2 rounded-xl bg-emerald-50 text-emerald-600 text-[10px] font-black uppercase tracking-widest border border-emerald-100">Live</span>
                                        </td>
                                        <td className="px-10 py-8 text-right">
                                            <div className="flex items-center justify-end space-x-3 opacity-0 group-hover:opacity-100 transition-opacity">
                                                <button 
                                                    onClick={() => {
                                                        setEditingItem(item)
                                                        setModalType(activeTab)
                                                        setShowModal(true)
                                                    }}
                                                    className="p-3 bg-slate-50 text-slate-400 hover:text-[#0D9488] hover:bg-[#0D9488]/10 rounded-xl transition-all"
                                                >
                                                    <Pencil size={18} />
                                                </button>
                                                <button 
                                                    onClick={() => handleDelete(item.id, activeTab === 'university' ? 'universities' : activeTab === 'faculty' ? 'faculties' : 'courses')}
                                                    className="p-3 bg-slate-50 text-slate-400 hover:text-rose-500 hover:bg-rose-50 rounded-xl transition-all"
                                                >
                                                    <Trash2 size={18} />
                                                </button>
                                            </div>
                                            <div className="group-hover:hidden text-slate-300">
                                                <MoreVertical size={20} />
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
                <div className="fixed inset-0 bg-slate-900/40 backdrop-blur-md flex items-center justify-center p-6 z-50 animate-in fade-in duration-300">
                    <div className="bg-white rounded-[2.5rem] max-w-lg w-full shadow-2xl overflow-hidden animate-in zoom-in-95 duration-300">
                        <div className="bg-[#0D9488] p-10 text-white relative">
                            <button 
                                onClick={() => {
                                    setShowModal(false)
                                    setEditingItem(null)
                                }}
                                className="absolute top-8 right-8 text-white/50 hover:text-white transition-colors"
                            >
                                <X size={24} />
                            </button>
                            <h3 className="text-3xl font-black tracking-tight">{editingItem ? 'Edit' : 'Add'} {modalType}</h3>
                            <p className="text-teal-100 font-medium mt-2">{editingItem ? 'Modify existing' : 'Registers a new'} academic unit in the system.</p>
                        </div>
                        <form onSubmit={editingItem ? handleEdit : handleAdd} className="p-10 space-y-8">
                            {modalType === 'university' && (
                                <>
                                    <div className="space-y-3">
                                        <label className="text-xs font-black text-slate-400 uppercase tracking-widest px-1">University Name</label>
                                        <input
                                            type="text" required placeholder="e.g. University of Ghana"
                                            className="w-full px-6 py-4 bg-slate-50 border-none rounded-2xl outline-none focus:ring-2 focus:ring-[#0D9488]/20 font-bold text-slate-700"
                                            value={editingItem ? editingItem.name : newUni.name}
                                            onChange={e => editingItem ? setEditingItem({...editingItem, name: e.target.value}) : setNewUni({ ...newUni, name: e.target.value })}
                                        />
                                    </div>

                                </>
                            )}

                            {modalType === 'faculty' && (
                                <>
                                    <div className="space-y-3">
                                        <label className="text-xs font-black text-slate-400 uppercase tracking-widest px-1">Faculty Name</label>
                                        <input
                                            type="text" required placeholder="e.g. Faculty of Social Sciences"
                                            className="w-full px-6 py-4 bg-slate-50 border-none rounded-2xl outline-none focus:ring-2 focus:ring-[#0D9488]/20 font-bold text-slate-700"
                                            value={editingItem ? editingItem.name : newFaculty.name}
                                            onChange={e => editingItem ? setEditingItem({...editingItem, name: e.target.value}) : setNewFaculty({ ...newFaculty, name: e.target.value })}
                                        />
                                    </div>
                                    <div className="space-y-3">
                                        <label className="text-xs font-black text-slate-400 uppercase tracking-widest px-1">Parent University</label>
                                        <select
                                            required
                                            className="w-full px-6 py-4 bg-slate-50 border-none rounded-2xl outline-none focus:ring-2 focus:ring-[#0D9488]/20 font-bold text-slate-700 appearance-none"
                                            value={editingItem ? editingItem.university_id : newFaculty.university_id}
                                            onChange={e => editingItem ? setEditingItem({...editingItem, university_id: e.target.value}) : setNewFaculty({ ...newFaculty, university_id: e.target.value })}
                                        >
                                            <option value="">Select University</option>
                                            {unis.map(u => <option key={u.id} value={u.id}>{u.name}</option>)}
                                        </select>
                                    </div>
                                </>
                            )}

                            {modalType === 'course' && (
                                <>
                                    <div className="space-y-3">
                                        <label className="text-xs font-black text-slate-400 uppercase tracking-widest px-1">Course Code</label>
                                        <input
                                            type="text" required placeholder="e.g. CS101"
                                            className="w-full px-6 py-4 bg-slate-50 border-none rounded-2xl outline-none focus:ring-2 focus:ring-[#0D9488]/20 font-bold text-slate-700"
                                            value={editingItem ? editingItem.code : newCourse.code}
                                            onChange={e => editingItem ? setEditingItem({...editingItem, code: e.target.value}) : setNewCourse({ ...newCourse, code: e.target.value })}
                                        />
                                    </div>
                                    <div className="space-y-3">
                                        <label className="text-xs font-black text-slate-400 uppercase tracking-widest px-1">Course Name</label>
                                        <input
                                            type="text" required placeholder="e.g. Data Structures"
                                            className="w-full px-6 py-4 bg-slate-50 border-none rounded-2xl outline-none focus:ring-2 focus:ring-[#0D9488]/20 font-bold text-slate-700"
                                            value={editingItem ? editingItem.name : newCourse.name}
                                            onChange={e => editingItem ? setEditingItem({...editingItem, name: e.target.value}) : setNewCourse({ ...newCourse, name: e.target.value })}
                                        />
                                    </div>
                                    <div className="space-y-3">
                                        <label className="text-xs font-black text-slate-400 uppercase tracking-widest px-1">Parent Faculty</label>
                                        <select
                                            required
                                            className="w-full px-6 py-4 bg-slate-50 border-none rounded-2xl outline-none focus:ring-2 focus:ring-[#0D9488]/20 font-bold text-slate-700 appearance-none"
                                            value={editingItem ? editingItem.faculty_id : newCourse.faculty_id}
                                            onChange={e => editingItem ? setEditingItem({...editingItem, faculty_id: e.target.value}) : setNewCourse({ ...newCourse, faculty_id: e.target.value })}
                                        >
                                            <option value="">Select Faculty</option>
                                            {faculties.map(f => <option key={f.id} value={f.id}>{f.name} ({f.university_name})</option>)}
                                        </select>
                                    </div>
                                </>
                            )}

                            <div className="flex space-x-4 pt-4">
                                <button 
                                    type="button" 
                                    onClick={() => {
                                        setShowModal(false)
                                        setEditingItem(null)
                                    }} 
                                    className="flex-1 px-8 py-5 border-2 border-slate-100 text-slate-400 font-black rounded-2xl hover:bg-slate-50 transition-colors"
                                >
                                    Cancel
                                </button>
                                <button 
                                    type="submit" 
                                    disabled={saving}
                                    className="flex-1 bg-[#0D9488] text-white font-black rounded-2xl py-5 hover:bg-teal-700 transition-all shadow-lg shadow-teal-700/20 disabled:opacity-50 flex items-center justify-center space-x-2"
                                >
                                    {saving && <Loader2 className="animate-spin" size={20} />}
                                    <span>{saving ? (editingItem ? 'Updating...' : 'Saving...') : (editingItem ? 'Update' : 'Save')}</span>
                                </button>
                            </div>
                        </form>
                    </div>
                </div>
            )}
        </div>
    )
}
