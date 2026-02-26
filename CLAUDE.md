# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

ResearchHubV2 is a full-stack mobile/web app for searching scientific papers with AI-powered summaries. Flutter frontend, Python FastAPI backend, Supabase for auth/data, Google Gemini 2.5 Flash for AI features.

## Common Commands

### Backend (run from `backend/`)
```bash
# Install dependencies
pip install -r requirements.txt

# Run dev server
uvicorn main:app --reload --host 0.0.0.0 --port 8000

# Health check: http://localhost:8000/health
# Swagger docs: http://localhost:8000/docs
```

### Frontend (run from `frontend/`)
```bash
# Install dependencies
flutter pub get

# Run on Chrome
flutter run -d chrome

# Run on Android emulator
flutter run -d emulator-5554

# Static analysis
flutter analyze

# Run tests
flutter test
```

### Environment Setup
Backend requires `backend/.env` (copy from `.env.example`) with: `GEMINI_API_KEY`, `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `SUPABASE_JWT_SECRET`, `ALLOWED_ORIGINS`.

Frontend Supabase keys can be passed via `--dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...` or are defaulted in `frontend/lib/core/constants/api_constants.dart`.

## Architecture

### Backend (`backend/`)
Layered FastAPI app: **Routers → Services → External APIs**.

- `main.py` — App entry, CORS config, router registration
- `app/config.py` — Pydantic `BaseSettings` loading from `.env`
- `app/dependencies.py` — JWT auth dependency (verifies Supabase tokens via HS256/RS256)
- `app/routers/papers.py` — `GET /api/papers/search` (no auth)
- `app/routers/ai.py` — `POST /api/ai/summarize`, `POST /api/ai/analyze-pdf` (JWT required)
- `app/services/paper_aggregator.py` — Concurrent search across arXiv, OpenAlex, Semantic Scholar using `asyncio.gather()`, deduplicates by title
- `app/services/gemini_service.py` — Gemini API integration for summaries and PDF analysis
- `app/models/paper.py` — Pydantic models: `Paper`, `PaperSearchResult`, `SourceStatus`

### Frontend (`frontend/lib/`)
Flutter app using **Riverpod** for state management and **Dio** for HTTP.

- `main.dart` — Initializes Supabase and SharedPreferences
- `app.dart` — MaterialApp with auth gate, bottom navigation (IndexedStack)
- **Services** (`services/`) — Domain-specific HTTP/Supabase clients (auth, papers, AI, favorites, profile, search history)
- **Providers** (`providers/`) — Riverpod providers and AsyncNotifiers for reactive state
- **Screens** (`screens/`) — One directory per screen: login, search, details, favorites, settings, profile
- **Models** (`models/paper.dart`) — `Paper`, `SourceStatus`, `PaperSearchResult`, `PaperCollection`
- `core/constants/api_constants.dart` — Backend URL auto-selects: `localhost:8000` for web, `10.0.2.2:8000` for Android emulator
- `core/theme/app_theme.dart` — Material Design 3 light/dark themes
- `core/l10n/app_localizations.dart` — Manual i18n for EN, RU, KK

### Database (`supabase/`)
- `schema.sql` — Tables: `profiles`, `collections`, `favorites` with Row-Level Security
- Profile auto-created on signup via trigger; all tables RLS-restricted to owning user

## Key Patterns

- **Multi-source aggregation**: Backend searches 3 paper APIs concurrently; partial results shown if a source fails, with `SourceStatus` indicating per-source health
- **Paper IDs** are source-prefixed: `arxiv:`, `openalex:`, `s2:`
- **JWT flow**: Frontend gets token from Supabase Auth → sends as `Authorization: Bearer` header → backend verifies against Supabase JWT secret or JWKS
- **Search history** is local-only (SharedPreferences, last 20 queries)
- **Favorites/collections** are stored in Supabase with RLS
- **Localization**: 3 languages (EN/RU/KK) with locale persisted in SharedPreferences and Supabase profile

## API Endpoints

| Method | Endpoint | Auth | Purpose |
|--------|----------|------|---------|
| GET | `/health` | No | Health check |
| GET | `/api/papers/search` | No | Search papers (params: `query`, `page`, `per_page`, `source`, `year_from`, `year_to`) |
| POST | `/api/ai/summarize` | JWT | AI summary of paper abstract |
| POST | `/api/ai/analyze-pdf` | JWT | Full PDF analysis (up to 20MB) |
