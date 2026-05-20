import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:spotlight/models/movie.dart';
import 'package:spotlight/models/review.dart';
import 'package:spotlight/models/cast_member.dart';
import 'package:spotlight/models/episode.dart';

class DetailsController {
  final Movie item;
  final List<Movie> relatedByDirector;
  final List<Movie> relatedByActor;
  final List<Movie> similar;
  final List<Episode> episodes;
  final int? tvNumberOfSeasons;
  final bool loadingRelated;
  final List<Review> comments;
  final Review? userReview;
  final List<CastMember> cast;
  final String? contentRating;
  final bool isFavorite;
  final String? userId;
  final bool loadingComments;
  final Map<String, dynamic>? contentDetails;

  // Callbacks for actions
  final VoidCallback onClose;
  final VoidCallback onToggleFavorite;
  final Future<bool> Function(int stars, String comment) onSubmitRating;
  final Future<bool> Function() onDeleteRating;
  final ValueChanged<Movie> onSelectItem;
  final Future<void> Function(Review) onEditComment;
  final Future<void> Function(Review) onDeleteComment;

  DetailsController({
    required this.item,
    required this.relatedByDirector,
    required this.relatedByActor,
    required this.similar,
    required this.episodes,
    required this.tvNumberOfSeasons,
    required this.loadingRelated,
    required this.comments,
    required this.userReview,
    required this.cast,
    required this.contentRating,
    required this.isFavorite,
    required this.userId,
    required this.loadingComments,
    required this.onClose,
    required this.onToggleFavorite,
    required this.onSubmitRating,
    required this.onDeleteRating,
    required this.onSelectItem,
    required this.onEditComment,
    required this.onDeleteComment,
    required this.contentDetails,
  });

  Future<void> shareMovie() async {
    final shareText =
        'Confira "${item.title}" (${item.year}) no Spotlight!\n\n${item.synopsis}\n\nBaixe o app Spotlight para descobrir mais filmes incríveis!';
    await Share.share(shareText);
  }

  void toggleFavorite() {
    onToggleFavorite();
  }

  void selectItem(Movie movie) {
    onSelectItem(movie);
  }

  Future<void> editComment(Review review) async {
    await onEditComment(review);
  }

  Future<void> deleteComment(Review review) async {
    await onDeleteComment(review);
  }
}
