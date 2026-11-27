import 'package:flutter_test/flutter_test.dart';
import 'package:libri_flow/core/services/api_service.dart';
import 'package:libri_flow/features/student/data/models/student_assignment_model.dart';
import 'package:libri_flow/features/student/data/models/student_goal_model.dart';
import 'package:libri_flow/features/student/data/models/student_subject_model.dart';
import 'package:libri_flow/features/student/data/models/student_schedule_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'auth_token': 'mock_token',
      'user_role': 'customer',
      'user_persona': 'student',
      'user_name': 'Test Student',
      'college_name': 'MIT',
      'degree_program': 'B.Tech CS',
      'current_semester': 'Semester 6',
    });
    ApiService.token = 'mock_token';
    ApiService.userType = UserType.student;
  });

  group('Phase 16B.2 - StudentAssignmentModel Unit Tests', () {
    test('StudentAssignmentModel.fromJson parses full payload properly', () {
      final json = {
        'id': 101,
        'user_id': 50,
        'subject_id': 12,
        'subject_name': 'Algorithms',
        'title': 'Problem Set 4: Dynamic Programming',
        'due_date': '2026-11-15T23:59:59.000Z',
        'priority': 'high',
        'status': 'pending',
        'is_completed': false,
        'created_at': '2026-11-01T10:00:00.000Z',
        'updated_at': '2026-11-06T12:00:00.000Z',
      };

      final model = StudentAssignmentModel.fromJson(json);

      expect(model.id, 101);
      expect(model.userId, 50);
      expect(model.subjectId, 12);
      expect(model.subjectName, 'Algorithms');
      expect(model.title, 'Problem Set 4: Dynamic Programming');
      expect(model.dueDate, '2026-11-15T23:59:59.000Z');
      expect(model.priority, 'high');
      expect(model.status, 'pending');
      expect(model.isCompleted, isFalse);
    });

    test('StudentAssignmentModel handles null/missing optional fields', () {
      final json = {
        'id': '202',
        'user_id': '60',
        'title': 'Read Chapter 3',
        'status': 'completed',
      };

      final model = StudentAssignmentModel.fromJson(json);

      expect(model.id, 202);
      expect(model.userId, 60);
      expect(model.subjectId, isNull);
      expect(model.subjectName, isNull);
      expect(model.title, 'Read Chapter 3');
      expect(model.dueDate, isNull);
      expect(model.priority, 'Medium');
      expect(model.status, 'completed');
      expect(model.isCompleted, isTrue); // status is completed
    });

    test('StudentAssignmentModel.toJson correctly serializes', () {
      final model = StudentAssignmentModel(
        id: 303,
        userId: 10,
        subjectId: 5,
        title: 'Midterm Essay',
        dueDate: '2026-12-01',
        priority: 'high',
        status: 'in_progress',
        isCompleted: false,
      );

      final json = model.toJson();

      expect(json['id'], 303);
      expect(json['user_id'], 10);
      expect(json['subject_id'], 5);
      expect(json['title'], 'Midterm Essay');
      expect(json['due_date'], '2026-12-01');
      expect(json['priority'], 'high');
      expect(json['status'], 'in_progress');
      expect(json['is_completed'], isFalse);
    });

    test('StudentAssignmentModel.copyWith correctly modifies properties', () {
      final model = StudentAssignmentModel(
        id: 404,
        userId: 10,
        title: 'Lab Report',
        status: 'pending',
        isCompleted: false,
      );

      final updated = model.copyWith(
        status: 'completed',
        isCompleted: true,
      );

      expect(updated.id, 404);
      expect(updated.title, 'Lab Report');
      expect(updated.status, 'completed');
      expect(updated.isCompleted, isTrue);
      // original remains unchanged
      expect(model.isCompleted, isFalse);
    });
  });

  group('Phase 16B.2 - StudentGoalModel Unit Tests', () {
    test('StudentGoalModel.fromJson parses full payload properly', () {
      final json = {
        'id': 201,
        'user_id': 50,
        'title': 'Achieve 9.0 GPA in Semester 6',
        'category': 'academic',
        'target_date': '2026-12-31',
        'progress': 0.85,
        'is_completed': false,
        'created_at': '2026-11-01T10:00:00.000Z',
        'updated_at': '2026-11-06T12:00:00.000Z',
      };

      final model = StudentGoalModel.fromJson(json);

      expect(model.id, 201);
      expect(model.userId, 50);
      expect(model.title, 'Achieve 9.0 GPA in Semester 6');
      expect(model.category, 'academic');
      expect(model.targetDate, '2026-12-31');
      expect(model.progress, 0.85);
      expect(model.percent, 85);
      expect(model.isCompleted, isFalse);
    });

    test('StudentGoalModel handles string progress or missing fields', () {
      final json = {
        'id': '205',
        'user_id': '50',
        'title': 'Read 5 Research Papers',
        'progress': '1.0',
        'is_completed': true,
      };

      final model = StudentGoalModel.fromJson(json);

      expect(model.id, 205);
      expect(model.userId, 50);
      expect(model.title, 'Read 5 Research Papers');
      expect(model.category, 'Academic');
      expect(model.targetDate, isNull);
      expect(model.progress, 1.0);
      expect(model.percent, 100);
      expect(model.isCompleted, isTrue);
    });

    test('StudentGoalModel.toJson serializes properly', () {
      final model = StudentGoalModel(
        id: 210,
        userId: 50,
        title: 'Master Rust Memory Safety',
        category: 'skill',
        targetDate: '2026-11-30',
        progress: 0.6,
        isCompleted: false,
      );

      final json = model.toJson();

      expect(json['id'], 210);
      expect(json['user_id'], 50);
      expect(json['title'], 'Master Rust Memory Safety');
      expect(json['category'], 'skill');
      expect(json['target_date'], '2026-11-30');
      expect(json['progress'], 0.6);
      expect(json['is_completed'], isFalse);
    });

    test('StudentGoalModel.copyWith updates fields properly', () {
      final model = StudentGoalModel(
        id: 220,
        userId: 50,
        title: 'Finish Compiler Project',
        progress: 0.4,
        isCompleted: false,
      );

      final updated = model.copyWith(
        progress: 1.0,
        isCompleted: true,
      );

      expect(updated.id, 220);
      expect(updated.progress, 1.0);
      expect(updated.percent, 100);
      expect(updated.isCompleted, isTrue);
      expect(model.progress, 0.4);
    });
  });

  group('Phase 16B.2 - Design System & UI Model Consistency', () {
    test('StudentSubjectModel and StudentScheduleModel have necessary fields for UI', () {
      final subject = StudentSubjectModel(
        id: 1,
        userId: 10,
        name: 'Operating Systems',
        code: 'CS301',
        progress: 0.65,
        target: 0.90,
        isLagging: false,
        instructor: 'Prof. Tanenbaum',
        credits: 4,
        hoursPerWeek: 5,
        syllabus: 'Processes, Threads, Memory Management, File Systems',
      );

      expect(subject.name, 'Operating Systems');
      expect(subject.syllabus, contains('Memory Management'));
      expect(subject.progress, 0.65);
      expect(subject.target, 0.90);

      final schedule = StudentScheduleModel(
        id: 1,
        userId: 10,
        subjectId: 1,
        subjectName: 'Operating Systems',
        topic: 'Virtual Memory & Page Tables',
        timeSlot: '09:00 - 10:30',
        date: '2026-11-10',
        durationMinutes: 90,
        isBoosted: true,
      );

      expect(schedule.subjectName, 'Operating Systems');
      expect(schedule.topic, 'Virtual Memory & Page Tables');
      expect(schedule.timeSlot, '09:00 - 10:30');
      expect(schedule.isBoosted, isTrue);
    });
  });
}
