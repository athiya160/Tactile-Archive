class StudentAssignmentModel {
  final int id;
  final int userId;
  final int? subjectId;
  final String? subjectName;
  final String title;
  final String? description;
  final String? dueDate;
  final String priority;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  StudentAssignmentModel({
    required this.id,
    required this.userId,
    this.subjectId,
    this.subjectName,
    required this.title,
    this.description,
    this.dueDate,
    this.priority = 'Medium',
    String? status,
    bool? isCompleted,
    this.createdAt,
    this.updatedAt,
  }) : status = status ?? (isCompleted == true ? 'completed' : 'pending');

  bool get isCompleted =>
      status.toLowerCase() == 'completed' || status.toLowerCase() == 'submitted';

  factory StudentAssignmentModel.fromJson(Map<String, dynamic> json) {
    final statusStr = json['status'] as String? ?? (json['is_completed'] == true ? 'completed' : 'pending');
    return StudentAssignmentModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      userId: json['user_id'] is int ? json['user_id'] : int.tryParse(json['user_id']?.toString() ?? '') ?? 0,
      subjectId: json['subject_id'] != null ? int.tryParse(json['subject_id'].toString()) : null,
      subjectName: json['subject_name'] as String?,
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      dueDate: json['due_date'] as String?,
      priority: json['priority'] as String? ?? 'Medium',
      status: statusStr,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      if (subjectId != null) 'subject_id': subjectId,
      if (subjectName != null) 'subject_name': subjectName,
      'title': title,
      if (description != null) 'description': description,
      if (dueDate != null) 'due_date': dueDate,
      'priority': priority,
      'status': status,
      'is_completed': isCompleted,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  StudentAssignmentModel copyWith({
    int? id,
    int? userId,
    int? subjectId,
    String? subjectName,
    String? title,
    String? description,
    String? dueDate,
    String? priority,
    String? status,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return StudentAssignmentModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      subjectId: subjectId ?? this.subjectId,
      subjectName: subjectName ?? this.subjectName,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      priority: priority ?? this.priority,
      status: status ?? (isCompleted != null ? (isCompleted ? 'completed' : 'pending') : this.status),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
