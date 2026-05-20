import 'package:spotlight/models/movie.dart';

/// Representa uma única mensagem no histórico de chat com o Spot AI.
///
/// [suggestedMovies] é preenchido apenas em respostas de recomendação,
/// onde o assistente retornou sugestões baseadas no TMDb. É null em
/// mensagens comuns ou enviadas pelo usuário.
class ChatMessage {
  const ChatMessage({
    required this.text,
    required this.isUser,
    this.suggestedMovies,
  });

  final String text;
  final bool isUser;

  /// Lista de filmes sugeridos pelo assistente (apenas em respostas de recomendação).
  final List<Movie>? suggestedMovies;
}
