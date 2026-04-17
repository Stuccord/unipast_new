import { createBrowserClient } from '@supabase/ssr'

// Provide valid placeholder strings during Vercel's build phase if env vars are missing
const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL || 'https://placeholder.supabase.co'
const supabaseAnonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY || 'placeholder_anon_key'

if (!process.env.NEXT_PUBLIC_SUPABASE_URL || !process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY) {
    if (process.env.NODE_ENV === 'production') {
        console.warn('CRITICAL: Supabase environment variables are missing! Using mock credentials to allow build.')
    }
}

export const createClientClient = () => createBrowserClient(supabaseUrl, supabaseAnonKey)

// Standard client for non-component usage
export const supabase = createBrowserClient(supabaseUrl, supabaseAnonKey)
