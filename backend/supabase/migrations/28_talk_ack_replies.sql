ALTER TABLE public.connection_signals
  DROP CONSTRAINT IF EXISTS connection_signals_status_check;

ALTER TABLE public.connection_signals
  ADD CONSTRAINT connection_signals_status_check
  CHECK (status IN (
    'pending',
    'yes',
    'soon',
    'not_now',
    'give_me_10',
    'tonight',
    'cant_today'
  ));

UPDATE public.connection_signals SET status = 'soon' WHERE status = 'give_me_10';
UPDATE public.connection_signals SET status = 'soon' WHERE status = 'tonight';
UPDATE public.connection_signals SET status = 'not_now' WHERE status = 'cant_today';

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
  AND status IN ('yes', 'soon', 'not_now')
  AND couple_id IN (
    SELECT id FROM public.couples
    WHERE bear_id = auth.uid() OR bunny_id = auth.uid()
  )
);
