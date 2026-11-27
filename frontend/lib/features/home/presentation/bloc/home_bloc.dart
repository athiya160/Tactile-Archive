import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/book.dart';
import '../../domain/usecases/get_catalog_books.dart';
import '../../domain/usecases/get_categories.dart';
import '../../domain/usecases/get_featured_books.dart';
import '../../domain/usecases/watch_favorite_ids.dart';
import '../../../book_details/domain/usecases/toggle_favorite.dart';
import '../../../../core/data/mock_catalog_datasource.dart';

// --- Events ---
abstract class HomeEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class HomeStarted extends HomeEvent {
  final String? initialCategory;
  final String? initialSearchQuery;
  HomeStarted({this.initialCategory, this.initialSearchQuery});

  @override
  List<Object?> get props => [initialCategory, initialSearchQuery];
}

class HomeCategorySelected extends HomeEvent {
  final String category;
  HomeCategorySelected(this.category);
  @override
  List<Object?> get props => [category];
}

class HomeSortChanged extends HomeEvent {
  final String sortBy;
  HomeSortChanged(this.sortBy);
  @override
  List<Object?> get props => [sortBy];
}

class HomeSearchChanged extends HomeEvent {
  final String query;
  HomeSearchChanged(this.query);
  @override
  List<Object?> get props => [query];
}

class HomeLoadMore extends HomeEvent {}

class HomePageRequested extends HomeEvent {
  final int page;
  HomePageRequested(this.page);
  @override
  List<Object?> get props => [page];
}

class HomeFavoriteToggled extends HomeEvent {
  final String bookId;
  HomeFavoriteToggled(this.bookId);
  @override
  List<Object?> get props => [bookId];
}

class HomeFavoritesUpdated extends HomeEvent {
  final Set<String> favoriteIds;
  HomeFavoritesUpdated(this.favoriteIds);
  @override
  List<Object?> get props => [favoriteIds];
}

// --- States ---
abstract class HomeState extends Equatable {
  @override
  List<Object?> get props => [];
}

class HomeInitial extends HomeState {}

class HomeLoading extends HomeState {}

class HomeError extends HomeState {
  final String message;
  HomeError(this.message);
  @override
  List<Object?> get props => [message];
}

class HomeLoaded extends HomeState {
  final List<Book> featuredBooks;
  final List<String> categories;
  final List<Book> catalogBooks;
  final String selectedCategory;
  final String? sortBy;
  final String? searchQuery;
  final bool hasReachedMax;
  final int currentPage;

  HomeLoaded({
    required this.featuredBooks,
    required this.categories,
    required this.catalogBooks,
    required this.selectedCategory,
    this.sortBy,
    this.searchQuery,
    this.hasReachedMax = false,
    this.currentPage = 1,
  });

  HomeLoaded copyWith({
    List<Book>? featuredBooks,
    List<String>? categories,
    List<Book>? catalogBooks,
    String? selectedCategory,
    String? sortBy,
    String? searchQuery,
    bool? hasReachedMax,
    int? currentPage,
  }) {
    return HomeLoaded(
      featuredBooks: featuredBooks ?? this.featuredBooks,
      categories: categories ?? this.categories,
      catalogBooks: catalogBooks ?? this.catalogBooks,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      sortBy: sortBy ?? this.sortBy,
      searchQuery: searchQuery ?? this.searchQuery,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      currentPage: currentPage ?? this.currentPage,
    );
  }

  @override
  List<Object?> get props => [
        featuredBooks,
        categories,
        catalogBooks,
        selectedCategory,
        sortBy,
        searchQuery,
        hasReachedMax,
        currentPage,
      ];
}

