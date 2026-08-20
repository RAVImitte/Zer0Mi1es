-- Drop the flawed recursive policy
DROP POLICY IF EXISTS "Read answers" ON public.daily_answers;

-- Create a secure function that bypasses RLS to check if the user answered
-- This prevents the infinite recursion error!
CREATE OR REPLACE FUNCTION public.has_user_answered(connection_id uuid)
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER -- Runs as admin, bypassing RLS to avoid infinite loops
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.daily_answers 
    WHERE daily_connection_id = connection_id 
    AND user_id = auth.uid()
  );
$$;

-- Create the new, safe policy
CREATE POLICY "Read answers"
ON public.daily_answers FOR SELECT TO authenticated
USING (
  -- 1. Must be part of the couple
  EXISTS (
    SELECT 1 FROM public.daily_connections dc
    JOIN public.couples c ON c.id = dc.couple_id
    WHERE dc.id = daily_answers.daily_connection_id
    AND (c.bear_id = auth.uid() OR c.bunny_id = auth.uid())
  )
  AND 
  (
    -- 2. Can read if it is YOUR answer
    user_id = auth.uid()
    OR
    -- 3. Can read partner's answer IF you have already submitted your own answer
    public.has_user_answered(daily_connection_id)
  )
);
