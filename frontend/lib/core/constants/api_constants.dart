import 'package:flutter/foundation.dart' show kIsWeb;

/// Central configuration.
/// Override for production builds via:
///   flutter build --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
class ApiConstants {
  ApiConstants._();

  // Backend
  // Web (Chrome) → localhost, Android emulator → 10.0.2.2
  static String get backendBaseUrl =>
      kIsWeb ? 'http://localhost:8000/api' : 'http://10.0.2.2:8000/api';

  // Supabase – anon key is designed to be public (paired with RLS).
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://fkordtloppoiqrpnmhxt.supabase.co',
  );
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZrb3JkdGxvcHBvaXFycG5taHh0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzEyMjE0OTMsImV4cCI6MjA4Njc5NzQ5M30.JnsdHKVAgaTmY6sh0QvH6qGaEGq9dQXAqiyyLNz0MVk',
  );
}
