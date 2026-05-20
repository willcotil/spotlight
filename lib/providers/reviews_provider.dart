import 'package:flutter/material.dart';
import 'package:spotlight/models/cast_member.dart';
import 'package:spotlight/models/movie.dart';
import 'package:spotlight/models/review.dart';
import 'package:spotlight/providers/auth_provider.dart';
import 'package:spotlight/services/review_service.dart';
import 'package:spotlight/services/tmdb_service.dart';
import 'package:spotlight/models/episode.dart';

/// Owns the currently-selected movie and all its async detail data:
/// reviews, cast, content rating, and watch providers.
class ReviewsProvider extends ChangeNotifier {
  final ReviewService _reviewService;
  AuthProvider _auth;

  Movie? _selectedMovie;
  List<Review> _contentReviews = [];
  Review? _userReview;
  List<CastMember> _contentCast = [];
  String? _contentRating;
  bool _loadingComments = false;
  
  List<Episode> _episodes = [];
  List<Movie> _relatedByDirector = [];
  List<Movie> _relatedByActor = [];
  List<Movie> _similar = [];
  int? _tvNumberOfSeasons;
  int _selectedSeason = 1;
  bool _loadingRelated = false;
  Map<String, dynamic>? _contentDetails;

  Movie? get selectedMovie => _selectedMovie;
  List<Review> get contentReviews => List.unmodifiable(_contentReviews);
  Review? get userReview => _userReview;
  List<CastMember> get contentCast => List.unmodifiable(_contentCast);
  String? get contentRating => _contentRating;
  bool get loadingComments => _loadingComments;
  
  List<Episode> get episodes => List.unmodifiable(_episodes);
  List<Movie> get relatedByDirector => List.unmodifiable(_relatedByDirector);
  List<Movie> get relatedByActor => List.unmodifiable(_relatedByActor);
  List<Movie> get similar => List.unmodifiable(_similar);
  int? get tvNumberOfSeasons => _tvNumberOfSeasons;
  int get selectedSeason => _selectedSeason;
  bool get loadingRelated => _loadingRelated;
  Map<String, dynamic>? get contentDetails => _contentDetails;

  ReviewsProvider(this._reviewService, this._auth);

  /// Called by ProxyProvider when AuthProvider changes.
  void updateAuth(AuthProvider auth) {
    _auth = auth;
    // Reload reviews if a movie is currently selected (e.g. after login).
    if (_selectedMovie != null) {
      _loadReviews(_selectedMovie!);
    }
  }

  // ── Open / close details ───────────────────────────────────────────────────

  void openDetails(Movie movie) {
    _selectedMovie = movie;
    _contentReviews = [];
    _userReview = null;
    _contentCast = [];
    _contentRating = null;
    _loadingComments = false;
    _loadingRelated = true;
    _episodes = [];
    _relatedByDirector = [];
    _relatedByActor = [];
    _similar = [];
    _tvNumberOfSeasons = null;
    _selectedSeason = 1;
    _contentDetails = null;
    notifyListeners();

    _loadReviews(movie);
    _loadCastAndRelated(movie);
    _loadContentRating(movie);
    _loadWatchProviders(movie);
    _loadSimilar(movie);
    _loadContentDetails(movie);
    if (movie.type == 'Série') {
      _loadTvData(movie);
    }
  }

  void closeDetails() {
    _selectedMovie = null;
    notifyListeners();
  }

  Future<void> loadSeason(int seasonNumber) async {
    final movie = _selectedMovie;
    if (movie == null || movie.type != 'Série') return;
    
    _selectedSeason = seasonNumber;
    notifyListeners();
    await loadEpisodesForSeason(seasonNumber);
  }

  // ── Private loaders ────────────────────────────────────────────────────────

  Future<void> _loadReviews(Movie movie) async {
    _loadingComments = true;
    notifyListeners();
    try {
      final reviews = await _reviewService.getReviews(tmdbId: movie.id);
      final uid = _auth.userId;
      Review? userReview;
      if (uid != null) {
        userReview = await _reviewService.getUserReview(
          tmdbId: movie.id,
          userId: uid,
        );
      }
      if (_selectedMovie?.id != movie.id) return;
      _contentReviews = reviews;
      _userReview = userReview;
    } catch (_) {
      // Graceful degradation — leave empty list.
    } finally {
      _loadingComments = false;
      notifyListeners();
    }
  }

  Future<void> _loadCastAndRelated(Movie movie) async {
    try {
      final cast = await TMDBService.fetchCast(movie.id, movie.type);
      if (_selectedMovie?.id != movie.id) return;
      _contentCast = cast;
      notifyListeners();

      if (cast.isNotEmpty) {
        final mainActorId = cast.first.id;
        final actorMovies = await TMDBService.fetchActorFilmography(mainActorId);
        if (_selectedMovie?.id == movie.id) {
          _relatedByActor = actorMovies.where((m) => m.id != movie.id).take(8).toList();
        }
      }

      if (movie.type == 'Filme') {
        final directorId = await TMDBService.fetchDirectorId(movie.id);
        if (directorId != null) {
          final directorMovies = await TMDBService.fetchRelatedByDirector(directorId);
          if (_selectedMovie?.id == movie.id) {
            _relatedByDirector = directorMovies.where((m) => m.id != movie.id).take(8).toList();
          }
        }
      } else if (movie.type == 'Série') {
        final creatorId = await TMDBService.fetchTvCreator(movie.id);
        if (creatorId != null) {
          final creatorMovies = await TMDBService.fetchActorFilmography(creatorId);
          if (_selectedMovie?.id == movie.id) {
            _relatedByDirector = creatorMovies.where((m) => m.id != movie.id).take(8).toList();
          }
        }
      }
      if (_selectedMovie?.id == movie.id) {
        _loadingRelated = false;
        notifyListeners();
      }
    } catch (_) {
      if (_selectedMovie?.id == movie.id) {
        _loadingRelated = false;
        notifyListeners();
      }
    }
  }

