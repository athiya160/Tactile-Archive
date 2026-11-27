class StudentSubjectModel {
  final int id;
  final int userId;
  final String name;
  final String? code;
  final double progress;
  final double target;
  final bool isLagging;
  final String color;
  final String? instructor;
  final int credits;
  final int hoursPerWeek;
  final String? syllabus;
  final List<int> textbookIds;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  StudentSubjectModel({
    required this.id,
    required this.userId,
    required this.name,
    this.code,
    this.progress = 0.0,
    this.target = 1.0,
    this.isLagging = false,
    this.color = '#006644',
    this.instructor,
    this.credits = 3,
    this.hoursPerWeek = 4,
    this.syllabus,
    this.textbookIds = const [],
    this.createdAt,
    this.updatedAt,
  });

  factory StudentSubjectModel.fromJson(Map<String, dynamic> json) {
    List<int> parsedTextbookIds = [];
    if (json['textbook_ids'] != null) {
      if (json['textbook_ids'] is List) {
        parsedTextbookIds = (json['textbook_ids'] as List)
            .map((e) => int.tryParse(e.toString()) ?? 0)
            .where((e) => e > 0)
            .toList();
      }
    }

    return StudentSubjectModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      userId: json['user_id'] is int ? json['user_id'] : int.tryParse(json['user_id'].toString()) ?? 0,
      name: json['name'] as String? ?? '',
      code: json['code'] as String?,
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      target: (json['target'] as num?)?.toDouble() ?? 1.0,
      isLagging: json['is_lagging'] as bool? ?? false,
      color: json['color'] as String? ?? '#006644',
      instructor: json['instructor'] as String?,
      credits: (json['credits'] as num?)?.toInt() ?? 3,
      hoursPerWeek: (json['hours_per_week'] as num?)?.toInt() ?? 4,
      syllabus: json['syllabus'] as String?,
      textbookIds: parsedTextbookIds,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'code': code,
      'progress': progress,
      'target': target,
      'is_lagging': isLagging,
      'color': color,
      'instructor': instructor,
      'credits': credits,
      'hours_per_week': hoursPerWeek,
      'syllabus': syllabus,
      'textbook_ids': textbookIds,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  StudentSubjectModel copyWith({
    int? id,
    int? userId,
    String? name,
    String? code,
    double? progress,
    double? target,
    bool? isLagging,
    String? color,
    String? instructor,
    int? credits,
    int? hoursPerWeek,
    String? syllabus,
    List<int>? textbookIds,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return StudentSubjectModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      code: code ?? this.code,
      progress: progress ?? this.progress,
      target: target ?? this.target,
      isLagging: isLagging ?? this.isLagging,
      color: color ?? this.color,
      instructor: instructor ?? this.instructor,
      credits: credits ?? this.credits,
      hoursPerWeek: hoursPerWeek ?? this.hoursPerWeek,
      syllabus: syllabus ?? this.syllabus,
      textbookIds: textbookIds ?? this.textbookIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
