import 'dart:async';

/// A reactive data source for managing favorites.
/// This acts as the single source of truth for the favorites state in the mock implementation.
class FavoritesDataSource {
  final Set<String> _favoriteIds = {'1', '6', '7'};
  final _controller = StreamController<Set<String>>.broadcast();

  FavoritesDataSource() {
    // Initial emission
    _controller.add(Set.unmodifiable(_favoriteIds));
  }

  Stream<Set<String>> get favoritesStream => _controller.stream;

  Set<String> get currentFavorites => Set.unmodifiable(_favoriteIds);

  bool isFavorite(String id) => _favoriteIds.contains(id);

  bool toggleFavorite(String id) {
    if (_favoriteIds.contains(id)) {
      _favoriteIds.remove(id);
    } else {
      _favoriteIds.add(id);
    }
    _controller.add(Set.unmodifiable(_favoriteIds));
    return _favoriteIds.contains(id);
  }

  void setFavorites(Set<String> favoriteIds) {
    _favoriteIds
      ..clear()
      ..addAll(favoriteIds);
    _controller.add(Set.unmodifiable(_favoriteIds));
  }

  void removeFavorite(String id) {
    if (_favoriteIds.remove(id)) {
      _controller.add(Set.unmodifiable(_favoriteIds));
    }
  }

  void dispose() {
    _controller.close();
  }
}
