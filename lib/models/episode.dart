class Episode {
  const Episode({
    required this.episodeNumber,
    required this.name,
    this.overview,
    this.stillPath,
    this.airDate,
    this.runtime,
    required this.seasonNumber,
  });

  final int episodeNumber;
  final String name;
  final String? overview;
  final String? stillPath;
  final String? airDate;
  final int? runtime;
  final int seasonNumber;

  factory Episode.fromJson(Map<String, dynamic> json) {
    return Episode(
      episodeNumber: json['episode_number'] as int? ?? 0,
      name: json['name'] as String? ?? 'Sem Título',
      overview: json['overview'] as String?,
      stillPath: json['still_path'] as String?,
      airDate: json['air_date'] as String?,
      runtime: json['runtime'] as int?,
      seasonNumber: json['season_number'] as int? ?? 1,
    );
  }

  @override
  String toString() {
    return 'Episode(S$seasonNumber E$episodeNumber - $name)';
  }
}
