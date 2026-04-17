-- Grant INSERT permissions to authenticated users for faculties, programmes, and courses
-- This allows Agents (Reps) and Students to add these records.
-- Universities remain read-only for non-admins (assuming no INSERT policy exists for them).

-- 1. Faculties
DROP POLICY IF EXISTS "Authenticated users can insert faculties" ON public.faculties;
CREATE POLICY "Authenticated users can insert faculties" 
  ON public.faculties FOR INSERT 
  TO authenticated 
  WITH CHECK (true);

-- 2. Programmes
DROP POLICY IF EXISTS "Authenticated users can insert programmes" ON public.programmes;
CREATE POLICY "Authenticated users can insert programmes" 
  ON public.programmes FOR INSERT 
  TO authenticated 
  WITH CHECK (true);

-- 3. Courses
DROP POLICY IF EXISTS "Authenticated users can insert courses" ON public.courses;
CREATE POLICY "Authenticated users can insert courses" 
  ON public.courses FOR INSERT 
  TO authenticated 
  WITH CHECK (true);

-- NOTE: Ensure no INSERT policy exists for public.universities that allows non-admins.
-- If there is one, it should be restricted to admins only.
DROP POLICY IF EXISTS "Admins can insert universities" ON public.universities;
CREATE POLICY "Admins can insert universities" 
  ON public.universities FOR INSERT 
  TO authenticated 
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.profiles 
      WHERE id = auth.uid() AND is_admin = true
    )
  );
