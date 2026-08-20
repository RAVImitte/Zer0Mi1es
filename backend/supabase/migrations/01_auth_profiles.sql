-- Create the public.profiles table
CREATE TABLE public.profiles (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  display_name text NOT NULL,
  avatar_id uuid,
  pet_id uuid,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- Enable Row Level Security (RLS)
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Policy: Users can read their own profile
CREATE POLICY "read own profile" 
ON public.profiles 
FOR SELECT 
TO authenticated 
USING (id = auth.uid());

-- Policy: Users can update their own profile
CREATE POLICY "update own profile" 
ON public.profiles 
FOR UPDATE 
TO authenticated 
USING (id = auth.uid())
WITH CHECK (id = auth.uid());

-- Policy: Users can insert their own profile (typically done via trigger on auth.users creation, but good to have)
CREATE POLICY "insert own profile" 
ON public.profiles 
FOR INSERT 
TO authenticated 
WITH CHECK (id = auth.uid());
