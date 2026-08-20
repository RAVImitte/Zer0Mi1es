-- 1. Create the question pool
CREATE TABLE public.question_pool (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  question_text text NOT NULL
);

-- Seed with 50 questions
INSERT INTO public.question_pool (question_text) VALUES
('What is a small moment from today that made you smile?'),
('What is something you are looking forward to this week?'),
('If we could teleport anywhere for dinner tonight, where would we go?'),
('What is one thing I did recently that made you feel loved?'),
('What is a goal you have for yourself this month?'),
('What is your favorite memory of us from the past year?'),
('If you had a free day with zero responsibilities, how would you spend it?'),
('What is something you need more of right now? (rest, hugs, alone time, etc.)'),
('What made you laugh the hardest recently?'),
('What is a song that always reminds you of me?'),
('What is a hobby or skill you’ve always wanted us to try together?'),
('What is the best meal we’ve ever eaten together?'),
('What is one thing you appreciate about our relationship?'),
('What is a movie or show you want to binge-watch together next?'),
('If you could relive one day of your life, which day would it be?'),
('What is something you’re feeling slightly stressed about right now?'),
('What is your ideal perfect morning routine?'),
('If you could instantly learn any language, what would it be?'),
('What is your favorite thing about my personality?'),
('What was your favorite childhood vacation?'),
('What is a weird quirk of mine that you secretly love?'),
('What is something you want to achieve before the end of the year?'),
('What is the most comforting thing I can do for you when you are sad?'),
('If we were to start a business together, what would it be?'),
('What is your favorite physical feature of mine?'),
('What is a topic you could talk about for hours without getting bored?'),
('What is something you used to believe that you no longer do?'),
('What is the best piece of advice you’ve ever received?'),
('If you could only eat three foods for the rest of your life, what would they be?'),
('What is a place you feel most at peace?'),
('What is something you’re really proud of yourself for?'),
('What is your favorite way to spend a rainy day?'),
('If we had a completely free weekend, what is your dream itinerary?'),
('What is a compliment you received that you’ll never forget?'),
('What is a small habit of mine that you find endearing?'),
('What is something you want to let go of in your life?'),
('What is the most adventurous thing we’ve ever done together?'),
('If you could have any animal in the world as a pet, what would it be?'),
('What is a book that changed your perspective on something?'),
('What is your favorite way to show someone you care about them?'),
('What is a dream you haven’t told many people about?'),
('What is something that always instantly puts you in a good mood?'),
('What is the most beautiful place you have ever seen?'),
('If you had to describe our relationship in three words, what would they be?'),
('What is a skill you think I’m really good at?'),
('What is your favorite time of year and why?'),
('What is a memory that always makes you laugh out loud?'),
('What is something you wish we did more often?'),
('What is the most meaningful gift you’ve ever received?'),
('What is one thing you want me to know today?');

-- 2. Create daily_connections table
CREATE TABLE public.daily_connections (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  couple_id uuid NOT NULL REFERENCES public.couples(id) ON DELETE CASCADE,
  date date NOT NULL,
  creator_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
  question text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(couple_id, date)
);

-- 3. Create daily_answers table
CREATE TABLE public.daily_answers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  daily_connection_id uuid NOT NULL REFERENCES public.daily_connections(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
  answer text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(daily_connection_id, user_id)
);

-- Enable RLS
ALTER TABLE public.question_pool ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.daily_connections ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.daily_answers ENABLE ROW LEVEL SECURITY;

-- question_pool is read-only for all authenticated users
CREATE POLICY "Anyone can read question pool"
ON public.question_pool FOR SELECT TO authenticated USING (true);

-- daily_connections policies
CREATE POLICY "Read own couple connections"
ON public.daily_connections FOR SELECT TO authenticated
USING (couple_id IN (SELECT id FROM public.couples WHERE bear_id = auth.uid() OR bunny_id = auth.uid()));

CREATE POLICY "Insert own couple connections"
ON public.daily_connections FOR INSERT TO authenticated
WITH CHECK (couple_id IN (SELECT id FROM public.couples WHERE bear_id = auth.uid() OR bunny_id = auth.uid()));

CREATE POLICY "Update own couple connections"
ON public.daily_connections FOR UPDATE TO authenticated
USING (couple_id IN (SELECT id FROM public.couples WHERE bear_id = auth.uid() OR bunny_id = auth.uid()))
WITH CHECK (couple_id IN (SELECT id FROM public.couples WHERE bear_id = auth.uid() OR bunny_id = auth.uid()));


-- daily_answers policies (HIDDEN ANSWER RULE IMPLEMENTED HERE)
CREATE POLICY "Insert own answer"
ON public.daily_answers FOR INSERT TO authenticated
WITH CHECK (user_id = auth.uid() AND EXISTS (
  SELECT 1 FROM public.daily_connections dc
  JOIN public.couples c ON c.id = dc.couple_id
  WHERE dc.id = daily_connection_id
  AND (c.bear_id = auth.uid() OR c.bunny_id = auth.uid())
));

CREATE POLICY "Read answers"
ON public.daily_answers FOR SELECT TO authenticated
USING (
  -- Must be part of the couple
  EXISTS (
    SELECT 1 FROM public.daily_connections dc
    JOIN public.couples c ON c.id = dc.couple_id
    WHERE dc.id = daily_answers.daily_connection_id
    AND (c.bear_id = auth.uid() OR c.bunny_id = auth.uid())
  )
  AND 
  (
    -- Can read if it is YOUR answer
    user_id = auth.uid()
    OR
    -- Can read partner's answer IF you have already submitted your own answer
    EXISTS (
      SELECT 1 FROM public.daily_answers da 
      WHERE da.daily_connection_id = daily_answers.daily_connection_id 
      AND da.user_id = auth.uid()
    )
  )
);
