import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:spotlight/app/app_constants.dart';
import 'package:spotlight/features/chat/chat_view.dart';
import 'package:spotlight/features/details/details_controller.dart';
import 'package:spotlight/features/details/details_view.dart';
import 'package:spotlight/features/hub/hub_view.dart';
import 'package:spotlight/features/list/list_view.dart';
import 'package:spotlight/features/profile/profile_view.dart';
import 'package:spotlight/features/search/search_view.dart';
import 'package:spotlight/models/review.dart';
import 'package:spotlight/providers/auth_provider.dart';

import 'package:spotlight/providers/favorites_provider.dart';
import 'package:spotlight/providers/reviews_provider.dart';
import 'package:spotlight/providers/theme_provider.dart';
import 'package:spotlight/widgets/auth_widgets.dart';
import 'package:spotlight/widgets/navigation.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  AppTab _activeTab = AppTab.hub;

  void _goToTab(AppTab tab) {
    FocusManager.instance.primaryFocus?.unfocus();
    final reviews = context.read<ReviewsProvider>();
    setState(() {
      _activeTab = tab;
      reviews.closeDetails();
    });
  }

  // ── Edit / delete comment dialogs (need BuildContext — stay here) ──────────

  Future<void> _editComment(Review review) async {
    final reviews = context.read<ReviewsProvider>();
    final movie = reviews.selectedMovie;
    if (movie == null) return;
    final darkMode = context.read<ThemeProvider>().darkMode;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => EditCommentSheet(
        darkMode: darkMode,
        movieTitle: movie.title,
        initialStars: review.nota,
        initialComment: review.comentario ?? '',
        onSubmit: (stars, comment) async {
          try {
            await context.read<ReviewsProvider>().updateReviewAndReload(
              movie: movie,
              reviewId: review.id,
              nota: stars,
              comentario: comment.isEmpty ? null : comment,
            );
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Comentário atualizado!')),
              );
            }
            return true;
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Erro ao atualizar comentário: $e')),
              );
            }
            return false;
          }
        },
      ),
    );
  }

  Future<void> _deleteComment(Review review) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF111113),
        title: const Text(
          'Excluir comentário',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Tem certeza que deseja excluir este comentário?',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Colors.white),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Excluir',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final reviews = context.read<ReviewsProvider>();
      final movie = reviews.selectedMovie;
      if (movie == null) return;
      try {
        await reviews.deleteComment(movie, review);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Comentário excluído.')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao excluir comentário: $e')),
          );
        }
      }
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final darkMode = context.watch<ThemeProvider>().darkMode;
    final auth = context.watch<AuthProvider>();
    final reviews = context.watch<ReviewsProvider>();
    final isDesktop = mediaQuery.size.width >= desktopBreakpoint;
    final isKeyboardOpen = mediaQuery.viewInsets.bottom > 0;
    final mobileBottomInset = mediaQuery.padding.bottom;
    final mobileNavHeight = 86.0 + mobileBottomInset;
    final hasDetails = reviews.selectedMovie != null;

    final background =
        hasDetails || darkMode
            ? const Color(0xFF09090B)
            : const Color(0xFFFAFAFA);

    return Scaffold(
      backgroundColor: background,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        top: !isDesktop,
        bottom: false,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (isDesktop)
                  DesktopSidebar(
                    darkMode: darkMode,
                    activeTab: _activeTab,
                    onTab: _goToTab,
                    onProfile: () => _goToTab(AppTab.profile),
                  ),
                Expanded(
                  child: _buildMainArea(
                    isDesktop: isDesktop,
                    darkMode: darkMode,
                    mobileNavHeight: mobileNavHeight,
                    isKeyboardOpen: isKeyboardOpen,
                  ),
                ),
              ],
            ),
            if (!isDesktop && !hasDetails && _activeTab != AppTab.profile)
              MobileHeader(
                darkMode: darkMode,
                onProfile: () => _goToTab(AppTab.profile),
                profileActive: _activeTab == AppTab.profile,
              ),
            if (!isDesktop && !isKeyboardOpen)
              MobileBottomNav(
                darkMode: darkMode,
                activeTab: _activeTab,
                onTab: _goToTab,
                bottomInset: mobileBottomInset,
              ),
            LoginModal(
              isOpen: auth.showLoginModal,
              darkMode: darkMode,
              onClose: () {
                FocusManager.instance.primaryFocus?.unfocus();
                context.read<AuthProvider>().closeLoginModal();
              },
              onLogin: (email, senha) =>
                  context.read<AuthProvider>().signInWithEmail(email, senha),
              onRegister: ({
                required String nome,
                required String email,
                required String senha,
                required String telefone,
                required String dataNascimento,
              }) => context.read<AuthProvider>().signUp(
                nome: nome,
                email: email,
                senha: senha,
                telefone: telefone,
                dataNascimento: dataNascimento,
              ),
              onGoogleLogin: () =>
                  context.read<AuthProvider>().signInWithGoogle(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainArea({
    required bool isDesktop,
    required bool darkMode,
    required double mobileNavHeight,
    required bool isKeyboardOpen,
  }) {
    final reviews = context.watch<ReviewsProvider>();
    final favorites = context.watch<FavoritesProvider>();
    final auth = context.watch<AuthProvider>();
    final hasDetails = reviews.selectedMovie != null;

    final isHubOrDetails = _activeTab == AppTab.hub || hasDetails;
    final horizontal = isDesktop ? 40.0 : (isHubOrDetails ? 0.0 : 16.0);
    final topPadding = hasDetails
        ? 0.0
        : _activeTab == AppTab.profile
        ? (isDesktop ? 28.0 : 20.0)
        : (isDesktop ? 28.0 : 80.0);
    final bottomPadding = isDesktop
        ? 20.0
        : (isKeyboardOpen
            ? 0.0
            : (_activeTab == AppTab.chat ? mobileNavHeight : (isHubOrDetails ? mobileNavHeight : mobileNavHeight + 14.0)));

    Widget content;
    if (hasDetails) {
      final item = reviews.selectedMovie!;
      final controller = DetailsController(
        item: item,
        relatedByDirector: reviews.relatedByDirector,
        relatedByActor: reviews.relatedByActor,
        similar: reviews.similar,
        episodes: reviews.episodes,
        tvNumberOfSeasons: reviews.tvNumberOfSeasons,
        loadingRelated: reviews.loadingRelated,
        comments: reviews.contentReviews,
        userReview: reviews.userReview,
        cast: reviews.contentCast,
        contentRating: reviews.contentRating,
        isFavorite: favorites.isFavorite(item),
        userId: auth.userId,
        loadingComments: reviews.loadingComments,
        contentDetails: reviews.contentDetails,
        onClose: () => reviews.closeDetails(),
        onToggleFavorite: () => favorites.toggleFavorite(item),
        onSubmitRating: (stars, comment) async {
          final ok = await reviews.submitRating(item, stars, comment);
          if (ok && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Avaliação salva!')),
            );
          } else if (!ok && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Erro ao salvar avaliação.')),
            );
          }
          return ok;
        },
        onDeleteRating: () async {
          final ok = await reviews.deleteRating(item);
          if (ok && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Avaliação excluída.')),
            );
          }
          return ok;
        },
        onSelectItem: (movie) => reviews.openDetails(movie),
        onEditComment: (review) => _editComment(review),
        onDeleteComment: (review) => _deleteComment(review),
      );
      content = DetailsView(controller: controller, darkMode: darkMode);
    } else {
      switch (_activeTab) {
        case AppTab.hub:
          content = const HubView();
          break;
        case AppTab.chat:
          content = const AIView();
          break;
        case AppTab.list:
          content = SavedListView(
            onSelect: (movie) => reviews.openDetails(movie),
          );
          break;
        case AppTab.search:
          content = const SearchView();
          break;
        case AppTab.profile:
          content = ProfileView(
            onBack: () => _goToTab(AppTab.hub),
          );
          break;
      }
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      padding: EdgeInsets.fromLTRB(
        horizontal,
        topPadding,
        horizontal,
        bottomPadding,
      ),
      child: content,
    );
  }
}
