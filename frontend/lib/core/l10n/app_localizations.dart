import 'package:flutter/widgets.dart';

/// Supported locales for ResearchHubV2.
const supportedLocales = [
  Locale('en'),
  Locale('ru'),
  Locale('kk'),
];

/// Simple localization delegate without code generation.
class AppLocalizations {
  final Locale locale;
  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  String get _lang => locale.languageCode;

  // ── Helpers ──────────────────────────────────────────────

  String _t(Map<String, String> map) => map[_lang] ?? map['en']!;

  // ── Strings ──────────────────────────────────────────────

  String get appTitle => _t({
        'en': 'ResearchHub',
        'ru': 'ResearchHub',
        'kk': 'ResearchHub',
      });

  String get searchTitle => _t({
        'en': 'Search Papers',
        'ru': 'Поиск статей',
        'kk': 'Мақалаларды іздеу',
      });

  String get favoritesTitle => _t({
        'en': 'Favorites',
        'ru': 'Избранное',
        'kk': 'Таңдаулылар',
      });

  String get settingsTitle => _t({
        'en': 'Settings',
        'ru': 'Настройки',
        'kk': 'Баптаулар',
      });

  String get searchHint => _t({
        'en': 'Search for papers…',
        'ru': 'Искать статьи…',
        'kk': 'Мақалаларды іздеу…',
      });

  String get signIn => _t({
        'en': 'Sign In',
        'ru': 'Войти',
        'kk': 'Кіру',
      });

  String get signUp => _t({
        'en': 'Sign Up',
        'ru': 'Регистрация',
        'kk': 'Тіркелу',
      });

  String get email => _t({
        'en': 'Email',
        'ru': 'Электронная почта',
        'kk': 'Электрондық пошта',
      });

  String get password => _t({
        'en': 'Password',
        'ru': 'Пароль',
        'kk': 'Құпия сөз',
      });

  String get confirmPassword => _t({
        'en': 'Confirm password',
        'ru': 'Подтвердите пароль',
        'kk': 'Құпия сөзді растаңыз',
      });

  String get emailRequired => _t({
        'en': 'Email is required',
        'ru': 'Введите почту',
        'kk': 'Поштаны енгізіңіз',
      });

  String get emailInvalid => _t({
        'en': 'Enter a valid email',
        'ru': 'Введите корректную почту',
        'kk': 'Дұрыс пошта енгізіңіз',
      });

  String get passwordRequired => _t({
        'en': 'Password is required',
        'ru': 'Введите пароль',
        'kk': 'Құпия сөзді енгізіңіз',
      });

  String get passwordTooShort => _t({
        'en': 'Password must be at least 6 characters',
        'ru': 'Пароль минимум 6 символов',
        'kk': 'Құпия сөз кемінде 6 таңба',
      });

  String get passwordsDoNotMatch => _t({
        'en': 'Passwords do not match',
        'ru': 'Пароли не совпадают',
        'kk': 'Құпия сөздер сәйкес келмейді',
      });

  String get noAccount => _t({
        'en': 'Don\'t have an account?',
        'ru': 'Нет аккаунта?',
        'kk': 'Аккаунтыңыз жоқ па?',
      });

  String get haveAccount => _t({
        'en': 'Already have an account?',
        'ru': 'Уже есть аккаунт?',
        'kk': 'Аккаунтыңыз бар ма?',
      });

  String get registrationSuccess => _t({
        'en': 'Registration successful! You can now sign in.',
        'ru': 'Регистрация успешна! Теперь войдите.',
        'kk': 'Тіркелу сәтті! Енді кіріңіз.',
      });

  String get loadMore => _t({
        'en': 'Load more',
        'ru': 'Загрузить ещё',
        'kk': 'Тағы жүктеу',
      });

  String get signOut => _t({
        'en': 'Sign Out',
        'ru': 'Выйти',
        'kk': 'Шығу',
      });

  String get aiSummary => _t({
        'en': 'AI Summary',
        'ru': 'AI Резюме',
        'kk': 'AI Түйіндеме',
      });

  String get generateSummary => _t({
        'en': 'Generate Summary',
        'ru': 'Создать резюме',
        'kk': 'Түйіндеме жасау',
      });

  String get addToFavorites => _t({
        'en': 'Add to Favorites',
        'ru': 'В избранное',
        'kk': 'Таңдаулыларға қосу',
      });

  String get removeFromFavorites => _t({
        'en': 'Remove from Favorites',
        'ru': 'Убрать из избранного',
        'kk': 'Таңдаулылардан алып тастау',
      });

  String get noResults => _t({
        'en': 'No results found',
        'ru': 'Ничего не найдено',
        'kk': 'Нәтижелер табылмады',
      });

  String get noFavorites => _t({
        'en': 'No favorites yet',
        'ru': 'Пока нет избранных',
        'kk': 'Әзірге таңдаулылар жоқ',
      });

  String get language => _t({
        'en': 'Language',
        'ru': 'Язык',
        'kk': 'Тіл',
      });

  String get theme => _t({
        'en': 'Theme',
        'ru': 'Тема',
        'kk': 'Тақырып',
      });

  String get darkMode => _t({
        'en': 'Dark Mode',
        'ru': 'Тёмная тема',
        'kk': 'Қараңғы тақырып',
      });

  String get authors => _t({
        'en': 'Authors',
        'ru': 'Авторы',
        'kk': 'Авторлар',
      });

