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
    Settings,
    LogOut,
    Search,
    Bell,
    GraduationCap,
    Menu,
    FileText,
    Zap,
    Cpu
} from 'lucide-react'
import { supabase } from '@/lib/supabase'
import { useRouter } from 'next/navigation'

const navItems = [
    { name: 'Terminal', href: '/admin', icon: LayoutDashboard },
    { name: 'Resources', href: '/admin/content', icon: FileText },
    { name: 'Injection', href: '/admin/upload', icon: Upload },
    { name: 'Core Setup', href: '/admin/academic', icon: GraduationCap },
    { name: 'Agents / Reps', href: '/admin/reps', icon: Users },
    { name: 'Revenue Flux', href: '/admin/financials', icon: DollarSign },
    { name: 'Neural Analytics', href: '/admin/analytics', icon: BarChart3 },
    { name: 'System Config', href: '/admin/settings', icon: Settings },
]

export default function AdminLayout({
    children,
}: {
    children: React.ReactNode
}) {
    const pathname = usePathname()
    const router = useRouter()
    const [profile, setProfile] = useState<any>(null)
    const [loading, setLoading] = useState(true)
    const [isSidebarOpen, setIsSidebarOpen] = useState(true)

    useEffect(() => {
        const fetchProfile = async () => {
            const { data: { user } } = await supabase.auth.getUser()
            if (user) {
                const { data } = await supabase.from('profiles').select('*').eq('id', user.id).single()
                if (data) {
                    setProfile(data)
                    const isRep = data.role === 'rep' || data.is_rep
                    const restrictedPaths = ['/admin/financials', '/admin/analytics', '/admin/academic', '/admin/reps', '/admin/settings']
                    if (isRep && restrictedPaths.includes(pathname)) {
                        router.push('/admin')
                    }
                }
            } else {
                router.push('/login')
            }
            setLoading(false)
        }
        fetchProfile()
    }, [pathname, router])

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

    const visibleNavItems = navItems.filter(item => {
        const isRep = profile?.role === 'rep' || profile?.is_rep
        if (isRep) {
            return ['Terminal', 'Resources', 'Injection'].includes(item.name)
        }
        return true
    })

    if (loading) {
        return (
            <div className="flex h-screen items-center justify-center bg-bg">
                <div className="relative w-20 h-20">
                    <div className="absolute inset-0 border-4 border-primary/20 rounded-full" />
                    <div className="absolute inset-0 border-4 border-primary rounded-full border-t-transparent animate-spin" />
                    <div className="absolute inset-0 flex items-center justify-center">
                        <span className="text-white font-orbitron font-black text-xl">U</span>
                    </div>
                </div>
            </div>
        )
    }

    return (
        <div className="flex h-screen bg-bg font-inter relative overflow-hidden text-white">
            {/* Background elements */}
            <div className="absolute top-0 right-0 w-[500px] h-[500px] bg-primary/5 rounded-full blur-[100px] -z-10" />
            <div className="absolute bottom-0 left-0 w-[300px] h-[300px] bg-secondary/5 rounded-full blur-[100px] -z-10" />
            
            {/* Mobile Backdrop */}
            {isSidebarOpen && (
                <div 
                    className="fixed inset-0 bg-black/60 backdrop-blur-md z-40 lg:hidden transition-opacity duration-300"
                    onClick={() => setIsSidebarOpen(false)}
                />
            )}

            {/* Sidebar */}
            <aside className={`fixed inset-y-0 left-0 z-50 bg-card/60 backdrop-blur-2xl border-r border-white/5 flex flex-col shadow-2xl transition-all duration-500 ease-in-out lg:static lg:inset-auto overflow-hidden ${
                isSidebarOpen 
                    ? 'translate-x-0 w-[280px] opacity-100' 
                    : '-translate-x-full lg:translate-x-0 lg:w-0 lg:opacity-0'
            }`}>
                <div className="p-8 pb-12 flex items-center justify-center">
                    <Link href="/admin" className="flex flex-col items-center">
                        <div className="relative w-12 h-12 mb-4">
                            <div className="absolute inset-0 bg-primary/20 rounded-xl blur-lg animate-pulse" />
                            <div className="relative w-full h-full bg-surface border border-primary/50 rounded-xl flex items-center justify-center shadow-[0_0_15px_rgba(0,255,204,0.2)]">
                                <span className="text-xl font-black font-orbitron text-primary tracking-tighter">U</span>
                            </div>
                        </div>
                        <h2 className="text-xl font-black text-white tracking-[0.2em] font-orbitron uppercase">UniPast</h2>
                        <span className="text-[8px] font-black text-primary/50 tracking-[0.4em] uppercase font-orbitron mt-1">Operational</span>
                    </Link>
                </div>

                <nav className="flex-1 px-4 space-y-2 overflow-y-auto">
                    <p className="px-4 pb-2 text-[10px] font-black text-white/20 uppercase tracking-[0.2em] font-orbitron">Systems Hub</p>
                    {visibleNavItems.map((item) => {
                        const Icon = item.icon
                        const isActive = pathname === item.href
                        return (
                            <Link
                                key={item.href}
                                href={item.href}
                                className={`group flex items-center gap-4 px-4 py-3.5 rounded-2xl transition-all duration-300 relative ${isActive
                                        ? 'bg-primary/10 text-primary shadow-[inset_0_0_20px_rgba(0,255,204,0.05)]'
                                        : 'hover:bg-white/5 text-white/50 hover:text-white'
                                    }`}
                            >
                                <Icon size={18} className={`${isActive ? 'text-primary' : 'text-white/30 group-hover:text-white'} transition-colors duration-300`} />
                                <span className={`text-[11px] font-black uppercase tracking-[0.15em] font-orbitron ${isActive ? 'translate-x-0' : 'translate-x-0 group-hover:translate-x-1'} transition-transform duration-300`}>
                                    {item.name}
                                </span>
                                {isActive && (
                                    <div className="absolute right-4 w-1 h-5 bg-primary rounded-full shadow-[0_0_10px_#00FFCC]" />
                                )}
                            </Link>
                        )
                    })}
                </nav>

                <div className="p-4 pt-8">
                    <div className="bg-white/5 rounded-3xl p-6 border border-white/5 relative overflow-hidden group hover:border-primary/20 transition-colors">
                        <div className="absolute top-0 right-0 w-16 h-16 bg-primary/5 rounded-full blur-xl group-hover:bg-primary/10 transition-colors" />
                        <div className="flex items-center gap-4 relative z-10">
                            <div className="h-12 w-12 rounded-2xl overflow-hidden border-2 border-white/10 group-hover:border-primary/30 transition-all flex-shrink-0">
                                 {profile?.avatar_url ? (
                                    <img src={profile.avatar_url} alt="Profile" className="h-full w-full object-cover" />
                                 ) : (
                                    <div className="h-full w-full bg-surface flex items-center justify-center text-white/50 text-xs font-bold font-orbitron uppercase">
                                        {profile?.full_name ? profile.full_name.split(' ').map((n: string) => n[0]).join('') : 'A'}
                                    </div>
                                 )}
                            </div>
                            <div className="flex-1 min-w-0">
                                <p className="text-[11px] font-black text-white truncate font-orbitron uppercase tracking-wider">{profile?.full_name || 'Administrator'}</p>
                                <p className="text-[9px] font-black text-primary/50 uppercase tracking-[0.1em] font-orbitron mt-0.5">{profile?.role || 'Root Access'}</p>
                            </div>
                        </div>
                        <button 
                            onClick={handleLogout}
                            className="mt-6 w-full py-3 bg-danger/10 hover:bg-danger/20 text-danger text-[9px] font-black font-orbitron uppercase tracking-[0.3em] rounded-xl flex items-center justify-center gap-2 transition-all group/logout"
                        >
                            <LogOut size={14} className="group-hover/logout:-translate-x-1 transition-transform" />
                            Terminate Session
                        </button>
                    </div>
                </div>
            </aside>

            {/* Main Content */}
            <main className="flex-1 flex flex-col overflow-hidden relative">
                {/* Top Header */}
                <header className="h-[90px] bg-bg/40 backdrop-blur-xl border-b border-white/5 flex items-center justify-between px-10 shrink-0 z-30">
                    <div className="flex items-center space-x-6">
                        <button 
                            onClick={() => setIsSidebarOpen(!isSidebarOpen)}
                            className="text-white/40 hover:text-primary p-2 bg-white/5 border border-white/5 rounded-xl transition-all lg:hidden"
                        >
                            <Menu size={22} />
                        </button>
                        <div className="flex items-center gap-3">
                            <div className="p-2.5 bg-primary/10 rounded-xl border border-primary/20">
                                <Cpu size={20} className="text-primary" />
                            </div>
                            <div>
                                <h1 className="text-[10px] font-black text-primary/50 uppercase tracking-[0.3em] font-orbitron leading-none mb-1.5">
                                    Systems Interface
                                </h1>
                                <p className="text-base font-black text-white uppercase tracking-[0.1em] font-orbitron">
                                    {navItems.find(i => i.href === pathname)?.name || 'Dashboard'}
                                </p>
                            </div>
                        </div>
                    </div>

                    <div className="hidden md:flex items-center space-x-8">
                        <div className="relative h-[48px]">
                            <Search className="absolute left-4 top-1/2 -translate-y-1/2 text-white/20 group-focus-within:text-primary transition-colors" size={18} />
                            <input
                                type="text"
                                placeholder="Neural Search Engine"
                                className="h-full bg-white/5 border border-white/5 rounded-2xl pl-12 pr-6 text-xs font-black font-orbitron tracking-widest text-white/60 focus:ring-4 focus:ring-primary/5 focus:border-primary/30 transition-all outline-none w-[320px] placeholder:text-white/10 placeholder:uppercase"
                            />
                        </div>
                        
                        <div className="flex items-center gap-4">
                            <button 
                                onClick={() => alert('Neural connection stable. No alerts.')}
                                className="w-12 h-12 flex items-center justify-center rounded-2xl bg-white/5 border border-white/5 text-white/30 hover:text-primary hover:border-primary/20 transition-all relative group"
                            >
                                <Bell size={20} className="group-hover:animate-bounce" />
                                <span className="absolute top-3.5 right-3.5 h-2 w-2 bg-primary rounded-full border-2 border-bg shadow-[0_0_10px_#00FFCC]"></span>
                            </button>
                            
                            <div className="flex items-center gap-4 pl-4 border-l border-white/5">
                                <div className="text-right">
                                    <p className="text-[10px] font-black text-white uppercase tracking-[0.1em] font-orbitron leading-none mb-1">Status</p>
                                    <p className="text-[9px] font-black text-primary uppercase tracking-[0.2em] font-orbitron flex items-center gap-2">
                                        Active
                                        <span className="w-1.5 h-1.5 rounded-full bg-primary animate-pulse shadow-[0_0_8px_#00FFCC]" />
                                    </p>
                                </div>
                            </div>
                        </div>
                    </div>
                </header>

                {/* Content Area */}
                <div className="flex-1 overflow-y-auto custom-scrollbar relative">
                    <div className="p-10 max-w-[1600px] mx-auto animate-in fade-in slide-in-from-bottom-4 duration-700">
                        {children}
                    </div>
                </div>

                <style jsx global>{`
                    .custom-scrollbar::-webkit-scrollbar {
                        width: 4px;
                    }
                    .custom-scrollbar::-webkit-scrollbar-track {
                        background: rgba(255, 255, 255, 0.02);
                    }
                    .custom-scrollbar::-webkit-scrollbar-thumb {
                        background: rgba(0, 255, 204, 0.1);
                        border-radius: 10px;
                    }
                    .custom-scrollbar::-webkit-scrollbar-thumb:hover {
                        background: rgba(0, 255, 204, 0.3);
                    }
                `}</style>
            </main>
        </div>
    )
}
