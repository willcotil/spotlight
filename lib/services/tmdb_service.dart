import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:spotlight/models/cast_member.dart';
import 'package:spotlight/models/movie.dart';
import 'package:spotlight/models/episode.dart';
import 'package:spotlight/services/app_exceptions.dart';
import 'package:spotlight/services/app_secrets.dart';

/// Service wrapper for The Movie Database (TMDb) API calls.
class TMDBService {
  static const String baseUrl = 'https://api.themoviedb.org/3';
  static const String token = AppSecrets.tmdbToken;

  static const Map<String, String> _headers = {
    'Authorization': 'Bearer $token',
    'accept': 'application/json',
  };

  static const int _maxRetries = 2;
  static const Duration _retryDelay = Duration(seconds: 1);

  static Future<T> _withRetry<T>(Future<T> Function() fn) async {
    int attempts = 0;
    while (true) {
      attempts++;
      try {
        return await fn();
      } on ParseException {
        rethrow;
      } on NetworkException catch (e) {
        if (e.message.contains('4')) rethrow;
        if (attempts > _maxRetries) rethrow;
        await Future<void>.delayed(_retryDelay);
      } on SocketException {
        if (attempts > _maxRetries) throw const NetworkException();
        await Future<void>.delayed(_retryDelay);
      } on TimeoutException {
        if (attempts > _maxRetries) throw const NetworkException('Tempo limite atingido.');
        await Future<void>.delayed(_retryDelay);
      } catch (_) {
        if (attempts > _maxRetries) throw const NetworkException();
        await Future<void>.delayed(_retryDelay);
      }
    }
  }

  static Future<Map<String, dynamic>> _get(String url) async {
    return _withRetry(() async {
      final response = await http.get(Uri.parse(url), headers: _headers);
      if (response.statusCode >= 400 && response.statusCode < 500) {
        throw NetworkException('Erro ${response.statusCode}');
      }
      if (response.statusCode >= 500) {
        throw NetworkException('Erro de servidor ${response.statusCode}');
      }
      try {
        return json.decode(response.body) as Map<String, dynamic>;
      } catch (_) {
        throw const ParseException();
      }
    });
  }

  static List<Movie> _filterFutureContent(dynamic data) {
    if (data['results'] == null) return [];
    final results = data['results'] as List;
    // Limite de 2026 conforme contexto do projeto
    final limitDate = DateTime(2026, 12, 31);
    
    return results.where((item) {
      final dateStr = item['release_date'] ?? item['first_air_date'] ?? '';
      if (dateStr.toString().isEmpty) return true; // Mantém se não houver data (evita esconder clássicos sem metadata)
      
      final date = DateTime.tryParse(dateStr.toString());
      if (date == null) return true;
      
      // Filtra apenas se a data for explicitamente depois do limite de 2026
      return date.isBefore(limitDate.add(const Duration(days: 1)));
    }).map((item) => Movie.fromJson(item as Map<String, dynamic>)).toList();
  }

  // ── Endpoints públicos (Restaurados para Brasil) ───────────────────────────

  static Future<List<Movie>> fetchTrending({required String type}) async {
    final endpoint = type == 'tv' ? '/trending/tv/week' : '/trending/movie/week';
    final data = await _get('$baseUrl$endpoint?language=pt-BR&region=BR');
    return _filterFutureContent(data);
  }

  static Future<List<Movie>> fetchGenre({required int genreId}) async {
    final data = await _get('$baseUrl/discover/movie?with_genres=$genreId&language=pt-BR&region=BR');
    return _filterFutureContent(data);
  }

  static Future<List<Movie>> fetchTopRated({required String type}) async {
    final endpoint = type == 'tv' ? '/tv/top_rated' : '/movie/top_rated';
    final data = await _get('$baseUrl$endpoint?language=pt-BR&region=BR');
    return _filterFutureContent(data);
  }

  static Future<List<Movie>> fetchFamily() async => fetchGenre(genreId: 10751);
  static Future<List<Movie>> fetchHorror() async => fetchGenre(genreId: 27);
  static Future<List<Movie>> fetchAction() async => fetchGenre(genreId: 28);
  static Future<List<Movie>> fetchAnimation() async => fetchGenre(genreId: 16);
  static Future<List<Movie>> fetchSciFi() async => fetchGenre(genreId: 878);

