-- Allow users to read the profile of their partner
CREATE POLICY "read partner profile" 
ON public.profiles 
FOR SELECT 
TO authenticated 
USING (
  EXISTS (
    SELECT 1 FROM public.couples 
    WHERE (bear_id = auth.uid() AND bunny_id = public.profiles.id)
       OR (bunny_id = auth.uid() AND bear_id = public.profiles.id)
  )
);
