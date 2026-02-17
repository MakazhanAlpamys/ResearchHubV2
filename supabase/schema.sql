-- ============================================================
-- ResearchHubV2 – Supabase Database Schema
-- ============================================================

-- 1. Profiles (extends auth.users with app-specific fields)
CREATE TABLE public.profiles (
  id             UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  display_name   TEXT NOT NULL DEFAULT '',
  avatar_url     TEXT NOT NULL DEFAULT '',
  preferred_lang TEXT NOT NULL DEFAULT 'en'
                   CHECK (preferred_lang IN ('en', 'ru', 'kk')),
  created_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 2. Collections (folders for organizing favorites)
CREATE TABLE public.collections (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  name        TEXT NOT NULL,
  color       TEXT NOT NULL DEFAULT '#0061A4',
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(user_id, name)
);

CREATE INDEX idx_collections_user_id ON public.collections(user_id);

-- 3. Favorites (saved papers per user)
CREATE TABLE public.favorites (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id        UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  paper_id       TEXT NOT NULL,            -- external ID (arXiv, OpenAlex, etc.)
  title          TEXT NOT NULL,
  authors        TEXT[] NOT NULL DEFAULT '{}',
  abstract       TEXT NOT NULL DEFAULT '',
  published_date DATE,
  source         TEXT NOT NULL DEFAULT '', -- 'arxiv' | 'openalex' | 'semantic_scholar'
  url            TEXT NOT NULL DEFAULT '',
  pdf_url        TEXT NOT NULL DEFAULT '',
  collection_id  UUID REFERENCES public.collections(id) ON DELETE SET NULL,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(user_id, paper_id)
);

-- Index for fast lookup of a user's favorites
CREATE INDEX idx_favorites_user_id ON public.favorites(user_id);

-- ============================================================
-- Row-Level Security
-- ============================================================

ALTER TABLE public.profiles    ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.collections ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.favorites   ENABLE ROW LEVEL SECURITY;

-- Profiles: users can only access their own row
CREATE POLICY "profiles_select_own"
  ON public.profiles FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "profiles_insert_own"
  ON public.profiles FOR INSERT
  WITH CHECK (auth.uid() = id);

CREATE POLICY "profiles_update_own"
  ON public.profiles FOR UPDATE
  USING (auth.uid() = id);

-- Favorites: users can only access their own rows
CREATE POLICY "favorites_select_own"
  ON public.favorites FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "favorites_insert_own"
  ON public.favorites FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "favorites_update_own"
  ON public.favorites FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "favorites_delete_own"
  ON public.favorites FOR DELETE
  USING (auth.uid() = user_id);

-- Collections: users can only access their own rows
CREATE POLICY "collections_select_own"
  ON public.collections FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "collections_insert_own"
  ON public.collections FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "collections_update_own"
  ON public.collections FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "collections_delete_own"
  ON public.collections FOR DELETE
  USING (auth.uid() = user_id);

-- ============================================================
-- Trigger: auto-create profile on sign-up
-- ============================================================

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  INSERT INTO public.profiles (id, display_name, avatar_url)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data ->> 'full_name',
             NEW.raw_user_meta_data ->> 'name', ''),
    COALESCE(NEW.raw_user_meta_data ->> 'avatar_url',
             NEW.raw_user_meta_data ->> 'picture', '')
  );
  RETURN NEW;
END;
$$;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- ============================================================
-- Trigger: auto-update updated_at on profiles
-- ============================================================

CREATE OR REPLACE FUNCTION public.update_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

CREATE TRIGGER profiles_updated_at
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at();
