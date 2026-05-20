import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:provider/provider.dart';
import 'package:spotlight/models/chat_message.dart';
import 'package:spotlight/models/movie.dart';
import 'package:spotlight/providers/auth_provider.dart';
import 'package:spotlight/providers/chat_provider.dart';
import 'package:spotlight/providers/reviews_provider.dart';
import 'package:spotlight/providers/theme_provider.dart';

class AIView extends StatefulWidget {
  const AIView({super.key});

  @override
  State<AIView> createState() => _AIViewState();
}

class _AIViewState extends State<AIView> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();

  // Rastreia o último userId para evitar chamadas duplicadas ao loadHistory
  String? _lastLoadedUserId;

  @override
  void initState() {
    super.initState();
    _textController.addListener(() => setState(() {}));
    // Carrega histórico após o primeiro frame para ter acesso ao contexto
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeLoadHistory());
  }

  /// Carrega o histórico do banco apenas quando o userId muda (login/logout).
  void _maybeLoadHistory() {
    if (!mounted) return;
    final userId = context.read<AuthProvider>().userId;
    if (userId != null && userId != _lastLoadedUserId) {
      _lastLoadedUserId = userId;
      context.read<ChatProvider>().loadHistory(userId);
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _textController.text;
    _textController.clear();
    // Passa userId para que as mensagens sejam persistidas no Supabase
    final userId = context.read<AuthProvider>().userId;
    await context.read<ChatProvider>().sendMessage(text, userId: userId);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatProvider>();
    final darkMode = context.watch<ThemeProvider>().darkMode;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    // Verifica se o userId mudou (ex: login após abrir o chat)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeLoadHistory();
      if (bottomInset > 0) {
        _scrollToBottom();
      }
    });

    // Exibe indicador enquanto o histórico é carregado do banco
    if (chat.isLoading) {
      return const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 20, top: 10),
            itemCount: chat.history.length + (chat.isTyping ? 1 : 0),
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              if (chat.isTyping && index == chat.history.length) {
                return const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 14,
                        color: Color(0xFF71717A),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Spot está escrevendo...',
                        style: TextStyle(
                          color: Color(0xFF71717A),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                );
              }

              final msg = chat.history[index];
              return _MessageItem(msg: msg, darkMode: darkMode);
            },
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: EdgeInsets.only(
            bottom: bottomInset > 0
                ? bottomInset + 8
                : 8,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: darkMode
                  ? const Color(0xFF18181B)
                  : const Color(0xFFF4F4F5),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                if (bottomInset > 0)
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
              ],
              border: Border.all(
                color: darkMode
                    ? const Color(0xFF27272A)
                    : const Color(0xFFE4E4E7),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    minLines: 1,
                    maxLines: 4,
                    onSubmitted: (_) => _submit(),
                    style: TextStyle(
                      color: darkMode ? Colors.white : Colors.black,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Pergunte sobre um filme...',
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: IconButton(
                    onPressed:
                        _textController.text.trim().isEmpty ? null : _submit,
                    style: IconButton.styleFrom(
                      backgroundColor:
                          darkMode ? Colors.white : const Color(0xFF18181B),
                      foregroundColor:
                          darkMode ? Colors.black : Colors.white,
                      padding: const EdgeInsets.all(12),
                    ),
                    icon: const Icon(Icons.send, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Widget de mensagem individual ──────────────────────────────────────────

/// Renderiza uma bolha de mensagem e, opcionalmente, um carrossel horizontal
/// de cards de filmes sugeridos (apenas para mensagens do assistente).
class _MessageItem extends StatelessWidget {
  const _MessageItem({required this.msg, required this.darkMode});

  final ChatMessage msg;
  final bool darkMode;

  @override
  Widget build(BuildContext context) {
    final user = msg.isUser;

    return Column(
      crossAxisAlignment:
          user ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        // Bolha de texto
        Row(
          mainAxisAlignment:
              user ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.72,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              decoration: BoxDecoration(
                color: user
                    ? (darkMode
                          ? Colors.white
                          : const Color(0xFF18181B))
                    : (darkMode
                          ? const Color(0xFF18181B)
                          : const Color(0xFFF4F4F5)),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(24),
                  topRight: const Radius.circular(24),
                  bottomLeft: Radius.circular(user ? 24 : 8),
                  bottomRight: Radius.circular(user ? 8 : 24),
                ),
                border:
                    user ? null : Border.all(color: const Color(0xFF27272A)),
              ),
              child: MarkdownBody(
                data: msg.text,
                styleSheet: MarkdownStyleSheet(
                  p: TextStyle(
                    color: user
                        ? (darkMode ? Colors.black : Colors.white)
                        : (darkMode ? Colors.white : Colors.black),
                    height: 1.4,
                    fontSize: 14,
                  ),
                  strong: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: user
                        ? (darkMode ? Colors.black : Colors.white)
                        : (darkMode ? Colors.white : Colors.black),
                    fontSize: 14,
                  ),
                  em: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: user
                        ? (darkMode ? Colors.black : Colors.white)
                        : (darkMode ? Colors.white : Colors.black),
                    fontSize: 14,
                  ),
                  listBullet: TextStyle(
                    color: user
                        ? (darkMode ? Colors.black : Colors.white)
                        : (darkMode ? Colors.white : Colors.black),
                  ),
                ),
              ),
            ),
          ],
        ),

        // Carrossel de filmes sugeridos (apenas em respostas do assistente)
        if (!user &&
            msg.suggestedMovies != null &&
            msg.suggestedMovies!.isNotEmpty) ...[
          const SizedBox(height: 12),
          // Usamos um SizedBox com altura fixa para o carrossel não quebrar o layout
          SizedBox(
            height: 165, // Aumentado levemente para acomodar títulos maiores sem overflow
            child: _SuggestedMoviesRow(movies: msg.suggestedMovies!),
          ),
        ],
      ],
    );
  }
}

// ── Carrossel horizontal de sugestões ─────────────────────────────────────

/// Lista horizontal compacta de cards de filmes sugeridos pelo assistente.
/// Cada card exibe o poster (80×120) e o título abaixo (máx. 2 linhas, 11px).
/// Tocar em um card abre o modal de detalhes via [ReviewsProvider.openDetails].
class _SuggestedMoviesRow extends StatelessWidget {
  const _SuggestedMoviesRow({required this.movies});

  final List<Movie> movies;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      itemCount: movies.length,
      separatorBuilder: (context, index) => const SizedBox(width: 12),
      itemBuilder: (context, index) {
        final movie = movies[index];
        return _SuggestedMovieCard(movie: movie);
      },
    );
  }
}

/// Card compacto de filme sugerido: poster + título.
class _SuggestedMovieCard extends StatelessWidget {
  const _SuggestedMovieCard({required this.movie});

  final Movie movie;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.read<ReviewsProvider>().openDetails(movie),
      child: SizedBox(
        width: 90, // Levemente mais largo para melhor espaçamento
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Poster do filme
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: 2 / 3,
                child: movie.posterUrl != null
                    ? CachedNetworkImage(
                        imageUrl: movie.posterUrl!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => _PosterPlaceholder(),
                        errorWidget: (context, url, error) => _PosterPlaceholder(),
                      )
                    : _PosterPlaceholder(),
              ),
            ),
            const SizedBox(height: 6),
            // Título abaixo do poster
            Text(
              movie.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Placeholder exibido enquanto o poster carrega ou em caso de erro.
class _PosterPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 120,
      decoration: BoxDecoration(
        color: const Color(0xFF27272A),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(
        Icons.movie_outlined,
        color: Color(0xFF71717A),
        size: 28,
      ),
    );
  }
}
