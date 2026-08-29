-- Add missing UPDATE policy for daily_answers so users can edit their answers

CREATE POLICY "Update own answer"
ON public.daily_answers FOR UPDATE TO authenticated
USING (
  user_id = auth.uid() 
  AND EXISTS (
    SELECT 1 FROM public.daily_connections dc
    JOIN public.couples c ON c.id = dc.couple_id
    WHERE dc.id = daily_answers.daily_connection_id
    AND (c.bear_id = auth.uid() OR c.bunny_id = auth.uid())
  )
)
WITH CHECK (
  user_id = auth.uid()
);
