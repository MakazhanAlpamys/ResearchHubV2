# ResearchHubV2

Мобильное приложение для поиска научных статей с AI-резюме.

**Стек:** Flutter · FastAPI · Supabase · Google Gemini 2.5 Flash

---

## Требования

| Инструмент | Версия | Проверка |
|---|---|---|
| **Python** | 3.10+ | `python --version` |
| **Flutter SDK** | 3.10+ | `flutter --version` |
| **Chrome** | любая | для веб-запуска |
| **Git** | любая | `git --version` |

> Flutter должен быть в PATH. Если `flutter doctor` показывает проблемы — исправь их перед запуском.

---

## Быстрый старт (пошагово)

### Шаг 1. Клонирование репозитория

```bash
git clone <URL_РЕПОЗИТОРИЯ>
cd ResearchHubV2
```

### Шаг 2. Настройка Supabase

1. Зайди на [supabase.com](https://supabase.com) → **New Project** → выбери регион, задай пароль БД
2. Дождись создания проекта (1-2 мин)
3. Зайди в **SQL Editor** → нажми **New query**
4. Скопируй всё содержимое файла `supabase/schema.sql` → вставь в редактор → нажми **Run**
5. Убедись что **Authentication → Providers → Email** включён (включён по умолчанию)
6. Перейди в **Settings → API** и скопируй три значения:
   - `Project URL` — выглядит как `https://abcdefg.supabase.co`
   - `anon public` key — длинная строка начинающаяся с `eyJ...`
   - `JWT Secret` — секрет для проверки токенов

> Эти значения понадобятся и для бэкенда (.env), и для фронтенда (--dart-define).

### Шаг 3. Получение ключа Google Gemini

1. Зайди на [aistudio.google.com/apikey](https://aistudio.google.com/apikey)
2. Нажми **Create API Key** → выбери проект → скопируй ключ
3. Ключ выглядит как `AIzaSy...` — сохрани его

### Шаг 4. Запуск Backend (Python + FastAPI)

#### 4.1. Создай виртуальное окружение

```bash
cd backend
python -m venv venv
```

#### 4.2. Активируй виртуальное окружение

**Windows (CMD):**
```cmd
venv\Scripts\activate
```

**Windows (PowerShell):**
```powershell
.\venv\Scripts\Activate.ps1
```
> Если PowerShell блокирует скрипт, выполни сначала:
> `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser`

**macOS / Linux:**
```bash
source venv/bin/activate
```

После активации в начале строки терминала появится `(venv)`.

#### 4.3. Установи зависимости

```bash
pip install -r requirements.txt
```

Устанавливаются: FastAPI, Uvicorn, httpx, google-generativeai, pydantic-settings, python-dotenv, PyJWT.

#### 4.4. Настрой переменные окружения

Создай файл `.env` из шаблона:

**Windows (CMD):**
```cmd
copy .env.example .env
```

**macOS / Linux:**
```bash
cp .env.example .env
```

Открой `.env` в любом редакторе и заполни реальными значениями:

```env
GEMINI_API_KEY=AIzaSy...твой_ключ
SUPABASE_URL=https://abcdefg.supabase.co
SUPABASE_ANON_KEY=eyJhbGci...твой_ключ
SUPABASE_JWT_SECRET=your-jwt-secret-from-supabase-dashboard
ALLOWED_ORIGINS=http://localhost:3000,http://localhost:8080
```

> `SUPABASE_JWT_SECRET` находится в Supabase Dashboard → Settings → API → JWT Secret. Он нужен для проверки токенов при запросах к AI-эндпоинтам.

#### 4.5. Запусти сервер

```bash
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

#### 4.6. Проверь что бэкенд работает

Открой в браузере: **http://localhost:8000/docs**

Должна появиться страница **Swagger UI** с эндпоинтами:
- `GET /api/papers/search` — поиск статей
- `POST /api/ai/summarize` — AI-резюме
- `POST /api/ai/analyze-pdf` — анализ полного PDF
- `GET /health` — проверка здоровья

> **Бэкенд должен работать всё время, пока используется приложение.** Не закрывай этот терминал.

### Шаг 5. Запуск Frontend (Flutter)

#### 5.1. Настрой API-ключи

Supabase ключи передаются через `--dart-define` при запуске (или заданы по умолчанию в `api_constants.dart`):

```bash
flutter run -d chrome \
  --dart-define=SUPABASE_URL=https://abcdefg.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJhbGci...
```

> Адрес бэкенда (`backendBaseUrl`) определяется автоматически: `localhost:8000` для Chrome, `10.0.2.2:8000` для Android-эмулятора.

#### 5.2. Установи зависимости Flutter

```bash
cd frontend
flutter pub get
```

#### 5.3. Запусти приложение

**Запуск в Chrome (рекомендуется для быстрой проверки):**
```bash
flutter run -d chrome
```

**Запуск на Android-эмуляторе:**
```bash
flutter run -d emulator-5554
```
> Чтобы увидеть список доступных устройств: `flutter devices`

**Запуск на физическом Android-устройстве (USB):**
1. Включи **Отладку по USB** в настройках разработчика телефона
2. Подключи телефон по USB
3. `flutter run`

> При запуске на физическом устройстве измени `backendBaseUrl` на IP своего компьютера в локальной сети (напр. `http://192.168.1.100:8000/api`)

### Шаг 6. Регистрация и использование

1. На экране входа нажми **«Регистрация»**
2. Введи email и пароль (минимум 6 символов)
3. После регистрации войди с этими данными
4. Используй поиск для нахождения научных статей
5. Нажимай на статью для просмотра деталей и генерации AI-резюме

---

## Структура проекта

```
ResearchHubV2/
├── .gitignore
├── README.md
├── supabase/
│   └── schema.sql               # SQL-схема (profiles, favorites, collections, RLS)
│   └── drop_all.sql               # drop all
├── backend/
│   ├── main.py                  # FastAPI — точка входа
│   ├── requirements.txt         # Python-зависимости
│   ├── .env.example             # Шаблон переменных окружения
│   ├── .env                     # Реальные ключи (НЕ коммитить!)
│   └── app/
│       ├── config.py            # Загрузка настроек из .env
│       ├── dependencies.py      # JWT-аутентификация (Supabase токены)
│       ├── models/
│       │   └── paper.py         # Pydantic-модели (Paper, SourceStatus, AnalyzePdf)
│       ├── services/
│       │   ├── paper_aggregator.py  # Поиск: arXiv + OpenAlex + Semantic Scholar
│       │   └── gemini_service.py    # AI-резюме + анализ PDF через Google Gemini
│       └── routers/
│           ├── papers.py        # GET /api/papers/search
│           └── ai.py            # POST /api/ai/summarize, POST /api/ai/analyze-pdf
└── frontend/
    ├── pubspec.yaml             # Flutter-зависимости
    └── lib/
        ├── main.dart            # Точка входа (Supabase.initialize, SharedPreferences)
        ├── app.dart             # MaterialApp + навигация + auth gate
        ├── core/
        │   ├── constants/
        │   │   └── api_constants.dart   # URL бэкенда и Supabase (dart-define)
        │   ├── theme/
        │   │   └── app_theme.dart       # Material Design 3 (light/dark)
        │   └── l10n/
        │       └── app_localizations.dart  # Переводы EN / RU / KK
        ├── models/
        │   └── paper.dart       # Модели: Paper, SourceStatus, PaperCollection
        ├── services/
        │   ├── auth_service.dart        # Email/пароль вход (Supabase Auth)
        │   ├── paper_service.dart       # HTTP-клиент для поиска статей
        │   ├── favorites_service.dart   # CRUD избранного + коллекции (Supabase)
        │   ├── ai_service.dart          # HTTP-клиент: AI-резюме + анализ PDF
        │   ├── profile_service.dart     # CRUD профиля пользователя (Supabase)
        │   └── search_history_service.dart  # История поиска (SharedPreferences)
        ├── providers/
        │   ├── auth_provider.dart        # Riverpod: auth state
        │   ├── paper_provider.dart       # Riverpod: поиск + пагинация
        │   ├── favorites_provider.dart   # Riverpod: избранное + коллекции
        │   ├── locale_provider.dart      # Riverpod: язык + тема (SharedPreferences)
        │   └── search_history_provider.dart # Riverpod: история поиска
        ├── screens/
        │   ├── login/login_screen.dart          # Вход / Регистрация
        │   ├── search/search_screen.dart        # Поиск + фильтры + история + статусы
        │   ├── details/paper_detail_screen.dart # Детали + AI-резюме + PDF анализ + цитаты
        │   ├── favorites/favorites_screen.dart  # Избранное + коллекции
        │   ├── settings/settings_screen.dart    # Язык, тема, профиль, выход
        │   └── profile/profile_screen.dart      # Редактирование профиля
        ├── utils/
        │   └── citation_formatter.dart  # Генерация цитат: BibTeX, APA, MLA
        └── widgets/
            └── paper_card.dart  # Карточка статьи
```

## Адреса бэкенда по платформам

| Платформа | `backendBaseUrl` | Настройка |
|---|---|---|
| **Chrome (Web)** | `http://localhost:8000/api` | Автоматически |
| **Android Emulator** | `http://10.0.2.2:8000/api` | Автоматически |
| **iOS Simulator** | `http://127.0.0.1:8000/api` | Вручную |
| **Физическое устройство** | `http://IP_ПК:8000/api` | Вручную |

> Для Chrome и Android-эмулятора адрес выбирается **автоматически** — ничего менять не нужно.
> Для iOS или физического телефона — замени значение в `api_constants.dart`.

## API эндпоинты

| Метод | URL | Описание | Auth | Параметры |
|---|---|---|---|---|
| `GET` | `/api/papers/search` | Поиск статей | Нет | `query`, `page`, `per_page`, `source`, `year_from`, `year_to` |
| `POST` | `/api/ai/summarize` | AI-резюме статьи | JWT | JSON: `title`, `abstract`, `language` |
| `POST` | `/api/ai/analyze-pdf` | Анализ полного PDF | JWT | JSON: `pdf_url`, `language` |
| `GET` | `/health` | Проверка здоровья | Нет | — |

## Функционал

### Основные возможности
- **Авторизация** — регистрация и вход по email + пароль (Supabase Auth)
- **JWT-аутентификация** — все AI-эндпоинты защищены проверкой Supabase JWT-токена
- **Поиск** — одновременный поиск по arXiv, OpenAlex, Semantic Scholar с дедупликацией
- **Фильтры** — по источнику и диапазону годов
- **Пагинация** — кнопка «Загрузить ещё» с корректным `has_more`
- **AI-резюме** — генерация краткого содержания через Google Gemini на 3 языках
- **Анализ PDF** — отправка полного PDF на анализ через Gemini 2.5 Flash (до 20 МБ)
- **Избранное** — сохранение статей в Supabase с RLS-защитой
- **Коллекции** — папки для организации избранных статей (создание, фильтрация, удаление)
- **Экспорт цитат** — копирование в формате BibTeX, APA или MLA
- **Профиль** — редактирование отображаемого имени пользователя

### UX-улучшения
- **Pull-to-refresh** — обновление списка поиска и избранного свайпом вниз
- **История поиска** — последние 20 запросов сохраняются локально (SharedPreferences)
- **Статусы источников** — при сбое источника показывается предупреждение (напр. «arXiv — недоступен»)
- **Обратная связь** — тост-уведомления при добавлении/удалении из избранного и ошибках
- **Состояние загрузки** — кнопка избранного показывает спиннер во время операции
- **Тёмная тема** — переключение light/dark, сохраняется в SharedPreferences
- **Локализация** — English, Русский, Қазақша — сохраняется между сессиями

### Безопасность
- CORS ограничен конкретными доменами (не `*`)
- Сообщения об ошибках бэкенда не раскрывают внутренних деталей
- Supabase-ключи фронтенда передаются через `--dart-define` (не в коде)
- RLS-политики на все таблицы — каждый пользователь видит только свои данные

## Частые проблемы

| Проблема | Решение |
|---|---|
| `flutter: command not found` | Добавь Flutter SDK в PATH, см. [flutter.dev/get-started](https://flutter.dev/get-started/install) |
| PowerShell блокирует `Activate.ps1` | `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser` |
| `pip: command not found` | Убедись что Python установлен и в PATH: `python --version` |
| Backend не отвечает из Chrome | Проверь что бэкенд запущен (`http://localhost:8000/health`) |
| CORS ошибка в браузере | `ALLOWED_ORIGINS` в `.env` должен включать адрес фронтенда |
| Android-эмулятор не видит бэкенд | Используй `10.0.2.2` вместо `localhost` (настроено автоматически) |
| Ошибка Supabase Auth | Проверь что `supabaseUrl` и `supabaseAnonKey` совпадают с данными в Supabase Dashboard |
| `No devices found` | Запусти эмулятор или подключи телефон, проверь `flutter devices` |
| AI-резюме 401 Unauthorized | Убедись что `SUPABASE_JWT_SECRET` в `.env` совпадает с JWT Secret в Supabase Dashboard |
