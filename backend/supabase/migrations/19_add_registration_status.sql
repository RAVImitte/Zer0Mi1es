-- 19_add_registration_status.sql

-- 1. Add column to profiles
ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS registration_status text NOT NULL DEFAULT 'signed_up';

-- 2. Update existing profiles that have a display name but no couple to 'name_entered'
UPDATE public.profiles
SET registration_status = 'name_entered'
WHERE display_name IS NOT NULL 
  AND display_name != ''
  AND id NOT IN (
    SELECT bear_id FROM public.couples WHERE bear_id IS NOT NULL
    UNION
    SELECT bunny_id FROM public.couples WHERE bunny_id IS NOT NULL
  );

-- 3. Update existing profiles that are in a couple to 'all_done'
UPDATE public.profiles
SET registration_status = 'all_done'
WHERE id IN (
  SELECT bear_id FROM public.couples WHERE bear_id IS NOT NULL
  UNION
  SELECT bunny_id FROM public.couples WHERE bunny_id IS NOT NULL
);

-- 4. Create a trigger function to update status when a couple changes
CREATE OR REPLACE FUNCTION public.update_profile_status_on_couple_change()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- If a couple is inserted or updated (someone joined)
  IF (TG_OP = 'INSERT' OR TG_OP = 'UPDATE') THEN
    IF NEW.bear_id IS NOT NULL THEN
      UPDATE public.profiles SET registration_status = 'all_done' WHERE id = NEW.bear_id;
    END IF;
    IF NEW.bunny_id IS NOT NULL THEN
      UPDATE public.profiles SET registration_status = 'all_done' WHERE id = NEW.bunny_id;
    END IF;
  END IF;

  -- If a couple is deleted (e.g. they unpair or account deleted)
  IF (TG_OP = 'DELETE' OR TG_OP = 'UPDATE') THEN
    -- If deleted, or if someone was removed from the couple
    IF OLD.bear_id IS NOT NULL AND (TG_OP = 'DELETE' OR NEW.bear_id IS NULL OR NEW.bear_id != OLD.bear_id) THEN
      UPDATE public.profiles SET registration_status = 'name_entered' WHERE id = OLD.bear_id;
    END IF;
    IF OLD.bunny_id IS NOT NULL AND (TG_OP = 'DELETE' OR NEW.bunny_id IS NULL OR NEW.bunny_id != OLD.bunny_id) THEN
      UPDATE public.profiles SET registration_status = 'name_entered' WHERE id = OLD.bunny_id;
    END IF;
  END IF;
  
  RETURN NULL; -- AFTER triggers can return NULL
END;
$$;

-- 5. Attach the trigger to the couples table
DROP TRIGGER IF EXISTS on_couple_change ON public.couples;
CREATE TRIGGER on_couple_change
AFTER INSERT OR UPDATE OR DELETE ON public.couples
FOR EACH ROW
EXECUTE FUNCTION public.update_profile_status_on_couple_change();
