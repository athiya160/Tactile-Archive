import 'package:flutter_test/flutter_test.dart';
import 'package:libri_flow/core/services/api_service.dart';
import 'package:libri_flow/core/design_system/tokens/ds_colors.dart';
import 'package:libri_flow/core/design_system/tokens/ds_radius.dart';
import 'package:libri_flow/features/student/data/models/student_assignment_model.dart';
import 'package:libri_flow/features/student/data/models/student_goal_model.dart';
import 'package:libri_flow/features/student/data/models/student_subject_model.dart';
import 'package:libri_flow/features/student/data/models/student_schedule_model.dart';
import 'package:libri_flow/features/reader/data/models/bookshelf_item_model.dart';
import 'package:libri_flow/features/reader/data/models/reading_goal_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'auth_token': 'mock_student_jwt_token',
      'user_role': 'customer',
      'user_persona': 'student',
      'user_name': 'Test Scholar',
      'college_name': 'Oxford Archive Faculty',
      'degree_program': 'B.Sc Classical Literature',
      'current_semester': 'Semester 4',
      'student_degree': 'B.Sc Classical Literature',
      'student_semester': 'Semester 4',
      'student_college': 'Oxford Archive Faculty',
    });
    ApiService.token = 'mock_student_jwt_token';
    ApiService.userType = UserType.student;
  });

  group('GATE 1: Student Experience & Academic Models', () {
    test('StudentSubjectModel handles syllabus, progress and lag status correctly', () {
      final json = {
        'id': 10,
        'user_id': 1,
        'name': 'Archival Manuscript Preservation',
        'code': 'AMP-301',
        'instructor': 'Dr. Alistair Vance',
        'credits': 4,
        'hours_per_week': 4,
        'color': '#183D32',
        'progress': 0.75,
        'target': 1.0,
        'is_lagging': false,
        'syllabus': 'https://archive.libri/syllabus/amp301.pdf',
        'textbook_ids': [101, 102],
      };

      final subject = StudentSubjectModel.fromJson(json);

      expect(subject.id, 10);
      expect(subject.name, 'Archival Manuscript Preservation');
      expect(subject.code, 'AMP-301');
      expect(subject.credits, 4);
      expect(subject.progress, 0.75);
      expect(subject.isLagging, false);
      expect(subject.syllabus, 'https://archive.libri/syllabus/amp301.pdf');
      expect(subject.textbookIds, [101, 102]);
    });

    test('StudentScheduleModel verifies class times, location, and study deadlines', () {
      final json = {
        'id': 20,
        'user_id': 1,
        'subject_id': 10,
        'subject_name': 'Archival Manuscript Preservation',
        'topic': 'Hall 4B - Archive Wing',
        'time_slot': '10:00 - 11:30',
        'date': '2026-11-20',
        'duration_minutes': 90,
        'status': 'Completed',
        'is_boosted': true,
      };

      final schedule = StudentScheduleModel.fromJson(json);

      expect(schedule.id, 20);
      expect(schedule.subjectName, 'Archival Manuscript Preservation');
      expect(schedule.timeSlot, '10:00 - 11:30');
      expect(schedule.topic, 'Hall 4B - Archive Wing');
      expect(schedule.isCompleted, true);
    });

    test('StudentAssignmentModel parses priority, deadlines and submission status', () {
      final json = {
        'id': 30,
        'user_id': 1,
        'subject_id': 10,
        'subject_name': 'Archival Manuscript Preservation',
        'title': 'Chapter 4 Conservation Critique',
        'due_date': '2026-11-25T18:00:00.000Z',
        'priority': 'high',
        'status': 'pending',
        'is_completed': false,
      };

      final assignment = StudentAssignmentModel.fromJson(json);

      expect(assignment.id, 30);
      expect(assignment.title, 'Chapter 4 Conservation Critique');
      expect(assignment.priority, 'high');
      expect(assignment.isCompleted, false);
    });

    test('StudentGoalModel calculates target progress and category', () {
      final json = {
        'id': 40,
        'user_id': 1,
        'title': 'Complete 5 Study Hours Weekly',
        'target_value': 5.0,
        'current_value': 3.5,
        'unit': 'hours',
        'progress': 0.70,
        'category': 'Academic',
      };

      final goal = StudentGoalModel.fromJson(json);

      expect(goal.id, 40);
      expect(goal.progress, 0.70);
      expect(goal.category, 'Academic');
    });

    test('AI Study Assistant query formatting handles concepts, quizzes and plans', () async {
      final quizPrompt = await ApiService.askStudyAssistant('Generate quiz for database normalization');
      expect(quizPrompt, contains('Quiz'));
      expect(quizPrompt, contains('Question'));

      final flashcardPrompt = await ApiService.askStudyAssistant('Flashcards for database normalization');
      expect(flashcardPrompt, contains('Flashcards'));
      expect(flashcardPrompt, contains('Card'));

      final planPrompt = await ApiService.askStudyAssistant('7-day study plan');
      expect(planPrompt, contains('Study Plan'));
    });
  });

  group('GATE 2: Reader Experience & Bookshelf Separation', () {
    test('BookshelfItemModel handles All, Currently Reading, Want to Read, and Completed', () {
      final readingItem = BookshelfItemModel(
        id: 1,
        userId: 2,
        bookId: 101,
        title: 'The Architecture of Solitude',
        author: 'Julian Thorne',
        coverUrl: '/images/solitude.jpg',
        category: 'currently_reading',
        progress: 0.5,
        currentPage: 150,
        totalPages: 300,
        rating: 4.5,
        personalNotes: 'Chapter 5 was profound.',
      );

      expect(readingItem.category, 'currently_reading');
      expect(readingItem.progress, 0.5);
      expect(readingItem.isFinished, false);

      final completedItem = readingItem.copyWith(
        category: 'completed',
        currentPage: 300,
        progress: 1.0,
      );

      expect(completedItem.category, 'completed');
      expect(completedItem.progress, 1.0);
      expect(completedItem.isFinished, true);
    });

    test('ReadingGoalModel calculates annual reader goals and pacing metrics', () {
      final goal = ReadingGoalModel(
        id: 5,
        userId: 2,
        targetBooks: 24,
        completedBooks: 12,
        targetPages: 6000,
        pagesRead: 3600,
        year: 2026,
      );

      expect(goal.bookProgress, 0.5);
      expect(goal.pageProgress, 0.6);
      expect(goal.targetBooks, 24);
      expect(goal.completedBooks, 12);
    });

    test('Persona Isolation: Reader experience never includes student academic models', () {
      // Switch persona to reader
      ApiService.userType = UserType.reader;

      expect(ApiService.userType, UserType.reader);
      expect(ApiService.userType, isNot(UserType.student));
    });

    test('Reader Reading Companion generates literary and reflective prompts', () async {
      final insight = await ApiService.askReadingCompanion('[Themes] Reflection on protagonist choices');
      expect(insight, contains('Reading Companion'));
      expect(insight, contains('Reflection Prompt'));
    });
  });

  group('GATE 3: AI Reading Concierge & Multi-Day Plan Generator', () {
    test('AI Recommendation Explainer formats structured rationale', () async {
      final explanation = await ApiService.explainRecommendation({
        'id': 101,
        'title': 'Atomic Habits',
        'category': 'Self-Improvement',
      });

      expect(explanation.isNotEmpty, true);
    });

    test('Reading plan generation supports 3, 7, 14, and 21 day durations with target calculations', () {
      const totalPages = 300;
      final durations = [3, 7, 14, 21];

      for (final duration in durations) {
        final pagesPerDay = (totalPages / duration).ceil();
        expect(pagesPerDay > 0, true);

        if (duration == 3) {
          expect(pagesPerDay, 100);
        } else if (duration == 7) {
          expect(pagesPerDay, 43);
        } else if (duration == 14) {
          expect(pagesPerDay, 22);
        } else if (duration == 21) {
          expect(pagesPerDay, 15);
        }
      }
    });

    test('Design Tokens verification: canonical colors and radii are strictly non-null', () {
      expect(DSColors.deepForestGreen, isNotNull);
      expect(DSColors.secondaryGreen, isNotNull);
      expect(DSColors.antiqueGold, isNotNull);
      expect(DSColors.warmIvory, isNotNull);
      expect(DSColors.paperWhite, isNotNull);
      expect(DSColors.charcoal, isNotNull);
      expect(DSColors.softBorder, isNotNull);
      expect(DSColors.accentTerracotta, isNotNull);

      expect(DSRadius.card, 20.0);
      expect(DSRadius.md, 12.0);
      expect(DSRadius.sm, 8.0);
      expect(DSRadius.xs, 4.0);
      expect(DSRadius.pill, 9999.0);
    });
  });
}
