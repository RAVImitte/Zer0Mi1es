-- 1. Create the pairing_tokens table
CREATE TABLE public.pairing_tokens (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  couple_id uuid NOT NULL REFERENCES public.couples(id) ON DELETE CASCADE,
  token_hash text NOT NULL UNIQUE,
  created_by uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  created_at timestamptz NOT NULL DEFAULT now(),
  expires_at timestamptz NOT NULL,
  used_at timestamptz
);

-- Enable RLS on pairing_tokens
ALTER TABLE public.pairing_tokens ENABLE ROW LEVEL SECURITY;

-- 2. Add RPC for creating a couple and generating a token
-- We wrap this in a function to ensure atomic creation of a couple and its token
CREATE OR REPLACE FUNCTION create_couple_with_token(raw_token text)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER -- Runs with elevated privileges to create the token securely
AS $$
DECLARE
  new_couple_id uuid;
  token_hash_val text;
BEGIN
  -- Check if user is already in a couple
  IF EXISTS (
    SELECT 1 FROM public.couples c 
    WHERE c.bear_id = auth.uid() OR c.bunny_id = auth.uid()
  ) THEN
    RAISE EXCEPTION 'User is already in a couple';
  END IF;

  -- Create the couple with the current user as bear_id
  INSERT INTO public.couples (bear_id)
  VALUES (auth.uid())
  RETURNING id INTO new_couple_id;

  -- Hash the raw token for storage (using simple sha256 for this example)
  -- In a real app, use a proper crypt function or pass the pre-hashed token from client
  -- We'll assume the client passed a raw token and we hash it here
  token_hash_val := encode(digest(raw_token, 'sha256'), 'hex');

  -- Create the pairing token (valid for 24 hours)
  INSERT INTO public.pairing_tokens (couple_id, token_hash, created_by, expires_at)
  VALUES (new_couple_id, token_hash_val, auth.uid(), now() + interval '24 hours');

  RETURN new_couple_id;
END;
$$;

-- 3. Add RPC for joining a couple using a token
CREATE OR REPLACE FUNCTION join_couple_with_token(raw_token text)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  target_token_row record;
  token_hash_val text;
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
  -- Wait, what if bear_id was null and bunny_id was set? The creator function sets bear_id.
  UPDATE public.couples
  SET bunny_id = auth.uid(),
      updated_at = now()
  WHERE id = target_token_row.couple_id;

  -- Mark token as used
  UPDATE public.pairing_tokens
  SET used_at = now()
  WHERE id = target_token_row.id;

  RETURN target_token_row.couple_id;
END;
$$;

-- Note: In order to use the 'digest' function, you may need to enable the pgcrypto extension.
-- CREATE EXTENSION IF NOT EXISTS "pgcrypto";
