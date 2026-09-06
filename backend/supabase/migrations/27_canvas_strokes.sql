ALTER TABLE public.canvases
  ADD COLUMN IF NOT EXISTS strokes jsonb NOT NULL DEFAULT '[]'::jsonb;

ALTER TABLE public.canvases REPLICA IDENTITY FULL;

DO $$
BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE public.canvases;
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

GRANT SELECT, INSERT, UPDATE ON public.canvases TO authenticated;
