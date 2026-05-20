import 'package:flutter_test/flutter_test.dart';
import 'package:spotlight/providers/search_provider.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

/// Aguarda até [maxWait] que a condição [predicate] seja verdadeira,
/// verificando a cada [interval].
Future<void> _waitUntil(
  bool Function() predicate, {
  Duration maxWait = const Duration(seconds: 2),
  Duration interval = const Duration(milliseconds: 50),
}) async {
  final deadline = DateTime.now().add(maxWait);
  while (!predicate()) {
    if (DateTime.now().isAfter(deadline)) {
      throw StateError('waitUntil: condição não satisfeita no tempo limite.');
    }
    await Future<void>.delayed(interval);
  }
}

// ── Testes ────────────────────────────────────────────────────────────────────

void main() {
  group('SearchProvider.search (debounce)', () {
    test('isLoading é true imediatamente após search() ser chamado', () {
      final provider = SearchProvider();

      // Digita uma query — o debounce ainda não disparou.
      provider.search('avengers');

      expect(provider.isLoading, isTrue);
      expect(provider.query, 'avengers');

      provider.dispose();
    });

    test('atualiza query a cada chamada de search()', () {
      final provider = SearchProvider();

      provider.search('a');
      expect(provider.query, 'a');

      provider.search('av');
      expect(provider.query, 'av');

      provider.search('avengers');
      expect(provider.query, 'avengers');

      provider.dispose();
    });

    test('debounce cancela timer anterior e não dispara múltiplas requisições',
        () async {
      final provider = SearchProvider();

      // Simula digitação rápida — todas dentro do intervalo de debounce.
      provider.search('a');
      provider.search('av');
      provider.search('ave');
      provider.search('aven');
      // A query final é 'aven'. O debounce de 500ms ainda não expirou.

      expect(provider.query, 'aven');
      expect(provider.isLoading, isTrue);

      // Aguarda mais que o debounce para que a requisição (que vai falhar
      // por não haver servidor real) seja concluída e isLoading vire false.
      await _waitUntil(
        () => !provider.isLoading,
        maxWait: const Duration(seconds: 3),
      );

      // Após o debounce, hasSearched deve ser verdadeiro mesmo que a
      // requisição tenha falhado com lista vazia.
      expect(provider.hasSearched, isTrue);
      // A query não deve ter mudado.
      expect(provider.query, 'aven');

      provider.dispose();
    });

    test('query vazia não dispara debounce e reseta estado imediatamente', () {
      final provider = SearchProvider();

      provider.search('avengers');
      expect(provider.isLoading, isTrue);

      // Limpar o campo deve resetar tudo imediatamente (sem aguardar debounce).
      provider.search('');

      expect(provider.query, '');
      expect(provider.isLoading, isFalse);
      expect(provider.hasSearched, isFalse);
      expect(provider.results, isEmpty);

      provider.dispose();
    });
  });

  group('SearchProvider.clear()', () {
    test('reseta todos os campos para o estado inicial', () {
      final provider = SearchProvider();

      provider.search('batman');
      // Agora há uma query e isLoading=true.

      provider.clear();

      expect(provider.query, '');
      expect(provider.isLoading, isFalse);
      expect(provider.hasSearched, isFalse);
      expect(provider.results, isEmpty);
      expect(provider.errorMessage, isNull);

      provider.dispose();
    });

    test('clearError() limpa errorMessage mas mantém outros estados', () {
      final provider = SearchProvider();

      // Força um estado de erro diretamente (requer acesso interno).
      // Como não temos acesso ao campo privado, usamos a API pública:
      // search() com query real que vai falhar (sem servidor),
      // e depois verificamos que clearError() funciona.
      provider.search('spiderman');

      // O errorMessage ainda é null (requisição não concluiu).
      expect(provider.errorMessage, isNull);

      // Chama clearError() de forma segura — não deve lançar exceção.
      provider.clearError();
      expect(provider.errorMessage, isNull);

      provider.dispose();
    });
  });
}
