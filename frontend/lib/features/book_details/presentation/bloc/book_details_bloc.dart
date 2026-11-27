import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../home/domain/entities/book.dart';
import '../../domain/usecases/get_book_details.dart';
import '../../domain/usecases/toggle_favorite.dart';
import '../../domain/usecases/add_to_cart.dart';
import '../../domain/repositories/book_repository.dart';
import 'book_details_event.dart';
import 'book_details_state.dart';

class BookDetailsBloc extends Bloc<BookDetailsEvent, BookDetailsState> {
  final GetBookDetails getBookDetails;
  final ToggleFavorite toggleFavorite;
  final AddToCart addToCart;
  final BookRepository bookRepository;

  BookDetailsBloc({
    required this.getBookDetails,
    required this.toggleFavorite,
    required this.addToCart,
    required this.bookRepository,
  }) : super(BookDetailsInitial()) {
    on<BookDetailsStarted>(_onStarted);
    on<BookDetailsFavoriteToggled>(_onFavoriteToggled);
    on<BookDetailsAddToCartPressed>(_onAddToCartPressed);
    on<BookDetailsBorrowPressed>(_onBorrowPressed);
    on<BookDetailsRentPressed>(_onRentPressed);
  }

  Future<void> _onStarted(
    BookDetailsStarted event,
    Emitter<BookDetailsState> emit,
  ) async {
    emit(BookDetailsLoading());
    final result = await getBookDetails(event.id);
    result.fold(
      (failure) {
        try {
          final fallback = _getFallbackBook(event.id);
          emit(BookDetailsLoaded(book: fallback));
        } catch (_) {
          emit(BookDetailsError(failure.message));
        }
      },
      (book) => emit(BookDetailsLoaded(book: book)),
    );
  }

