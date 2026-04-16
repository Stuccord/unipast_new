'use server'

import { createClient } from '@supabase/supabase-js'

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!
const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY!

const supabaseAdmin = createClient(supabaseUrl, supabaseServiceKey)

export async function uploadPastQuestion(formData: FormData) {
    const file = formData.get('file') as File
    const course_id = formData.get('course_id') as string
    const year = parseInt(formData.get('year') as string)
    const semester = parseInt(formData.get('semester') as string)
    const level = parseInt(formData.get('level') as string)
    const title = formData.get('title') as string

    if (!file || !course_id) return { error: 'Missing required fields' }

    const fileExt = file.name.split('.').pop()
    const filePath = `${course_id}/${Date.now()}.${fileExt}`

    const { error: uploadError } = await supabaseAdmin.storage
        .from('questions')
        .upload(filePath, file)

    if (uploadError) return { error: uploadError.message }

    const { error: dbError } = await supabaseAdmin.from('past_questions').insert({
        course_id,
        title,
        year,
        semester,
        pdf_url: filePath,
    })

    if (dbError) return { error: dbError.message }

    // 3. Trigger a global notification
    await supabaseAdmin.from('notifications').insert({
        title: 'New Past Question Available!',
        message: `${title || 'A new paper'} has been uploaded for your course.`,
        type: 'info'
    })
    return { success: true }
}

export async function deletePastQuestion(id: string, filePath: string) {
    if (!id || !filePath) return { error: 'Missing ID or file path' }

    // 1. Delete from Storage
    const { error: storageError } = await supabaseAdmin.storage
        .from('questions')
        .remove([filePath])

    if (storageError) {
        console.error('Storage deletion error:', storageError)
        // We continue even if storage delete fails to clean up the DB
    }

    // 2. Delete from Database
    const { error: dbError } = await supabaseAdmin
        .from('past_questions')
        .delete()
        .eq('id', id)

    if (dbError) return { error: dbError.message }

    return { success: true }
}
