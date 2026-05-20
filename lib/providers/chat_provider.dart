import 'dart:async';

import 'package:flutter/material.dart';
import 'package:spotlight/models/chat_message.dart';
import 'package:spotlight/models/movie.dart';
import 'package:spotlight/services/gemini_service.dart';
import 'package:spotlight/services/groq_service.dart';
import 'package:spotlight/services/tmdb_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Gerencia o histórico de chat com o Spot AI e a persistência no Supabase.
///
/// Fluxo de uso:
///   1. Ao fazer login, chame [loadHistory] passando o userId do AuthProvider.
///   2. Use [sendMessage] para enviar mensagens; o provider atualiza a UI e
///      persiste no banco automaticamente.
///   3. Ao deslogar, chame [clearHistory] para limpar o estado local.
class ChatProvider extends ChangeNotifier {
  final _db = Supabase.instance.client;

  // Mensagem de boas-vindas exibida antes de qualquer interação
  static const _welcomeMessage = ChatMessage(
    text: 'Olá! Sou o Spot, seu assistente inteligente de cinema. '
        'Como posso ajudar?',
    isUser: false,
  );

  final List<ChatMessage> _history = [_welcomeMessage];

  bool _isTyping = false;
  bool _isLoading = false;

  // Assinatura do stream de autenticação para reagir a login/logout
  StreamSubscription<AuthState>? _authSub;

  ChatProvider() {
    // Escuta mudanças de sessão: carrega histórico ao logar, limpa ao deslogar
    _authSub = _db.auth.onAuthStateChange.listen((event) {
      if (event.event == AuthChangeEvent.signedIn &&
          event.session?.user.id != null) {
        loadHistory(event.session!.user.id);
      } else if (event.event == AuthChangeEvent.signedOut) {
        clearHistory();
      }
    });
  }

  /// Lista imutável do histórico de mensagens.
  List<ChatMessage> get history => List.unmodifiable(_history);

  /// Indica se o assistente está gerando uma resposta.
  bool get isTyping => _isTyping;

  /// Indica se o histórico está sendo carregado do banco de dados.
  bool get isLoading => _isLoading;

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  // ── Persistência ──────────────────────────────────────────────────────────

