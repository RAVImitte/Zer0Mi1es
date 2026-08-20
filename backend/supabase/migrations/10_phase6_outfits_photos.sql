-- 1. Create daily_outfits table
drop table daily_outfits;
CREATE TABLE public.daily_outfits (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  couple_id uuid NOT NULL REFERENCES public.couples(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
  date date NOT NULL,
  top_color text NOT NULL,
  bottom_color text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(couple_id, user_id, date)
);

ALTER TABLE public.daily_outfits ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Read own couple outfits"
ON public.daily_outfits FOR SELECT TO authenticated
USING (couple_id IN (SELECT id FROM public.couples WHERE bear_id = auth.uid() OR bunny_id = auth.uid()));

CREATE POLICY "Insert own couple outfits"
ON public.daily_outfits FOR INSERT TO authenticated
WITH CHECK (user_id = auth.uid() AND couple_id IN (SELECT id FROM public.couples WHERE bear_id = auth.uid() OR bunny_id = auth.uid()));

CREATE POLICY "Update own couple outfits"
ON public.daily_outfits FOR UPDATE TO authenticated
USING (user_id = auth.uid() AND couple_id IN (SELECT id FROM public.couples WHERE bear_id = auth.uid() OR bunny_id = auth.uid()))
WITH CHECK (user_id = auth.uid() AND couple_id IN (SELECT id FROM public.couples WHERE bear_id = auth.uid() OR bunny_id = auth.uid()));

-- Enable realtime for avatar updates
ALTER PUBLICATION supabase_realtime ADD TABLE public.daily_outfits;

-- 2. Create daily_photos table (metadata)
drop table daily_photos;
CREATE TABLE public.daily_photos (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  couple_id uuid NOT NULL REFERENCES public.couples(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
  date date NOT NULL,
  storage_path text NOT NULL,
  comment text,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(couple_id, user_id, date)
);

ALTER TABLE public.daily_photos ENABLE ROW LEVEL SECURITY;

-- Photo metadata RLS (Implementing Photo Lock: You can only read partner's photo if you have uploaded yours)
CREATE POLICY "Insert own photo metadata"
ON public.daily_photos FOR INSERT TO authenticated
WITH CHECK (user_id = auth.uid() AND couple_id IN (SELECT id FROM public.couples WHERE bear_id = auth.uid() OR bunny_id = auth.uid()));

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
    EXISTS (
      SELECT 1 FROM public.daily_photos dp 
      WHERE dp.couple_id = daily_photos.couple_id 
      AND dp.date = daily_photos.date
      AND dp.user_id = auth.uid()
    )
  )
);

-- Realtime for photo notifications/updates
ALTER PUBLICATION supabase_realtime ADD TABLE public.daily_photos;

-- 3. Set up Storage Bucket for actual images
INSERT INTO storage.buckets (id, name, public) 
VALUES ('photos', 'photos', false)
ON CONFLICT (id) DO NOTHING;

-- Storage RLS: Users can only upload to their own couple's folder
-- The path convention will be: {couple_id}/{user_id}/{date}.jpg
CREATE POLICY "Users can upload their own photos"
ON storage.objects FOR INSERT TO authenticated
WITH CHECK (
  bucket_id = 'photos' 
  AND (storage.foldername(name))[1] IN (
    SELECT id::text FROM public.couples WHERE bear_id = auth.uid() OR bunny_id = auth.uid()
  )
  -- Enforce path structure: {couple_id}/{user_id}/...
  AND (storage.foldername(name))[2] = auth.uid()::text
);

-- Storage RLS: Users can read photos from their couple
-- Note: The metadata table handles the "lock" logic (you only know the path if you can query the metadata table). 
-- Storage RLS itself just prevents gross unauthorized access from outsiders.
CREATE POLICY "Users can view their couple's photos"
ON storage.objects FOR SELECT TO authenticated
USING (
  bucket_id = 'photos' 
  AND (storage.foldername(name))[1] IN (
    SELECT id::text FROM public.couples WHERE bear_id = auth.uid() OR bunny_id = auth.uid()
  )
);

CREATE POLICY "Users can update their own photos"
ON storage.objects FOR UPDATE TO authenticated
USING (
  bucket_id = 'photos' 
  AND (storage.foldername(name))[2] = auth.uid()::text
);

CREATE POLICY "Users can delete their own photos"
ON storage.objects FOR DELETE TO authenticated
USING (
  bucket_id = 'photos' 
  AND (storage.foldername(name))[2] = auth.uid()::text
);
