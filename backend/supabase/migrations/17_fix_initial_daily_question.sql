-- 17_fix_initial_daily_question.sql
-- Fixes the issue where new couples see "Today's question is not ready yet?"
-- by ensuring a question is generated immediately upon joining the couple.

CREATE OR REPLACE FUNCTION join_couple_with_token(raw_token text)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  target_token_row record;
  token_hash_val text;
  random_question text;
BEGIN
  -- Hash the incoming raw token
  token_hash_val := encode(digest(raw_token, 'sha256'), 'hex');

  -- Find the token
  SELECT * INTO target_token_row 
  FROM public.pairing_tokens 
  WHERE token_hash = token_hash_val
  FOR UPDATE; -- Lock the row to prevent race conditions

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Invalid token';
  END IF;

  IF target_token_row.used_at IS NOT NULL THEN
    RAISE EXCEPTION 'Token has already been used';
  END IF;

  IF target_token_row.expires_at < now() THEN
    RAISE EXCEPTION 'Token has expired';
  END IF;

  IF target_token_row.created_by = auth.uid() THEN
    RAISE EXCEPTION 'Cannot pair with yourself';
  END IF;

  -- Check if current user is already in a couple
  IF EXISTS (
    SELECT 1 FROM public.couples c 
    WHERE c.bear_id = auth.uid() OR c.bunny_id = auth.uid()
  ) THEN
    RAISE EXCEPTION 'You are already in a couple';
  END IF;

  -- Update the couple: add the second user as bunny_id
  UPDATE public.couples
  SET bunny_id = auth.uid(),
      updated_at = now()
  WHERE id = target_token_row.couple_id;

  -- Mark token as used
  UPDATE public.pairing_tokens
  SET used_at = now()
  WHERE id = target_token_row.id;

  -- ✨ FIX: Generate their very first daily question immediately! ✨
  -- Pick a random question
  SELECT question_text INTO random_question FROM public.question_pool ORDER BY random() LIMIT 1;
  
  -- Insert the first question for them using the bear_id as the first creator
  INSERT INTO public.daily_connections (couple_id, date, creator_id, question)
  VALUES (target_token_row.couple_id, CURRENT_DATE, target_token_row.created_by, random_question)
  ON CONFLICT DO NOTHING;

  RETURN target_token_row.couple_id;
END;
$$;
