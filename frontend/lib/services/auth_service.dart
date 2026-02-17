import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final _supabase = Supabase.instance.client;

  User? get currentUser => _supabase.auth.currentUser;
  String? get userId => currentUser?.id;
  bool get isLoggedIn => currentUser != null;

  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  Future<void> signIn({required String email, required String password}) async {
    await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signUp({required String email, required String password}) async {
    await _supabase.auth.signUp(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
}