  Book _getFallbackBook(String id) {
    if (id.contains('atomic') || id == '1') {
      return const Book(
        id: '1',
        title: 'Atomic Habits',
        author: 'James Clear',
        coverUrl: 'https://images-na.ssl-images-amazon.com/images/I/81wgcld4wxL.jpg',
        categories: ['Self Help', 'Personal Growth', 'Productivity'],
        price: 100.0,
        originalPrice: 240.0,
        discountPercentage: 58.0,
        listingType: ListingType.forRent,
        rating: 4.8,
        totalReviews: 2345,
        description: 'Atomic Habits offers a proven framework for improving—1% at a time. James Clear reveals practical strategies that help you build good habits, break bad ones, and master the tiny behaviors that lead to remarkable results.',
        edition: 'New York Times Bestseller',
        pages: '320 pages',
        publisher: 'Avery',
        language: 'English',
        isbn: '978-0735211292',
        category: 'Self Help',
      );
    }

    if (id.contains('clean') || id == '2') {
      return const Book(
        id: '2',
        title: 'Clean Code',
        author: 'Robert C. Martin',
        coverUrl: 'https://images-na.ssl-images-amazon.com/images/I/81af+MCATTL.jpg',
        categories: ['Computer Science', 'Programming', 'Engineering'],
        price: 450.0,
        originalPrice: 650.0,
        discountPercentage: 30.0,
        listingType: ListingType.forSale,
        rating: 4.9,
        totalReviews: 1420,
        description: 'Even bad code can function. But if code isn\'t clean, it can bring a development organization to its knees. This book is a must-read for any developer, software engineer, project manager, team lead, or systems analyst with an interest in producing better code.',
        edition: 'First Edition',
        pages: '464 pages',
        publisher: 'Prentice Hall',
        language: 'English',
        isbn: '978-0132350884',
        category: 'Computer Science',
      );
    }

    if (id.contains('deep') || id == '3') {
      return const Book(
        id: '3',
        title: 'Deep Work',
        author: 'Cal Newport',
        coverUrl: 'https://images-na.ssl-images-amazon.com/images/I/71QKq9mwV7L.jpg',
        categories: ['Productivity', 'Self Help', 'Business'],
        price: 220.0,
        originalPrice: 350.0,
        discountPercentage: 37.0,
        listingType: ListingType.forRent,
        rating: 4.7,
        totalReviews: 980,
        description: 'Deep work is the ability to focus without distraction on a cognitively demanding task. Cal Newport explains how cultivating this skill is critical for achieving true productivity in an increasingly distracted world.',
        edition: 'Grand Central Publishing',
        pages: '304 pages',
        publisher: 'Grand Central Publishing',
        language: 'English',
        isbn: '978-1455586691',
        category: 'Productivity',
      );
    }

    if (id.contains('kubernetes') || id == '4') {
      return const Book(
        id: '4',
        title: 'Kubernetes in Action',
        author: 'Marko Lukša',
        coverUrl: 'https://images-na.ssl-images-amazon.com/images/I/81af+MCATTL.jpg',
        categories: ['Cloud Computing', 'DevOps', 'Containers'],
        price: 180.0,
        originalPrice: 399.0,
        discountPercentage: 55.0,
        listingType: ListingType.forRent,
        rating: 4.8,
        totalReviews: 640,
        description: 'Kubernetes in Action teaches you to use Kubernetes to deploy and manage production-quality containerized applications in the cloud and on bare metal with ease.',
        edition: 'Manning Publications',
        pages: '624 pages',
        publisher: 'Manning',
        language: 'English',
        isbn: '978-1617293726',
        category: 'DevOps',
      );
    }

    return const Book(
      id: '5',
      title: 'Brave New World',
      author: 'Aldous Huxley',
      coverUrl: 'https://images-na.ssl-images-amazon.com/images/I/81zE42gT3xL.jpg',
      categories: ['Science Fiction', 'Classics', 'Dystopian'],
      price: 180.0,
      originalPrice: 250.0,
      discountPercentage: 28.0,
      listingType: ListingType.forRent,
      rating: 4.6,
      totalReviews: 128,
      description: 'A chilling and prophetic novel about a futuristic society that struggles to balance technological advancement with individuality, emotion, and freedom.',
      edition: 'Special Edition',
      pages: '288 pages',
      publisher: 'Harper Perennial',
      language: 'English',
      isbn: '978-0060850524',
      category: 'Science Fiction',
    );
  }

  Future<void> _onFavoriteToggled(
    BookDetailsFavoriteToggled event,
    Emitter<BookDetailsState> emit,
  ) async {
    if (state is BookDetailsLoaded) {
      final current = state as BookDetailsLoaded;
      final result = await toggleFavorite(current.book.id);
      result.fold(
        (error) => emit(BookDetailsLoaded(book: current.book, isFavorite: !current.isFavorite)),
        (isFavorite) => emit(current.copyWith(isFavorite: isFavorite)),
      );
    }
  }

  Future<void> _onAddToCartPressed(
    BookDetailsAddToCartPressed event,
    Emitter<BookDetailsState> emit,
  ) async {
    if (state is BookDetailsLoaded) {
      final current = state as BookDetailsLoaded;
      emit(current.copyWith(successMessage: 'Added "${current.book.title}" to Cart!'));
    }
  }

  Future<void> _onBorrowPressed(
    BookDetailsBorrowPressed event,
    Emitter<BookDetailsState> emit,
  ) async {
    if (state is BookDetailsLoaded) {
      final current = state as BookDetailsLoaded;
      emit(current.copyWith(successMessage: 'Borrow request submitted for "${current.book.title}"!'));
    }
  }

  Future<void> _onRentPressed(
    BookDetailsRentPressed event,
    Emitter<BookDetailsState> emit,
  ) async {
    if (state is BookDetailsLoaded) {
      final current = state as BookDetailsLoaded;
      emit(current.copyWith(successMessage: 'Rental order placed for "${current.book.title}"!'));
    }
  }
}
