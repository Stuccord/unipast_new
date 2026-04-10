'use client'

import { useState, useEffect } from 'react'
import { User, Mail, Shield, Camera, Edit2, Loader2, CheckCircle2, AlertCircle } from 'lucide-react'
import { supabase } from '@/lib/supabase'

export default function ProfilePage() {
    const [profile, setProfile] = useState<any>(null)
    const [loading, setLoading] = useState(true)
    const [updating, setUpdating] = useState(false)
    const [uploadingImage, setUploadingImage] = useState(false)
    const [status, setStatus] = useState<{ type: 'success' | 'error', message: string } | null>(null)

    const [formData, setFormData] = useState({
        full_name: '',
        email: ''
    })

    useEffect(() => {
        fetchProfile()
    }, [])

    async function fetchProfile() {
        setLoading(true)
        try {
            const { data: { user } } = await supabase.auth.getUser()
            if (user) {
                const { data, error } = await supabase
                    .from('profiles')
                    .select('*')
                    .eq('id', user.id)
                    .single()
                
                if (data) {
                    setProfile(data)
                    setFormData({
                        full_name: data.full_name || '',
                        email: data.email || user.email || ''
                    })
                }
            }
        } catch (error) {
            console.error('Error fetching profile:', error)
        } finally {
            setLoading(false)
        }
    }

    async function handleUpdate(e: React.FormEvent) {
        e.preventDefault()
        setUpdating(true)
        setStatus(null)
        try {
            const { data: { user } } = await supabase.auth.getUser()
            if (!user) throw new Error('No user found')

            const { error } = await supabase
                .from('profiles')
                .update({
                    full_name: formData.full_name,
                    email: formData.email
                })
                .eq('id', user.id)

            if (error) throw error
            
            setStatus({ type: 'success', message: 'Profile updated successfully!' })
            fetchProfile()
        } catch (error: any) {
            setStatus({ type: 'error', message: error.message || 'Error updating profile' })
        } finally {
            setUpdating(false)
        }
    }

    async function handleImageUpload(e: React.ChangeEvent<HTMLInputElement>) {
        const file = e.target.files?.[0]
        if (!file) return

        setUploadingImage(true)
        setStatus(null)

        try {
            const { data: { user } } = await supabase.auth.getUser()
            if (!user) throw new Error('No user found')

            const fileExt = file.name.split('.').pop()
            const filePath = `${user.id}/${Math.random()}.${fileExt}`

            const { error: uploadError } = await supabase.storage
                .from('profiles')
                .upload(filePath, file)

            if (uploadError) throw uploadError

            const { data: { publicUrl } } = supabase.storage
                .from('profiles')
                .getPublicUrl(filePath)

            const { error: updateError } = await supabase
                .from('profiles')
                .update({ avatar_url: publicUrl })
                .eq('id', user.id)

            if (updateError) throw updateError

            setStatus({ type: 'success', message: 'Profile picture updated!' })
            fetchProfile()
        } catch (error: any) {
            setStatus({ type: 'error', message: error.message || 'Error uploading image' })
        } finally {
            setUploadingImage(false)
        }
    }

    if (loading) {
        return (
            <div className="flex h-[60vh] items-center justify-center">
                <Loader2 className="animate-spin text-[#0D9488]" size={48} />
            </div>
        )
    }

    return (
        <div className="space-y-10 max-w-4xl">
            <div className="flex flex-col space-y-2">
                <h2 className="text-3xl font-bold text-slate-800">Admin Profile</h2>
                <p className="text-slate-500 font-medium">Manage your personal information and profile settings</p>
            </div>

            <div className="bg-white rounded-[2.5rem] border border-slate-100 shadow-sm overflow-hidden">
                <div className="p-12 flex flex-col md:flex-row items-center space-y-8 md:space-y-0 md:space-x-12 bg-slate-50/50">
                    <div className="relative">
                        <div className="h-40 w-40 rounded-full bg-slate-200 border-4 border-white shadow-xl flex items-center justify-center overflow-hidden">
                             {profile?.avatar_url ? (
                                <img src={profile.avatar_url} alt="Profile" className="h-full w-full object-cover" />
                             ) : (
                                <div className="text-6xl font-black text-slate-400">
                                    {formData.full_name ? formData.full_name.split(' ').map((n: string) => n[0]).join('') : 'A'}
                                </div>
                             )}
                        </div>
                        <label className="absolute bottom-1 right-1 p-3 bg-[#0D9488] text-white rounded-full shadow-lg hover:scale-110 transition-transform cursor-pointer">
                            {uploadingImage ? <Loader2 className="animate-spin" size={20} /> : <Camera size={20} />}
                            <input type="file" className="hidden" accept="image/*" onChange={handleImageUpload} disabled={uploadingImage} />
                        </label>
                    </div>
                    <div className="text-center md:text-left space-y-2">
                        <h3 className="text-3xl font-black text-slate-800 tracking-tight">{formData.full_name || 'Administrator'}</h3>
                        <p className="text-[#0D9488] font-bold text-lg uppercase tracking-widest">{profile?.role || 'Lead Administrator'}</p>
                        <div className="flex items-center justify-center md:justify-start space-x-2 text-slate-400 font-medium">
                            <Mail size={16} />
                            <span>{formData.email}</span>
                        </div>
                    </div>
                </div>

                <div className="p-12 space-y-10">
                    {status && (
                        <div className={`p-6 rounded-2xl border flex items-center space-x-4 ${
                            status.type === 'success' ? 'bg-emerald-50 border-emerald-100 text-emerald-700' : 'bg-rose-50 border-rose-100 text-rose-700'
                        }`}>
                            {status.type === 'success' ? <CheckCircle2 size={24} /> : <AlertCircle size={24} />}
                            <p className="font-bold">{status.message}</p>
                        </div>
                    )}

                    <form onSubmit={handleUpdate} className="grid grid-cols-1 md:grid-cols-2 gap-10">
                        <div className="space-y-3">
                            <label className="text-xs font-black text-slate-400 uppercase tracking-widest px-1">Full Name</label>
                            <input 
                                type="text" 
                                value={formData.full_name}
                                onChange={(e) => setFormData({ ...formData, full_name: e.target.value })}
                                className="w-full bg-slate-50 border-none rounded-2xl py-4 px-6 text-slate-800 font-bold focus:ring-2 focus:ring-[#0D9488]/20 transition-all outline-none" 
                            />
                        </div>
                        <div className="space-y-3">
                            <label className="text-xs font-black text-slate-400 uppercase tracking-widest px-1">Email Address</label>
                            <input 
                                type="email" 
                                value={formData.email}
                                onChange={(e) => setFormData({ ...formData, email: e.target.value })}
                                className="w-full bg-slate-50 border-none rounded-2xl py-4 px-6 text-slate-800 font-bold focus:ring-2 focus:ring-[#0D9488]/20 transition-all outline-none" 
                            />
                        </div>
                        <div className="space-y-3">
                            <label className="text-xs font-black text-slate-400 uppercase tracking-widest px-1">Role</label>
                            <div className="w-full bg-slate-100 rounded-2xl py-4 px-6 text-slate-500 font-bold flex items-center justify-between">
                                <span className="capitalize">{profile?.role || 'Administrator'}</span>
                                <Shield size={18} />
                            </div>
                        </div>
                        <div className="space-y-3">
                            <label className="text-xs font-black text-slate-400 uppercase tracking-widest px-1">Level / Status</label>
                            <div className="w-full bg-slate-100 rounded-2xl py-4 px-6 text-slate-500 font-bold flex items-center justify-between">
                                <span>{profile?.level || 'N/A'} - {profile?.status || 'Active'}</span>
                                <Edit2 size={18} />
                            </div>
                        </div>

                        <div className="md:col-span-2 pt-6 border-t border-slate-100 flex justify-end space-x-4">
                            <button 
                                type="button"
                                onClick={() => fetchProfile()}
                                className="px-8 py-4 text-slate-500 font-bold hover:text-slate-800 transition-colors"
                            >
                                Discard
                            </button>
                            <button 
                                type="submit"
                                disabled={updating}
                                className="bg-[#0D9488] hover:bg-teal-700 text-white font-black py-4 px-10 rounded-2xl transition-all shadow-lg shadow-teal-700/20 disabled:opacity-50 flex items-center space-x-2"
                            >
                                {updating && <Loader2 className="animate-spin" size={20} />}
                                <span>{updating ? 'Updating...' : 'Update Profile'}</span>
                            </button>
                        </div>
                    </form>
                </div>
            </div>
        </div>
    )
}
