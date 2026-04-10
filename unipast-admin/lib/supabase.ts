import { createBrowserClient } from '@supabase/ssr'

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!
const supabaseAnonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!

export const createClientClient = () => createBrowserClient(supabaseUrl, supabaseAnonKey)

// Standard client for non-component usage
export const supabase = createBrowserClient(supabaseUrl, supabaseAnonKey)
