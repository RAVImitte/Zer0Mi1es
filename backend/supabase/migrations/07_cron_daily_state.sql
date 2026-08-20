CREATE OR REPLACE FUNCTION public.generate_daily_questions()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  couple RECORD;
  days_elapsed integer;
  turn_creator_id uuid;
  random_question text;
BEGIN
  -- Iterate through all fully paired couples
  FOR couple IN SELECT id, bear_id, bunny_id, created_at FROM public.couples WHERE bunny_id IS NOT NULL LOOP
    -- Check if a question already exists for today
    IF NOT EXISTS (SELECT 1 FROM public.daily_connections WHERE couple_id = couple.id AND date = CURRENT_DATE) THEN
      
      -- Calculate days elapsed since couple was created
      days_elapsed := CURRENT_DATE - DATE(couple.created_at);
      
      -- Determine whose turn it is
      IF days_elapsed % 2 = 0 THEN
        turn_creator_id := couple.bear_id;
      ELSE
        turn_creator_id := couple.bunny_id;
      END IF;
      
      -- Pick a random question
      SELECT question_text INTO random_question FROM public.question_pool ORDER BY random() LIMIT 1;
      
      -- Insert the row
      INSERT INTO public.daily_connections (couple_id, date, creator_id, question)
      VALUES (couple.id, CURRENT_DATE, turn_creator_id, random_question);
      
    END IF;
  END LOOP;
END;
$$;

-- Note: To actually schedule this, you need to enable pg_cron in Supabase 
-- (Dashboard > Database > Extensions > pg_cron).
-- Once enabled, you can run:
-- SELECT cron.schedule('generate_daily_questions_job', '0 0 * * *', 'SELECT public.generate_daily_questions();');

-- For immediate testing right now, let's just run it once manually so today has a question!
SELECT public.generate_daily_questions();
