ALTER TABLE public.connection_signals
  ADD COLUMN IF NOT EXISTS status text NOT NULL DEFAULT 'pending',
  ADD COLUMN IF NOT EXISTS acknowledged_at timestamptz,
  ADD COLUMN IF NOT EXISTS acknowledged_by uuid REFERENCES public.profiles(id);

ALTER TABLE public.connection_signals
  DROP CONSTRAINT IF EXISTS connection_signals_status_check;

ALTER TABLE public.connection_signals
  ADD CONSTRAINT connection_signals_status_check
  CHECK (status IN ('pending', 'give_me_10', 'tonight', 'cant_today'));

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
  AND couple_id IN (
    SELECT id FROM public.couples
    WHERE bear_id = auth.uid() OR bunny_id = auth.uid()
  )
);
