-- Notes on love drops: keep message, allow an emoji for the Note action.
ALTER TABLE public.love_drops
  ADD COLUMN IF NOT EXISTS message text;

ALTER TABLE public.love_drops
  ADD COLUMN IF NOT EXISTS emoji text;