// --- Bloc ---
class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final GetFeaturedBooks getFeaturedBooks;
  final GetCategories getCategories;
  final GetCatalogBooks getCatalogBooks;
  final ToggleFavorite toggleFavorite;
  final WatchFavoriteIds watchFavoriteIds;
  StreamSubscription? _favoritesSubscription;

  static final List<Book> _defaultMockBooks = MockCatalogDataSource.books;

  static final List<String> _defaultMockCategories = MockCatalogDataSource.categories;

  HomeBloc({
    required this.getFeaturedBooks,
    required this.getCategories,
    required this.getCatalogBooks,
    required this.toggleFavorite,
    required this.watchFavoriteIds,
  }) : super(HomeInitial()) {
    on<HomeStarted>(_onStarted);
    on<HomeCategorySelected>(_onCategorySelected);
    on<HomeSearchChanged>(_onSearchChanged);
    on<HomeSortChanged>(_onSortChanged);
    on<HomeLoadMore>(_onLoadMore);
    on<HomePageRequested>(_onPageRequested);
    on<HomeFavoriteToggled>(_onFavoriteToggled);
    on<HomeFavoritesUpdated>(_onFavoritesUpdated);

    _favoritesSubscription = watchFavoriteIds(NoParams()).listen((ids) {
      if (!isClosed) {
        add(HomeFavoritesUpdated(ids));
      }
    });
  }

  @override
  Future<void> close() {
    _favoritesSubscription?.cancel();
    return super.close();
  }

  Future<void> _onFavoritesUpdated(
    HomeFavoritesUpdated event,
    Emitter<HomeState> emit,
  ) async {
    final currentState = state;
    if (currentState is HomeLoaded) {
      final updatedFeatured = currentState.featuredBooks.map((b) {
        return b.copyWith(isFavorite: event.favoriteIds.contains(b.id));
      }).toList();

      final updatedCatalog = currentState.catalogBooks.map((b) {
        return b.copyWith(isFavorite: event.favoriteIds.contains(b.id));
      }).toList();

      emit(
        currentState.copyWith(
          featuredBooks: updatedFeatured,
          catalogBooks: updatedCatalog,
        ),
      );
    }
  }

  Future<void> _onStarted(HomeStarted event, Emitter<HomeState> emit) async {
    emit(HomeLoading());
    final initialCategory = event.initialCategory ?? 'All Books';
    final hasSearch = event.initialSearchQuery != null && event.initialSearchQuery!.trim().isNotEmpty;

    final featuredResult = await getFeaturedBooks(NoParams());
    final categoriesResult = await getCategories(NoParams());
    final catalogResult = await getCatalogBooks(
      GetCatalogBooksParams(
        category: initialCategory == 'All Books' ? null : initialCategory,
        searchQuery: hasSearch ? event.initialSearchQuery : null,
      ),
    );

    final featured = (featuredResult.isSuccess && featuredResult.data != null && featuredResult.data!.isNotEmpty)
        ? featuredResult.data!
        : _defaultMockBooks;

    final categories = (categoriesResult.isSuccess && categoriesResult.data != null && categoriesResult.data!.isNotEmpty)
        ? categoriesResult.data!
        : _defaultMockCategories;

    final catalog = (catalogResult.isSuccess && catalogResult.data != null)
        ? catalogResult.data!
        : (hasSearch ? <Book>[] : _defaultMockBooks);

    emit(
      HomeLoaded(
        featuredBooks: featured,
        categories: categories,
        catalogBooks: catalog,
        selectedCategory: initialCategory,
        searchQuery: hasSearch ? event.initialSearchQuery : null,
      ),
    );
  }

  Future<void> _onFavoriteToggled(
    HomeFavoriteToggled event,
    Emitter<HomeState> emit,
  ) async {
    final currentState = state;
    if (currentState is HomeLoaded) {
      final updatedFeatured = currentState.featuredBooks.map((b) {
        if (b.id == event.bookId) {
          return b.copyWith(isFavorite: !b.isFavorite);
        }
        return b;
      }).toList();

      final updatedCatalog = currentState.catalogBooks.map((b) {
        if (b.id == event.bookId) {
          return b.copyWith(isFavorite: !b.isFavorite);
        }
        return b;
      }).toList();

      emit(
        currentState.copyWith(
          featuredBooks: updatedFeatured,
          catalogBooks: updatedCatalog,
        ),
      );

      await toggleFavorite(event.bookId);
    }
  }

  Future<void> _onCategorySelected(
    HomeCategorySelected event,
    Emitter<HomeState> emit,
  ) async {
    final currentState = state;
    if (currentState is HomeLoaded) {
      emit(HomeLoading());
      final result = await getCatalogBooks(
        GetCatalogBooksParams(
          category: event.category,
          sortBy: currentState.sortBy,
          searchQuery: currentState.searchQuery,
        ),
      );

      final books = (result.isSuccess && result.data != null) ? result.data! : _defaultMockBooks;

      emit(
        currentState.copyWith(
          catalogBooks: books,
          selectedCategory: event.category,
          currentPage: 1,
          hasReachedMax: books.length < 10,
        ),
      );
    }
  }

  Future<void> _onSearchChanged(
    HomeSearchChanged event,
    Emitter<HomeState> emit,
  ) async {
    final currentState = state;
    if (currentState is HomeLoaded) {
      final result = await getCatalogBooks(
        GetCatalogBooksParams(
          category: currentState.selectedCategory,
          sortBy: currentState.sortBy,
          searchQuery: event.query,
        ),
      );

      final isSearchActive = event.query.trim().isNotEmpty;
      final books = (result.isSuccess && result.data != null)
          ? result.data!
          : (isSearchActive ? <Book>[] : _defaultMockBooks);

      emit(
        currentState.copyWith(
          catalogBooks: books,
          searchQuery: event.query,
          currentPage: 1,
          hasReachedMax: books.length < 10,
        ),
      );
    }
  }

  Future<void> _onSortChanged(
    HomeSortChanged event,
    Emitter<HomeState> emit,
  ) async {
    final currentState = state;
    if (currentState is HomeLoaded) {
      final result = await getCatalogBooks(
        GetCatalogBooksParams(
          category: currentState.selectedCategory,
          sortBy: event.sortBy,
          searchQuery: currentState.searchQuery,
        ),
      );

      final books = (result.isSuccess && result.data != null) ? result.data! : _defaultMockBooks;

      emit(
        currentState.copyWith(
          catalogBooks: books,
          sortBy: event.sortBy,
          currentPage: 1,
          hasReachedMax: false,
        ),
      );
    }
  }

  Future<void> _onLoadMore(HomeLoadMore event, Emitter<HomeState> emit) async {
    final currentState = state;
    if (currentState is HomeLoaded && !currentState.hasReachedMax) {
      final nextPage = currentState.currentPage + 1;
      final result = await getCatalogBooks(
        GetCatalogBooksParams(
          category: currentState.selectedCategory,
          sortBy: currentState.sortBy,
          searchQuery: currentState.searchQuery,
          page: nextPage,
        ),
      );

      if (result.isSuccess && result.data != null) {
        final newBooks = result.data!;
        if (newBooks.isEmpty) {
          emit(currentState.copyWith(hasReachedMax: true));
        } else {
          emit(
            currentState.copyWith(
              catalogBooks: List.of(currentState.catalogBooks)..addAll(newBooks),
              currentPage: nextPage,
            ),
          );
        }
      }
    }
  }

  Future<void> _onPageRequested(
    HomePageRequested event,
    Emitter<HomeState> emit,
  ) async {
    final currentState = state;
    if (currentState is HomeLoaded) {
      emit(HomeLoading());

      final result = await getCatalogBooks(
        GetCatalogBooksParams(
          category: currentState.selectedCategory,
          sortBy: currentState.sortBy,
          searchQuery: currentState.searchQuery,
          page: event.page,
        ),
      );

      if (result.isSuccess && result.data != null) {
        emit(
          currentState.copyWith(
            catalogBooks: result.data!,
            currentPage: event.page,
            hasReachedMax: result.data!.length < 10,
          ),
        );
      } else {
        emit(currentState);
      }
    }
  }
}
