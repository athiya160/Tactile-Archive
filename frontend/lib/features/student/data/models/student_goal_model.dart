class StudentGoalModel {
  final int id;
  final int userId;
  final String title;
  final String? targetDate;
  final double progress;
  final String category;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  StudentGoalModel({
    required this.id,
    required this.userId,
    required this.title,
    this.targetDate,
    this.progress = 0.0,
    this.category = 'Academic',
    String? status,
    bool? isCompleted,
    this.createdAt,
    this.updatedAt,
  }) : status = status ?? (isCompleted == true ? 'completed' : 'active');

  int get percent => (progress * 100).round();
  bool get isCompleted => status.toLowerCase() == 'completed' || progress >= 1.0;

  factory StudentGoalModel.fromJson(Map<String, dynamic> json) {
    double prog = 0.0;
    if (json['progress'] != null) {
      prog = (json['progress'] is num)
          ? (json['progress'] as num).toDouble()
          : double.tryParse(json['progress'].toString()) ?? 0.0;
    }
    final statusStr = json['status'] as String? ?? (json['is_completed'] == true ? 'completed' : 'active');
    return StudentGoalModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      userId: json['user_id'] is int ? json['user_id'] : int.tryParse(json['user_id']?.toString() ?? '') ?? 0,
      title: json['title'] as String? ?? '',
      targetDate: json['target_date'] as String?,
      progress: prog,
      category: json['category'] as String? ?? 'Academic',
      status: statusStr,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      if (targetDate != null) 'target_date': targetDate,
      'progress': progress,
      'category': category,
      'status': status,
      'is_completed': isCompleted,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  StudentGoalModel copyWith({
    int? id,
    int? userId,
    String? title,
    String? targetDate,
    double? progress,
    String? category,
    String? status,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return StudentGoalModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      targetDate: targetDate ?? this.targetDate,
      progress: progress ?? (isCompleted == true ? 1.0 : this.progress),
      category: category ?? this.category,
      status: status ?? (isCompleted != null ? (isCompleted ? 'completed' : 'active') : this.status),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
