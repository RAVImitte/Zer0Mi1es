-- 18_delete_account.sql

CREATE OR REPLACE FUNCTION public.delete_my_account()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  my_uid uuid;
  my_couple_id uuid;
BEGIN
  my_uid := auth.uid();
  IF my_uid IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  -- Find if the user is in a couple
  SELECT id INTO my_couple_id FROM public.couples 
  WHERE bear_id = my_uid OR bunny_id = my_uid;

  -- Delete the couple if one exists.
  -- This will cascade to pairing_tokens, daily_photos, daily_outfits, etc.
  IF my_couple_id IS NOT NULL THEN
    DELETE FROM public.couples WHERE id = my_couple_id;
  END IF;

  -- Delete the user from auth.users
  -- This cascades to public.profiles and clears the auth session
  DELETE FROM auth.users WHERE id = my_uid;
END;
$$;
