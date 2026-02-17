import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/l10n/app_localizations.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/locale_provider.dart';
import 'screens/login/login_screen.dart';
import 'screens/search/search_screen.dart';
import 'screens/favorites/favorites_screen.dart';
import 'screens/settings/settings_screen.dart';

class ResearchHubApp extends ConsumerWidget {
  const ResearchHubApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'ResearchHub',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      locale: locale,
      supportedLocales: supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const _AuthGate(),
    );
  }
}

/// Redirects to Login or Home based on auth state.
class _AuthGate extends ConsumerWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoggedIn = ref.watch(isLoggedInProvider);
    return isLoggedIn ? const _HomeShell() : const LoginScreen();
  }
}

/// Bottom-navigation shell: Search, Favorites, Settings.
class _HomeShell extends StatefulWidget {
  const _HomeShell();

  @override
  State<_HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<_HomeShell> {
  int _index = 0;

  static const _screens = [
    SearchScreen(),
    FavoritesScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.search),
            selectedIcon: const Icon(Icons.search_rounded),
            label: l10n.searchTitle,
          ),
          NavigationDestination(
            icon: const Icon(Icons.bookmark_border),
            selectedIcon: const Icon(Icons.bookmark),
            label: l10n.favoritesTitle,
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
            label: l10n.settingsTitle,
          ),
        ],
      ),
    );
  }
}
