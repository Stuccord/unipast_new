'use client'

import Link from 'next/link'
import { usePathname } from 'next/navigation'
import { useState, useEffect } from 'react'
import {
    LayoutDashboard,
    Users,
    Upload,
    BarChart3,
    DollarSign,
    Folder,
    Settings,
    User,
    LogOut,
    Search,
    Bell,
    GraduationCap,
    Menu
} from 'lucide-react'
import { supabase } from '@/lib/supabase'
import { useRouter } from 'next/navigation'
import Image from 'next/image'

const navItems = [
    { name: 'Dashboard', href: '/admin', icon: LayoutDashboard },
    { name: 'Users', href: '/admin/reps', icon: Users },
    { name: 'Uploads', href: '/admin/upload', icon: Upload },
    { name: 'Analytics', href: '/admin/analytics', icon: BarChart3 },
    { name: 'Revenue', href: '/admin/financials', icon: DollarSign },
    { name: 'Content', href: '/admin/academic', icon: Folder },
    { name: 'Settings', href: '/admin/settings', icon: Settings },
    { name: 'Admin Profile', href: '/admin/profile', icon: User },
]

export default function AdminLayout({
    children,
}: {
    children: React.ReactNode
}) {
    const pathname = usePathname()
    const router = useRouter()
    const [profile, setProfile] = useState<any>(null)
    const [isSidebarOpen, setIsSidebarOpen] = useState(true)

    useEffect(() => {
        const fetchProfile = async () => {
            const { data: { user } } = await supabase.auth.getUser()
            if (user) {
                const { data } = await supabase.from('profiles').select('*').eq('id', user.id).single()
                if (data) setProfile(data)
            }
        }
        fetchProfile()
    }, [])

    // Responsiveness: Close sidebar on mobile by default, and on route change
    useEffect(() => {
        if (typeof window !== 'undefined' && window.innerWidth < 1024) {
            setIsSidebarOpen(false)
        }
    }, [])

    useEffect(() => {
        if (typeof window !== 'undefined' && window.innerWidth < 1024) {
            setIsSidebarOpen(false)
        }
    }, [pathname])

    const handleLogout = async () => {
        await supabase.auth.signOut()
        router.push('/login')
    }

    return (
        <div className="flex h-screen bg-slate-50 font-sans relative overflow-hidden">
            {/* Mobile Backdrop */}
            {isSidebarOpen && (
                <div 
                    className="fixed inset-0 bg-slate-900/50 backdrop-blur-sm z-40 lg:hidden transition-opacity duration-300"
                    onClick={() => setIsSidebarOpen(false)}
                />
            )}

            {/* Sidebar */}
            <aside className={`fixed inset-y-0 left-0 z-50 bg-[#1E293B] text-slate-300 flex flex-col shadow-xl transition-all duration-300 ease-in-out lg:static lg:inset-auto overflow-hidden ${
                isSidebarOpen 
                    ? 'translate-x-0 w-72 opacity-100' 
                    : '-translate-x-full lg:translate-x-0 lg:w-0 lg:opacity-0'
            }`}>
                <div className="p-6 flex items-center space-x-3">
                    <div className="bg-[#0D9488] p-2 rounded-lg">
                        <GraduationCap className="text-white" size={24} />
                    </div>
                    <h2 className="text-2xl font-bold text-white tracking-tight">UniPast</h2>
                </div>

                <nav className="flex-1 px-4 py-4 space-y-1">
                    {navItems.map((item) => {
                        const Icon = item.icon
                        const isActive = pathname === item.href
                        return (
                            <Link
                                key={item.href}
                                href={item.href}
                                className={`group flex items-center justify-between px-4 py-3 rounded-lg transition-all duration-200 relative ${isActive
                                        ? 'bg-[#334155] text-white'
                                        : 'hover:bg-[#334155] hover:text-white'
                                    }`}
                            >
                                <div className="flex items-center space-x-3">
                                    <Icon size={20} className={isActive ? 'text-[#0D9488]' : 'text-slate-400 group-hover:text-white'} />
                                    <span className="font-medium text-sm">{item.name}</span>
                                </div>
                                {isActive && (
                                    <div className="absolute left-0 top-1/2 -translate-y-1/2 w-1 h-6 bg-[#0D9488] rounded-r-full" />
                                )}
                            </Link>
                        )
                    })}
                </nav>

                <div className="p-4 border-t border-slate-700/50">
                    <div className="flex items-center space-x-3 px-4 py-2">
                        <div className="relative h-10 w-10 rounded-full overflow-hidden border-2 border-slate-600">
                             {profile?.avatar_url ? (
                                <img src={profile.avatar_url} alt="Profile" className="h-full w-full object-cover" />
                             ) : (
                                <div className="h-full w-full bg-slate-500 flex items-center justify-center text-white text-xs font-bold">
                                    {profile?.full_name ? profile.full_name.split(' ').map((n: string) => n[0]).join('') : 'A'}
                                </div>
                             )}
                        </div>
                        <div className="flex-1 min-w-0">
                            <p className="text-sm font-semibold text-white truncate">{profile?.full_name || 'Admin'}</p>
                        </div>
                        <button 
                            onClick={handleLogout}
                            className="text-slate-500 hover:text-white transition-colors"
                        >
                            <LogOut size={18} />
                        </button>
                    </div>
                </div>
            </aside>

            {/* Main Content */}
            <main className="flex-1 flex flex-col overflow-hidden">
                {/* Top Header */}
                <header className="h-20 bg-white border-b border-slate-200 flex items-center justify-between px-8 shrink-0 z-30">
                    <div className="flex items-center space-x-4">
                        <button 
                            onClick={() => setIsSidebarOpen(!isSidebarOpen)}
                            className="text-slate-400 hover:text-slate-600 lg:hidden p-2 rounded-lg hover:bg-slate-100 transition-colors"
                        >
                            <Menu size={24} />
                        </button>
                        <div className="flex items-center space-x-2">
                            <button 
                                onClick={() => setIsSidebarOpen(!isSidebarOpen)}
                                className="text-slate-400 hover:text-[#0D9488] transition-colors p-1 rounded-md hover:bg-slate-100"
                                title="Toggle Sidebar"
                            >
                                <Menu size={20} />
                            </button>
                            <h1 className="text-lg font-bold text-slate-800 tracking-tight">
                                {navItems.find(i => i.href === pathname)?.name || 'Dashboard'}
                            </h1>
                        </div>
                    </div>

                    <div className="flex items-center space-x-6">
                        <div className="relative w-80">
                            <Search className="absolute left-4 top-1/2 -translate-y-1/2 text-slate-400" size={18} />
                            <input
                                type="text"
                                placeholder="Search"
                                className="w-full bg-slate-100 border-none rounded-full py-2.5 pl-11 pr-4 text-sm focus:ring-2 focus:ring-[#0D9488]/20 transition-all outline-none"
                            />
                        </div>
                        
                        <div className="flex items-center space-x-4 text-slate-400">
                            <Link href="/admin/settings" className="hover:text-slate-600 transition-colors">
                                <Settings size={22} />
                            </Link>
                            <button 
                                onClick={() => alert('No new notifications')}
                                className="hover:text-slate-600 transition-colors relative"
                            >
                                <Bell size={22} />
                                <span className="absolute top-0 right-0 h-2 w-2 bg-red-500 rounded-full border-2 border-white"></span>
                            </button>
                        </div>

                        <div className="h-10 w-10 rounded-full overflow-hidden border border-slate-200">
                             {profile?.avatar_url ? (
                                <img src={profile.avatar_url} alt="Profile" className="h-full w-full object-cover" />
                             ) : (
                                <div className="h-full w-full bg-slate-200 flex items-center justify-center text-slate-500 text-xs font-bold">
                                    {profile?.full_name ? profile.full_name.split(' ').map((n: string) => n[0]).join('') : 'A'}
                                </div>
                             )}
                        </div>
                    </div>
                </header>

                {/* Content Area */}
                <div className="flex-1 overflow-y-auto bg-white">
                    <div className="p-8 max-w-[1600px] mx-auto">
                        {children}
                    </div>
                </div>
            </main>
        </div>
    )
}
