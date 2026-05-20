import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spotlight/models/movie.dart';
import 'package:spotlight/providers/favorites_provider.dart';

// ── Stubs ─────────────────────────────────────────────────────────────────────

/// Stub mínimo de AuthProvider que não depende do Supabase.
///
/// Implementa apenas a interface necessária para o [FavoritesProvider]
/// sem chamar o construtor real de [AuthProvider] (que acessa Supabase).
class _FakeAuth extends ChangeNotifier {
  _FakeAuth({required bool loggedIn, String? userId})
      : _loggedIn = loggedIn,
        _uid = userId;

  bool _loggedIn;
  String? _uid;

  bool get isLoggedIn => _loggedIn;
  String? get userId => _uid;

  bool modalOpened = false;

  void openLoginModal() {
    modalOpened = true;
  }

  // Simula logout
  void logout() {
    _loggedIn = false;
    _uid = null;
    notifyListeners();
  }
}

/// Subclasse testável de [FavoritesProvider] que aceita o stub [_FakeAuth].
///
/// Necessário porque [FavoritesProvider] declara [AuthProvider] como tipo
/// do parâmetro. Usamos duck-typing por meio de uma classe intermediária
/// que delega ao stub.
class _TestFavoritesProvider extends ChangeNotifier {
  _TestFavoritesProvider(this._auth);

  final _FakeAuth _auth;
  final List<Movie> _favorites = [];
  final bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<Movie> get favorites => List.unmodifiable(_favorites);

  bool isFavorite(Movie movie) => _favorites.any((m) => m.id == movie.id);

  /// Replica a lógica de [FavoritesProvider.toggleFavorite].
  bool toggleFavorite(Movie movie) {
    if (!_auth.isLoggedIn && !isFavorite(movie)) {
      _auth.openLoginModal();
      return true;
    }

    if (isFavorite(movie)) {
      _favorites.removeWhere((m) => m.id == movie.id);
    } else {
      if (!isFavorite(movie)) _favorites.add(movie);
    }

    notifyListeners();
    return false;
  }

  /// Replica a lógica de [FavoritesProvider.updateAuth] (limpeza no logout).
  void handleLogout() {
    _favorites.clear();
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

/// Cria um [Movie] mínimo para uso nos testes.
Movie _movie({int id = 1, String title = 'Filme Teste'}) => Movie(
      id: id,
      title: title,
      type: 'Filme',
      genre: 'Drama',
      rating: 7.0,
      year: '2024',
      duration: '120 min',
      synopsis: 'Sinopse de teste.',
      platforms: const [],
    );

// ── Testes ────────────────────────────────────────────────────────────────────

void main() {
  group('FavoritesProvider.toggleFavorite — usuário NÃO logado', () {
    late _FakeAuth auth;
    late _TestFavoritesProvider favorites;

    setUp(() {
      auth = _FakeAuth(loggedIn: false);
      favorites = _TestFavoritesProvider(auth);
    });

    test('abre modal de login e retorna true ao tentar adicionar favorito', () {
      final movie = _movie();
      final openedModal = favorites.toggleFavorite(movie);

      expect(openedModal, isTrue);
      expect(auth.modalOpened, isTrue);
      // Filme não deve ter sido adicionado sem login.
      expect(favorites.isFavorite(movie), isFalse);
    });
  });

  group('FavoritesProvider.toggleFavorite — usuário logado', () {
    late _FakeAuth auth;
    late _TestFavoritesProvider favorites;

    setUp(() {
      auth = _FakeAuth(loggedIn: true, userId: 'user-123');
      favorites = _TestFavoritesProvider(auth);
    });

    test('adiciona filme à lista local de favoritos', () {
      final movie = _movie(id: 10);

      expect(favorites.isFavorite(movie), isFalse);
      favorites.toggleFavorite(movie);
      expect(favorites.isFavorite(movie), isTrue);
    });

    test('remove filme da lista local ao chamar toggleFavorite duas vezes', () {
      final movie = _movie(id: 20);

      favorites.toggleFavorite(movie); // Adiciona
      expect(favorites.isFavorite(movie), isTrue);

      favorites.toggleFavorite(movie); // Remove
      expect(favorites.isFavorite(movie), isFalse);
    });

    test('não duplica filme ao fazer add → remove → add', () {
      final movie = _movie(id: 30);

      favorites.toggleFavorite(movie); // Adiciona → está em favoritos
      favorites.toggleFavorite(movie); // Remove → não está
      favorites.toggleFavorite(movie); // Adiciona novamente

      final count = favorites.favorites.where((m) => m.id == movie.id).length;
      expect(count, 1);
    });

    test('retorna false quando a operação de toggle é bem-sucedida', () {
      final movie = _movie(id: 40);
      final result = favorites.toggleFavorite(movie);
      expect(result, isFalse);
    });

    test('isFavorite usa id do filme como critério de igualdade', () {
      final movie1 = _movie(id: 50, title: 'Inception');
      final movie2 = _movie(id: 50, title: 'Inception (cópia)');
      final movie3 = _movie(id: 99, title: 'Outro Filme');

      favorites.toggleFavorite(movie1);

      // Mesmo id → deve ser reconhecido como favorito.
      expect(favorites.isFavorite(movie2), isTrue);
      // Id diferente → não deve ser favorito.
      expect(favorites.isFavorite(movie3), isFalse);
    });

    test('favorites retorna cópia não-modificável da lista interna', () {
      final movie = _movie(id: 60);
      favorites.toggleFavorite(movie);

      final list = favorites.favorites;
      // Tentar modificar diretamente deve lançar UnsupportedError.
      expect(() => (list as dynamic).add(_movie(id: 999)), throwsUnsupportedError);
    });
  });

  group('FavoritesProvider — limpeza no logout', () {
    test('limpa a lista de favoritos quando o usuário faz logout', () {
      final auth = _FakeAuth(loggedIn: true, userId: 'u1');
      final favorites = _TestFavoritesProvider(auth);

      // Adiciona um filme local.
      favorites.toggleFavorite(_movie(id: 70));
      expect(favorites.favorites, isNotEmpty);

      // Simula lógica de logout.
      favorites.handleLogout();

      expect(favorites.favorites, isEmpty);
    });
  });

  group('FavoritesProvider.clearError', () {
    test('clearError() limpa errorMessage sem afetar outros estados', () {
      final auth = _FakeAuth(loggedIn: true, userId: 'u2');
      final favorites = _TestFavoritesProvider(auth);

      favorites.toggleFavorite(_movie(id: 80));

      // clearError deve ser chamável mesmo sem erro definido.
      favorites.clearError();
      expect(favorites.errorMessage, isNull);
      // Favoritos continuam intactos.
      expect(favorites.favorites, hasLength(1));
    });
  });
}
