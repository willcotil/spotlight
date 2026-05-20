/// Hierarquia de exceções tipadas para a camada de serviços do Spotlight.
///
/// Substitui os blocos `catch (_) {}` genéricos, permitindo que os providers
/// e views diferenciem erros de rede, parsing e autenticação.
library;

// ── Exceção base ──────────────────────────────────────────────────────────────

/// Exceção raiz da hierarquia Spotlight.
///
/// Todas as exceções de serviço herdam desta classe para facilitar
/// captura genérica quando necessário.
sealed class SpotlightException implements Exception {
  const SpotlightException(this.message);

  /// Mensagem legível em português para exibir ao usuário.
  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

// ── Subclasses concretas ───────────────────────────────────────────────────────

/// Falha em requisição HTTP ou ausência de conectividade.
///
/// Lançada quando a requisição não chega ao servidor ou o servidor retorna
/// um código 5xx.
final class NetworkException extends SpotlightException {
  const NetworkException([
    super.message = 'Falha de conexão. Verifique sua internet e tente novamente.',
  ]);
}

/// Falha ao interpretar a resposta JSON retornada por uma API.
///
/// Lançada quando o JSON está mal formado ou quando um campo obrigatório
/// está ausente/com tipo inesperado.
final class ParseException extends SpotlightException {
  const ParseException([
    super.message = 'Erro ao processar os dados recebidos. Tente novamente.',
  ]);
}

/// Falha relacionada a autenticação ou autorização no Spotlight.
///
/// Lançada quando a sessão expirou, as credenciais são inválidas ou
/// quando a API retorna um código 4xx de autenticação.
///
/// **Atenção:** O pacote `supabase_flutter` também exporta um `AuthException`
/// (do pacote `gotrue`). Esta classe usa o prefixo `Spotlight` para evitar
/// conflito de nomes.
final class SpotlightAuthException extends SpotlightException {
  const SpotlightAuthException([
    super.message = 'Falha de autenticação. Verifique suas credenciais.',
  ]);
}
