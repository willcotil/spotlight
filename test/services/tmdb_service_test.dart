import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:spotlight/services/app_exceptions.dart';
import 'package:spotlight/services/tmdb_service.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

/// Retorna o payload JSON mínimo que representa uma lista de resultados TMDb.
String _resultsJson(List<Map<String, dynamic>> items) =>
    json.encode({'results': items});

/// Cria um item de filme mínimo aceito por Movie.fromJson.
Map<String, dynamic> _movieItem({
  int id = 1,
  String title = 'Test Movie',
  String mediaType = 'movie',
}) =>
    {
      'id': id,
      'title': title,
      'name': title,
      'media_type': mediaType,
      'genre_ids': <int>[],
      'vote_average': 7.5,
      'release_date': '2024-01-01',
      'first_air_date': '2024-01-01',
      'overview': 'Sinopse de teste.',
      'poster_path': null,
      'backdrop_path': null,
    };

// ── Interceptação do cliente HTTP ─────────────────────────────────────────────

/// Substitui o cliente HTTP global durante os testes.
///
/// **Atenção:** [TMDBService] usa `http.get` diretamente (cliente global).
/// Aqui usamos [http.runWithClient] para injetar o cliente de teste sem
/// modificar o código de produção.
Future<T> _withClient<T>(
  MockClient client,
  Future<T> Function() fn,
) =>
    http.runWithClient(fn, () => client);

// ── Testes ────────────────────────────────────────────────────────────────────

void main() {
  group('TMDBService.fetchTrending', () {
    test('retorna lista de filmes quando a resposta é 200', () async {
      final client = MockClient((request) async {
        expect(request.url.path, contains('/trending/movie/week'));
        return http.Response(
          _resultsJson([_movieItem(id: 42, title: 'Inception')]),
          200,
        );
      });

      final movies = await _withClient(
        client,
        () => TMDBService.fetchTrending(type: 'movie'),
      );

      expect(movies, hasLength(1));
      expect(movies.first.id, 42);
      expect(movies.first.title, 'Inception');
    });

    test('retorna lista de séries quando type == tv', () async {
      final client = MockClient((request) async {
        expect(request.url.path, contains('/trending/tv/week'));
        return http.Response(
          _resultsJson([_movieItem(id: 10, mediaType: 'tv')]),
          200,
        );
      });

      final movies = await _withClient(
        client,
        () => TMDBService.fetchTrending(type: 'tv'),
      );

      expect(movies, hasLength(1));
      expect(movies.first.id, 10);
    });

    test('lança NetworkException para erro 4xx (sem retry)', () async {
      var callCount = 0;
      final client = MockClient((_) async {
        callCount++;
        return http.Response('Unauthorized', 401);
      });

      await expectLater(
        _withClient(client, () => TMDBService.fetchTrending(type: 'movie')),
        throwsA(isA<NetworkException>()),
      );

      // Erros 4xx não devem ser retentados.
      expect(callCount, 1);
    });

    test('retenta até 2 vezes para erros 5xx e depois lança NetworkException',
        () async {
      var callCount = 0;
      final client = MockClient((_) async {
        callCount++;
        return http.Response('Internal Server Error', 500);
      });

      await expectLater(
        _withClient(client, () => TMDBService.fetchTrending(type: 'movie')),
        throwsA(isA<NetworkException>()),
      );

      // 1 tentativa original + 2 retries = 3 chamadas ao todo.
      expect(callCount, 3);
    });

    test('lança ParseException quando o JSON não contém "results"', () async {
      final client = MockClient(
        (_) async => http.Response(json.encode({'data': []}), 200),
      );

      await expectLater(
        _withClient(client, () => TMDBService.fetchTrending(type: 'movie')),
        throwsA(isA<ParseException>()),
      );
    });
  });

  // ── searchMedia ────────────────────────────────────────────────────────────

  group('TMDBService.searchMedia', () {
    test('retorna lista filtrada de filmes e séries', () async {
      final client = MockClient((request) async {
        expect(request.url.path, contains('/search/multi'));
        expect(request.url.queryParameters['query'], 'matrix');
        return http.Response(
          _resultsJson([
            _movieItem(id: 1, mediaType: 'movie'),
            _movieItem(id: 2, mediaType: 'tv'),
            // Pessoas devem ser filtradas
            {
              ..._movieItem(id: 3),
              'media_type': 'person',
            },
          ]),
          200,
        );
      });

      final results = await _withClient(
        client,
        () => TMDBService.searchMedia('matrix'),
      );

      // 'person' deve ser excluído
      expect(results, hasLength(2));
      expect(results.map((m) => m.id).toList(), containsAll([1, 2]));
    });

    test('retorna lista vazia quando a query está em branco', () async {
      // Nenhuma requisição HTTP deve ser feita para query vazia.
      final client = MockClient((_) async {
        fail('Não deveria chamar a API para query vazia');
      });

      final results = await _withClient(
        client,
        () => TMDBService.searchMedia('  '),
      );

      expect(results, isEmpty);
    });

    test('lança NetworkException para erro de servidor', () async {
      final client = MockClient(
        (_) async => http.Response('Server Error', 500),
      );

      await expectLater(
        _withClient(client, () => TMDBService.searchMedia('batman')),
        throwsA(isA<NetworkException>()),
      );
    });
  });
}
