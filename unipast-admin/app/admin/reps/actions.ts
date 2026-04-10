'use server'

import { createClient } from '@supabase/supabase-js'

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!
const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY!

const supabaseAdmin = createClient(supabaseUrl, supabaseServiceKey)

export async function inviteRep(formData: {
    full_name: string,
    email: string,
    password?: string,
    university_id: string,
    faculty_id: string,
    current_level: number
}) {
    try {
        // 1. Create the user via Supabase Auth Admin API
        const { data: userData, error: createError } = await supabaseAdmin.auth.admin.createUser({
            email: formData.email,
            password: formData.password || 'Temporary123!', // Fallback if admin didn't set one
            email_confirm: true,
            user_metadata: { full_name: formData.full_name }
        })

        if (createError) throw createError

        const userId = userData.user.id

        // 2. Update/Insert the profile
        // Note: The trigger handle_new_user might have already inserted a row
        // We use upsert or update to ensure details are set correctly
        const { error: profileError } = await supabaseAdmin
            .from('profiles')
            .upsert({
                id: userId,
                full_name: formData.full_name,
                email: formData.email,
                university_id: formData.university_id,
                faculty_id: formData.faculty_id,
                current_level: formData.current_level,
                role: 'rep',
                is_rep: true,
                status: 'Pending'
            })

        if (profileError) throw profileError

        return { success: true }
    } catch (error: any) {
        console.error('Invite Rep Error:', error)
        return { error: error.message || 'An unknown error occurred during invitation.' }
    }
}
