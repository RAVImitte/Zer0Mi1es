GRANT SELECT, INSERT, UPDATE ON public.connection_signals TO authenticated;

ALTER TABLE public.connection_signals REPLICA IDENTITY FULL;
ALTER TABLE public.moods REPLICA IDENTITY FULL;
ALTER TABLE public.love_drops REPLICA IDENTITY FULL;
ALTER TABLE public.daily_outfits REPLICA IDENTITY FULL;

DROP POLICY IF EXISTS "Recipient can acknowledge pending talk signals"
ON public.connection_signals;

CREATE POLICY "Recipient can acknowledge pending talk signals"
ON public.connection_signals
FOR UPDATE
TO authenticated
USING (
  status = 'pending'
  AND user_id <> auth.uid()
  AND couple_id IN (
    SELECT id FROM public.couples
    WHERE bear_id = auth.uid() OR bunny_id = auth.uid()
  )
)
WITH CHECK (
  user_id <> auth.uid()
  AND acknowledged_by = auth.uid()
  AND status IN ('give_me_10', 'tonight', 'cant_today')
  AND couple_id IN (
    SELECT id FROM public.couples
    WHERE bear_id = auth.uid() OR bunny_id = auth.uid()
  )
);
