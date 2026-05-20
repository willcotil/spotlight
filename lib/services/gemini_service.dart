import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:spotlight/models/movie.dart';
import 'package:spotlight/services/app_secrets.dart';

/// Wrapper para a API de geração de texto do Google Gemini.
///
/// A chave de API é lida de [AppSecrets.geminiApiKey].
/// Para configurar, edite lib/services/app_secrets.dart e preencha o valor real.
class GeminiService {
  /// Instrução de sistema que garante respostas sempre em português
  /// e mantém o contexto de assistente de entretenimento.
  static const String _systemInstruction = '''
Você é o Spot AI, assistente inteligente de entretenimento do aplicativo Spotlight.

Regras obrigatórias:
- Responda SEMPRE em português do Brasil, independentemente do idioma da pergunta.
- Foque em filmes, séries, documentários, streaming e cultura pop.
- Seja amigável, conciso e direto. Evite respostas longas demais.
- Se a pergunta não for sobre entretenimento, redirecione gentilmente para o tema.
- Nunca revele que é um modelo de linguagem ou que tem limitações técnicas.
- Não invente informações; se não souber algo, diga que não sabe.
''';

  /// Envia [userMessage] ao Gemini e retorna o texto gerado pelo assistente.
  static Future<String> generateResponse(String userMessage) async {
    final key = AppSecrets.geminiApiKey;

    if (key.isEmpty || key == 'YOUR_KEY_HERE') {
      return 'Chave da API Gemini não configurada. '
          'Preencha AppSecrets.geminiApiKey em lib/services/app_secrets.dart.';
    }

    try {
      final model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: key,
        systemInstruction: Content.text(_systemInstruction),
      );

      final content = [Content.text(userMessage)];
      final response = await model.generateContent(content);

      return response.text ?? 'Sem resposta.';
    } catch (e) {
      debugPrint('Gemini Error: $e');
      return 'Erro ao conectar com a IA. Tente novamente em instantes.';
    }
  }

  /// Extrai palavras-chave de busca (títulos, gêneros, etc.) de uma mensagem.
  /// Ajuda o TMDb a encontrar resultados mais precisos.
  static Future<String> extractSearchKeywords(String userMessage) async {
    final key = AppSecrets.geminiApiKey;
    if (key.isEmpty || key == 'YOUR_KEY_HERE') return userMessage;

    try {
      final model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: key,
        systemInstruction: Content.text(
            'Você é um extrator de termos de busca. '
            'Extraia apenas os nomes de filmes, séries ou gêneros citados na mensagem. '
            'Retorne APENAS os termos separados por espaço. '
            'Se não houver termos claros, retorne a mensagem original limpa.'),
      );

      final content = [Content.text(userMessage)];
      final response = await model.generateContent(content);

      return response.text?.trim() ?? userMessage;
    } catch (_) {
      return userMessage;
    }
  }

  /// Constrói um prompt enriquecido para pedidos de recomendação.
  ///
  /// Combina a mensagem original do usuário com metadados dos [movies] obtidos
  /// do TMDb. O Gemini usa esse contexto para citar títulos reais na resposta.
  ///
  /// Se [movies] estiver vazio, retorna [userMessage] sem alterações para que
  /// o assistente responda como um consultor genérico de filmes.
  static String buildRecommendationPrompt(
    String userMessage,
    List<Movie> movies,
  ) {
    if (movies.isEmpty) return userMessage;

    // Formata cada filme como uma linha de contexto compacta
    final movieLines = movies.map((m) {
      final rating = m.rating > 0 ? ' (nota ${m.rating.toStringAsFixed(1)})' : '';
      final year = m.year.isNotEmpty ? ' [${m.year}]' : '';
      return '• ${m.title}$year$rating — ${m.genre}';
    }).join('\n');

    return '''
Pedido do usuário: "$userMessage"

Filmes e séries disponíveis no catálogo para recomendar:
$movieLines

Instruções CRÍTICAS para sua resposta:
- Responda em português do Brasil, de forma calorosa e conversacional.
- Ao citar qualquer título, use EXATAMENTE o nome que aparece na lista acima, sem traduzir.
- Cite APENAS títulos que aparecem na lista fornecida acima.
- Se a lista tiver títulos irrelevantes, ignore-os e foque nos que fazem sentido.
- Se nenhum título fizer sentido, dê uma resposta genérica sem citar nomes específicos.
- NÃO invente títulos que não estão na lista.
- Limite sua resposta a no máximo 100 palavras.
- Finalize com uma recomendação direta de um dos itens da lista.
''';
  }
}
