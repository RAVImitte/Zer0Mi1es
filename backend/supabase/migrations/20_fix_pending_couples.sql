-- 1. Clean up any orphaned pending couples from the old system
DELETE FROM public.couples WHERE bunny_id IS NULL OR bear_id IS NULL;

-- 2. Drop couple_id from pairing_tokens since couples are only created upon successful join
ALTER TABLE public.pairing_tokens DROP COLUMN IF EXISTS couple_id;

-- 3. Update create_couple_with_token to NOT create a couple yet
DROP FUNCTION IF EXISTS create_couple_with_token(text);

CREATE OR REPLACE FUNCTION create_couple_with_token(raw_token text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  token_hash_val text;
BEGIN
  -- Check if user is already in a fully paired couple
  IF EXISTS (
    SELECT 1 FROM public.couples c 
    WHERE c.bear_id = auth.uid() OR c.bunny_id = auth.uid()
  ) THEN
    RAISE EXCEPTION 'User is already in a couple';
  END IF;

  -- Delete any unused tokens previously created by this user to prevent clutter
  DELETE FROM public.pairing_tokens WHERE created_by = auth.uid() AND used_at IS NULL;

  -- Hash the raw token
  token_hash_val := encode(digest(raw_token, 'sha256'), 'hex');

  -- Create the pairing token
  INSERT INTO public.pairing_tokens (token_hash, created_by, expires_at)
  VALUES (token_hash_val, auth.uid(), now() + interval '24 hours');
END;
$$;

-- 4. Update join_couple_with_token to create the couple ONLY when joined
CREATE OR REPLACE FUNCTION join_couple_with_token(raw_token text)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  target_token_row record;
  token_hash_val text;
  new_couple_id uuid;
BEGIN
  -- Hash the incoming raw token
  token_hash_val := encode(digest(raw_token, 'sha256'), 'hex');

  -- Find the token
  SELECT * INTO target_token_row 
  FROM public.pairing_tokens 
  WHERE token_hash = token_hash_val
  FOR UPDATE; 

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

  -- Create the couple NOW since the partner has joined!
  INSERT INTO public.couples (bear_id, bunny_id)
  VALUES (target_token_row.created_by, auth.uid())
  RETURNING id INTO new_couple_id;

  -- Mark token as used
  UPDATE public.pairing_tokens
  SET used_at = now()
  WHERE id = target_token_row.id;

  -- Generate their very first daily question immediately!
  DECLARE
    random_question text;
  BEGIN
    SELECT question_text INTO random_question FROM public.question_pool ORDER BY random() LIMIT 1;
    INSERT INTO public.daily_connections (couple_id, date, creator_id, question)
    VALUES (new_couple_id, CURRENT_DATE, target_token_row.created_by, random_question)
    ON CONFLICT DO NOTHING;
  END;

  RETURN new_couple_id;
END;
$$;
