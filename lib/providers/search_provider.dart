import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:spotlight/models/movie.dart';
import 'package:spotlight/services/app_exceptions.dart';
import 'package:spotlight/services/tmdb_service.dart';

/// Gerencia o estado da tela de busca: query, resultados, carregamento e
/// flag de "já buscou ao menos uma vez".
class SearchProvider extends ChangeNotifier {
  /// Texto digitado pelo usuário na caixa de busca.
  String _query = '';

  /// Lista de resultados retornados pelo TMDb.
  List<Movie> _results = [];

  /// Indica se uma requisição está em andamento.
  bool _isLoading = false;

  /// Verdadeiro após a primeira busca ser disparada (evita mostrar "sem
  /// resultados" antes de o usuário ter digitado algo).
  bool _hasSearched = false;

  /// Mensagem de erro para exibir ao usuário, ou null quando não há erro.
  String? _errorMessage;

  /// Timer responsável pelo debounce de 500 ms.
  Timer? _debounce;

  // ── Getters públicos ───────────────────────────────────────────────────────

  String get query => _query;
  List<Movie> get results => List.unmodifiable(_results);
  bool get isLoading => _isLoading;
  bool get hasSearched => _hasSearched;
  String? get errorMessage => _errorMessage;

  // ── Ações públicas ─────────────────────────────────────────────────────────

  /// Atualiza a query e agenda uma busca com debounce de 500 ms.
  ///
  /// Limpa os resultados imediatamente quando o campo está vazio.
  void search(String query) {
    _query = query;
    _errorMessage = null;

    // Cancela timer anterior para evitar requisições desnecessárias.
    _debounce?.cancel();

    if (query.trim().isEmpty) {
      _results = [];
      _isLoading = false;
      _hasSearched = false;
      notifyListeners();
      return;
    }

    // Marca como carregando imediatamente para feedback visual instantâneo.
    _isLoading = true;
    notifyListeners();

    _debounce = Timer(const Duration(milliseconds: 500), () async {
      await _fetchResults(query.trim());
    });
  }

  /// Limpa completamente o estado de busca (usada ao fechar a aba, por ex.).
  void clear() {
    _debounce?.cancel();
    _query = '';
    _results = [];
    _isLoading = false;
    _hasSearched = false;
    _errorMessage = null;
    notifyListeners();
  }

  /// Limpa a mensagem de erro (chamada após exibir o SnackBar).
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // ── Lógica interna ─────────────────────────────────────────────────────────

  Future<void> _fetchResults(String query) async {
    try {
      final items = await TMDBService.searchMedia(query);

      // Descarta resultado obsoleto se a query mudou enquanto aguardávamos.
      if (_query.trim() != query) return;

      _results = items;
      _hasSearched = true;
    } on NetworkException catch (e) {
      _results = [];
      _hasSearched = true;
      _errorMessage = e.message;
    } on ParseException catch (e) {
      _results = [];
      _hasSearched = true;
      _errorMessage = e.message;
    } catch (_) {
      _results = [];
      _hasSearched = true;
      _errorMessage = 'Falha ao buscar resultados. Tente novamente.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}
