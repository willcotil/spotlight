import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:spotlight/models/episode.dart';
import 'package:spotlight/providers/theme_provider.dart';
import 'package:spotlight/widgets/ui_components.dart';

class EpisodeDetailView extends StatelessWidget {
  const EpisodeDetailView({
    super.key,
    required this.episode,
    required this.seriesName,
  });

  final Episode episode;
  final String seriesName;

  @override
  Widget build(BuildContext context) {
    final darkMode = context.watch<ThemeProvider>().darkMode;
    final textColor = darkMode ? Colors.white : Colors.black;
    final secondaryTextColor = darkMode ? const Color(0xFFD4D4D8) : const Color(0xFF52525B);
    final bgColor = darkMode ? const Color(0xFF09090B) : const Color(0xFFFAFAFA);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        title: Text(
          seriesName,
          style: TextStyle(color: textColor, fontSize: 16),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (episode.stillPath != null)
              Container(
                width: double.infinity,
                height: 240,
                decoration: const BoxDecoration(
                  color: Color(0xFF18181B),
                ),
                child: SmartNetworkImage(
                  imageUrl: 'https://image.tmdb.org/t/p/w780${episode.stillPath}',
                  fit: BoxFit.cover,
                ),
              )
            else
              Container(
                width: double.infinity,
                height: 240,
                color: darkMode ? const Color(0xFF18181B) : const Color(0xFFE4E4E7),
                child: Icon(
                  Icons.tv,
                  color: secondaryTextColor,
                  size: 64,
                ),
              ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Temporada ${episode.seasonNumber} • Episódio ${episode.episodeNumber}',
                    style: TextStyle(
                      color: darkMode
                          ? const Color(0xFF60A5FA)
                          : const Color(0xFF2563EB),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    episode.name,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      if (episode.airDate != null && episode.airDate!.isNotEmpty) ...[
                        Icon(Icons.calendar_today, size: 16, color: secondaryTextColor),
                        const SizedBox(width: 6),
                        Text(
                          episode.airDate!,
                          style: TextStyle(color: secondaryTextColor, fontSize: 14),
                        ),
                        const SizedBox(width: 16),
                      ],
                      if (episode.runtime != null && episode.runtime! > 0) ...[
                        Icon(Icons.schedule, size: 16, color: secondaryTextColor),
                        const SizedBox(width: 6),
                        Text(
                          episode.runtime! >= 60
                              ? '${episode.runtime! ~/ 60}h ${episode.runtime! % 60}min'
                              : '${episode.runtime} min',
                          style: TextStyle(color: secondaryTextColor, fontSize: 14),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Sinopse',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    (episode.overview?.isNotEmpty ?? false)
                        ? episode.overview!
                        : 'Nenhuma sinopse disponível para este episódio.',
                    style: TextStyle(
                      color: secondaryTextColor,
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
