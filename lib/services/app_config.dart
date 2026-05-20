import 'package:spotlight/services/app_secrets.dart';

/// App configuration values that define the backend API endpoints used by the app.
abstract class AppConfig {
  /// Supabase project URL used for authentication and database access.
  static const supabaseUrl = AppSecrets.supabaseUrl;

  /// Supabase anonymous API key used for client-side authentication.
  static const supabaseAnonKey = AppSecrets.supabaseAnonKey;
}
