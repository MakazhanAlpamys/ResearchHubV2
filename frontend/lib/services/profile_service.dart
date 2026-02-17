import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileService {
  final _supabase = Supabase.instance.client;

  String? get _userId => _supabase.auth.currentUser?.id;

  Future<Map<String, dynamic>?> getProfile() async {
    final userId = _userId;
    if (userId == null) return null;

    return await _supabase
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();
  }

  Future<void> updateProfile({
    String? displayName,
    String? preferredLang,
  }) async {
    final userId = _userId;
    if (userId == null) throw StateError('User not authenticated');

    final updates = <String, dynamic>{};
    if (displayName != null) updates['display_name'] = displayName;
    if (preferredLang != null) updates['preferred_lang'] = preferredLang;

    if (updates.isNotEmpty) {
      await _supabase.from('profiles').update(updates).eq('id', userId);
    }
  }
}
