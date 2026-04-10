-- ACTIVITY SCHEMA
-- Create the activities table to track all app events
CREATE TABLE IF NOT EXISTS public.activities (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    event_type TEXT NOT NULL,
    description TEXT,
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.activities ENABLE ROW LEVEL SECURITY;

-- Allow anyone to insert (so we can log from anywhere)
-- In a more strict setup, we might limit this, but for simplicity:
CREATE POLICY "Anyone can insert activities" 
  ON public.activities FOR INSERT WITH CHECK (true);

-- Only admins can read activities
CREATE POLICY "Admins can view all activities" 
  ON public.activities FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.profiles 
      WHERE id = auth.uid() AND is_admin = true
    )
  );

-- Enable Realtime for activities table
-- Note: This requires running 'ALTER PUBLICATION supabase_realtime ADD TABLE activities;' 
-- in the SQL editor if not automatically enabled.
