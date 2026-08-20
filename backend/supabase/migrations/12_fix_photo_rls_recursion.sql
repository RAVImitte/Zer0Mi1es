-- Drop the flawed recursive policy
DROP POLICY IF EXISTS "Read photos metadata" ON public.daily_photos;

-- Create a secure function that bypasses RLS to check if the user uploaded a photo today
CREATE OR REPLACE FUNCTION public.has_uploaded_photo_today(c_id uuid, p_date date)
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER -- Bypasses RLS to avoid infinite recursion
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.daily_photos 
    WHERE couple_id = c_id 
    AND date = p_date
    AND user_id = auth.uid()
  );
$$;

-- Create the new safe policy
CREATE POLICY "Read photos metadata"
ON public.daily_photos FOR SELECT TO authenticated
USING (
  -- Must be part of the couple
  couple_id IN (SELECT id FROM public.couples WHERE bear_id = auth.uid() OR bunny_id = auth.uid())
  AND 
  (
    -- Can read if it is YOUR photo
    user_id = auth.uid()
    OR
    -- Can read partner's photo IF you have already submitted your own photo for the same date
    public.has_uploaded_photo_today(couple_id, date)
  )
);
