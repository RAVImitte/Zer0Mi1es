-- 1. Create a secure function to check couple membership to avoid RLS subquery issues
CREATE OR REPLACE FUNCTION public.is_member_of_couple(c_id uuid)
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.couples 
    WHERE id = c_id 
    AND (bear_id = auth.uid() OR bunny_id = auth.uid())
  );
$$;

-- 2. Drop the old daily_outfits policies
DROP POLICY IF EXISTS "Read own couple outfits" ON public.daily_outfits;
DROP POLICY IF EXISTS "Insert own couple outfits" ON public.daily_outfits;
DROP POLICY IF EXISTS "Update own couple outfits" ON public.daily_outfits;

-- 3. Create the new, safe policies using the helper function
CREATE POLICY "Read own couple outfits"
ON public.daily_outfits FOR SELECT TO authenticated
USING (public.is_member_of_couple(couple_id));

CREATE POLICY "Insert own couple outfits"
ON public.daily_outfits FOR INSERT TO authenticated
WITH CHECK (user_id = auth.uid() AND public.is_member_of_couple(couple_id));

CREATE POLICY "Update own couple outfits"
ON public.daily_outfits FOR UPDATE TO authenticated
USING (user_id = auth.uid() AND public.is_member_of_couple(couple_id))
WITH CHECK (user_id = auth.uid() AND public.is_member_of_couple(couple_id));
