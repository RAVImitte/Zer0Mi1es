-- Fix has_user_answered to only count actual answers, not just guesses
CREATE OR REPLACE FUNCTION public.has_user_answered(connection_id uuid)
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.daily_answers 
    WHERE daily_connection_id = connection_id 
    AND user_id = auth.uid()
    AND answer IS NOT NULL
    AND TRIM(answer) != ''
  );
$$;

-- Fix has_partner_answered to only count actual answers, not just guesses
CREATE OR REPLACE FUNCTION public.has_partner_answered(connection_id uuid)
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.daily_answers 
    WHERE daily_connection_id = connection_id 
    AND user_id != auth.uid()
    AND answer IS NOT NULL
    AND TRIM(answer) != ''
  );
$$;

-- Add has_partner_guessed so the UI knows if the partner has guessed
CREATE OR REPLACE FUNCTION public.has_partner_guessed(connection_id uuid)
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.daily_answers 
    WHERE daily_connection_id = connection_id 
    AND user_id != auth.uid()
    AND guess IS NOT NULL
    AND TRIM(guess) != ''
  );
$$;
