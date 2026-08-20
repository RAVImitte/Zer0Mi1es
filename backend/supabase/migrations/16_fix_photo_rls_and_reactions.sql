-- 1. Add reaction columns
ALTER TABLE public.daily_photos 
ADD COLUMN IF NOT EXISTS reaction_emoji text,
ADD COLUMN IF NOT EXISTS reaction_text text;

-- 2. Drop the old broken policies
DROP POLICY IF EXISTS "Insert own photo metadata" ON public.daily_photos;
DROP POLICY IF EXISTS "Read photos metadata" ON public.daily_photos;
DROP POLICY IF EXISTS "Update own photo metadata" ON public.daily_photos;
DROP POLICY IF EXISTS "Update partner photo reaction" ON public.daily_photos;

-- 3. We will reuse the public.is_member_of_couple(couple_id) function created in 15_fix_outfit_rls.sql
-- We also reuse the public.has_uploaded_photo_today(couple_id, date) function created in 12_fix_photo_rls_recursion.sql

-- 4. Create new safe policies for SELECT, INSERT, and UPDATE
CREATE POLICY "Read photos metadata"
ON public.daily_photos FOR SELECT TO authenticated
USING (
  public.is_member_of_couple(couple_id)
  AND 
  (
    user_id = auth.uid()
    OR
    public.has_uploaded_photo_today(couple_id, date)
  )
);

CREATE POLICY "Insert own photo metadata"
ON public.daily_photos FOR INSERT TO authenticated
WITH CHECK (user_id = auth.uid() AND public.is_member_of_couple(couple_id));

-- For Upserts (updates to our own row):
CREATE POLICY "Update own photo metadata"
ON public.daily_photos FOR UPDATE TO authenticated
USING (user_id = auth.uid() AND public.is_member_of_couple(couple_id))
WITH CHECK (user_id = auth.uid() AND public.is_member_of_couple(couple_id));

-- For Reacting (updates to the PARTNER's row):
-- Users can only update their partner's photo if they are in the couple, AND they have uploaded their own photo today
CREATE POLICY "Update partner photo reaction"
ON public.daily_photos FOR UPDATE TO authenticated
USING (
  user_id != auth.uid() 
  AND public.is_member_of_couple(couple_id)
  AND public.has_uploaded_photo_today(couple_id, date)
)
WITH CHECK (
  user_id != auth.uid() 
  AND public.is_member_of_couple(couple_id)
  AND public.has_uploaded_photo_today(couple_id, date)
);
