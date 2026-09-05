CREATE TABLE public.canvases (
  couple_id uuid PRIMARY KEY REFERENCES public.couples(id) ON DELETE CASCADE,
  storage_path text NOT NULL,
  updated_at timestamptz NOT NULL DEFAULT now(),
  updated_by uuid NOT NULL REFERENCES public.profiles(id)
);

ALTER TABLE public.canvases ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Couple can read canvas"
ON public.canvases FOR SELECT TO authenticated
USING (
  couple_id IN (SELECT id FROM public.couples WHERE bear_id = auth.uid() OR bunny_id = auth.uid())
);

CREATE POLICY "Couple can upsert canvas"
ON public.canvases FOR INSERT TO authenticated
WITH CHECK (
  updated_by = auth.uid()
  AND couple_id IN (SELECT id FROM public.couples WHERE bear_id = auth.uid() OR bunny_id = auth.uid())
);

CREATE POLICY "Couple can update canvas"
ON public.canvases FOR UPDATE TO authenticated
USING (
  couple_id IN (SELECT id FROM public.couples WHERE bear_id = auth.uid() OR bunny_id = auth.uid())
)
WITH CHECK (
  updated_by = auth.uid()
  AND couple_id IN (SELECT id FROM public.couples WHERE bear_id = auth.uid() OR bunny_id = auth.uid())
);

INSERT INTO storage.buckets (id, name, public)
VALUES ('canvas', 'canvas', false)
ON CONFLICT (id) DO NOTHING;

CREATE POLICY "Users can write couple canvas"
ON storage.objects FOR INSERT TO authenticated
WITH CHECK (
  bucket_id = 'canvas'
  AND (storage.foldername(name))[1] IN (
    SELECT id::text FROM public.couples WHERE bear_id = auth.uid() OR bunny_id = auth.uid()
  )
);

CREATE POLICY "Users can update couple canvas"
ON storage.objects FOR UPDATE TO authenticated
USING (
  bucket_id = 'canvas'
  AND (storage.foldername(name))[1] IN (
    SELECT id::text FROM public.couples WHERE bear_id = auth.uid() OR bunny_id = auth.uid()
  )
);

CREATE POLICY "Users can read couple canvas"
ON storage.objects FOR SELECT TO authenticated
USING (
  bucket_id = 'canvas'
  AND (storage.foldername(name))[1] IN (
    SELECT id::text FROM public.couples WHERE bear_id = auth.uid() OR bunny_id = auth.uid()
  )
);
