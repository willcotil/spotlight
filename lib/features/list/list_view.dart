import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:spotlight/models/movie.dart';
import 'package:spotlight/providers/favorites_provider.dart';
import 'package:spotlight/providers/theme_provider.dart';
import 'package:spotlight/widgets/ui_components.dart';

class SavedListView extends StatelessWidget {
  const SavedListView({super.key, required this.onSelect});

  final ValueChanged<Movie> onSelect;

  @override
  Widget build(BuildContext context) {
    final favoritesProvider = context.watch<FavoritesProvider>();
    final favorites = favoritesProvider.favorites;
    final darkMode = context.watch<ThemeProvider>().darkMode;

    // Exibe SnackBar de erro caso o provider registre uma falha.
    if (favoritesProvider.errorMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(favoritesProvider.errorMessage!),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.read<FavoritesProvider>().clearError();
      });
    }

    // Indicador de carregamento durante sincronização com Supabase.
    if (favoritesProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Minha Lista',
                style: TextStyle(
                  color: darkMode ? Colors.white : Colors.black,
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Títulos que você salvou para assistir depois.',
                style: TextStyle(color: Color(0xFF71717A), fontSize: 14),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
        if (favorites.isEmpty)
          const SliverToBoxAdapter(
            child: _EmptyState(
              icon: Icons.bookmark_outline,
              text: 'Você ainda não salvou nenhum título.',
            ),
          )
        else
          SliverGrid(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final movie = favorites[index];
                final isFav = context
                    .watch<FavoritesProvider>()
                    .isFavorite(movie);
                return InkWell(
                  onTap: () => onSelect(movie),
                  borderRadius: BorderRadius.circular(20),
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
                                      ),
                                    ),
                              if (isFav)
                                const Positioned(
                                  top: 10,
                                  right: 10,
                                  child: Icon(
                                    Icons.bookmark,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        movie.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: darkMode
                              ? const Color(0xFFE4E4E7)
                              : const Color(0xFF18181B),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${movie.genre} • ${movie.year}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF71717A),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                );
              },
              childCount: favorites.length,
            ),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 220,
              childAspectRatio: 0.58,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(vertical: 72),
      child: Column(
        children: [
          Icon(icon, size: 54, color: const Color(0xFF71717A)),
          const SizedBox(height: 12),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF71717A)),
          ),
        ],
      ),
    );
  }
}
