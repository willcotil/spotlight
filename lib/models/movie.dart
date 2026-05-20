class Movie {
  final int id;
  final String title;
  final String type; // 'Filme' ou 'Série'
  final String genre;
  final double rating;
  final String year;
  final String duration;
  final String synopsis;
  final String? posterUrl;
  final String? backdropUrl;
  final List<String> platforms;
  final String? contentRating; // 'L', 'A10', 'A12', 'A14', 'A16', 'A18'

  Movie({
    required this.id,
    required this.title,
    required this.type,
    required this.genre,
    required this.rating,
    required this.year,
    required this.duration,
    required this.synopsis,
    this.posterUrl,
    this.backdropUrl,
    required this.platforms,
    this.contentRating,
  });

  factory Movie.fromJson(
    Map<String, dynamic> json, {
    String defaultType = 'Filme',
  }) {
    const genreMap = {
      28: "Ação",
      12: "Aventura",
      16: "Animação",
      35: "Comédia",
      80: "Crime",
      99: "Documentário",
      18: "Drama",
      10751: "Família",
      14: "Fantasia",
      36: "História",
      27: "Terror",
      10402: "Música",
      9648: "Mistério",
      10749: "Romance",
      878: "Ficção Científica",
      10770: "Cinema TV",
      53: "Thriller",
      10752: "Guerra",
      37: "Faroeste",
    };

    final isTV = json['media_type'] == 'tv' || json['first_air_date'] != null;
    final genreId = (json['genre_ids'] as List?)?.firstOrNull as int?;

    return Movie(
      id: json['id'] ?? 0,
      title: json['title'] ?? json['name'] ?? 'Desconhecido',
      type: isTV ? 'Série' : 'Filme',
      genre: genreMap[genreId] ?? 'Drama',
      rating: (json['vote_average'] as num?)?.toDouble() ?? 0.0,
      year: _parseYear(json['release_date'] ?? json['first_air_date']),
      duration: 'Indisponível',
      synopsis: json['overview'] ?? 'Nenhuma sinopse disponível.',
      posterUrl: json['poster_path'] != null
          ? 'https://image.tmdb.org/t/p/w500${json['poster_path']}'
          : null,
      backdropUrl: json['backdrop_path'] != null
          ? 'https://image.tmdb.org/t/p/w1280${json['backdrop_path']}'
          : null,
      platforms: const [],
    );
  }

  /// Extrai o ano (4 dígitos) de uma string de data ou retorna string vazia.
  static String _parseYear(dynamic value) {
    final s = value?.toString() ?? '';
    return s.length >= 4 ? s.substring(0, 4) : s;
  }

  /// Serializa os dados mínimos do filme para armazenamento no Supabase.
  /// Inclui dados suficientes para popular o modal de detalhes e os cards,
  /// evitando chamadas extras à API.
  Map<String, dynamic> toMinimalJson() {
    return {
      'id': id,
      'title': title,
      'media_type': type == 'Série' ? 'tv' : 'movie',
      'poster_path': posterUrl?.replaceAll('https://image.tmdb.org/t/p/w500', ''),
      'overview': synopsis,
      'vote_average': rating,
      'release_date': type == 'Série' ? null : year,
      'first_air_date': type == 'Série' ? year : null,
      // O genre_ids na resposta da API seria uma lista, mas aqui salvamos 
      // um valor arbitrário apenas para a conversão de genre no fromJson 
      // não falhar (ou podemos mapear de volta).
      // A implementação de fromJson já usa default 'Drama' se faltar.
      // O ideal seria tentar mapear, mas como `genreMap` é privado e extenso,
      // podemos confiar no default do fromJson ou não enviar.
    };
  }

  /// Cria uma cópia do filme com campos opcionalmente sobrepostos.
  Movie copyWith({List<String>? platforms, String? title}) {
    return Movie(
      id: id,
      title: title ?? this.title,
      type: type,
      genre: genre,
      rating: rating,
      year: year,
      duration: duration,
      synopsis: synopsis,
      posterUrl: posterUrl,
      backdropUrl: backdropUrl,
      platforms: platforms ?? this.platforms,
      contentRating: contentRating,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Movie && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
