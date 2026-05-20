import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:spotlight/models/movie.dart';
import 'package:spotlight/services/app_secrets.dart';

/// Serviço de fallback utilizando a API do Groq (Llama 3).
///
/// Entra em ação quando o Gemini atinge o limite de cota.
class GroqService {
  static const String _baseUrl = 'https://api.groq.com/openai/v1/chat/completions';

  /// Instrução de sistema idêntica à do Gemini para manter consistência.
  static const String _systemInstruction = '''
Você é o Spot AI, assistente inteligente de entretenimento do aplicativo Spotlight.

Regras obrigatórias:
- Responda SEMPRE em português do Brasil.
- Foque em filmes, séries e streaming.
- Seja amigável e conciso.
''';

  static Future<String> generateResponse(String userMessage) async {
    final key = AppSecrets.groqApiKey;

    // Chaves do Groq geralmente começam com 'gsk_'. 
    // Só barramos se estiver vazia ou for curta demais (placeholder).
    if (key.isEmpty || key.length < 20) {
      // Se a chave não estiver configurada, não tentamos
      return 'Erro: Cota do Gemini excedida e Groq não configurado.';
    }

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Authorization': 'Bearer $key',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'model': 'llama-3.3-70b-versatile',
          'messages': [
            {'role': 'system', 'content': _systemInstruction},
            {'role': 'user', 'content': userMessage},
          ],
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['choices'][0]['message']['content'] as String;
      } else {
        final errorData = json.decode(response.body);
        final errorMessage = errorData['error']?['message'] ?? 'Erro desconhecido';
        debugPrint('Groq Error: $errorMessage');
        
        if (response.statusCode == 401) {
          return 'Erro: Chave do Groq inválida ou não configurada.';
        }
        return 'Erro ao conectar com assistente de reserva (Groq): $errorMessage';
      }
    } catch (e) {
      debugPrint('Groq Exception: $e');
      return 'Erro crítico no sistema de chat.';
    }
  }

  /// Extrai palavras-chave de busca (títulos, gêneros, etc.) de uma mensagem.
  /// Versão Groq para quando o Gemini falha.
  static Future<String> extractSearchKeywords(String userMessage) async {
    final key = AppSecrets.groqApiKey;
    if (key.isEmpty || key.length < 20) return userMessage;

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Authorization': 'Bearer $key',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'model': 'llama-3.3-70b-versatile',
          'messages': [
            {
              'role': 'system',
              'content': 'Você é um extrator de termos de busca. '
                  'Extraia apenas os nomes de filmes, séries ou gêneros citados na mensagem. '
                  'Retorne APENAS os termos separados por espaço. '
                  'Se não houver termos claros, retorne a mensagem original limpa.'
            },
            {'role': 'user', 'content': userMessage},
          ],
          'temperature': 0.0,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['choices'][0]['message']['content']?.toString().trim() ?? userMessage;
      }
      return userMessage;
    } catch (_) {
      return userMessage;
    }
  }

  /// Constrói um prompt enriquecido para pedidos de recomendação (Versão Groq).
  static String buildRecommendationPrompt(
    String userMessage,
    List<Movie> movies,
  ) {
    if (movies.isEmpty) return userMessage;

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
- Use os nomes EXATOS dos títulos da lista fornecida acima quando for citá-los.
- Cite APENAS títulos que aparecem na lista de catálogo fornecida acima.
- Se a lista tiver títulos irrelevantes, ignore-os e foque nos que fazem sentido para o pedido.
- NÃO invente títulos que não estão na lista.
- Limite sua resposta a no máximo 100 palavras.
- Finalize com uma recomendação direta de um dos itens da lista.
''';
  }
}
