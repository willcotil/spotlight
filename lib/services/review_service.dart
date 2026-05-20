import 'package:spotlight/models/movie.dart';
import 'package:spotlight/models/review.dart';
import 'package:spotlight/services/app_exceptions.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;

/// Service for creating, updating and querying movie reviews.
///
/// This service stores reviews in Supabase and keeps a local media cache
/// record in the `midias_cache` table to connect TMDb IDs with app data.
///
/// Lança [AuthException] para erros de permissão e [NetworkException] para
/// falhas de conectividade ou respostas inesperadas.
class ReviewService {
  final _db = Supabase.instance.client;

  /// Returns all reviews for a given TMDb item, ordered by newest first.
  Future<List<Review>> getReviews({required int tmdbId}) async {
    try {
      final midiaId = await _getMidiaId(tmdbId);
      if (midiaId == null) {
        return [];
      }

      final data = await _db
          .from('avaliacoes')
          .select('*, profiles(nome, avatar_url)')
          .eq('midia_id', midiaId)
          .order('criado_em', ascending: false);

      return (data as List)
          .map((row) => Review.fromSupabaseJson(row as Map<String, dynamic>))
          .toList();
    } on SpotlightAuthException {
      rethrow;
    } on PostgrestException catch (e) {
      if (e.code == '42501' || e.message.contains('permission')) {
        throw const SpotlightAuthException('Sem permissão para acessar avaliações.');
      }
      throw NetworkException('Erro ao buscar avaliações: ${e.message}');
    } catch (_) {
      throw const NetworkException('Falha ao carregar avaliações.');
    }
  }

  /// Returns the current user's review for a given TMDb item, if any.
  Future<Review?> getUserReview({
    required int tmdbId,
    required String userId,
  }) async {
    try {
      final midiaId = await _getMidiaId(tmdbId);
      if (midiaId == null) {
        return null;
      }

      final data = await _db
          .from('avaliacoes')
          .select('*, profiles(nome, avatar_url)')
          .eq('midia_id', midiaId)
          .eq('usuario_id', userId)
          .maybeSingle();

      if (data == null) {
        return null;
      }

      return Review.fromSupabaseJson(data);
    } on SpotlightAuthException {
      rethrow;
    } on PostgrestException catch (e) {
      if (e.code == '42501' || e.message.contains('permission')) {
        throw const SpotlightAuthException();
      }
      throw NetworkException('Erro ao buscar avaliação do usuário: ${e.message}');
    } catch (_) {
      throw const NetworkException('Falha ao carregar avaliação.');
    }
  }

  /// Creates a review record for the current user and media item.
  Future<Review> createReview({
    required String userId,
    required Movie movie,
    required int nota,
    String? comentario,
  }) async {
    try {
      final midiaId = await _upsertMidiaCache(movie);

      final data = await _db
          .from('avaliacoes')
          .insert({
            'usuario_id': userId,
            'midia_id': midiaId,
            'nota': nota,
            if (comentario != null && comentario.isNotEmpty)
              'comentario': comentario,
          })
          .select('*, profiles(nome, avatar_url)')
          .single();

      return Review.fromSupabaseJson(data);
    } on SpotlightAuthException {
      rethrow;
    } on NetworkException {
      rethrow;
    } on PostgrestException catch (e) {
      if (e.code == '42501' || e.message.contains('permission')) {
        throw const SpotlightAuthException('Você precisa estar logado para avaliar.');
      }
      throw NetworkException('Erro ao salvar avaliação: ${e.message}');
    } catch (_) {
      throw const NetworkException('Falha ao salvar avaliação.');
    }
  }

  /// Updates an existing review with a new score and optional comment.
  Future<Review> updateReview({
    required String reviewId,
    required int nota,
    String? comentario,
  }) async {
    try {
      final data = await _db
          .from('avaliacoes')
          .update({
            'nota': nota,
            'comentario': comentario,
            'atualizado_em': DateTime.now().toIso8601String(),
          })
          .eq('id', reviewId)
          .select('*, profiles(nome, avatar_url)')
          .single();

      return Review.fromSupabaseJson(data);
    } on SpotlightAuthException {
      rethrow;
    } on NetworkException {
      rethrow;
    } on PostgrestException catch (e) {
      if (e.code == '42501' || e.message.contains('permission')) {
        throw const SpotlightAuthException('Sem permissão para editar esta avaliação.');
      }
      throw NetworkException('Erro ao atualizar avaliação: ${e.message}');
    } catch (_) {
      throw const NetworkException('Falha ao atualizar avaliação.');
    }
  }

  /// Deletes a review by its Supabase review ID.
  Future<void> deleteReview(String reviewId) async {
    try {
      await _db.from('avaliacoes').delete().eq('id', reviewId);
    } on PostgrestException catch (e) {
      if (e.code == '42501' || e.message.contains('permission')) {
        throw const SpotlightAuthException('Sem permissão para excluir esta avaliação.');
      }
      throw NetworkException('Erro ao excluir avaliação: ${e.message}');
    } catch (_) {
      throw const NetworkException('Falha ao excluir avaliação.');
    }
  }

  /// Looks up the internal cached media record for a TMDb item.
  Future<int?> _getMidiaId(int tmdbId) async {
    final data = await _db
        .from('midias_cache')
        .select('id')
        .eq('tmdb_id', tmdbId)
        .maybeSingle();

    return data?['id'] as int?;
  }

  /// Inserts or updates the local media cache record for a movie or show.
  Future<int> _upsertMidiaCache(Movie movie) async {
    final data = await _db
        .from('midias_cache')
        .upsert(_movieToCacheJson(movie), onConflict: 'tmdb_id')
        .select('id')
        .single();

    return data['id'] as int;
  }

  /// Converts a Movie object into the JSON format required by Supabase.
  Map<String, dynamic> _movieToCacheJson(Movie movie) {
    return {
      'tmdb_id': movie.id,
      'titulo': movie.title,
      'tipo': movie.type == 'Serie' || movie.type == 'Série' ? 'tv' : 'movie',
      'sinopse': movie.synopsis,
      'poster_path': movie.posterUrl,
      'backdrop_path': movie.backdropUrl,
      'data_lancamento': _toReleaseDate(movie.year),
      'ultima_sincronizacao': DateTime.now().toIso8601String(),
    };
  }

  String? _toReleaseDate(String year) {
    final value = year.trim();
    if (value.length != 4) {
      return null;
    }
    return '$value-01-01';
  }
}
