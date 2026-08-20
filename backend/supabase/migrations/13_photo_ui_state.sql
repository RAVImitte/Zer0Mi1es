-- Create a function to check if the partner has uploaded a photo today
CREATE OR REPLACE FUNCTION public.has_partner_uploaded_photo(c_id uuid, p_date date)
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.daily_photos 
    WHERE couple_id = c_id 
    AND date = p_date
    AND user_id != auth.uid()
  );
$$;
