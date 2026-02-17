import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kLocaleKey = 'preferred_locale';
const _kThemeKey = 'theme_mode';

/// Provided via override in main.dart after pre-loading SharedPreferences.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be overridden in main()');
});

final localeProvider =
    NotifierProvider<LocaleNotifier, Locale>(LocaleNotifier.new);

class LocaleNotifier extends Notifier<Locale> {
  @override
  Locale build() {
    final prefs = ref.read(sharedPreferencesProvider);
    final code = prefs.getString(_kLocaleKey);
    if (code != null) return Locale(code);

    final systemCode =
        WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    const supported = {'en', 'ru', 'kk'};
    return Locale(supported.contains(systemCode) ? systemCode : 'en');
  }

  Future<void> setLocale(Locale locale) async {
    state = locale;
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_kLocaleKey, locale.languageCode);
  }
}

final themeModeProvider =
    NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    final prefs = ref.read(sharedPreferencesProvider);
    final idx = prefs.getInt(_kThemeKey);
    if (idx != null && idx < ThemeMode.values.length) {
      return ThemeMode.values[idx];
    }
    return ThemeMode.system;
  }

  Future<void> setTheme(ThemeMode mode) async {
    state = mode;
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setInt(_kThemeKey, mode.index);
  }
}
