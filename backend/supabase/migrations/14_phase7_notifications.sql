-- Add fcm_token to the profiles table
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS fcm_token text;

-- Ensure the user can update their own token
-- (The existing "update own profile" policy should cover this, but we explicitly re-create it just in case)
DROP POLICY IF EXISTS "update own profile" ON public.profiles;
CREATE POLICY "update own profile"
ON public.profiles FOR UPDATE
TO authenticated
USING (id = auth.uid())
WITH CHECK (id = auth.uid());
