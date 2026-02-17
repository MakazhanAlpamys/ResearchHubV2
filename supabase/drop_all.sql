-- ============================================================
-- ResearchHubV2 – Drop Everything (clean slate)
-- Run this in Supabase SQL Editor to wipe the DB,
-- then re-run schema.sql to recreate from scratch.
-- ============================================================

-- 1. Drop triggers first (they depend on functions and tables)
DROP TRIGGER IF EXISTS profiles_updated_at   ON public.profiles;
DROP TRIGGER IF EXISTS on_auth_user_created  ON auth.users;

-- 2. Drop tables with CASCADE (auto-removes RLS policies, indexes, FKs)
DROP TABLE IF EXISTS public.favorites   CASCADE;
DROP TABLE IF EXISTS public.collections CASCADE;
DROP TABLE IF EXISTS public.profiles    CASCADE;

-- 3. Drop functions
DROP FUNCTION IF EXISTS public.update_updated_at();
DROP FUNCTION IF EXISTS public.handle_new_user();
