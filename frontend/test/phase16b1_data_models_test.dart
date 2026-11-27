import 'package:flutter_test/flutter_test.dart';
import 'package:libri_flow/features/student/data/models/student_subject_model.dart';
import 'package:libri_flow/features/student/data/models/student_schedule_model.dart';
import 'package:libri_flow/features/reader/data/models/bookshelf_item_model.dart';
import 'package:libri_flow/features/reader/data/models/reading_goal_model.dart';

void main() {
  group('Phase 16B.1 - StudentSubjectModel Tests', () {
    test('StudentSubjectModel.fromJson correctly parses full backend payload', () {
      final json = {
        'id': 10,
        'user_id': 42,
        'name': 'Distributed Systems',
        'code': 'CS450',
        'progress': 0.75,
        'target': 0.95,
        'is_lagging': false,
        'color': '#006644',
        'instructor': 'Dr. Lamport',
        'credits': 4,
        'hours_per_week': 6,
        'syllabus': 'Consensus, Paxos, Raft, Vector Clocks',
        'textbook_ids': [12, 15, 20],
        'created_at': '2026-11-01T10:00:00.000Z',
        'updated_at': '2026-11-06T15:30:00.000Z',
      };

      final model = StudentSubjectModel.fromJson(json);

      expect(model.id, 10);
      expect(model.userId, 42);
      expect(model.name, 'Distributed Systems');
      expect(model.code, 'CS450');
      expect(model.progress, 0.75);
      expect(model.target, 0.95);
      expect(model.isLagging, isFalse);
      expect(model.color, '#006644');
      expect(model.instructor, 'Dr. Lamport');
      expect(model.credits, 4);
      expect(model.hoursPerWeek, 6);
      expect(model.syllabus, 'Consensus, Paxos, Raft, Vector Clocks');
      expect(model.textbookIds, [12, 15, 20]);
      expect(model.createdAt, isNotNull);
      expect(model.updatedAt, isNotNull);
    });

    test('StudentSubjectModel handles missing / null optional fields gracefully', () {
      final json = {
        'id': '5',
        'user_id': '101',
        'name': 'Philosophy of Science',
      };

      final model = StudentSubjectModel.fromJson(json);

      expect(model.id, 5);
      expect(model.userId, 101);
      expect(model.name, 'Philosophy of Science');
      expect(model.code, isNull);
      expect(model.progress, 0.0);
      expect(model.target, 1.0);
      expect(model.isLagging, isFalse);
      expect(model.color, '#006644');
      expect(model.instructor, isNull);
      expect(model.credits, 3);
      expect(model.hoursPerWeek, 4);
      expect(model.textbookIds, isEmpty);
    });

    test('StudentSubjectModel.toJson correctly serializes model', () {
      final model = StudentSubjectModel(
        id: 7,
        userId: 2,
        name: 'Linear Algebra',
        code: 'MATH201',
        progress: 0.5,
        target: 0.8,
        isLagging: true,
        credits: 3,
        textbookIds: [5],
      );

      final json = model.toJson();

      expect(json['id'], 7);
      expect(json['user_id'], 2);
      expect(json['name'], 'Linear Algebra');
      expect(json['code'], 'MATH201');
      expect(json['progress'], 0.5);
      expect(json['target'], 0.8);
      expect(json['is_lagging'], isTrue);
      expect(json['textbook_ids'], [5]);
    });

    test('StudentSubjectModel.copyWith creates updated clone', () {
      final model = StudentSubjectModel(
        id: 1,
        userId: 1,
        name: 'Biology',
        progress: 0.2,
      );

      final updated = model.copyWith(progress: 0.8, isLagging: false);

      expect(updated.id, 1);
      expect(updated.name, 'Biology');
      expect(updated.progress, 0.8);
      expect(updated.isLagging, isFalse);
    });
  });

  group('Phase 16B.1 - StudentScheduleModel Tests', () {
    test('StudentScheduleModel.fromJson correctly parses schedule payload', () {
      final json = {
        'id': 101,
        'user_id': 42,
        'subject_id': 10,
        'subject_name': 'Distributed Systems',
        'topic': 'Raft Consensus Review',
        'time_slot': '09:00 AM - 10:30 AM',
        'date': '2026-11-10',
        'duration_minutes': 90,
        'status': 'Completed',
        'color': '#006644',
        'is_boosted': true,
        'notes': 'Prepare slides on leader election',
      };

      final model = StudentScheduleModel.fromJson(json);

      expect(model.id, 101);
      expect(model.userId, 42);
      expect(model.subjectId, 10);
      expect(model.subjectName, 'Distributed Systems');
      expect(model.topic, 'Raft Consensus Review');
      expect(model.timeSlot, '09:00 AM - 10:30 AM');
      expect(model.date, '2026-11-10');
      expect(model.durationMinutes, 90);
      expect(model.status, 'Completed');
      expect(model.isCompleted, isTrue);
      expect(model.isBoosted, isTrue);
      expect(model.notes, 'Prepare slides on leader election');
    });

    test('StudentScheduleModel.isCompleted getter works accurately', () {
      final pending = StudentScheduleModel(
        id: 1,
        userId: 1,
        subjectName: 'Math',
        topic: 'Calculus',
        timeSlot: '10 AM',
        status: 'Pending',
      );
      final completed = pending.copyWith(status: 'completed');

      expect(pending.isCompleted, isFalse);
      expect(completed.isCompleted, isTrue);
    });
  });

  group('Phase 16B.1 - BookshelfItemModel Tests', () {
    test('BookshelfItemModel.fromJson correctly parses bookshelf payload', () {
      final json = {
        'id': 201,
        'user_id': 88,
        'book_id': 35,
        'title': 'The Great Gatsby',
        'author': 'F. Scott Fitzgerald',
        'cover_url': 'https://example.com/gatsby.jpg',
        'category': 'currently_reading',
        'progress': 0.60,
        'current_page': 120,
        'total_pages': 200,
        'status': 'Active Rental',
        'format': 'Hardcover',
        'days_left': 8,
        'genre': 'Classic Literature',
        'rating': 4.5,
      };

      final model = BookshelfItemModel.fromJson(json);

      expect(model.id, 201);
      expect(model.userId, 88);
      expect(model.bookId, 35);
      expect(model.title, 'The Great Gatsby');
      expect(model.author, 'F. Scott Fitzgerald');
      expect(model.coverUrl, 'https://example.com/gatsby.jpg');
      expect(model.category, 'currently_reading');
      expect(model.progress, 0.60);
      expect(model.currentPage, 120);
      expect(model.totalPages, 200);
      expect(model.status, 'Active Rental');
      expect(model.format, 'Hardcover');
      expect(model.daysLeft, 8);
      expect(model.genre, 'Classic Literature');
      expect(model.rating, 4.5);
      expect(model.percentRead, 60);
      expect(model.pagesRemaining, 80);
      expect(model.isFinished, isFalse);
    });

    test('BookshelfItemModel calculates isFinished for completed category or 1.0 progress', () {
      final item1 = BookshelfItemModel(
        id: 1,
        userId: 1,
        title: 'Book A',
        author: 'Author A',
        category: 'completed',
        progress: 0.9,
      );
      final item2 = BookshelfItemModel(
        id: 2,
        userId: 1,
        title: 'Book B',
        author: 'Author B',
        category: 'currently_reading',
        progress: 1.0,
      );
      final item3 = BookshelfItemModel(
        id: 3,
        userId: 1,
        title: 'Book C',
        author: 'Author C',
        category: 'currently_reading',
        progress: 0.5,
      );

      expect(item1.isFinished, isTrue);
      expect(item2.isFinished, isTrue);
      expect(item3.isFinished, isFalse);
    });

    test('BookshelfItemModel pagesRemaining clamps safely between 0 and totalPages', () {
      final item = BookshelfItemModel(
        id: 1,
        userId: 1,
        title: 'Book',
        author: 'Author',
        currentPage: 350,
        totalPages: 300,
      );

      expect(item.pagesRemaining, 0);
    });
  });

  group('Phase 16B.1 - ReadingGoalModel Tests', () {
    test('ReadingGoalModel.fromJson correctly parses reading goal payload', () {
      final json = {
        'id': 301,
        'user_id': 88,
        'year': 2026,
        'target_books': 20,
        'completed_books': 8,
        'target_pages': 6000,
        'pages_read': 2400,
        'daily_reading_goal_minutes': 45,
        'streak_days': 14,
        'last_read_date': '2026-11-06',
      };

      final model = ReadingGoalModel.fromJson(json);

      expect(model.id, 301);
      expect(model.userId, 88);
      expect(model.year, 2026);
      expect(model.targetBooks, 20);
      expect(model.completedBooks, 8);
      expect(model.targetPages, 6000);
      expect(model.pagesRead, 2400);
      expect(model.dailyReadingGoalMinutes, 45);
      expect(model.streakDays, 14);
      expect(model.lastReadDate, '2026-11-06');

      expect(model.bookProgress, closeTo(0.40, 0.001));
      expect(model.bookProgressPercent, 40);
      expect(model.booksRemaining, 12);

      expect(model.pageProgress, closeTo(0.40, 0.001));
      expect(model.pageProgressPercent, 40);
      expect(model.pagesRemaining, 3600);
    });

    test('ReadingGoalModel handles edge cases with 0 targets safely', () {
      final model = ReadingGoalModel(
        id: 1,
        userId: 1,
        year: 2026,
        targetBooks: 0,
        completedBooks: 0,
        targetPages: 0,
        pagesRead: 0,
      );

      expect(model.bookProgress, 0.0);
      expect(model.bookProgressPercent, 0);
      expect(model.booksRemaining, 0);
      expect(model.pageProgress, 0.0);
      expect(model.pageProgressPercent, 0);
      expect(model.pagesRemaining, 0);
    });
  });

  group('Phase 16B.1 - Mock Dashboard Parsing Tests', () {
    test('Parses simulated backend student dashboard payload into model lists', () {
      final mockResponse = {
        'education_level': 'Undergraduate',
        'course': 'Computer Science',
        'total_subjects': 2,
        'overall_progress': 0.65,
        'subjects': [
          {'id': 1, 'user_id': 10, 'name': 'Algorithms', 'progress': 0.7},
          {'id': 2, 'user_id': 10, 'name': 'Databases', 'progress': 0.6},
        ],
        'schedule': [
          {'id': 10, 'user_id': 10, 'subject_name': 'Algorithms', 'topic': 'Graphs', 'time_slot': '10 AM'}
        ],
      };

      final subjectsList = (mockResponse['subjects'] as List)
          .map((item) => StudentSubjectModel.fromJson(item as Map<String, dynamic>))
          .toList();

      final scheduleList = (mockResponse['schedule'] as List)
          .map((item) => StudentScheduleModel.fromJson(item as Map<String, dynamic>))
          .toList();

      expect(subjectsList.length, 2);
      expect(subjectsList[0].name, 'Algorithms');
      expect(subjectsList[1].name, 'Databases');
      expect(scheduleList.length, 1);
      expect(scheduleList[0].topic, 'Graphs');
    });

    test('Parses simulated backend reader dashboard payload into bookshelf and goal models', () {
      final mockResponse = {
        'total_books_read': 5,
        'current_streak_days': 12,
        'goal': {
          'id': 1,
          'user_id': 20,
          'year': 2026,
          'target_books': 15,
          'completed_books': 5,
        },
        'currently_reading': [
          {'id': 1, 'user_id': 20, 'title': 'Dune', 'author': 'Frank Herbert', 'category': 'currently_reading', 'progress': 0.3}
        ],
        'want_to_read': [
          {'id': 2, 'user_id': 20, 'title': 'Neuromancer', 'author': 'William Gibson', 'category': 'want_to_read'}
        ],
      };

      final goal = ReadingGoalModel.fromJson(mockResponse['goal'] as Map<String, dynamic>);
      final currentlyReading = (mockResponse['currently_reading'] as List)
          .map((item) => BookshelfItemModel.fromJson(item as Map<String, dynamic>))
          .toList();
      final wantToRead = (mockResponse['want_to_read'] as List)
          .map((item) => BookshelfItemModel.fromJson(item as Map<String, dynamic>))
          .toList();

      expect(goal.targetBooks, 15);
      expect(goal.completedBooks, 5);
      expect(currentlyReading.length, 1);
      expect(currentlyReading[0].title, 'Dune');
      expect(wantToRead.length, 1);
      expect(wantToRead[0].title, 'Neuromancer');
    });
  });
}
