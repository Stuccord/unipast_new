
-- Run these in your Supabase SQL Editor:

-- 1. Add course_id and programme_id to notifications
ALTER TABLE notifications ADD COLUMN IF NOT EXISTS course_id UUID REFERENCES courses(id) ON DELETE CASCADE;
ALTER TABLE notifications ADD COLUMN IF NOT EXISTS programme_id UUID REFERENCES programmes(id) ON DELETE CASCADE;

-- 2. Add notifications_cleared_at to profiles
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS notifications_cleared_at TIMESTAMPTZ;

-- 3. Re-enable RLS for profiles just in case (already should be enabled)
-- Ensure users can update their own profile fields
CREATE POLICY "Enable update for users based on id" ON profiles
FOR UPDATE USING (auth.uid() = id);
