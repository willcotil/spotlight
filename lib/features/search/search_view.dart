import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:spotlight/providers/favorites_provider.dart';
import 'package:spotlight/providers/reviews_provider.dart';
import 'package:spotlight/providers/search_provider.dart';
import 'package:spotlight/providers/theme_provider.dart';
import 'package:spotlight/widgets/ui_components.dart';

/// Tela de busca — consome [SearchProvider] para estado reativo e
/// [ReviewsProvider] para abrir o modal de detalhes.
class SearchView extends StatefulWidget {
  const SearchView({super.key});

  @override
  State<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView> {
  final _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final darkMode = context.watch<ThemeProvider>().darkMode;
    final search = context.watch<SearchProvider>();
    final favorites = context.watch<FavoritesProvider>();

    // Exibe SnackBar quando a busca retornar erro.
    if (search.errorMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(search.errorMessage!),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.read<SearchProvider>().clearError();
      });
    }

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // ── Barra de busca ─────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: darkMode
                      ? const Color(0x2618181B)
                      : const Color(0xFFF4F4F5),
                  border: Border.all(
                    color: darkMode
                        ? const Color(0xFF27272A)
                        : const Color(0xFFE4E4E7),
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _textController,
                  style: TextStyle(
                    color: darkMode ? Colors.white : Colors.black,
                  ),
                  onChanged: (value) =>
                      context.read<SearchProvider>().search(value),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 15,
                    ),
                    border: InputBorder.none,
                    prefixIcon:
                        const Icon(Icons.search, color: Color(0xFF71717A)),
                    hintText: 'Buscar filmes, séries ou gêneros...',
                    hintStyle: const TextStyle(color: Color(0xFF71717A)),
                    // Botão para limpar o campo
                    suffixIcon: search.query.isNotEmpty
                        ? IconButton(
                            icon: const Icon(
                              Icons.close,
                              color: Color(0xFF71717A),
                            ),
                            onPressed: () {
                              _textController.clear();
                              context.read<SearchProvider>().clear();
                            },
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ── Estados vazios / loading ──────────────────────────────────
              if (search.isLoading)
                _EmptyState(
                  icon: Icons.search,
                  text: 'Buscando "${search.query}"...',
                  showSpinner: true,
                )
              else if (search.query.isEmpty)
                const _EmptyState(
                  icon: Icons.tv,
                  text:
                      'Digite o nome de um filme ou série para pesquisar no catálogo mundial.',
                )
              else if (search.hasSearched && search.results.isEmpty)
                _EmptyState(
                  icon: Icons.search_off,
                  text:
                      'Nenhum resultado encontrado para "${search.query}".',
                ),
            ],
          ),
        ),

        // ── Grade de resultados ────────────────────────────────────────────
        if (!search.isLoading &&
            search.query.isNotEmpty &&
            search.results.isNotEmpty)
          SliverGrid(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final movie = search.results[index];
                final isFav = favorites.isFavorite(movie);

                return InkWell(
                  onTap: () =>
                      context.read<ReviewsProvider>().openDetails(movie),
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
                              // Pôster ou placeholder
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
                              // Indicador de favorito
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
              childCount: search.results.length,
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

// ── Widget auxiliar de estado vazio ───────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.text,
    this.showSpinner = false,
  });

  final IconData icon;
  final String text;

  /// Se verdadeiro, exibe um [CircularProgressIndicator] abaixo do ícone.
  final bool showSpinner;

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
          if (showSpinner) ...[
            const SizedBox(height: 20),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ],
        ],
      ),
    );
  }
}
