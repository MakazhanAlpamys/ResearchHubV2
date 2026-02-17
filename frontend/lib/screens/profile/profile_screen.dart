import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/l10n/app_localizations.dart';
import '../../services/profile_service.dart';

final _profileServiceProvider =
    Provider<ProfileService>((ref) => ProfileService());

final _profileProvider = FutureProvider<Map<String, dynamic>?>((ref) {
  return ref.read(_profileServiceProvider).getProfile();
});

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _nameController = TextEditingController();
  bool _saving = false;
  bool _initialized = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref.read(_profileServiceProvider).updateProfile(
            displayName: _nameController.text.trim(),
          );
      ref.invalidate(_profileProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).profileSaved)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).error)),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final profileAsync = ref.watch(_profileProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.profile)),
      body: profileAsync.when(
        data: (profile) {
          if (!_initialized && profile != null) {
            _nameController.text = profile['display_name'] as String? ?? '';
            _initialized = true;
          }
          final email =
              profile?['email'] as String? ??
              (Supabase.instance.client.auth.currentUser?.email ?? '');

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              // Avatar placeholder
              Center(
                child: CircleAvatar(
                  radius: 48,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Text(
                    _nameController.text.isNotEmpty
                        ? _nameController.text[0].toUpperCase()
                        : (email.isNotEmpty ? email[0].toUpperCase() : '?'),
                    style: theme.textTheme.headlineLarge?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  email,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: l10n.displayName,
                  prefixIcon: const Icon(Icons.person_outline),
                ),
                textInputAction: TextInputAction.done,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.saveProfile),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(l10n.error)),
      ),
    );
  }
}
