CREATE TABLE public.voice_drops (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  couple_id uuid NOT NULL REFERENCES public.couples(id) ON DELETE CASCADE,
  sender_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
  storage_path text NOT NULL,
  duration_ms int NOT NULL CHECK (duration_ms > 0 AND duration_ms <= 15000),
  created_at timestamptz NOT NULL DEFAULT now(),
  expires_at timestamptz NOT NULL DEFAULT (now() + interval '24 hours')
);

ALTER TABLE public.voice_drops ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Couple can read unexpired voice drops"
ON public.voice_drops FOR SELECT TO authenticated
USING (
  couple_id IN (SELECT id FROM public.couples WHERE bear_id = auth.uid() OR bunny_id = auth.uid())
  AND expires_at > now()
);

CREATE POLICY "Sender can insert own voice drops"
ON public.voice_drops FOR INSERT TO authenticated
WITH CHECK (
  sender_id = auth.uid()
  AND couple_id IN (SELECT id FROM public.couples WHERE bear_id = auth.uid() OR bunny_id = auth.uid())
);

ALTER PUBLICATION supabase_realtime ADD TABLE public.voice_drops;

INSERT INTO storage.buckets (id, name, public)
VALUES ('voice', 'voice', false)
ON CONFLICT (id) DO NOTHING;

CREATE POLICY "Users can upload couple voice"
ON storage.objects FOR INSERT TO authenticated
WITH CHECK (
  bucket_id = 'voice'
  AND (storage.foldername(name))[1] IN (
    SELECT id::text FROM public.couples WHERE bear_id = auth.uid() OR bunny_id = auth.uid()
  )
  AND (storage.foldername(name))[2] = auth.uid()::text
);

CREATE POLICY "Users can read couple voice"
ON storage.objects FOR SELECT TO authenticated
USING (
  bucket_id = 'voice'
  AND (storage.foldername(name))[1] IN (
    SELECT id::text FROM public.couples WHERE bear_id = auth.uid() OR bunny_id = auth.uid()
  )
);
