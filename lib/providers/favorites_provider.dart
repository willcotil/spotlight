import 'dart:async';

import 'package:flutter/material.dart';
import 'package:spotlight/models/movie.dart';
import 'package:spotlight/providers/auth_provider.dart';
import 'package:spotlight/services/app_exceptions.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Gerencia a lista de favoritos do usuário.
///
/// Escuta o stream de autenticação do Supabase diretamente para reagir
/// a login/logout de forma confiável, sem depender do ProxyProvider.
class FavoritesProvider extends ChangeNotifier {
  AuthProvider _auth;

  final _db = Supabase.instance.client;
  StreamSubscription<AuthState>? _authSub;

  final List<Movie> _favorites = [];

  bool _isLoading = false;
  String? _errorMessage;

  List<Movie> get favorites => List.unmodifiable(_favorites);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  FavoritesProvider(this._auth) {
    // Carrega imediatamente se já há sessão ativa ao iniciar o app.
    final currentUser = _db.auth.currentUser;
    if (currentUser != null) {
      loadFavorites(currentUser.id);
    }

    // Escuta mudanças de auth diretamente no Supabase.
    _authSub = _db.auth.onAuthStateChange.listen((event) {
      final user = event.session?.user;
      if (user != null) {
        loadFavorites(user.id);
      } else {
        _favorites.clear();
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  // ── ProxyProvider ──────────────────────────────────────────────────────────

  /// Mantido para o ProxyProvider continuar funcionando sem erros.
  /// A lógica real de carregar/limpar agora está no stream (_authSub).
  void updateAuth(AuthProvider auth) {
    _auth = auth;
  }

  // ── Consultas ──────────────────────────────────────────────────────────────

  bool isFavorite(Movie movie) => _favorites.any((m) => m.id == movie.id);

  // ── Ações públicas ─────────────────────────────────────────────────────────

  /// Carrega todos os favoritos do usuário a partir do Supabase.
  Future<void> loadFavorites(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final rows = await _db
          .from('favoritos')
          .select()
          .eq('user_id', userId)
          .order('added_at', ascending: false);

      _favorites
        ..clear()
        ..addAll(
          (rows as List)
              .map((r) => _rowToMovie(r as Map<String, dynamic>))
              .toList(),
        );
    } on PostgrestException catch (e) {
      _errorMessage = 'Erro ao carregar favoritos: ${e.message}';
    } on NetworkException catch (e) {
      _errorMessage = e.message;
    } catch (_) {
      _errorMessage = 'Falha ao carregar favoritos.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Alterna um filme entre favorito e não-favorito.
  ///
  /// Retorna `true` quando o modal de login foi exibido (usuário não logado
  /// tentando adicionar). Retorna `false` em qualquer outro caso.
  bool toggleFavorite(Movie movie) {
    if (!_auth.isLoggedIn && !isFavorite(movie)) {
      _auth.openLoginModal();
      return true;
    }

    if (isFavorite(movie)) {
      _removeFavoriteLocal(movie);
      if (_auth.isLoggedIn) {
        removeFavorite(_auth.userId!, movie.id);
      }
    } else {
      _addFavoriteLocal(movie);
      if (_auth.isLoggedIn) {
        syncFavorite(_auth.userId!, movie);
      }
    }

    notifyListeners();
    return false;
  }

  /// Persiste a adição de um favorito no Supabase.
  Future<void> syncFavorite(String userId, Movie movie) async {
    try {
      await _db.from('favoritos').upsert(
        _movieToRow(userId, movie),
        onConflict: 'user_id,tmdb_id',
      );
    } on PostgrestException catch (e) {
      _errorMessage = 'Erro ao salvar favorito: ${e.message}';
      notifyListeners();
    } catch (_) {
      _errorMessage = 'Falha ao salvar favorito no servidor.';
      notifyListeners();
    }
  }

  /// Remove um favorito do Supabase pelo tmdbId.
  Future<void> removeFavorite(String userId, int tmdbId) async {
    try {
      await _db
          .from('favoritos')
          .delete()
          .eq('user_id', userId)
          .eq('tmdb_id', tmdbId);
    } on PostgrestException catch (e) {
      _errorMessage = 'Erro ao remover favorito: ${e.message}';
      notifyListeners();
    } catch (_) {
      _errorMessage = 'Falha ao remover favorito do servidor.';
      notifyListeners();
    }
  }

  /// Limpa a mensagem de erro (chamada após exibir o SnackBar).
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // ── Helpers privados ───────────────────────────────────────────────────────

  void _addFavoriteLocal(Movie movie) {
    if (!isFavorite(movie)) _favorites.add(movie);
  }

  void _removeFavoriteLocal(Movie movie) {
    _favorites.removeWhere((m) => m.id == movie.id);
  }

  /// Converte uma linha do Supabase em um objeto [Movie].
  Movie _rowToMovie(Map<String, dynamic> row) {
    return Movie(
      id: row['tmdb_id'] as int,
      title: row['title'] as String? ?? 'Desconhecido',
      type: row['media_type'] == 'tv' ? 'Série' : 'Filme',
      genre: '',
      rating: 0.0,
      year: '',
      duration: 'Indisponível',
      synopsis: '',
      posterUrl: row['poster_path'] as String?,
      platforms: const [],
    );
  }

  /// Converte um [Movie] no formato JSON esperado pela tabela `favoritos`.
  Map<String, dynamic> _movieToRow(String userId, Movie movie) {
    return {
      'user_id': userId,
      'tmdb_id': movie.id,
      'media_type':
          movie.type == 'Série' || movie.type == 'Serie' ? 'tv' : 'movie',
      'title': movie.title,
      'poster_path': movie.posterUrl,
    };
  }
}
