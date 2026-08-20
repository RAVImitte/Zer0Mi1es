-- Create love_drops table
CREATE TABLE public.love_drops (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  couple_id uuid NOT NULL REFERENCES public.couples(id) ON DELETE CASCADE,
  sender_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
  type text NOT NULL,
  message text,
  created_at timestamptz NOT NULL DEFAULT now()
);

-- Create moods table
CREATE TABLE public.moods (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  couple_id uuid NOT NULL REFERENCES public.couples(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
  mood text NOT NULL,
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(couple_id, user_id)
);

-- Create connection_signals table
CREATE TABLE public.connection_signals (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  couple_id uuid NOT NULL REFERENCES public.couples(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
  signal_type text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  expires_at timestamptz
);

-- Enable RLS
ALTER TABLE public.love_drops ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.moods ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.connection_signals ENABLE ROW LEVEL SECURITY;

-- Enable Realtime
ALTER PUBLICATION supabase_realtime ADD TABLE public.love_drops;
ALTER PUBLICATION supabase_realtime ADD TABLE public.moods;
ALTER PUBLICATION supabase_realtime ADD TABLE public.connection_signals;

-- RLS Policies for love_drops
CREATE POLICY "Users can read love drops for their couple"
ON public.love_drops FOR SELECT TO authenticated
USING (couple_id IN (SELECT id FROM public.couples WHERE bear_id = auth.uid() OR bunny_id = auth.uid()));

CREATE POLICY "Users can insert love drops for their couple"
ON public.love_drops FOR INSERT TO authenticated
WITH CHECK (couple_id IN (SELECT id FROM public.couples WHERE bear_id = auth.uid() OR bunny_id = auth.uid()) AND sender_id = auth.uid());

-- RLS Policies for moods
CREATE POLICY "Users can read moods for their couple"
ON public.moods FOR SELECT TO authenticated
USING (couple_id IN (SELECT id FROM public.couples WHERE bear_id = auth.uid() OR bunny_id = auth.uid()));

CREATE POLICY "Users can insert/update their own mood"
ON public.moods FOR ALL TO authenticated
USING (user_id = auth.uid() AND couple_id IN (SELECT id FROM public.couples WHERE bear_id = auth.uid() OR bunny_id = auth.uid()))
WITH CHECK (user_id = auth.uid() AND couple_id IN (SELECT id FROM public.couples WHERE bear_id = auth.uid() OR bunny_id = auth.uid()));

-- RLS Policies for connection_signals
CREATE POLICY "Users can read connection signals for their couple"
ON public.connection_signals FOR SELECT TO authenticated
USING (couple_id IN (SELECT id FROM public.couples WHERE bear_id = auth.uid() OR bunny_id = auth.uid()));

CREATE POLICY "Users can insert connection signals for their couple"
ON public.connection_signals FOR INSERT TO authenticated
WITH CHECK (couple_id IN (SELECT id FROM public.couples WHERE bear_id = auth.uid() OR bunny_id = auth.uid()) AND user_id = auth.uid());