  static Future<List<Movie>> fetchOscar2026() async {
    // Filtro mais amplo: Filmes de 2024/2025 com boa nota e popularidade
    final data = await _get('$baseUrl/discover/movie?primary_release_date.gte=2024-10-01&primary_release_date.lte=2025-12-31&vote_count.gte=50&sort_by=popularity.desc&language=pt-BR&region=BR');
    return _filterFutureContent(data);
  }

  static Future<List<Movie>> fetchNewsByProvider({required int providerId, required String type}) async {
    final endpoint = type == 'tv' ? '/discover/tv' : '/discover/movie';
    final data = await _get('$baseUrl$endpoint?with_watch_providers=$providerId&watch_region=BR&language=pt-BR&region=BR');
    return _filterFutureContent(data);
  }

  static Future<List<Movie>> searchMedia(String query) => search(query);

  static Future<List<Movie>> search(String query) async {
    if (query.trim().isEmpty) return [];
    final data = await _get('$baseUrl/search/multi?query=${Uri.encodeComponent(query)}&language=pt-BR&region=BR');
    return _filterFutureContent(data)
        .where((m) => m.type == 'Filme' || m.type == 'Série')
        .toList();
  }

  static const Map<int, String> _providerSlugMap = {
    8: 'netflix', 119: 'prime', 337: 'disney', 384: 'hbo', 1899: 'hbo', 350: 'apple', 307: 'globoplay',
    167: 'star', 619: 'paramount', 531: 'paramount', 283: 'crunchyroll', 188: 'mubi', 2: 'apple',
  };

  static Future<List<String>> fetchWatchProviders(int id, String type) async {
    try {
      final endpoint = type == 'Série' ? 'tv' : 'movie';
      final data = await _get('$baseUrl/$endpoint/$id/watch/providers');
      final br = (data['results'] as Map?)?['BR'] as Map?;
      if (br == null) return type != 'Série' ? ['cinemark'] : [];
      final slugs = <String>{};
      final providers = [...(br['flatrate'] ?? []), ...(br['rent'] ?? []), ...(br['buy'] ?? [])];
      for (final p in providers) {
        final pid = p['provider_id'] as int?;
        if (pid != null && _providerSlugMap.containsKey(pid)) slugs.add(_providerSlugMap[pid]!);
      }
      return slugs.isEmpty && type != 'Série' ? ['cinemark'] : slugs.toList();
    } catch (_) { return []; }
  }

  static Future<String?> fetchTrailer({required int id, required String type, int? seasonNumber}) async {
    try {
      final endpoint = type == 'Série' ? '/tv/$id/season/${seasonNumber ?? 1}/videos' : '/movie/$id/videos';
      String? findKey(List? list) {
        if (list == null || list.isEmpty) return null;
        final v = list.firstWhere((v) => v['type'] == 'Trailer' && v['site'] == 'YouTube',
          orElse: () => list.firstWhere((v) => v['type'] == 'Teaser' && v['site'] == 'YouTube',
            orElse: () => list.firstWhere((v) => v['site'] == 'YouTube', orElse: () => null)));
        return v?['key'];
      }
      var data = await _get('$baseUrl$endpoint?language=pt-BR');
      var key = findKey(data['results']);
      if (key == null) {
        data = await _get('$baseUrl$endpoint?language=en-US');
        key = findKey(data['results']);
      }
      return key != null ? 'https://www.youtube.com/watch?v=$key' : null;
    } catch (_) { return null; }
  }

  static Future<Map<String, dynamic>?> fetchImages(int id, String type) async {
    try {
      final endpoint = type == 'Série' ? 'tv' : 'movie';
      return await _get('$baseUrl/$endpoint/$id/images?include_image_language=pt,en,null');
    } catch (_) { return null; }
  }

  static Future<List<CastMember>> fetchCast(int id, String type) async {
    try {
      final endpoint = type == 'Série' ? 'tv' : 'movie';
      final data = await _get('$baseUrl/$endpoint/$id/credits?language=pt-BR');
      return (data['cast'] as List?)?.take(10).map((i) => CastMember.fromJson(i)).toList() ?? [];
    } catch (_) { return []; }
  }

