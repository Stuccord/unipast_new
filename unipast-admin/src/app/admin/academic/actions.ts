'use server'

import { createClient } from '@supabase/supabase-js'

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!
const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY!

const supabaseAdmin = createClient(supabaseUrl, supabaseServiceKey)

export async function addAcademicItem(table: string, payload: any) {
    const { data, error } = await supabaseAdmin.from(table).insert([payload]).select()
    if (error) return { error: error.message }
    return { data }
}

export async function updateAcademicItem(table: string, id: string, payload: any) {
    const { data, error } = await supabaseAdmin.from(table).update(payload).eq('id', id).select()
    if (error) return { error: error.message }
    return { data }
}

export async function deleteAcademicItem(table: string, id: string) {
    const { error } = await supabaseAdmin.from(table).delete().eq('id', id)
    if (error) return { error: error.message }
    return { success: true }
}
