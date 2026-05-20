// Central API services export for all Spotlight backend integrations.
//
// This module groups the application's backend integrations in a single access point:
// - Supabase configuration and authentication
// - Movie and TV metadata retrieval from TMDB
// - Gemini text generation (optional AI assistant)
// - Review and cache CRUD operations from Supabase
//
// Import this file when the application needs to access any of the service classes.

export 'app_config.dart';
export 'app_exceptions.dart';
export 'auth_service.dart';
export 'gemini_service.dart';
export 'review_service.dart';
export 'tmdb_service.dart';
