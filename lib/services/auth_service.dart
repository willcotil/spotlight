import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Wrapper service for all authentication-related API interactions.
///
/// This class encapsulates Supabase auth flows and exposes simple methods
/// for email/password login, registration and OAuth login via Google.
class AuthService {
  final _supabase = Supabase.instance.client;

  /// Currently signed-in Supabase user, or `null` when no user is authenticated.
  User? get currentUser => _supabase.auth.currentUser;

  /// Stream of authentication state changes (sign in / sign out events).
  Stream<AuthState> get onAuthStateChange => _supabase.auth.onAuthStateChange;

  /// Signs in a user with email and password credentials.
  Future<void> signInWithEmail(String email, String senha) async {
    await _supabase.auth.signInWithPassword(email: email, password: senha);
  }

  /// Creates a new user account in Supabase and stores optional profile data.
  Future<void> signUp({
    required String email,
    required String senha,
    required String nome,
    DateTime? dataNascimento,
    String? telefone,
  }) async {
    await _supabase.auth.signUp(
      email: email,
      password: senha,
      data: {
        'full_name': nome,
        if (dataNascimento != null)
          'data_nascimento': dataNascimento.toIso8601String().substring(0, 10),
        if (telefone != null && telefone.isNotEmpty) 'telefone': telefone,
      },
    );
  }

  /// Initiates Google OAuth login.
  ///
  /// Supports web and desktop flows, handling redirect URLs and code exchange
  /// when needed for native desktop environments.
  Future<void> signInWithGoogle() async {
    if (kIsWeb) {
      await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: Uri.base.origin,
        authScreenLaunchMode: LaunchMode.externalApplication,
      );
      return;
    }

    final platform = defaultTargetPlatform;
    final isDesktop =
        platform == TargetPlatform.windows ||
        platform == TargetPlatform.macOS ||
        platform == TargetPlatform.linux;

    if (isDesktop) {
      final server = await HttpServer.bind('localhost', 0);
      final port = server.port;
      final redirectUrl = 'http://localhost:$port';

      await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: redirectUrl,
        authScreenLaunchMode: LaunchMode.externalApplication,
      );

      HttpRequest? request;
      try {
        request = await server.first.timeout(const Duration(minutes: 3));
      } on TimeoutException {
        await server.close(force: true);
        throw Exception('Tempo de autenticacao expirado. Tente novamente.');
      }

      final code = request.uri.queryParameters['code'];
      request.response
        ..statusCode = 200
        ..headers.contentType = ContentType.html
        ..write(
          '<html><body><h2>Login realizado! Voce pode fechar esta aba.</h2></body></html>',
        );
      await request.response.close();
      await server.close(force: true);

      if (code == null) {
        throw Exception('Codigo de autenticacao nao encontrado.');
      }
      await _supabase.auth.exchangeCodeForSession(code);
      return;
    }

    await _supabase.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'br.com.spotlight://login-callback',
      authScreenLaunchMode: LaunchMode.externalApplication,
    );
  }

  /// Signs out the current authenticated user from Supabase.
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
}