  static Future<String?> fetchContentRating(int id, String type) async {
    try {
      final isSeries = type == 'Série';
      final endpoint = isSeries ? 'tv' : 'movie';
      final append = isSeries ? 'content_ratings' : 'release_dates';
      final data = await _get('$baseUrl/$endpoint/$id?language=pt-BR&append_to_response=$append');
      if (isSeries) {
        for (final r in (data['content_ratings']?['results'] ?? [])) {
          if (r['iso_3166_1'] == 'BR') return _normalizeBrRating(r['rating'] ?? '');
        }
      } else {
        for (final r in (data['release_dates']?['results'] ?? [])) {
          if (r['iso_3166_1'] == 'BR') {
            for (final rel in (r['release_dates'] ?? [])) {
              if (rel['certification']?.isNotEmpty ?? false) return _normalizeBrRating(rel['certification']);
            }
          }
        }
      }
      return 'L';
    } catch (_) { return 'L'; }
  }

  static String _normalizeBrRating(String raw) {
    const valid = {'L', 'A10', 'A12', 'A14', 'A16', 'A18', '10', '12', '14', '16', '18'};
    if (valid.contains(raw)) return raw.length <= 2 && int.tryParse(raw) != null ? 'A$raw' : raw;
    return 'L';
  }

  static Future<int?> fetchDirectorId(int movieId) async {
    try {
      final data = await _get('$baseUrl/movie/$movieId/credits?language=pt-BR');
      for (final m in (data['crew'] ?? [])) { if (m['job'] == 'Director') return m['id']; }
      return null;
    } catch (_) { return null; }
  }

  static Future<List<Movie>> fetchRelatedByDirector(int directorId) async {
    try {
      final data = await _get('$baseUrl/discover/movie?with_crew=$directorId&language=pt-BR&region=BR');
      return (data['results'] as List).map((i) => Movie.fromJson(i)).toList();
    } catch (_) { return []; }
  }

  static Future<List<Episode>> fetchEpisodes(int tvId, int seasonNumber) async {
    try {
      final data = await _get('$baseUrl/tv/$tvId/season/$seasonNumber?language=pt-BR');
      return (data['episodes'] as List).map((i) => Episode.fromJson(i)).toList();
    } catch (_) { return []; }
  }

  static Future<int?> fetchTvNumberOfSeasons(int tvId) async {
    try {
      final data = await _get('$baseUrl/tv/$tvId?language=pt-BR');
      final seasons = data['seasons'] as List?;
      if (seasons != null) {
        int max = 0;
        final now = DateTime.now();
        for (final s in seasons) {
          final n = s['season_number'] ?? 0;
          final date = DateTime.tryParse(s['air_date'] ?? '');
          if (n > 0 && s['episode_count'] > 0 && date != null && date.isBefore(now.add(const Duration(days: 30)))) {
            if (n > max) max = n;
          }
        }
        if (max > 0) return max;
      }
      return data['number_of_seasons'];
    } catch (_) { return null; }
  }

  static Future<Map<String, dynamic>?> fetchActorDetails(int personId) async {
    try { return await _get('$baseUrl/person/$personId?language=pt-BR'); } catch (_) { return null; }
  }

  static Future<List<Movie>> fetchActorFilmography(int personId) async {
    try {
      final data = await _get('$baseUrl/person/$personId/combined_credits?language=pt-BR&region=BR');
      return (data['cast'] as List).where((i) => i['media_type'] == 'movie' || i['media_type'] == 'tv')
          .map((i) => Movie.fromJson(i)).toList();
    } catch (_) { return []; }
  }

  static Future<List<Movie>> fetchSimilar(int id, String type) async {
    try {
      final endpoint = type == 'Série' ? 'tv' : 'movie';
      final data = await _get('$baseUrl/$endpoint/$id/similar?language=pt-BR&region=BR');
      return (data['results'] as List).map((i) => Movie.fromJson(i)).toList();
    } catch (_) { return []; }
  }

  static Future<int?> fetchTvCreator(int tvId) async {
    try {
      final data = await _get('$baseUrl/tv/$tvId?language=pt-BR');
      final creators = data['created_by'] as List?;
      return (creators != null && creators.isNotEmpty) ? creators[0]['id'] : null;
    } catch (_) { return null; }
  }

  static Future<Map<String, dynamic>?> fetchMovieDetails(int id, String type) async {
    try {
      final endpoint = type == 'Série' ? 'tv' : 'movie';
      return await _get('$baseUrl/$endpoint/$id?append_to_response=alternative_titles,translations,release_dates,content_ratings&language=pt-BR&region=BR');
    } catch (_) { return null; }
  }
}
