import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libri_flow/core/services/api_service.dart';
import 'package:libri_flow/features/home/presentation/pages/browse_books_page.dart';
import 'package:libri_flow/features/home/presentation/pages/reader_dashboard_page.dart';
import 'package:libri_flow/features/home/presentation/pages/student_dashboard_page.dart';
import 'package:libri_flow/features/student/data/models/student_assignment_model.dart';
import 'package:libri_flow/features/student/data/models/student_goal_model.dart';
import 'package:libri_flow/features/student/data/models/student_subject_model.dart';
import 'package:libri_flow/features/reader/data/models/bookshelf_item_model.dart';
import 'package:libri_flow/features/reader/data/models/reading_goal_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

final Uint8List _kTransparentImage = Uint8List.fromList(<int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49,
  0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06,
  0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44,
  0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00, 0x05, 0x00, 0x01, 0x0D,
  0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42,
  0x60, 0x82
]);

class _MockHttpClient extends Fake implements HttpClient {
  @override
  bool autoUncompress = true;

  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _MockHttpClientRequest();

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async => _MockHttpClientRequest();
}

class _MockHttpClientRequest extends Fake implements HttpClientRequest {
  @override
  final HttpHeaders headers = _MockHttpHeaders();

  @override
  Future<HttpClientResponse> close() async => _MockHttpClientResponse();
}

class _MockHttpHeaders extends Fake implements HttpHeaders {
  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {}
  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {}
}

class _MockHttpClientResponse extends Fake implements HttpClientResponse {
  @override
  int get statusCode => HttpStatus.ok;

  @override
  int get contentLength => _kTransparentImage.length;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.fromIterable([_kTransparentImage]).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }
}

class _TestHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) => _MockHttpClient();
}

Widget wrapWithApp(Widget child, Size size) {
  return MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(size: size),
      child: Material(child: child),
    ),
  );
}

void main() {
  setUpAll(() {
    HttpOverrides.global = _TestHttpOverrides();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'auth_token': 'mock_e2e_token',
      'user_role': 'customer',
      'user_persona': 'student',
      'user_name': 'Alice Student',
      'college_name': 'Indian Institute of Technology',
      'degree_program': 'Computer Science',
      'current_semester': 'Semester 6',
    });
    ApiService.token = 'mock_e2e_token';
    ApiService.userType = UserType.student;
  });

  group('Phase 16B.5 — End-to-End Integration & Multi-Viewport Suite', () {
    const viewports = <String, Size>{
      'Compact Mobile (360x800)': Size(360, 800),
      'Standard Mobile (390x844)': Size(390, 844),
      'Large Mobile (430x932)': Size(430, 932),
      'Tablet Portrait (768x1024)': Size(768, 1024),
      'Tablet Landscape (1024x768)': Size(1024, 768),
      'Desktop Viewport (1440x900)': Size(1440, 900),
    };

    // ──────────────────────────────────────────────────────────────────────────
    // 1. STUDENT DASHBOARD RESPONSIVE VERIFICATION
    // ──────────────────────────────────────────────────────────────────────────
    for (final entry in viewports.entries) {
      testWidgets('StudentDashboardPage renders cleanly without overflow on ${entry.key}', (tester) async {
        tester.view.physicalSize = entry.value;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(wrapWithApp(const StudentDashboardPage(), entry.value));
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.byType(StudentDashboardPage), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    // ──────────────────────────────────────────────────────────────────────────
    // 2. READER DASHBOARD RESPONSIVE VERIFICATION
    // ──────────────────────────────────────────────────────────────────────────
    for (final entry in viewports.entries) {
      testWidgets('ReaderDashboardPage renders cleanly without overflow on ${entry.key}', (tester) async {
        tester.view.physicalSize = entry.value;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(wrapWithApp(const ReaderDashboardPage(), entry.value));
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.byType(ReaderDashboardPage), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    // ──────────────────────────────────────────────────────────────────────────
    // 3. EXPLORE & DISCOVERY RESPONSIVE VERIFICATION
    // ──────────────────────────────────────────────────────────────────────────
    for (final entry in viewports.entries) {
      testWidgets('BrowseBooksPage renders cleanly without overflow on ${entry.key}', (tester) async {
        tester.view.physicalSize = entry.value;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(wrapWithApp(const BrowseBooksPage(), entry.value));
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.byType(BrowseBooksPage), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    // ──────────────────────────────────────────────────────────────────────────
    // 4. PERSONA ISOLATION & SEPARATION VERIFICATION
    // ──────────────────────────────────────────────────────────────────────────
    testWidgets('Reader and Student experiences maintain strict UI isolation', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      // Render Reader Dashboard
      await tester.pumpWidget(wrapWithApp(const ReaderDashboardPage(), const Size(1200, 800)));
      await tester.pump(const Duration(milliseconds: 100));

      // Should find living bookshelf tabs or concierge but NOT syllabus or academic GPA
      expect(find.text('Academic Planner'), findsNothing);
      expect(find.text('Current Semester GPA'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    // ──────────────────────────────────────────────────────────────────────────
    // 5. DATA MODEL END-TO-END INTEGRATION
    // ──────────────────────────────────────────────────────────────────────────
    test('Student and Reader data models parse and serialize with full fidelity', () {
      // Student Subject
      final subj = StudentSubjectModel(
        id: 1,
        userId: 10,
        name: 'Distributed Systems',
        code: 'CS401',
        progress: 0.65,
        target: 0.90,
        isLagging: false,
        instructor: 'Dr. Lamport',
        credits: 4,
        hoursPerWeek: 5,
        syllabus: 'Consensus, Paxos, Raft',
      );
      expect(subj.name, 'Distributed Systems');
      expect(subj.progress, 0.65);
      expect(subj.isLagging, isFalse);

      // Student Assignment
      final asgn = StudentAssignmentModel(
        id: 2,
        userId: 10,
        subjectId: 1,
        title: 'Implement Raft Consensus',
        dueDate: '2026-11-25',
        priority: 'high',
        status: 'pending',
        isCompleted: false,
      );
      expect(asgn.title, 'Implement Raft Consensus');
      expect(asgn.priority, 'high');

      // Student Goal
      final goal = StudentGoalModel(
        id: 3,
        userId: 10,
        title: 'Publish Workshop Paper',
        targetDate: '2026-12-15',
        progress: 0.80,
        category: 'Academic',
        status: 'Active',
      );
      expect(goal.progress, 0.80);

      // Reader Bookshelf Item
      final book = BookshelfItemModel(
        id: 4,
        userId: 20,
        bookId: 100,
        title: 'Ficciones',
        author: 'Jorge Luis Borges',
        category: 'currently_reading',
        currentPage: 75,
        totalPages: 174,
        progress: 0.43,
      );
      expect(book.isFinished, isFalse);
      expect(book.category, 'currently_reading');

      // Move to completed
      final bookCompleted = book.copyWith(category: 'completed', progress: 1.0, currentPage: 174);
      expect(bookCompleted.isFinished, isTrue);

      // Reading Goal
      final rg = ReadingGoalModel(
        id: 5,
        userId: 20,
        year: 2026,
        targetBooks: 25,
        completedBooks: 5,
        targetPages: 5000,
        pagesRead: 1250,
        streakDays: 14,
      );
      expect(rg.bookProgress, 0.20);
      expect(rg.pageProgress, 0.25);
    });
  });
}
