import 'dart:async';

import 'package:flutter/material.dart';
import 'package:spotlight/services/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Manages authentication state and login-modal visibility for the whole app.
class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  StreamSubscription<AuthState>? _authSub;

  bool _isLoggedIn = false;
  String? _userId;
  User? _currentUser;
  bool _showLoginModal = false;

  bool get isLoggedIn => _isLoggedIn;
  String? get userId => _userId;
  User? get currentUser => _currentUser;
  bool get showLoginModal => _showLoginModal;

  AuthProvider() {
    final user = _authService.currentUser;
    _isLoggedIn = user != null;
    _userId = user?.id;
    _currentUser = user;

    _authSub = _authService.onAuthStateChange.listen((event) {
      final user = event.session?.user;
      _isLoggedIn = user != null;
      _userId = user?.id;
      _currentUser = user;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  // ── Modal helpers ──────────────────────────────────────────────────────────

  void openLoginModal() {
    _showLoginModal = true;
    notifyListeners();
  }

  void closeLoginModal() {
    _showLoginModal = false;
    notifyListeners();
  }

  // ── Auth actions ───────────────────────────────────────────────────────────

  Future<void> signInWithEmail(String email, String password) async {
    final normalizedEmail = email.trim().toLowerCase();
    final normalizedPassword = password.trim();

    if (normalizedEmail.isEmpty || normalizedPassword.isEmpty) {
      throw Exception('Preencha e-mail e senha para continuar.');
    }

    await _authService.signInWithEmail(normalizedEmail, normalizedPassword);
    _showLoginModal = false;
    notifyListeners();
  }

  Future<void> signUp({
    required String nome,
    required String email,
    required String senha,
    required String telefone,
    required String dataNascimento,
  }) async {
    final normalizedName = nome.trim();
    final normalizedEmail = email.trim().toLowerCase();
    final normalizedPassword = senha.trim();

    if (normalizedName.isEmpty ||
        normalizedEmail.isEmpty ||
        normalizedPassword.isEmpty) {
      throw Exception('Nome, e-mail e senha sao obrigatorios.');
    }

    await _authService.signUp(
      email: normalizedEmail,
      senha: normalizedPassword,
      nome: normalizedName,
      telefone: telefone.trim(),
      dataNascimento: _parseBirthDate(dataNascimento),
    );

    _showLoginModal = false;
    notifyListeners();
  }

  Future<void> signInWithGoogle() async {
    await _authService.signInWithGoogle();
    _showLoginModal = false;
    notifyListeners();
  }

  Future<void> signOut() async {
    await _authService.signOut();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  DateTime? _parseBirthDate(String value) {
    final text = value.trim();
    if (text.isEmpty) return null;
    final parts = text.split('/');
    if (parts.length != 3) return null;
    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) return null;
    return DateTime(year, month, day);
  }
}
