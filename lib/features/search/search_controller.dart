import 'package:flutter/material.dart';
import 'package:spotlight/models/movie.dart';

class SearchController {
  final List<Movie> favorites;
  final ValueChanged<Movie> onSelect;

  SearchController({
    required this.favorites,
    required this.onSelect,
  });

  void selectMovie(Movie movie) {
    onSelect(movie);
  }

  bool isFavorite(Movie movie) {
    return favorites.any((m) => m.id == movie.id);
  }
}