  String get abstract_ => _t({
        'en': 'Abstract',
        'ru': 'Аннотация',
        'kk': 'Аннотация',
      });

  String get openPdf => _t({
        'en': 'Open PDF',
        'ru': 'Открыть PDF',
        'kk': 'PDF ашу',
      });

  String get filters => _t({
        'en': 'Filters',
        'ru': 'Фильтры',
        'kk': 'Сүзгілер',
      });

  String get yearFrom => _t({
        'en': 'Year from',
        'ru': 'Год от',
        'kk': 'Жылдан',
      });

  String get yearTo => _t({
        'en': 'Year to',
        'ru': 'Год до',
        'kk': 'Жылға дейін',
      });

  String get source => _t({
        'en': 'Source',
        'ru': 'Источник',
        'kk': 'Дереккөз',
      });

  String get allSources => _t({
        'en': 'All sources',
        'ru': 'Все источники',
        'kk': 'Барлық дереккөздер',
      });

  String get apply => _t({
        'en': 'Apply',
        'ru': 'Применить',
        'kk': 'Қолдану',
      });

  String get error => _t({
        'en': 'Something went wrong',
        'ru': 'Произошла ошибка',
        'kk': 'Қателік орын алды',
      });

  String get retry => _t({
        'en': 'Retry',
        'ru': 'Повторить',
        'kk': 'Қайталау',
      });

  String get welcomeTitle => _t({
        'en': 'Welcome to ResearchHub',
        'ru': 'Добро пожаловать в ResearchHub',
        'kk': 'ResearchHub-қа қош келдіңіз',
      });

  String get welcomeSubtitle => _t({
        'en': 'Discover, summarize, and save\nscientific papers with AI',
        'ru': 'Находите, суммируйте и сохраняйте\nнаучные статьи с помощью ИИ',
        'kk': 'AI көмегімен ғылыми мақалаларды\nтабыңыз, қорытыңыз және сақтаңыз',
      });

  // ── New strings ──────────────────────────────────────────

  String get profile => _t({
        'en': 'Profile',
        'ru': 'Профиль',
        'kk': 'Профиль',
      });

  String get displayName => _t({
        'en': 'Display Name',
        'ru': 'Отображаемое имя',
        'kk': 'Көрсетілетін аты',
      });

  String get saveProfile => _t({
        'en': 'Save',
        'ru': 'Сохранить',
        'kk': 'Сақтау',
      });

  String get profileSaved => _t({
        'en': 'Profile saved',
        'ru': 'Профиль сохранён',
        'kk': 'Профиль сақталды',
      });

  String get recentSearches => _t({
        'en': 'Recent searches',
        'ru': 'Недавние запросы',
        'kk': 'Соңғы іздеулер',
      });

  String get clearHistory => _t({
        'en': 'Clear history',
        'ru': 'Очистить историю',
        'kk': 'Тарихты тазалау',
      });

  String get sourceUnavailable => _t({
        'en': 'unavailable',
        'ru': 'недоступен',
        'kk': 'қол жетімсіз',
      });

  String get copyCitation => _t({
        'en': 'Copy Citation',
        'ru': 'Копировать цитату',
        'kk': 'Дәйексөзді көшіру',
      });

  String get citationCopied => _t({
        'en': 'Citation copied',
        'ru': 'Цитата скопирована',
        'kk': 'Дәйексөз көшірілді',
      });

  String get collections => _t({
        'en': 'Collections',
        'ru': 'Коллекции',
        'kk': 'Жинақтар',
      });

  String get allFavorites => _t({
        'en': 'All Favorites',
        'ru': 'Все избранные',
        'kk': 'Барлық таңдаулылар',
      });

  String get newCollection => _t({
        'en': 'New Collection',
        'ru': 'Новая коллекция',
        'kk': 'Жаңа жинақ',
      });

  String get collectionName => _t({
        'en': 'Collection name',
        'ru': 'Название коллекции',
        'kk': 'Жинақ атауы',
      });

  String get create => _t({
        'en': 'Create',
        'ru': 'Создать',
        'kk': 'Жасау',
      });

  String get delete => _t({
        'en': 'Delete',
        'ru': 'Удалить',
        'kk': 'Жою',
      });

  String get moveToCollection => _t({
        'en': 'Move to collection',
        'ru': 'Переместить в коллекцию',
        'kk': 'Жинаққа жылжыту',
      });

  String get addedToFavorites => _t({
        'en': 'Added to favorites',
        'ru': 'Добавлено в избранное',
        'kk': 'Таңдаулыларға қосылды',
      });

  String get removedFromFavorites => _t({
        'en': 'Removed from favorites',
        'ru': 'Удалено из избранного',
        'kk': 'Таңдаулылардан алынды',
      });

  String get analyzePdf => _t({
        'en': 'Analyze Full PDF',
        'ru': 'Анализ полного PDF',
        'kk': 'Толық PDF талдау',
      });

  String get pdfAnalysis => _t({
        'en': 'PDF Analysis',
        'ru': 'Анализ PDF',
        'kk': 'PDF талдауы',
      });

  String get cancel => _t({
        'en': 'Cancel',
        'ru': 'Отмена',
        'kk': 'Болдырмау',
      });
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['en', 'ru', 'kk'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale);

  @override
  bool shouldReload(covariant LocalizationsDelegate old) => false;
}
