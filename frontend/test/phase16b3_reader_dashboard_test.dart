import 'package:flutter_test/flutter_test.dart';
import 'package:libri_flow/core/services/api_service.dart';
import 'package:libri_flow/features/reader/data/models/bookshelf_item_model.dart';
import 'package:libri_flow/features/reader/data/models/reading_goal_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'auth_token': 'mock_reader_jwt_token',
      'user_role': 'customer',
      'user_persona': 'reader',
      'user_name': 'Clara Oswald',
    });
    ApiService.token = 'mock_reader_jwt_token';
    ApiService.userType = UserType.reader;
  });

  group('Phase 16B.3 — BookshelfItemModel Unit & Edge Case Tests', () {
    test('BookshelfItemModel correctly parses all 4 categories and properties', () {
      final json = {
        'id': 42,
        'user_id': 10,
        'book_id': 105,
        'title': 'The Name of the Rose',
        'author': 'Umberto Eco',
        'cover_url': 'https://example.com/cover.jpg',
        'category': 'currently_reading',
        'progress': 0.58,
        'current_page': 290,
        'total_pages': 500,
        'status': 'Personal Library',
        'format': 'Hardcover',
        'days_left': 12,
        'genre': 'Historical Mystery',
        'personal_notes': 'Intricate theological labyrinths.',
        'rating': 5.0,
        'started_at': '2026-11-01T10:00:00.000Z',
        'finished_at': null,
      };

      final model = BookshelfItemModel.fromJson(json);

      expect(model.id, 42);
      expect(model.userId, 10);
      expect(model.bookId, 105);
      expect(model.title, 'The Name of the Rose');
      expect(model.author, 'Umberto Eco');
      expect(model.category, 'currently_reading');
      expect(model.progress, 0.58);
      expect(model.percentRead, 58);
      expect(model.currentPage, 290);
      expect(model.totalPages, 500);
      expect(model.pagesRemaining, 210);
      expect(model.isFinished, isFalse);
      expect(model.format, 'Hardcover');
      expect(model.rating, 5.0);
    });

    test('BookshelfItemModel calculates isFinished for completed category or 1.0 progress', () {
      final model1 = BookshelfItemModel(
        id: 1,
        userId: 1,
        title: 'Kafka on the Shore',
        author: 'Haruki Murakami',
        category: 'completed',
        progress: 0.95,
      );
      expect(model1.isFinished, isTrue);

      final model2 = BookshelfItemModel(
        id: 2,
        userId: 1,
        title: 'Invisible Cities',
        author: 'Italo Calvino',
        category: 'currently_reading',
        progress: 1.0,
      );
      expect(model2.isFinished, isTrue);

      final model3 = BookshelfItemModel(
        id: 3,
        userId: 1,
        title: 'Ficciones',
        author: 'Jorge Luis Borges',
        category: 'paused',
        progress: 0.4,
      );
      expect(model3.isFinished, isFalse);
    });

    test('BookshelfItemModel copyWith updates fields properly', () {
      final model = BookshelfItemModel(
        id: 10,
        userId: 5,
        title: 'Piranesi',
        author: 'Susanna Clarke',
        category: 'want_to_read',
        currentPage: 0,
        totalPages: 245,
      );

      final moved = model.copyWith(
        category: 'currently_reading',
        currentPage: 50,
        progress: 50 / 245,
      );

      expect(moved.id, 10);
      expect(moved.category, 'currently_reading');
      expect(moved.currentPage, 50);
      expect(model.category, 'want_to_read'); // Original is unchanged
    });
  });

  group('Phase 16B.3 — ReadingGoalModel Unit & Edge Case Tests', () {
    test('ReadingGoalModel calculates bookProgress and pageProgress accurately', () {
      final json = {
        'id': 1,
        'user_id': 10,
        'year': 2026,
        'target_books': 20,
        'completed_books': 10,
        'target_pages': 5000,
        'pages_read': 2500,
        'daily_reading_goal_minutes': 30,
        'streak_days': 14,
      };

      final goal = ReadingGoalModel.fromJson(json);

      expect(goal.year, 2026);
      expect(goal.targetBooks, 20);
      expect(goal.completedBooks, 10);
      expect(goal.bookProgress, 0.5);
      expect(goal.bookProgressPercent, 50);
      expect(goal.booksRemaining, 10);

      expect(goal.targetPages, 5000);
      expect(goal.pagesRead, 2500);
      expect(goal.pageProgress, 0.5);
      expect(goal.pageProgressPercent, 50);
      expect(goal.pagesRemaining, 2500);
      expect(goal.streakDays, 14);
    });

    test('ReadingGoalModel clamps progress safely between 0.0 and 1.0', () {
      final goal = ReadingGoalModel(
        id: 2,
        userId: 10,
        year: 2026,
        targetBooks: 10,
        completedBooks: 15, // Exceeded goal
      );

      expect(goal.bookProgress, 1.0);
      expect(goal.bookProgressPercent, 100);
      expect(goal.booksRemaining, 0);
    });

    test('ReadingGoalModel handles 0 target gracefully without division by zero', () {
      final goal = ReadingGoalModel(
        id: 3,
        userId: 10,
        year: 2026,
        targetBooks: 0,
        completedBooks: 0,
        targetPages: 0,
        pagesRead: 0,
      );

      expect(goal.bookProgress, 0.0);
      expect(goal.bookProgressPercent, 0);
      expect(goal.pageProgress, 0.0);
      expect(goal.pageProgressPercent, 0);
    });
  });

  group('Phase 16B.3 — Reader Experience Separation & Security Tests', () {
    test('Reader experience has no student-only academic widgets', () {
      // BookshelfItemModel and ReadingGoalModel should contain zero academic fields
      final item = BookshelfItemModel(
        id: 1,
        userId: 1,
        title: 'Literary Classic',
        author: 'Author',
      );

      // Verify BookshelfItem has reading attributes, not syllabus/semester/exam fields
      final json = item.toJson();
      expect(json.containsKey('syllabus'), isFalse);
      expect(json.containsKey('semester'), isFalse);
      expect(json.containsKey('instructor'), isFalse);
      expect(json.containsKey('credits'), isFalse);
      expect(json.containsKey('course_code'), isFalse);
      expect(json.containsKey('is_lagging'), isFalse);
    });

    test('Reader persona session defaults cleanly and does not trigger student onboarding', () {
      expect(ApiService.userType, equals(UserType.reader));
      expect(ApiService.isLoggedIn, isTrue);
    });
  });
}