  Future<void> _loadContentDetails(Movie movie) async {
    try {
      final details = await TMDBService.fetchMovieDetails(movie.id, movie.type);
      if (_selectedMovie?.id != movie.id) return;
      _contentDetails = details;
      
      if (details != null) {
        String? finalBrTitle;

        // 1. Tenta pegar o título das traduções oficiais (BR)
        if (details['translations'] != null) {
          final trans = details['translations']['translations'] as List?;
          final br = trans?.firstWhere(
            (t) => t['iso_3166_1'] == 'BR',
            orElse: () => null,
          );
          if (br != null && br['data'] != null) {
            finalBrTitle = br['data']['title'] ?? br['data']['name'];
          }
        }

        // 2. Se falhar, tenta nos 'Alternative Titles' (BR)
        if ((finalBrTitle == null || finalBrTitle.isEmpty) && details['alternative_titles'] != null) {
          final alt = (details['alternative_titles']['results'] ?? details['alternative_titles']['titles']) as List?;
          final brAlt = alt?.firstWhere(
            (a) => a['iso_3166_1'] == 'BR',
            orElse: () => null,
          );
          if (brAlt != null) {
            finalBrTitle = brAlt['title'] ?? brAlt['name'];
          }
        }

        // 3. Como última instância, usa o título principal da API
        if (finalBrTitle == null || finalBrTitle.isEmpty) {
          finalBrTitle = details['title'] ?? details['name'];
        }

        if (finalBrTitle != null && finalBrTitle.isNotEmpty) {
          _selectedMovie = _selectedMovie!.copyWith(title: finalBrTitle);
        }
      }
      
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _loadSimilar(Movie movie) async {
    try {
      final similar = await TMDBService.fetchSimilar(movie.id, movie.type);
      if (_selectedMovie?.id != movie.id) return;
      _similar = similar
          .where((m) =>
              m.id != movie.id &&
              m.rating >= 6.0 &&
              m.posterUrl != null &&
              m.posterUrl!.isNotEmpty)
          .take(8)
          .toList();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _loadTvData(Movie movie) async {
    try {
      final seasons = await TMDBService.fetchTvNumberOfSeasons(movie.id);
      if (_selectedMovie?.id != movie.id) return;
      _tvNumberOfSeasons = seasons ?? 1;
      
      final eps = await TMDBService.fetchEpisodes(movie.id, 1);
      if (_selectedMovie?.id != movie.id) return;
      _episodes = eps;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> loadEpisodesForSeason(int seasonNumber) async {
    final movie = _selectedMovie;
    if (movie == null || movie.type != 'Série') return;
    
    try {
      final eps = await TMDBService.fetchEpisodes(movie.id, seasonNumber);
      if (_selectedMovie?.id != movie.id) return;
      _episodes = eps;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _loadContentRating(Movie movie) async {
    try {
      final rating = await TMDBService.fetchContentRating(movie.id, movie.type);
      if (_selectedMovie?.id != movie.id) return;
      _contentRating = rating ?? 'L';
      notifyListeners();
    } catch (_) {
      _contentRating = 'L';
      notifyListeners();
    }
  }

  Future<void> _loadWatchProviders(Movie movie) async {
    try {
      final providers = await TMDBService.fetchWatchProviders(
        movie.id,
        movie.type,
      );
      if (_selectedMovie?.id != movie.id) return;
      _selectedMovie = _selectedMovie!.copyWith(platforms: providers);
      notifyListeners();
    } catch (_) {}
  }

  // ── Public rating / comment actions ───────────────────────────────────────

  Future<bool> submitRating(Movie movie, int stars, String comment) async {
    if (!_auth.isLoggedIn) {
      _auth.openLoginModal();
      return true;
    }
    final uid = _auth.userId;
    if (uid == null) {
      _auth.openLoginModal();
      return true;
    }

    try {
      final cleanComment = comment.trim();
      if (_userReview != null) {
        await _reviewService.updateReview(
          reviewId: _userReview!.id,
          nota: stars,
          comentario: cleanComment.isEmpty ? null : cleanComment,
        );
      } else {
        await _reviewService.createReview(
          userId: uid,
          movie: movie,
          nota: stars,
          comentario: cleanComment.isEmpty ? null : cleanComment,
        );
      }
      await _loadReviews(movie);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteRating(Movie movie) async {
    if (!_auth.isLoggedIn || _userReview == null) {
      _auth.openLoginModal();
      return true;
    }
    try {
      await _reviewService.deleteReview(_userReview!.id);
      await _loadReviews(movie);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Updates a review entry and reloads the list for [movie].
  Future<void> updateReviewAndReload({
    required Movie movie,
    required String reviewId,
    required int nota,
    required String? comentario,
  }) async {
    await _reviewService.updateReview(
      reviewId: reviewId,
      nota: nota,
      comentario: comentario,
    );
    await _loadReviews(movie);
  }

  Future<void> deleteComment(Movie movie, Review review) async {
    try {
      await _reviewService.deleteReview(review.id);
      await _loadReviews(movie);
    } catch (_) {}
  }
}
