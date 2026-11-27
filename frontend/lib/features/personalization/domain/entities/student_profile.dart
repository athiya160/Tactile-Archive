class StudentProfile {
  final int? id;
  final int? userId;
  final String educationLevel;
  final String course;
  final List<String> subjects;
  final String examGoal;
  final int studyDuration;
  final String difficultyLevel;
  final List<String> academicInterests;

  const StudentProfile({
    this.id,
    this.userId,
    this.educationLevel = 'Undergraduate',
    this.course = 'General',
    this.subjects = const [],
    this.examGoal = 'Semester Exams',
    this.studyDuration = 60,
    this.difficultyLevel = 'Intermediate',
    this.academicInterests = const [],
  });
}
