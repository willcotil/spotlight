import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Gerencia a preferência de tema claro/escuro.
///
/// A preferência é persistida com [SharedPreferences] para sobreviver
/// ao fechamento do aplicativo.
class ThemeProvider extends ChangeNotifier {
  static const _kDarkModeKey = 'darkMode';

  bool _darkMode = true; // Padrão: modo escuro.

  bool get darkMode => _darkMode;

  /// Inicializa o provider e carrega a preferência salva.
  ThemeProvider() {
    _loadPreference();
  }

  /// Alterna entre claro e escuro, salvando a nova preferência.
  Future<void> toggleTheme() async {
    _darkMode = !_darkMode;
    notifyListeners();
    await _savePreference(_darkMode);
  }

  // ── Persistência ───────────────────────────────────────────────────────────

  Future<void> _loadPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Se a chave não existir ainda, mantém o padrão (true = escuro).
      _darkMode = prefs.getBool(_kDarkModeKey) ?? true;
      notifyListeners();
    } catch (_) {
      // Falha silenciosa; mantém o valor padrão.
    }
  }

  Future<void> _savePreference(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kDarkModeKey, value);
    } catch (_) {
      // Falha silenciosa.
    }
  }
}
