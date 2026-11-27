class StudentScheduleModel {
  final int id;
  final int userId;
  final int? subjectId;
  final String subjectName;
  final String topic;
  final String timeSlot;
  final String? date;
  final int durationMinutes;
  final String status;
  final String color;
  final bool isBoosted;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  StudentScheduleModel({
    required this.id,
    required this.userId,
    this.subjectId,
    required this.subjectName,
    required this.topic,
    required this.timeSlot,
    this.date,
    this.durationMinutes = 60,
    this.status = 'Pending',
    this.color = '#006644',
    this.isBoosted = false,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  bool get isCompleted => status.toLowerCase() == 'completed';

  factory StudentScheduleModel.fromJson(Map<String, dynamic> json) {
    return StudentScheduleModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      userId: json['user_id'] is int ? json['user_id'] : int.tryParse(json['user_id'].toString()) ?? 0,
      subjectId: json['subject_id'] != null ? int.tryParse(json['subject_id'].toString()) : null,
      subjectName: json['subject_name'] as String? ?? '',
      topic: json['topic'] as String? ?? '',
      timeSlot: json['time_slot'] as String? ?? '',
      date: json['date'] as String?,
      durationMinutes: (json['duration_minutes'] as num?)?.toInt() ?? 60,
      status: json['status'] as String? ?? 'Pending',
      color: json['color'] as String? ?? '#006644',
      isBoosted: json['is_boosted'] as bool? ?? false,
      notes: json['notes'] as String?,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'subject_id': subjectId,
      'subject_name': subjectName,
      'topic': topic,
      'time_slot': timeSlot,
      'date': date,
      'duration_minutes': durationMinutes,
      'status': status,
      'color': color,
      'is_boosted': isBoosted,
      'notes': notes,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  StudentScheduleModel copyWith({
    int? id,
    int? userId,
    int? subjectId,
    String? subjectName,
    String? topic,
    String? timeSlot,
    String? date,
    int? durationMinutes,
    String? status,
    String? color,
    bool? isBoosted,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return StudentScheduleModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      subjectId: subjectId ?? this.subjectId,
      subjectName: subjectName ?? this.subjectName,
      topic: topic ?? this.topic,
      timeSlot: timeSlot ?? this.timeSlot,
      date: date ?? this.date,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      status: status ?? this.status,
      color: color ?? this.color,
      isBoosted: isBoosted ?? this.isBoosted,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
