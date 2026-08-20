-- 1. Enable Realtime for the new tables so the UI instantly updates when partner answers!
ALTER PUBLICATION supabase_realtime ADD TABLE public.daily_connections;
ALTER PUBLICATION supabase_realtime ADD TABLE public.daily_answers;

-- 2. Create a secure function to let the client know IF the partner answered, 
-- WITHOUT revealing WHAT they answered (bypassing the strict RLS rule just to return a boolean).
CREATE OR REPLACE FUNCTION public.has_partner_answered(connection_id uuid)
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.daily_answers 
    WHERE daily_connection_id = connection_id 
    AND user_id != auth.uid()
  );
$$;
