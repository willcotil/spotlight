import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:spotlight/features/details/details_controller.dart';
import 'package:spotlight/models/cast_member.dart';
import 'package:spotlight/models/movie.dart';
import 'package:spotlight/models/review.dart';
import 'package:spotlight/models/episode.dart';
import 'package:spotlight/features/actor/actor_detail_view.dart';
import 'package:spotlight/features/details/episode_detail_view.dart';
import 'package:spotlight/providers/reviews_provider.dart';
import 'package:spotlight/services/tmdb_service.dart';
import 'package:spotlight/widgets/ui_components.dart';

class DetailsView extends StatelessWidget {
  const DetailsView({
    super.key,
    required this.controller,
    required this.darkMode,
  });

  final DetailsController controller;
  final bool darkMode;

  void _openRatingSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final screenHeight = MediaQuery.sizeOf(context).height;
        final maxHeight = screenHeight * 0.92;
        final initialHeight = (screenHeight * 0.62).clamp(360.0, maxHeight);
        return _RatingSheetContent(
          darkMode: darkMode,
          movieTitle: controller.item.title,
          initialStars:
              controller.userReview?.nota ??
              controller.item.rating.round().clamp(1, 5),
          initialComment: controller.userReview?.comentario ?? '',
          canDelete: controller.userReview != null,
          sheetHeight: initialHeight,
          minSheetHeight: 320.0,
          maxSheetHeight: maxHeight,
          onSubmit: controller.onSubmitRating,
          onDelete: controller.onDeleteRating,
        );
      },
    );
  }

  Widget _ratingChip(BuildContext context) {
    final raw = controller.item.rating;
    final ratingText = raw > 0
        ? raw.toStringAsFixed(1).replaceAll('.', ',')
        : '-';
    return InkWell(
      onTap: () => _openRatingSheet(context),
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.amber, width: 1),
          color: Colors.transparent,
        ),
        child: Text(
          'TMDB $ratingText',
          style: const TextStyle(
            color: Colors.amber,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            height: 1.0, // Garantindo centralização perfeita
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final item = controller.item;
    return SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.65,
            child: Stack(
              fit: StackFit.expand,
              children: [
                item.backdropUrl != null
                    ? SmartNetworkImage(
                        imageUrl: item.backdropUrl,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        color: const Color(0xFF18181B),
                        child: const Icon(
                          Icons.image_outlined,
                          size: 94,
                          color: Color(0xFF71717A),
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
                Positioned(
                  top: 12,
                  left: 12,
                  right: 12,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _RoundBlurButton(
                        icon: Icons.arrow_back_ios_new_rounded,
                        onTap: controller.onClose,
                      ),
                      _RoundBlurButton(
                        icon: Icons.share_outlined,
                        onTap: controller.shareMovie,
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: 22,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                        ),
                        child: const Text(
                          'Novo',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TitleLogo(
                        movie: item,
                        height: 110,
                        darkMode: true,
                        fontSize: 58,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
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
                          if (item.platforms.isNotEmpty)
                            const SizedBox(width: 2),
                          Text(
                            '${item.type} • ${item.genre}',
                            style: const TextStyle(
                              color: Color(0xFFD4D4D8),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Column(
              children: [
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth >= 620;
                    final maxWidth = isWide ? 430.0 : 360.0;

                    return Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: maxWidth),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 48,
                                child: _TrailerButton(
                                  movie: item,
                                  selectedSeason: context
                                      .watch<ReviewsProvider>()
                                      .selectedSeason,
                                ),
                              ),
                            ),
                            SizedBox(width: isWide ? 14 : 12),
                            SizedBox(
                              width: 48,
                              height: 48,
                              child: InkWell(
                                onTap: controller.onToggleFavorite,
                                borderRadius: BorderRadius.circular(999),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xCC27272A),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: const Color(0xFF3F3F46),
                                    ),
                                  ),
                                  child: Icon(
                                    controller.isFavorite
                                        ? Icons.check
                                        : Icons.add,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                Text(
                  '"${item.synopsis}"',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFFD4D4D8),
                    height: 1.6,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 18),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  children: [
                    _chip(item.year),
                    _chip(
                      controller.contentRating ?? 'L',
                      filled: true,
                      classification: controller.contentRating ?? 'L',
                    ),
                    _chip('4K'),
                    _chip('CC'),
                    _ratingChip(context),
                  ],
                ),
                if (item.type == 'Série' && controller.episodes.isNotEmpty) ...[
                  const SizedBox(height: 28),
                  _EpisodesSection(
                    episodes: controller.episodes,
                    tvNumberOfSeasons: controller.tvNumberOfSeasons ?? 1,
                    seriesName: controller.item.title,
                  ),
                ],
                const SizedBox(height: 28),
                _RelatedSection(
                  title: 'Relacionados',
                  type: controller.item.type,
                  similar: controller.similar,
                  byDirector: controller.relatedByDirector,
                  byActor: controller.relatedByActor,
                  loading: controller.loadingRelated,
                  onSelectItem: controller.onSelectItem,
                ),
                const SizedBox(height: 26),
                _CastSection(cast: controller.cast),
                const SizedBox(height: 26),
                _CommentsSection(
                  comments: controller.comments,
                  loading: controller.loadingComments,
                  userId: controller.userId,
                  onEditComment: controller.onEditComment,
                  onDeleteComment: controller.onDeleteComment,
                ),
                const SizedBox(height: 26),
                _ContentInfoSection(
                  contentDetails: controller.contentDetails,
                  movieType: controller.item.type,
                  contentRating: controller.contentRating,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String text, {bool filled = false, String? classification}) {
    Color backgroundColor = filled
        ? const Color(0xFF27272A)
        : Colors.transparent;
    Color borderColor = const Color(0xFF3F3F46);
    Color textColor = const Color(0xFFA1A1AA);

    if (filled && classification != null) {
      switch (classification) {
        case 'L':
          backgroundColor = const Color(0xFF22C55E);
          textColor = Colors.white;
          break;
        case 'A10':
          backgroundColor = const Color(0xFF3B82F6);
          textColor = Colors.white;
          break;
        case 'A12':
          backgroundColor = const Color(0xFFF59E0B);
          textColor = Colors.white;
          break;
        case 'A14':
          backgroundColor = const Color(0xFFFF8C42);
          textColor = Colors.white;
          break;
        case 'A16':
          backgroundColor = const Color(0xFFEF4444);
          textColor = Colors.white;
          break;
        case 'A18':
          backgroundColor = const Color(0xFF991B1B);
          textColor = Colors.white;
          break;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(3),
        border: filled ? null : Border.all(color: borderColor),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _RelatedSection extends StatefulWidget {
  const _RelatedSection({
    required this.title,
    required this.type,
    required this.similar,
    required this.byDirector,
    required this.byActor,
    required this.loading,
    required this.onSelectItem,
  });

  final String title;
  final String type;
  final List<Movie> similar;
  final List<Movie> byDirector;
  final List<Movie> byActor;
  final bool loading;
  final ValueChanged<Movie> onSelectItem;

  @override
  State<_RelatedSection> createState() => _RelatedSectionState();
}

class _RelatedSectionState extends State<_RelatedSection> with TickerProviderStateMixin {
  TabController? _tabController;
  int _activeTabs = 0;
  List<Widget> _tabs = [];
  List<List<Movie>> _tabData = [];

  @override
  void initState() {
    super.initState();
    _buildTabs();
  }

  @override
  void didUpdateWidget(covariant _RelatedSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.loading != widget.loading || 
        oldWidget.similar != widget.similar ||
        oldWidget.byDirector != widget.byDirector ||
        oldWidget.byActor != widget.byActor) {
      _buildTabs();
    }
  }

  void _buildTabs() {
    _tabs = [];
    _tabData = [];
    if (widget.similar.isNotEmpty) {
      _tabs.add(const Tab(text: 'Similares'));
      _tabData.add(widget.similar);
    }
    if (widget.byDirector.isNotEmpty) {
      _tabs.add(Tab(text: widget.type == 'Série' ? 'Criador' : 'Diretor'));
      _tabData.add(widget.byDirector);
    }
    if (widget.byActor.isNotEmpty) {
      _tabs.add(const Tab(text: 'Ator'));
      _tabData.add(widget.byActor);
    }
    _activeTabs = _tabs.length;
    if (_activeTabs > 0) {
      _tabController?.dispose();
      _tabController = TabController(length: _activeTabs, vsync: this);
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_activeTabs == 0) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              widget.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Color(0xFF71717A),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: const Color(0xFF71717A),
          dividerColor: Colors.transparent,
          tabs: _tabs,
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: TabBarView(
            controller: _tabController,
            children: _tabData.map((list) {
              return ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: list.length,
                separatorBuilder: (context, index) => const SizedBox(width: 14),
                itemBuilder: (context, index) {
                  final movie = list[index];
                  return InkWell(
                    onTap: () => widget.onSelectItem(movie),
                    borderRadius: BorderRadius.circular(20),
                    child: SizedBox(
                      width: 130,
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
                                          color: const Color(0xFF18181B),
                                          child: const Icon(
                                            Icons.image_outlined,
                                            color: Color(0xFF71717A),
                                            size: 34,
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
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _CastSection extends StatelessWidget {
  const _CastSection({required this.cast});

  final List<CastMember> cast;

  String _extractCharacterName(String character) {
    return character;
  }

  @override
  Widget build(BuildContext context) {
    if (cast.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Text(
              'Elenco',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(width: 6),
            Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFF71717A)),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 132,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: cast.length,
            separatorBuilder: (context, index) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final actor = cast[index];
              return SizedBox(
                width: 90,
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ActorDetailView(actor: actor),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Column(
                    children: [
                      Container(
                        width: 82,
                        height: 82,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF18181B),
                        ),
                        child: actor.profileUrl.isNotEmpty
                            ? ClipOval(
                                child: SmartNetworkImage(
                                  imageUrl: actor.profileUrl,
                                  fit: BoxFit.cover,
                                  errorWidget: const Icon(
                                    Icons.person,
                                    color: Color(0xFF52525B),
                                    size: 32,
                                  ),
                                ),
                              )
                            : const Icon(
                                Icons.person,
                                color: Color(0xFF52525B),
                                size: 32,
                              ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        actor.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFFD4D4D8),
                          fontSize: 12,
                        ),
                      ),
                      if (actor.character.isNotEmpty)
                        Text(
                          _extractCharacterName(actor.character),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFFA1A1AA),
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CommentsSection extends StatefulWidget {
  const _CommentsSection({
    required this.comments,
    required this.loading,
    required this.userId,
    required this.onEditComment,
    required this.onDeleteComment,
  });

  final List<Review> comments;
  final bool loading;
  final String? userId;
  final Future<void> Function(Review) onEditComment;
  final Future<void> Function(Review) onDeleteComment;

  @override
  State<_CommentsSection> createState() => _CommentsSectionState();
}

class _CommentsSectionState extends State<_CommentsSection> {
  int _visibleCount = 3;

  String _formatRelativeDate(DateTime? date) {
    if (date == null) return '';
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays > 365) return '${(diff.inDays / 365).floor()} anos atrás';
    if (diff.inDays > 30) return '${(diff.inDays / 30).floor()} meses atrás';
    if (diff.inDays > 0) return '${diff.inDays} dias atrás';
    if (diff.inHours > 0) return '${diff.inHours} horas atrás';
    if (diff.inMinutes > 0) return '${diff.inMinutes} minutos atrás';
    return 'Agora mesmo';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Text(
              'Comentários',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(width: 6),
            Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFF71717A)),
          ],
        ),
        const SizedBox(height: 12),
        if (widget.loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 18),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (widget.comments.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Text(
              'Ainda não há comentários para este conteúdo...',
              style: TextStyle(color: Color(0xFFA1A1AA), fontSize: 13),
            ),
          )
        else
          Column(
            children: [
              ...widget.comments.take(_visibleCount).map((entry) {
                final isUserComment = entry.usuarioId == widget.userId;
                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF18181B),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF27272A)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFF27272A),
                            ),
                            child: const Icon(Icons.person, color: Color(0xFF71717A), size: 20),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  entry.autorNome ?? 'Usuario',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Row(
                                  children: [
                                    Row(
                                      children: List.generate(5, (index) {
                                        return Icon(
                                          index < entry.nota
                                              ? Icons.star_rounded
                                              : Icons.star_border_rounded,
                                          size: 12,
                                          color: const Color(0xFFF59E0B),
                                        );
                                      }),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      _formatRelativeDate(entry.atualizadoEm),
                                      style: const TextStyle(
                                        color: Color(0xFF71717A),
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          if (isUserComment) ...[
                            IconButton(
                              onPressed: () async => await widget.onEditComment(entry),
                              icon: const Icon(
                                Icons.edit,
                                size: 18,
                                color: Color(0xFF71717A),
                              ),
                            ),
                            IconButton(
                              onPressed: () async => await widget.onDeleteComment(entry),
                              icon: const Icon(
                                Icons.delete,
                                size: 18,
                                color: Colors.redAccent,
                              ),
                            ),
                          ],
                        ],
                      ),
                      if ((entry.comentario ?? '').isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          entry.comentario!,
                          style: const TextStyle(
                            color: Color(0xFFE4E4E7),
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }),
              if (_visibleCount < widget.comments.length)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: TextButton(
                    onPressed: () {
                      setState(() {
                        _visibleCount += 5;
                      });
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFA1A1AA),
                    ),
                    child: const Text('Carregar mais'),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

class _RoundBlurButton extends StatelessWidget {
  const _RoundBlurButton({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.42),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

class _RatingSheetContent extends StatefulWidget {
  const _RatingSheetContent({
    required this.darkMode,
    required this.movieTitle,
    required this.initialStars,
    required this.initialComment,
    required this.canDelete,
    required this.sheetHeight,
    required this.minSheetHeight,
    required this.maxSheetHeight,
    required this.onSubmit,
    required this.onDelete,
  });

  final bool darkMode;
  final String movieTitle;
  final int initialStars;
  final String initialComment;
  final bool canDelete;
  final double sheetHeight;
  final double minSheetHeight;
  final double maxSheetHeight;
  final Future<bool> Function(int stars, String comment) onSubmit;
  final Future<bool> Function() onDelete;

  @override
  State<_RatingSheetContent> createState() => _RatingSheetContentState();
}

class _RatingSheetContentState extends State<_RatingSheetContent> {
  late int selectedStars;
  final TextEditingController commentController = TextEditingController();
  bool _loading = false;
  late double _sheetHeight;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    selectedStars = widget.initialStars.clamp(1, 5);
    commentController.text = widget.initialComment;
    _sheetHeight = widget.sheetHeight;
  }

  @override
  void dispose() {
    commentController.dispose();
    super.dispose();
  }

  void _dismissDraft() {
    FocusScope.of(context).unfocus();
    commentController.clear();
    selectedStars = widget.initialStars.clamp(1, 5);
  }

  void _updateSheetHeight(double nextHeight) {
    if (!mounted) return;
    setState(() {
      _sheetHeight = nextHeight.clamp(
        widget.minSheetHeight,
        widget.maxSheetHeight,
      );
    });
  }

  void _closeByDrag() {
    if (_closing || !mounted) return;
    _closing = true;
    _dismissDraft();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final darkMode = widget.darkMode;
    final textColor = darkMode ? Colors.white : Colors.black;
    final bgColor = darkMode ? const Color(0xFF111113) : Colors.white;
    final borderColor = darkMode
        ? const Color(0xFF27272A)
        : const Color(0xFFE4E4E7);

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          height: _sheetHeight,
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
            border: Border(top: BorderSide(color: borderColor)),
          ),
          child: Column(
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onVerticalDragStart: (_) {
                  _closing = false;
                },
                onVerticalDragUpdate: (details) {
                  final nextHeight = _sheetHeight - details.delta.dy;
                  if (nextHeight <= widget.minSheetHeight + 24) {
                    _closeByDrag();
                    return;
                  }
                  _updateSheetHeight(nextHeight);
                },
                onVerticalDragEnd: (details) {
                  final velocity = details.primaryVelocity ?? 0;
                  if (velocity > 450 ||
                      _sheetHeight <= widget.minSheetHeight + 32) {
                    _closeByDrag();
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.only(top: 10, bottom: 10),
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: darkMode
                          ? const Color(0xFF52525B)
                          : const Color(0xFFD4D4D8),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Text(
                  'Avaliar conteúdo',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Text(
                  widget.movieTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF71717A),
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final star = index + 1;
                  return IconButton(
                    onPressed: () => setState(() => selectedStars = star),
                    icon: Icon(
                      star <= selectedStars
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      color: const Color(0xFFF59E0B),
                      size: 34,
                    ),
                  );
                }),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: TextField(
                    controller: commentController,
                    expands: true,
                    maxLines: null,
                    minLines: null,
                    textAlignVertical: TextAlignVertical.top,
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      hintText: 'Comentário (opcional)',
                      hintStyle: const TextStyle(color: Color(0xFF71717A)),
                      filled: true,
                      fillColor: darkMode
                          ? const Color(0xFF1C1C1E)
                          : const Color(0xFFF4F4F5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: borderColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: borderColor),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                        borderSide: BorderSide(
                          color: Color(0xFF3B82F6),
                          width: 1.2,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : FilledButton(
                        onPressed: () async {
                          setState(() => _loading = true);
                          final comment = commentController.text.trim();
                          final shouldClose = await widget.onSubmit(
                            selectedStars,
                            comment,
                          );
                          if (!context.mounted) return;
                          setState(() => _loading = false);
                          if (shouldClose) Navigator.of(context).pop();
                        },
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Concluir avaliação'),
                      ),
              ),
              if (widget.canDelete && !_loading)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: TextButton(
                    onPressed: () async {
                      setState(() => _loading = true);
                      final shouldClose = await widget.onDelete();
                      if (!context.mounted) return;
                      setState(() => _loading = false);
                      if (shouldClose) Navigator.of(context).pop();
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                    ),
                    child: const Text('Excluir avaliação'),
                  ),
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrailerButton extends StatefulWidget {
  const _TrailerButton({required this.movie, required this.selectedSeason});

  final Movie movie;
  final int selectedSeason;

  @override
  State<_TrailerButton> createState() => _TrailerButtonState();
}

class _TrailerButtonState extends State<_TrailerButton> {
  bool _loading = false;

  Future<void> _watchTrailer() async {
    setState(() => _loading = true);
    try {
      final trailerUrl = await TMDBService.fetchTrailer(
        id: widget.movie.id,
        type: widget.movie.type,
        seasonNumber: widget.movie.type == 'Série' ? widget.selectedSeason : null,
      );

      if (trailerUrl != null) {
        final uri = Uri.parse(trailerUrl);
        // Em dispositivos móveis (Android 11+/iOS 9+), canLaunchUrl pode falhar 
        // devido a restrições de visibilidade de pacotes. 
        // Tentamos o launchUrl diretamente dentro de um try-catch.
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _showError('Trailer não encontrado para este conteúdo.');
      }
    } catch (_) {
      _showError('Erro ao buscar o trailer. Tente novamente.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red.shade800,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: _loading ? null : _watchTrailer,
      style: FilledButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        shape: const StadiumBorder(),
        textStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 15,
        ),
      ),
      child: _loading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.black,
              ),
            )
          : const Text('Assistir trailer'),
    );
  }
}

class _EpisodesSection extends StatefulWidget {
  const _EpisodesSection({
    required this.episodes,
    required this.tvNumberOfSeasons,
    required this.seriesName,
  });

  final List<Episode> episodes;
  final int tvNumberOfSeasons;
  final String seriesName;

  @override
  State<_EpisodesSection> createState() => _EpisodesSectionState();
}

class _EpisodesSectionState extends State<_EpisodesSection> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Episódios',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 16),
        // Seletor de Temporadas: Lista horizontal unificada
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: List.generate(widget.tvNumberOfSeasons, (index) {
              final s = index + 1;
              final currentSelected = context.watch<ReviewsProvider>().selectedSeason;
              final isSelected = currentSelected == s;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: InkWell(
                  onTap: () {
                    context.read<ReviewsProvider>().loadSeason(s);
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : const Color(0xFF18181B),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? Colors.white : const Color(0xFF3F3F46),
                      ),
                    ),
                    child: Text(
                      'Temporada $s',
                      style: TextStyle(
                        color: isSelected ? Colors.black : const Color(0xFFA1A1AA),
                        fontSize: 14,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 16),
        if (widget.episodes.isEmpty)
          const Text(
            'Nenhum episódio encontrado.',
            style: TextStyle(color: Color(0xFFA1A1AA)),
          )
        else
          SizedBox(
            height: 160,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(bottom: 0),
              itemCount: widget.episodes.length,
              separatorBuilder: (_, index) => const SizedBox(width: 16),
              itemBuilder: (context, index) {
                final ep = widget.episodes[index];
                return SizedBox(
                  width: 260,
                  height: 160,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EpisodeDetailView(
                            episode: ep,
                            seriesName: widget.seriesName,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: const Color(0xFF18181B),
                        gradient: ep.stillPath == null
                            ? const LinearGradient(
                                colors: [Color(0xFF09090B), Color(0xFF18181B)],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              )
                            : null,
                      ),
                      clipBehavior: Clip.hardEdge,
                      child: Stack(
                        children: [
                          if (ep.stillPath != null)
                            Positioned.fill(
                              child: SmartNetworkImage(
                                imageUrl: 'https://image.tmdb.org/t/p/w300${ep.stillPath}',
                                fit: BoxFit.cover,
                              ),
                            ),
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: ClipRRect(
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                                child: Container(
                                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.45),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '${ep.episodeNumber}. ${ep.name}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        (ep.overview?.isNotEmpty ?? false)
                                            ? ep.overview!
                                            : 'Sem descrição.',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Color(0xFFA1A1AA),
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _ContentInfoSection extends StatefulWidget {
  const _ContentInfoSection({
    required this.contentDetails,
    required this.movieType,
    required this.contentRating,
  });

  final Map<String, dynamic>? contentDetails;
  final String movieType;
  final String? contentRating;

  @override
  State<_ContentInfoSection> createState() => _ContentInfoSectionState();
}

class _ContentInfoSectionState extends State<_ContentInfoSection> {
  String _getOriginCountry() {
    if (widget.contentDetails == null) return '-';
    final countries = widget.contentDetails!['origin_country'] as List?;
    if (countries == null || countries.isEmpty) return '-';
    final code = countries[0] as String;
    const mapping = {
      'US': 'Estados Unidos',
      'BR': 'Brasil',
      'GB': 'Reino Unido',
      'JP': 'Japão',
      'KR': 'Coreia do Sul',
      'FR': 'França',
      'DE': 'Alemanha',
      'IT': 'Itália',
      'ES': 'Espanha',
      'CA': 'Canadá',
      'AU': 'Austrália',
      'IN': 'Índia',
      'MX': 'México',
      'AR': 'Argentina',
      'CN': 'China',
    };
    return mapping[code] ?? code;
  }

  String _getOriginalLanguage() {
    if (widget.contentDetails == null) return '-';
    final lang = widget.contentDetails!['original_language'] as String?;
    if (lang == null) return '-';
    const mapping = {
      'en': 'Inglês',
      'pt': 'Português',
      'es': 'Espanhol',
      'ja': 'Japonês',
      'ko': 'Coreano',
      'fr': 'Francês',
      'de': 'Alemão',
      'it': 'Italiano',
      'zh': 'Chinês',
      'hi': 'Hindi',
      'ru': 'Russo',
    };
    return mapping[lang] ?? lang;
  }

  String _getSpokenLanguagesList() {
    if (widget.contentDetails == null) return '-';
    final langs = widget.contentDetails!['spoken_languages'] as List?;
    if (langs == null || langs.isEmpty) return '-';
    
    const mapping = {
      'en': 'Inglês',
      'pt': 'Português (Brasil)',
      'es': 'Espanhol',
      'fr': 'Francês',
      'de': 'Alemão',
      'ja': 'Japonês',
      'ko': 'Coreano',
      'it': 'Italiano',
      'zh': 'Mandarim',
      'ru': 'Russo',
      'ar': 'Árabe',
    };
    
    return langs.map((l) {
      final code = l['iso_639_1'] as String?;
      if (code != null && mapping.containsKey(code)) {
        return mapping[code];
      }
      return (l['name'] ?? l['english_name']).toString();
    }).join(', ');
  }

  String _getSubtitlesList() {
    if (widget.contentDetails == null) return '-';
    final trans = widget.contentDetails!['translations'];
    if (trans == null) return '-';
    final translations = trans['translations'] as List?;
    if (translations == null || translations.isEmpty) return '-';
    return translations.map((t) => (t['name'] ?? t['english_name']).toString()).toSet().join(', ');
  }

  String _getContentAdvisories() {
    if (widget.contentDetails == null) return '-';
    if (widget.movieType == 'Filme') {
      final releases = widget.contentDetails!['release_dates'];
      if (releases != null && releases['results'] != null) {
        final results = releases['results'] as List;
        Map<String, dynamic>? brResult;
        Map<String, dynamic>? usResult;
        for (final r in results) {
          if (r['iso_3166_1'] == 'BR') brResult = r;
          if (r['iso_3166_1'] == 'US') usResult = r;
        }
        final target = brResult ?? usResult;
        if (target != null && target['release_dates'] != null) {
          final dates = target['release_dates'] as List;
          for (final d in dates) {
            final note = d['note'] ?? d['certification_notes'];
            if (note != null && note.toString().isNotEmpty) {
              return note.toString();
            }
          }
        }
      }
    } else {
      final contentRatings = widget.contentDetails!['content_ratings'];
      if (contentRatings != null && contentRatings['results'] != null) {
        final results = contentRatings['results'] as List;
        Map<String, dynamic>? brResult;
        Map<String, dynamic>? usResult;
        for (final r in results) {
          if (r['iso_3166_1'] == 'BR') brResult = r;
          if (r['iso_3166_1'] == 'US') usResult = r;
        }
        final target = brResult ?? usResult;
        if (target != null) {
          final note = target['note'] ?? target['certification_notes'];
          if (note != null && note.toString().isNotEmpty) {
            return note.toString();
          }
        }
      }
    }
    return '-';
  }

  Widget _buildInfoRow(String label, String value) {
    if (value == '-') return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFFA1A1AA),
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        const Divider(height: 1, color: Color(0xFF27272A)),
      ],
    );
  }



  @override
  Widget build(BuildContext context) {
    if (widget.contentDetails == null) return const SizedBox.shrink();

    final releaseDate = widget.contentDetails!['release_date'] ?? widget.contentDetails!['first_air_date'] ?? '-';
    final releaseYear = releaseDate != '-' && releaseDate.toString().length >= 4 
        ? releaseDate.toString().substring(0, 4) 
        : '-';
    
    final advisories = _getContentAdvisories();
    final spokenLanguages = _getSpokenLanguagesList();
    final subtitles = _getSubtitlesList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Informações',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        _buildInfoRow('Lançamento', releaseYear),
        _buildInfoRow('Classificação', widget.contentRating ?? '-'),
        _buildInfoRow('Recomendações de Conteúdo', advisories),
        _buildInfoRow('Região de Origem', _getOriginCountry()),
        const SizedBox(height: 24),
        const Text(
          'Idiomas',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        _buildInfoRow('Áudio Original', _getOriginalLanguage()),
        _buildInfoRow('Áudio', spokenLanguages),
        _buildInfoRow('Legendas', subtitles),
      ],
    );
  }
}
