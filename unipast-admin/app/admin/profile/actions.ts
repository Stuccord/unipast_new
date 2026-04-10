'use server'

import { createClient } from '@supabase/supabase-js'

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!
const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY!

const supabaseAdmin = createClient(supabaseUrl, supabaseServiceKey)

export async function updateProfileFull(userId: string, formData: FormData) {
    const full_name = formData.get('full_name') as string
    const email = formData.get('email') as string
    const current_level = parseInt(formData.get('current_level') as string)
    const current_semester = parseInt(formData.get('current_semester') as string)
    
    const { error } = await supabaseAdmin
        .from('profiles')
        .update({ full_name, email, current_level, current_semester })
        .eq('id', userId)

    if (error) return { error: error.message }
    return { success: true }
}

export async function uploadProfilePicture(userId: string, formData: FormData) {
    const file = formData.get('file') as File
    
    if (!file) return { error: 'No file provided' }

    const fileExt = file.name.split('.').pop()
    const filePath = `${userId}/${Date.now()}.${fileExt}`

    // Upload the file using service role to bypass RLS
    const { error: uploadError } = await supabaseAdmin.storage
        .from('profiles')
        .upload(filePath, file)

    if (uploadError) return { error: uploadError.message }

    const { data: { publicUrl } } = supabaseAdmin.storage
        .from('profiles')
        .getPublicUrl(filePath)

    // Update profile with new avatar URL
    const { error: updateError } = await supabaseAdmin
        .from('profiles')
        .update({ avatar_url: publicUrl })
        .eq('id', userId)

    if (updateError) return { error: updateError.message }

    return { success: true }
}