  /// Carrega o histórico de mensagens do Supabase para o [userId] informado.
  ///
  /// Deve ser chamado logo após o login do usuário.
  Future<void> loadHistory(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final rows = await _db
          .from('chat_history')
          .select('role, content, metadata')
          .eq('user_id', userId)
          .order('created_at', ascending: true)
          .limit(100); // Limita para não sobrecarregar a UI

      _history.clear();
      _history.add(_welcomeMessage);

      for (final row in rows as List) {
        List<Movie>? suggestedMovies;
        if (row['metadata'] != null) {
          final metadata = row['metadata'] as Map<String, dynamic>;
          if (metadata['suggested_movies'] != null) {
            final list = metadata['suggested_movies'] as List;
            suggestedMovies = list.map((item) => Movie.fromJson(item as Map<String, dynamic>)).toList();
          }
        }

        _history.add(ChatMessage(
          text: row['content'] as String,
          isUser: row['role'] == 'user',
          suggestedMovies: suggestedMovies,
        ));
      }
    } catch (_) {
      // Falha silenciosa: mantém apenas a mensagem de boas-vindas
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Persiste uma única mensagem no banco para o [userId] informado.
  Future<void> _saveMessage({
    required String userId,
    required ChatMessage message,
  }) async {
    try {
      Map<String, dynamic>? metadata;
      if (message.suggestedMovies != null && message.suggestedMovies!.isNotEmpty) {
        metadata = {
          'suggested_movies': message.suggestedMovies!.map((m) => m.toMinimalJson()).toList(),
        };
      }

      await _db.from('chat_history').insert({
        'user_id': userId,
        'role': message.isUser ? 'user' : 'assistant',
        'content': message.text,
        'metadata': metadata,
      });
    } catch (_) {
      // Falha silenciosa: mensagem já está na UI mesmo sem persistência
    }
  }

  /// Limpa o histórico local (usar ao deslogar).
  void clearHistory() {
    _history.clear();
    _history.add(_welcomeMessage);
    notifyListeners();
  }

  // ── Detecção de intenção de recomendação ──────────────────────────────────

  /// Palavras-chave que indicam que o usuário quer uma recomendação de conteúdo.
  static const _recommendationKeywords = [
    'quero',
    'sugira',
    'indica',
    'recomenda',
    'assistir',
    'filme',
    'série',
    'ver',
    'assistindo',
    'mood',
    'clima',
    'humor',
  ];

  /// Retorna true se [text] contiver ao menos uma palavra-chave de recomendação.
  bool _isRecommendationRequest(String text) {
    final lower = text.toLowerCase();
    return _recommendationKeywords.any((kw) => lower.contains(kw));
  }

  // ── Envio de mensagens ────────────────────────────────────────────────────

  /// Envia [text] ao Gemini, adiciona as mensagens ao histórico e
  /// persiste no Supabase se [userId] for fornecido.
  ///
  /// Quando a mensagem é identificada como pedido de recomendação, busca filmes
  /// relevantes no TMDb, enriquece o prompt com os metadados e anexa a lista
  /// de sugestões à mensagem do assistente.
  Future<void> sendMessage(String text, {String? userId}) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    // Adiciona mensagem do usuário
    final userMsg = ChatMessage(text: trimmed, isUser: true);
    _history.add(userMsg);
    _isTyping = true;
    notifyListeners();

    // Persiste mensagem do usuário (não bloqueia a UI)
    if (userId != null) {
      _saveMessage(userId: userId, message: userMsg);
    }

    // Detecta intenção de recomendação e busca filmes se necessário
    List<Movie> suggestedMovies = [];
    String prompt = trimmed;

    if (_isRecommendationRequest(trimmed)) {
      try {
        // Tenta extrair keywords com o Gemini
        String keywords = await GeminiService.extractSearchKeywords(trimmed);
        
        // Se o Gemini falhou/retornou erro de cota, tenta com o Groq
        if (keywords.contains('Erro') || keywords.contains('cota') || keywords == trimmed) {
           debugPrint('ChatProvider: Gemini falhou na extração, tentando Groq...');
           keywords = await GroqService.extractSearchKeywords(trimmed);
        }

        final results = await TMDBService.searchMedia(keywords);
        suggestedMovies = results.take(5).toList();
      } catch (e) {
        debugPrint('ChatProvider: Falha na extração de keywords, usando fallback raw. Erro: $e');
        try {
          final results = await TMDBService.searchMedia(trimmed);
          suggestedMovies = results.take(5).toList();
        } catch (_) {}
      }
      
      // Tenta construir o prompt rico para o Gemini
      prompt = GeminiService.buildRecommendationPrompt(trimmed, suggestedMovies);
    }

    // ── Geração da Resposta (Gemini com Fallback para Groq) ──────────────────
    String reply = '';

    try {
      // Tenta o Gemini primeiro
      reply = await GeminiService.generateResponse(prompt);
      
      // Se o Gemini retornar uma mensagem de erro conhecida, forçamos o catch para o fallback
      if (reply.contains('cota') || reply.contains('Erro ao conectar') || reply.contains('Chave da API')) {
        throw Exception('Gemini indisponível');
      }
    } catch (e) {
      debugPrint('ChatProvider: Gemini falhou ($e). Tentando fallback para Groq...');
      
      // Se estivermos recomendando, passamos o prompt rico para o Groq também
      String groqPrompt = prompt;
      if (suggestedMovies.isNotEmpty) {
        groqPrompt = GroqService.buildRecommendationPrompt(trimmed, suggestedMovies);
      }

      try {
        final groqReply = await GroqService.generateResponse(groqPrompt);
        if (groqReply.contains('Erro')) {
          reply = 'Erro ao conectar com a IA. Tente novamente em instantes.';
        } else {
          reply = groqReply;
        }
      } catch (ge) {
        debugPrint('ChatProvider: Fallback para Groq também falhou ($ge)');
        reply = 'Erro ao conectar com a IA. Tente novamente em instantes.';
      }
    }

    // Filtra os filmes sugeridos para manter apenas os que a IA realmente citou na resposta.
    // Usa múltiplas estratégias para lidar com títulos em português vs inglês,
    // subtítulos, pontuação e variações.
    final replyLower = reply.toLowerCase();
    final List<Movie> finalSuggestions = suggestedMovies.where((m) {
      final fullTitle = m.title.toLowerCase();

      // 1. Título completo
      if (replyLower.contains(fullTitle)) return true;

      // 2. Antes dos separadores (":", "-", "–")
      for (final sep in [':', '-', '–']) {
        if (fullTitle.contains(sep)) {
          final short = fullTitle.split(sep).first.trim();
          if (short.length > 3 && replyLower.contains(short)) return true;
        }
      }

      // 3. Palavras significativas do título (ignora artigos curtos)
      final stopWords = {'the', 'a', 'an', 'of', 'in', 'on', 'at', 'o', 'os', 'as', 'de', 'do', 'da', 'dos', 'das', 'e', 'em'};
      final words = fullTitle.split(RegExp(r'\s+')).where((w) => w.length > 3 && !stopWords.contains(w)).toList();
      if (words.length >= 2) {
        // Se pelo menos 2 palavras significativas aparecem na resposta, aceita
        final matches = words.where((w) => replyLower.contains(w)).length;
        if (matches >= 2) return true;
      } else if (words.length == 1 && words.first.length > 5) {
        if (replyLower.contains(words.first)) return true;
      }

      return false;
    }).toList();

    debugPrint('Spot Chat: TMDb trouxe ${suggestedMovies.length} itens. IA citou ${finalSuggestions.length} itens.');

    // Adiciona resposta do assistente, com filmes anexados se houver sugestões
    final assistantMsg = ChatMessage(
      text: reply,
      isUser: false,
      suggestedMovies: finalSuggestions.isEmpty ? null : finalSuggestions,
    );
    _history.add(assistantMsg);
    _isTyping = false;
    notifyListeners();

    // Persiste resposta do assistente
    if (userId != null) {
      _saveMessage(userId: userId, message: assistantMsg);
    }
  }
}
