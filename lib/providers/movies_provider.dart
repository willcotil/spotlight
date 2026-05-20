import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:spotlight/models/movie.dart';
import 'package:spotlight/services/app_exceptions.dart';
import 'package:spotlight/services/tmdb_service.dart';

/// Responsável pelas 12 coleções de filmes/séries exibidas na aba Hub.
class MoviesProvider extends ChangeNotifier {
  bool _loading = true;

  /// Mensagem de erro para exibir ao usuário, ou null quando não há erro.
  String? _errorMessage;

  List<Movie> _topSeries = [];
  List<Movie> _topMovies = [];
  List<Movie> _dramaMovies = [];
  List<Movie> _topRatedSeries = [];
  List<Movie> _familyMovies = [];
  List<Movie> _horrorMovies = [];
  List<Movie> _oscar2026Movies = [];
  List<Movie> _actionMovies = [];
  List<Movie> _animationMovies = [];
  List<Movie> _sciFiMovies = [];
  List<Movie> _netflixNew = [];
  List<Movie> _primeNew = [];
  List<Movie> _hboNew = [];
  List<Movie> _disneyNew = [];
  List<Movie> _appleNew = [];
  List<Movie> _carouselItems = [];

  bool get loading => _loading;
  String? get errorMessage => _errorMessage;
  List<Movie> get topSeries => _topSeries;
  List<Movie> get topMovies => _topMovies;
  List<Movie> get dramaMovies => _dramaMovies;
  List<Movie> get topRatedSeries => _topRatedSeries;
  List<Movie> get familyMovies => _familyMovies;
  List<Movie> get horrorMovies => _horrorMovies;
  List<Movie> get oscar2026Movies => _oscar2026Movies;
  List<Movie> get actionMovies => _actionMovies;
  List<Movie> get animationMovies => _animationMovies;
  List<Movie> get sciFiMovies => _sciFiMovies;
  List<Movie> get netflixNew => _netflixNew;
  List<Movie> get primeNew => _primeNew;
  List<Movie> get hboNew => _hboNew;
  List<Movie> get disneyNew => _disneyNew;
  List<Movie> get appleNew => _appleNew;
  List<Movie> get carouselItems => _carouselItems;

  MoviesProvider() {
    // Agenda após o primeiro frame para não chamar notifyListeners durante build.
    SchedulerBinding.instance.addPostFrameCallback((_) => loadData());
  }

  Future<void> loadData() async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait<List<Movie>>([
        TMDBService.fetchTrending(type: 'tv'),
        TMDBService.fetchTrending(type: 'movie'),
        TMDBService.fetchGenre(genreId: 18),
        TMDBService.fetchTopRated(type: 'tv'),
        TMDBService.fetchFamily(),
        TMDBService.fetchHorror(),
        TMDBService.fetchOscar2026(),
        TMDBService.fetchNewsByProvider(providerId: 8, type: 'movie'),
        TMDBService.fetchNewsByProvider(providerId: 119, type: 'movie'),
        TMDBService.fetchNewsByProvider(providerId: 1899, type: 'movie'),
        TMDBService.fetchNewsByProvider(providerId: 337, type: 'movie'),
        TMDBService.fetchNewsByProvider(providerId: 350, type: 'movie'),
        TMDBService.fetchAction(),
        TMDBService.fetchAnimation(),
        TMDBService.fetchSciFi(),
      ]);

      _topSeries = results[0];
      _topMovies = results[1];
      _dramaMovies = results[2];
      _topRatedSeries = results[3];
      _familyMovies = results[4];
      _horrorMovies = results[5];
      _oscar2026Movies = results[6];
      _netflixNew = results[7];
      _primeNew = results[8];
      _hboNew = results[9];
      _disneyNew = results[10];
      _appleNew = results[11];
      _actionMovies = results[12];
      _animationMovies = results[13];
      _sciFiMovies = results[14];
      _carouselItems = [..._topMovies.take(3), ..._topSeries.take(2)];
    } on NetworkException catch (e) {
      _errorMessage = e.message;
    } on ParseException catch (e) {
      _errorMessage = e.message;
    } catch (_) {
      _errorMessage = 'Falha ao carregar conteúdo. Tente novamente.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Limpa a mensagem de erro (chamada após exibir o SnackBar).
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

