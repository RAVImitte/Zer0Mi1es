DROP POLICY IF EXISTS "Recipient can acknowledge pending talk signals"
ON public.connection_signals;

CREATE POLICY "Recipient can acknowledge pending talk signals"
ON public.connection_signals
FOR UPDATE
TO authenticated
USING (
  status = 'pending'
  AND user_id::text <> auth.uid()::text
  AND couple_id IN (
    SELECT id FROM public.couples
    WHERE bear_id = auth.uid() OR bunny_id = auth.uid()
  )
)
WITH CHECK (
  user_id::text <> auth.uid()::text
  AND acknowledged_by = auth.uid()
  AND status IN ('yes', 'soon', 'tonight', 'not_now')
  AND couple_id IN (
    SELECT id FROM public.couples
    WHERE bear_id = auth.uid() OR bunny_id = auth.uid()
  )
);
