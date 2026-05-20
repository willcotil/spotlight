import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:spotlight/app/app_constants.dart';
import 'package:spotlight/models/movie.dart';
import 'package:spotlight/providers/favorites_provider.dart';
import 'package:spotlight/providers/movies_provider.dart';
import 'package:spotlight/providers/reviews_provider.dart';
import 'package:spotlight/providers/theme_provider.dart';
import 'package:spotlight/widgets/ui_components.dart';

class HubView extends StatelessWidget {
  const HubView({super.key});

  @override
  Widget build(BuildContext context) {
    final movies = context.watch<MoviesProvider>();
    final favorites = context.watch<FavoritesProvider>();
    final darkMode = context.watch<ThemeProvider>().darkMode;
    void onSelect(Movie m) => context.read<ReviewsProvider>().openDetails(m);
    void onToggleFavorite(Movie m) =>
        context.read<FavoritesProvider>().toggleFavorite(m);

    // Exibe SnackBar de erro caso o provider registre uma falha.
    if (movies.errorMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(movies.errorMessage!),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.read<MoviesProvider>().clearError();
      });
    }

    if (movies.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final isDesktopLayout = MediaQuery.sizeOf(context).width >= desktopBreakpoint;
    final sidePadding = isDesktopLayout ? 0.0 : 16.0;
    final topGap = isDesktopLayout ? 0.0 : 8.0;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          SizedBox(height: topGap),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: sidePadding),
            child: HeroCarousel(
              items: movies.carouselItems,
              favorites: favorites.favorites,
              onSelect: onSelect,
              onToggleFavorite: onToggleFavorite,
            ),
          ),
          const SizedBox(height: 40),
          Padding(
            padding: EdgeInsets.only(left: sidePadding),
            child: Column(
              children: [
                HorizontalMovieList(
                  darkMode: darkMode,
                  title: 'Top Séries',
                  movies: movies.topSeries,
                  ranked: true,
                  onSelect: onSelect,
                ),
                HorizontalMovieList(
                  darkMode: darkMode,
                  title: 'Top Filmes',
                  movies: movies.topMovies,
                  ranked: true,
                  onSelect: onSelect,
                ),
                PromoBanner(
                  darkMode: darkMode,
                  items: [...movies.topMovies, ...movies.topSeries],
                ),
                HorizontalMovieList(
                  darkMode: darkMode,
                  title: 'Melhores em Drama',
                  movies: movies.dramaMovies,
                  ranked: false,
                  onSelect: onSelect,
                ),
                HorizontalMovieList(
                  darkMode: darkMode,
                  title: 'Animações que Encantam',
                  movies: movies.animationMovies,
                  ranked: false,
                  onSelect: onSelect,
                ),
                HorizontalMovieList(
                  darkMode: darkMode,
                  title: 'Ação e Adrenalina',
                  movies: movies.actionMovies,
                  ranked: false,
                  onSelect: onSelect,
                ),
                HorizontalMovieList(
                  darkMode: darkMode,
                  title: 'Ficção Científica',
                  movies: movies.sciFiMovies,
                  ranked: false,
                  onSelect: onSelect,
                ),
                HorizontalMovieList(
                  darkMode: darkMode,
                  title: 'Séries Mais Bem Avaliadas',
                  movies: movies.topRatedSeries,
                  ranked: false,
                  onSelect: onSelect,
                ),
                HorizontalMovieList(
                  darkMode: darkMode,
                  title: 'Filmes para Ver com a Família',
                  movies: movies.familyMovies,
                  ranked: false,
                  onSelect: onSelect,
                ),
                HorizontalMovieList(
                  darkMode: darkMode,
                  title: 'Sexta de Terror 🎃',
                  movies: movies.horrorMovies,
                  ranked: false,
                  onSelect: onSelect,
                ),
                HorizontalMovieList(
                  darkMode: darkMode,
                  title: 'Oscar 2026 🏆',
                  movies: movies.oscar2026Movies,
                  ranked: false,
                  onSelect: onSelect,
                ),
                HorizontalMovieList(
                  darkMode: darkMode,
                  title: 'Lançamentos na Netflix',
                  movies: movies.netflixNew,
                  ranked: false,
                  onSelect: onSelect,
                ),
                HorizontalMovieList(
                  darkMode: darkMode,
                  title: 'Novidades no Prime Video',
                  movies: movies.primeNew,
                  ranked: false,
                  onSelect: onSelect,
                ),
                HorizontalMovieList(
                  darkMode: darkMode,
                  title: 'Destaques na Max',
                  movies: movies.hboNew,
                  ranked: false,
                  onSelect: onSelect,
                ),
                HorizontalMovieList(
                  darkMode: darkMode,
                  title: 'Novidades no Disney+',
                  movies: movies.disneyNew,
                  ranked: false,
                  onSelect: onSelect,
                ),
                HorizontalMovieList(
                  darkMode: darkMode,
                  title: 'Destaques na Apple TV+',
                  movies: movies.appleNew,
                  ranked: false,
                  onSelect: onSelect,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class HeroCarousel extends StatefulWidget {
  const HeroCarousel({
    super.key,
    required this.items,
    required this.favorites,
    required this.onSelect,
    required this.onToggleFavorite,
  });

  final List<Movie> items;
  final List<Movie> favorites;
  final ValueChanged<Movie> onSelect;
  final ValueChanged<Movie> onToggleFavorite;

  @override
  State<HeroCarousel> createState() => _HeroCarouselState();
}

class _HeroCarouselState extends State<HeroCarousel> {
  final controller = PageController();
  Timer? timer;
  int index = 0;

  @override
  void initState() {
    super.initState();
    _startTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) => _prefetchImages());
  }

  @override
  void didUpdateWidget(covariant HeroCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items.length != widget.items.length) {
      index = 0;
      _startTimer();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _prefetchImages());
  }

  void _prefetchImages() {
    for (var i = 0; i < widget.items.length && i < 2; i++) {
      final url = widget.items[i].backdropUrl;
      if (url != null && url.isNotEmpty) {
        precacheImage(CachedNetworkImageProvider(url), context);
      }
    }
  }

  void _startTimer() {
    timer?.cancel();
    if (widget.items.isEmpty) {
      return;
    }
    timer = Timer.periodic(const Duration(seconds: 6), (_) {
      if (!mounted || widget.items.isEmpty) {
        return;
      }
      final next = (index + 1) % widget.items.length;
      controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 550),
        curve: Curves.easeOut,
      );
      setState(() => index = next);
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return const SizedBox.shrink();
    }

    final item = widget.items[index.clamp(0, widget.items.length - 1)];
    final isFav = widget.favorites.any((m) => m.id == item.id);
    final screenSize = MediaQuery.sizeOf(context);
    final isDesktop = screenSize.width >= desktopBreakpoint;
    final mobileHeroHeight = (screenSize.height * 0.62).clamp(500.0, 620.0);

    return SizedBox(
      height: isDesktop ? 640 : mobileHeroHeight,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(isDesktop ? 40 : 28),
            child: PageView.builder(
              controller: controller,
              itemCount: widget.items.length,
              onPageChanged: (value) => setState(() => index = value),
              itemBuilder: (context, i) {
                final movie = widget.items[i];
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    if (movie.backdropUrl != null)
                      SmartNetworkImage(
                        imageUrl: movie.backdropUrl,
                        fit: BoxFit.cover,
                        errorWidget: Container(color: const Color(0xFF18181B)),
                      )
                    else
                      Container(
                        color: const Color(0xFF18181B),
                        child: const Center(
                          child: Icon(
                            Icons.image_outlined,
                            size: 88,
                            color: Color(0xFF52525B),
                          ),
                        ),
                      ),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0x0009090B),
                            Color(0xCC09090B),
                            Color(0xFF09090B),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Padding(
              padding: EdgeInsets.fromLTRB(22, 20, 22, isDesktop ? 28 : 20),
              child: Column(
                children: [
                  TitleLogo(
                    movie: item,
                    height: isDesktop ? 120 : 84,
                    darkMode: true,
                    fontSize: isDesktop ? 64 : 40,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (item.platforms.isNotEmpty)
                        ...item.platforms
                            .take(3)
                            .map(
                              (p) => Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: PlatformLogo(
                                  platform: p,
                                  darkMode: true,
                                ),
                              ),
                            ),
                      if (item.platforms.isNotEmpty) const SizedBox(width: 2),
                      Text(
                        '${item.type} • ${item.genre}',
                        style: const TextStyle(
                          color: Color(0xFFD4D4D8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isDesktop ? 430 : 360,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: FilledButton(
                            onPressed: () => widget.onSelect(item),
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              minimumSize: Size(0, isDesktop ? 60 : 56),
                              shape: const StadiumBorder(),
                              textStyle: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                            child: const Text('Ver Detalhes'),
                          ),
                        ),
                        SizedBox(width: isDesktop ? 14 : 12),
                        SizedBox(
                          width: isDesktop ? 58 : 48,
                          height: isDesktop ? 60 : 48,
                          child: InkWell(
                            onTap: () => widget.onToggleFavorite(item),
                            borderRadius: BorderRadius.circular(999),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.22),
                                ),
                              ),
                              child: Icon(
                                isFav ? Icons.check : Icons.add,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(widget.items.length, (dotIndex) {
                      final active = dotIndex == index;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: active ? 30 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: active ? Colors.white : Colors.white38,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class HorizontalMovieList extends StatelessWidget {
  const HorizontalMovieList({
    super.key,
    required this.title,
    required this.movies,
    required this.onSelect,
    required this.darkMode,
    required this.ranked,
  });

  final String title;
  final List<Movie> movies;
  final ValueChanged<Movie> onSelect;
  final bool darkMode;
  final bool ranked;

  @override
  Widget build(BuildContext context) {
    if (movies.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: darkMode ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right,
              color: darkMode ? Colors.white54 : Colors.black45,
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 236,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: movies.length,
            separatorBuilder: (context, index) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final movie = movies[index];
              return InkWell(
                onTap: () => onSelect(movie),
                borderRadius: BorderRadius.circular(18),
                child: SizedBox(
                  width: 150,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              movie.posterUrl != null
                                  ? SmartNetworkImage(
                                      imageUrl: movie.posterUrl,
                                      fit: BoxFit.cover,
                                    )
                                  : Container(
                                      color: darkMode
                                          ? const Color(0xFF18181B)
                                          : const Color(0xFFE4E4E7),
                                      child: const Icon(
                                        Icons.image_outlined,
                                        color: Color(0xFF71717A),
                                        size: 34,
                                      ),
                                    ),
                              if (ranked)
                                const DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Color(0xB3000000),
                                        Colors.transparent,
                                        Color(0xCC000000),
                                      ],
                                    ),
                                  ),
                                ),
                              if (ranked)
                                Positioned(
                                  left: 10,
                                  top: 8,
                                  child: Text(
                                    '${index + 1}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 38,
                                      fontWeight: FontWeight.w700,
                                      height: 1,
                                    ),
                                  ),
                                ),
                              if (ranked)
                                Positioned(
                                  left: 8,
                                  right: 8,
                                  bottom: 10,
                                  child: Text(
                                    movie.genre,
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Color(0xFFE4E4E7),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }
}

class PromoBanner extends StatefulWidget {
  const PromoBanner({super.key, required this.darkMode, required this.items});

  final bool darkMode;
  final List<Movie> items;

  @override
  State<PromoBanner> createState() => _PromoBannerState();
}

class _PromoBannerState extends State<PromoBanner> {
  bool _visible = true;

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();

    final slots = [...widget.items.take(16)];
    while (slots.length < 16) {
      slots.add(
        Movie(
          id: slots.length,
          title: '',
          type: 'Filme',
          genre: 'Drama',
          rating: 0,
          year: '',
          duration: '',
          synopsis: '',
          platforms: const [],
        ),
      );
    }

    return Column(
      children: [
        Container(
          height: 460,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(34),
            color: widget.darkMode ? const Color(0xFF18181B) : const Color(0xFFE4E4E7),
            border: Border.all(
              color: widget.darkMode ? const Color(0xFF27272A) : const Color(0xFFD4D4D8),
            ),
          ),
          child: Stack(
            children: [
              GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.all(8),
                itemCount: slots.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                ),
                itemBuilder: (context, index) {
                  final item = slots[index];
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: item.posterUrl != null
                        ? SmartNetworkImage(
                            imageUrl: item.posterUrl,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            color: widget.darkMode
                                ? const Color(0xFF27272A)
                                : const Color(0xFFD4D4D8),
                            child: const Icon(
                              Icons.image_outlined,
                              color: Color(0xFF71717A),
                            ),
                          ),
                  );
                },
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x44000000),
                      Color(0xCC000000),
                      Color(0xF2000000),
                    ],
                  ),
                ),
                child: SizedBox.expand(),
              ),
              // Botão de fechar (Hidden)
              Positioned(
                top: 14,
                right: 14,
                child: GestureDetector(
                  onTap: () => setState(() => _visible = false),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.4),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 20,
                right: 20,
                bottom: 26,
                child: Column(
                  children: [
                    const SpotlightLogo(darkMode: true, size: 42),
                    const SizedBox(height: 18),
                    const Text(
                      'Curta lançamentos todas as semanas.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        height: 1.05,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 18),
                    FilledButton(
                      onPressed: () {},
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        minimumSize: const Size(double.infinity, 54),
                        shape: const StadiumBorder(),
                        textStyle: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      child: const Text('Aceite o período grátis'),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      '7 dias grátis, depois R\$ 29,90/mês. Cancele a qualquer momento. Termos se aplicam.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFFA1A1AA),
                        fontSize: 11,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }
}


