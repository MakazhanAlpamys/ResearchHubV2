import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';
import '../profile/profile_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static const _languageLabels = {
    'en': 'English',
    'ru': 'Русский',
    'kk': 'Қазақша',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final currentLocale = ref.watch(localeProvider);
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        children: [
          const SizedBox(height: 8),
          // Profile
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: Text(l10n.profile),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ),
          ),
          const Divider(),
          // Language
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(l10n.language,
                style: theme.textTheme.labelLarge
                    ?.copyWith(color: theme.colorScheme.primary)),
          ),
          for (final entry in _languageLabels.entries)
            ListTile(
              title: Text(entry.value),
              leading: Icon(
                currentLocale.languageCode == entry.key
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: currentLocale.languageCode == entry.key
                    ? theme.colorScheme.primary
                    : null,
              ),
              onTap: () {
                ref.read(localeProvider.notifier).setLocale(Locale(entry.key));
              },
            ),
          const Divider(),
          // Dark mode
          SwitchListTile(
            title: Text(l10n.darkMode),
            secondary: const Icon(Icons.dark_mode),
            value: themeMode == ThemeMode.dark,
            onChanged: (v) {
              ref.read(themeModeProvider.notifier).setTheme(
                  v ? ThemeMode.dark : ThemeMode.light);
            },
          ),
          const Divider(),
          // Sign out
          ListTile(
            leading: const Icon(Icons.logout),
            title: Text(l10n.signOut),
            onTap: () => ref.read(authServiceProvider).signOut(),
          ),
        ],
      ),
    );
  }
}
