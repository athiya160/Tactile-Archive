import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/tokens/ds_colors.dart';
import '../../../../core/design_system/tokens/ds_radius.dart';
import '../../../../core/design_system/tokens/ds_shadows.dart';
import '../../../../core/design_system/components/ds_buttons.dart';
import '../../../../core/design_system/components/ds_inputs.dart';
import '../../../../core/design_system/components/ds_feedback.dart';
import '../../../../core/services/api_service.dart';
import '../../presentation/bloc/home_bloc.dart';
import '../../../home/domain/entities/book.dart';
import '../../../../core/widgets/tactile_footer.dart';

import '../../../student/data/models/student_subject_model.dart';
import '../../../student/data/models/student_schedule_model.dart';
import '../../../student/data/models/student_assignment_model.dart';
import '../../../student/data/models/student_goal_model.dart';

class StudentDashboardPage extends StatefulWidget {
  const StudentDashboardPage({super.key});

  @override
  State<StudentDashboardPage> createState() => _StudentDashboardPageState();
}

class _StudentDashboardPageState extends State<StudentDashboardPage> {
  String _selectedTab = 'Overview'; // Overview, Planner, Subjects, Assignments, Goals
  bool _isLoading = true;
  String? _errorMessage;

  // Real Persistent State
  List<StudentSubjectModel> _subjects = [];
  List<StudentScheduleModel> _schedule = [];
  List<StudentAssignmentModel> _assignments = [];
  List<StudentGoalModel> _goals = [];
  Map<String, dynamic>? _dashboardSummary;

  // Filters
  String _assignmentFilter = 'All'; // All, High Priority, Pending, Completed

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData({bool showSpinner = true}) async {
    if (showSpinner && mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      if (ApiService.isLoggedIn) {
        await ApiService.fetchCompositeProfile();
      }

      final summaryFuture = ApiService.getStudentDashboard();
      final subjectsFuture = ApiService.getStudentSubjects();
      final scheduleFuture = ApiService.getStudentSchedule();
      final assignmentsFuture = ApiService.getStudentAssignments();
      final goalsFuture = ApiService.getStudentGoals();

      final results = await Future.wait([
        summaryFuture,
        subjectsFuture,
        scheduleFuture,
        assignmentsFuture,
        goalsFuture,
      ]);

      if (!mounted) return;

      setState(() {
        _dashboardSummary = results[0] as Map<String, dynamic>;
        
        final rawSubjects = results[1] as List<dynamic>;
        _subjects = rawSubjects
            .map((e) => StudentSubjectModel.fromJson(e as Map<String, dynamic>))
            .toList();

        final rawSchedule = results[2] as List<dynamic>;
        _schedule = rawSchedule
            .map((e) => StudentScheduleModel.fromJson(e as Map<String, dynamic>))
            .toList();

        final rawAssignments = results[3] as List<dynamic>;
        _assignments = rawAssignments
            .map((e) => StudentAssignmentModel.fromJson(e as Map<String, dynamic>))
            .toList();

        final rawGoals = results[4] as List<dynamic>;
        _goals = rawGoals
            .map((e) => StudentGoalModel.fromJson(e as Map<String, dynamic>))
            .toList();

        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;
      debugPrint('[StudentDashboardPage] Error loading student data: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Unable to connect to academic services. Please check your backend connection.';
      });
    }
  }

  double get _overallProgress {
    if (_subjects.isEmpty) return 0.0;
    final sum = _subjects.fold<double>(0.0, (acc, s) => acc + s.progress);
    return (sum / _subjects.length).clamp(0.0, 1.0);
  }

  // ─── CRUD OPERATIONS ────────────────────────────────────────────────────────

  Future<void> _showAddSubjectDialog([StudentSubjectModel? existing]) async {
    final isEdit = existing != null;
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final codeCtrl = TextEditingController(text: existing?.code ?? '');
    final instructorCtrl = TextEditingController(text: existing?.instructor ?? '');
    final creditsCtrl = TextEditingController(text: existing?.credits.toString() ?? '4');
    final hoursCtrl = TextEditingController(text: existing?.hoursPerWeek.toString() ?? '6');
    final targetCtrl = TextEditingController(
      text: existing != null ? (existing.target * 100).round().toString() : '80',
    );
    final syllabusCtrl = TextEditingController(text: existing?.syllabus ?? '');
    String selectedColor = existing?.color ?? '#183D32';

    final colorOptions = [
      '#183D32', // Deep Forest Green
      '#285C49', // Secondary Green
      '#3182CE', // Academic Blue
      '#C47C62', // Muted Terracotta
      '#805AD5', // Royal Violet
      '#D69E2E', // Warm Gold
    ];

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          backgroundColor: DSColors.paperWhite,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DSRadius.card)),
          title: Text(
            isEdit ? 'Edit Academic Subject' : 'Add Academic Subject',
            style: GoogleFonts.playfairDisplay(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: DSColors.deepForestGreen,
            ),
          ),
          content: SingleChildScrollView(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 480),
              width: double.infinity,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DSTextField(
                    labelText: 'Subject Name *',
                    hintText: 'e.g. Distributed Systems',
                    controller: nameCtrl,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: DSTextField(
                          labelText: 'Course Code',
                          hintText: 'e.g. CS501',
                          controller: codeCtrl,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DSTextField(
                          labelText: 'Credits',
                          hintText: 'e.g. 4',
                          keyboardType: TextInputType.number,
                          controller: creditsCtrl,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: DSTextField(
                          labelText: 'Instructor',
                          hintText: 'e.g. Dr. Aris Thorne',
                          controller: instructorCtrl,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DSTextField(
                          labelText: 'Hours / Week',
                          hintText: 'e.g. 6',
                          keyboardType: TextInputType.number,
                          controller: hoursCtrl,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  DSTextField(
                    labelText: 'Target Progress (%)',
                    hintText: 'e.g. 80',
                    keyboardType: TextInputType.number,
                    controller: targetCtrl,
                  ),
                  const SizedBox(height: 14),
                  DSTextField(
                    labelText: 'Syllabus Topics & Key Concepts',
                    hintText: 'e.g. Raft Consensus, Paxos, Vector Clocks, Byzantine Fault Tolerance',
                    maxLines: 3,
                    controller: syllabusCtrl,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Subject Accent Color',
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: DSColors.charcoal),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: colorOptions.map((c) {
                      final colorVal = Color(int.parse(c.replaceFirst('#', '0xFF')));
                      final isSel = selectedColor.toLowerCase() == c.toLowerCase();
                      return GestureDetector(
                        onTap: () => setDlgState(() => selectedColor = c),
                        child: Container(
                          margin: const EdgeInsets.only(right: 10),
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: colorVal,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSel ? DSColors.charcoal : Colors.transparent,
                              width: 2.5,
                            ),
                            boxShadow: isSel ? DSShadows.sm : null,
                          ),
                          child: isSel
                              ? const Icon(Icons.check, size: 16, color: Colors.white)
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text('Cancel', style: GoogleFonts.inter(color: DSColors.charcoal)),
            ),
            DSButton.primary(
              text: isEdit ? 'Save Changes' : 'Add Subject',
              onPressed: () async {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) {
                  DSSnackBar.show(context, message: 'Please enter a subject name', isError: true);
                  return;
                }

                final targetPercent = double.tryParse(targetCtrl.text.trim()) ?? 80.0;
                final targetVal = (targetPercent / 100.0).clamp(0.0, 1.0);
                final credits = int.tryParse(creditsCtrl.text.trim()) ?? 4;
                final hours = int.tryParse(hoursCtrl.text.trim()) ?? 6;

                final payload = {
                  'name': name,
                  'code': codeCtrl.text.trim().isEmpty ? null : codeCtrl.text.trim(),
                  'instructor': instructorCtrl.text.trim().isEmpty ? null : instructorCtrl.text.trim(),
                  'credits': credits,
                  'hours_per_week': hours,
                  'target': targetVal,
                  'syllabus': syllabusCtrl.text.trim().isEmpty ? null : syllabusCtrl.text.trim(),
                  'color': selectedColor,
                };

                try {
                  Navigator.of(ctx).pop();
                  if (isEdit) {
                    await ApiService.updateStudentSubject(existing.id, payload);
                    DSSnackBar.show(context, message: 'Subject "$name" updated successfully!');
                  } else {
                    await ApiService.createStudentSubject(payload);
                    DSSnackBar.show(context, message: 'Subject "$name" added to your curriculum!');
                  }
                  await _loadAllData(showSpinner: false);
                } catch (e) {
                  DSSnackBar.show(context, message: 'Error saving subject: $e', isError: true);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteSubject(StudentSubjectModel subject) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: DSColors.paperWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DSRadius.card)),
        title: Text(
          'Delete Subject',
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.bold,
            color: DSColors.deepForestGreen,
          ),
        ),
        content: Text(
          'Are you sure you want to remove "${subject.name}"? All associated schedules and assignments will be removed.',
          style: GoogleFonts.inter(color: DSColors.charcoal),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancel', style: GoogleFonts.inter(color: DSColors.charcoal)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ApiService.deleteStudentSubject(subject.id);
        DSSnackBar.show(context, message: 'Subject "${subject.name}" removed');
        await _loadAllData(showSpinner: false);
      } catch (e) {
        DSSnackBar.show(context, message: 'Failed to delete subject: $e', isError: true);
      }
    }
  }

  Future<void> _showScheduleSessionDialog([StudentScheduleModel? existing]) async {
    final isEdit = existing != null;
    int? selectedSubjectId = existing?.subjectId ?? (_subjects.isNotEmpty ? _subjects.first.id : null);
    String subjectName = existing?.subjectName ?? (_subjects.isNotEmpty ? _subjects.first.name : 'General Study');
    final topicCtrl = TextEditingController(text: existing?.topic ?? '');
    final timeSlotCtrl = TextEditingController(text: existing?.timeSlot ?? '09:00 AM - 10:30 AM');
    final durationCtrl = TextEditingController(text: existing?.durationMinutes.toString() ?? '90');
    final dateCtrl = TextEditingController(
      text: existing?.date ?? DateTime.now().toIso8601String().substring(0, 10),
    );
    bool isBoosted = existing?.isBoosted ?? false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          backgroundColor: DSColors.paperWhite,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DSRadius.card)),
          title: Text(
            isEdit ? 'Edit Study Session' : 'Schedule Study Session',
            style: GoogleFonts.playfairDisplay(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: DSColors.deepForestGreen,
            ),
          ),
          content: SingleChildScrollView(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 480),
              width: double.infinity,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_subjects.isNotEmpty) ...[
                    Text(
                      'Subject',
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: DSColors.charcoal),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: DSColors.warmIvory,
                        borderRadius: BorderRadius.circular(DSRadius.md),
                        border: Border.all(color: DSColors.softBorder),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: selectedSubjectId,
                          isExpanded: true,
                          items: _subjects.map((s) {
                            return DropdownMenuItem<int>(
                              value: s.id,
                              child: Text(
                                '${s.name} ${s.code != null ? "(${s.code})" : ""}',
                                style: GoogleFonts.inter(fontSize: 14, color: DSColors.charcoal),
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              final found = _subjects.firstWhere((s) => s.id == val);
                              setDlgState(() {
                                selectedSubjectId = val;
                                subjectName = found.name;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                  DSTextField(
                    labelText: 'Study Topic / Concept *',
                    hintText: 'e.g. Raft Consensus Algorithm & Leader Election',
                    controller: topicCtrl,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: DSTextField(
                          labelText: 'Time Slot',
                          hintText: 'e.g. 09:00 AM - 10:30 AM',
                          controller: timeSlotCtrl,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DSTextField(
                          labelText: 'Duration (mins)',
                          hintText: 'e.g. 90',
                          keyboardType: TextInputType.number,
                          controller: durationCtrl,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  DSTextField(
                    labelText: 'Date (YYYY-MM-DD)',
                    hintText: 'e.g. 2026-11-10',
                    controller: dateCtrl,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Checkbox(
                        value: isBoosted,
                        activeColor: DSColors.deepForestGreen,
                        onChanged: (val) => setDlgState(() => isBoosted = val ?? false),
                      ),
                      Text(
                        'Apply AI Study Boost (Extra focus session)',
                        style: GoogleFonts.inter(fontSize: 13, color: DSColors.charcoal),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text('Cancel', style: GoogleFonts.inter(color: DSColors.charcoal)),
            ),
            DSButton.primary(
              text: isEdit ? 'Save Changes' : 'Schedule Session',
              onPressed: () async {
                final topic = topicCtrl.text.trim();
                if (topic.isEmpty) {
                  DSSnackBar.show(context, message: 'Please specify a study topic', isError: true);
                  return;
                }

                final payload = {
                  'subject_id': selectedSubjectId,
                  'subject_name': subjectName,
                  'topic': topic,
                  'time_slot': timeSlotCtrl.text.trim().isEmpty ? '09:00 AM - 10:30 AM' : timeSlotCtrl.text.trim(),
                  'duration_minutes': int.tryParse(durationCtrl.text.trim()) ?? 90,
                  'date': dateCtrl.text.trim().isEmpty ? null : dateCtrl.text.trim(),
                  'is_boosted': isBoosted,
                  'status': existing?.status ?? 'Pending',
                };

                try {
                  Navigator.of(ctx).pop();
                  if (isEdit) {
                    await ApiService.updateStudentScheduleItem(existing.id, payload);
                    DSSnackBar.show(context, message: 'Study session updated!');
                  } else {
                    await ApiService.createStudentScheduleItem(payload);
                    DSSnackBar.show(context, message: 'Study session scheduled for "$topic"!');
                  }
                  await _loadAllData(showSpinner: false);
                } catch (e) {
                  DSSnackBar.show(context, message: 'Failed to save session: $e', isError: true);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleScheduleStatus(StudentScheduleModel item) async {
    final nextStatus = item.isCompleted ? 'Pending' : 'Completed';
    try {
      await ApiService.updateStudentScheduleItem(item.id, {'status': nextStatus});
      DSSnackBar.show(
        context,
        message: nextStatus == 'Completed'
            ? 'Completed study session: "${item.topic}"'
            : 'Marked session as pending',
      );
      await _loadAllData(showSpinner: false);
    } catch (e) {
      DSSnackBar.show(context, message: 'Failed to update session: $e', isError: true);
    }
  }

  Future<void> _deleteScheduleItem(StudentScheduleModel item) async {
    try {
      await ApiService.deleteStudentScheduleItem(item.id);
      DSSnackBar.show(context, message: 'Session deleted');
      await _loadAllData(showSpinner: false);
    } catch (e) {
      DSSnackBar.show(context, message: 'Failed to delete session: $e', isError: true);
    }
  }

  Future<void> _showAddAssignmentDialog([StudentAssignmentModel? existing]) async {
    final isEdit = existing != null;
    int? selectedSubjectId = existing?.subjectId ?? (_subjects.isNotEmpty ? _subjects.first.id : null);
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final descCtrl = TextEditingController(text: existing?.description ?? '');
    final dueCtrl = TextEditingController(
      text: existing?.dueDate ?? DateTime.now().add(const Duration(days: 7)).toIso8601String().substring(0, 10),
    );
    String priority = existing?.priority ?? 'Medium';

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          backgroundColor: DSColors.paperWhite,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DSRadius.card)),
          title: Text(
            isEdit ? 'Edit Assignment' : 'Add Assignment & Deadline',
            style: GoogleFonts.playfairDisplay(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: DSColors.deepForestGreen,
            ),
          ),
          content: SingleChildScrollView(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 480),
              width: double.infinity,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DSTextField(
                    labelText: 'Assignment Title *',
                    hintText: 'e.g. Implement Scaled Dot-Product Attention in PyTorch',
                    controller: titleCtrl,
                  ),
                  const SizedBox(height: 14),
                  if (_subjects.isNotEmpty) ...[
                    Text(
                      'Associated Subject',
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: DSColors.charcoal),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: DSColors.warmIvory,
                        borderRadius: BorderRadius.circular(DSRadius.md),
                        border: Border.all(color: DSColors.softBorder),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: selectedSubjectId,
                          isExpanded: true,
                          items: _subjects.map((s) {
                            return DropdownMenuItem<int>(
                              value: s.id,
                              child: Text(s.name, style: GoogleFonts.inter(fontSize: 14, color: DSColors.charcoal)),
                            );
                          }).toList(),
                          onChanged: (val) => setDlgState(() => selectedSubjectId = val),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: DSTextField(
                          labelText: 'Due Date (YYYY-MM-DD)',
                          hintText: 'e.g. 2026-11-20',
                          controller: dueCtrl,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Priority',
                              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: DSColors.charcoal),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              decoration: BoxDecoration(
                                color: DSColors.warmIvory,
                                borderRadius: BorderRadius.circular(DSRadius.md),
                                border: Border.all(color: DSColors.softBorder),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: priority,
                                  isExpanded: true,
                                  items: ['Low', 'Medium', 'High'].map((p) {
                                    return DropdownMenuItem<String>(
                                      value: p,
                                      child: Text(p, style: GoogleFonts.inter(fontSize: 14, color: DSColors.charcoal)),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) setDlgState(() => priority = val);
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  DSTextField(
                    labelText: 'Description / Problem Set Notes',
                    hintText: 'e.g. Read chapter 4, complete questions 1-5, include unit test outputs',
                    maxLines: 2,
                    controller: descCtrl,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text('Cancel', style: GoogleFonts.inter(color: DSColors.charcoal)),
            ),
            DSButton.primary(
              text: isEdit ? 'Save Changes' : 'Add Assignment',
              onPressed: () async {
                final title = titleCtrl.text.trim();
                if (title.isEmpty) {
                  DSSnackBar.show(context, message: 'Please enter assignment title', isError: true);
                  return;
                }

                final payload = {
                  'subject_id': selectedSubjectId,
                  'title': title,
                  'description': descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                  'due_date': dueCtrl.text.trim().isEmpty ? null : dueCtrl.text.trim(),
                  'priority': priority,
                  'status': existing?.status ?? 'Pending',
                };

                try {
                  Navigator.of(ctx).pop();
                  if (isEdit) {
                    await ApiService.updateStudentAssignment(existing.id, payload);
                    DSSnackBar.show(context, message: 'Assignment updated!');
                  } else {
                    await ApiService.createStudentAssignment(payload);
                    DSSnackBar.show(context, message: 'Assignment "$title" added to schedule!');
                  }
                  await _loadAllData(showSpinner: false);
                } catch (e) {
                  DSSnackBar.show(context, message: 'Failed to save assignment: $e', isError: true);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleAssignmentStatus(StudentAssignmentModel assignment) async {
    final nextStatus = assignment.isCompleted ? 'Pending' : 'Completed';
    try {
      await ApiService.updateStudentAssignment(assignment.id, {'status': nextStatus});
      DSSnackBar.show(
        context,
        message: nextStatus == 'Completed'
            ? 'Assignment completed: "${assignment.title}"'
            : 'Marked assignment as pending',
      );
      await _loadAllData(showSpinner: false);
    } catch (e) {
      DSSnackBar.show(context, message: 'Failed to update assignment: $e', isError: true);
    }
  }

  Future<void> _deleteAssignment(StudentAssignmentModel assignment) async {
    try {
      await ApiService.deleteStudentAssignment(assignment.id);
      DSSnackBar.show(context, message: 'Assignment removed');
      await _loadAllData(showSpinner: false);
    } catch (e) {
      DSSnackBar.show(context, message: 'Failed to delete assignment: $e', isError: true);
    }
  }

  Future<void> _showAddGoalDialog([StudentGoalModel? existing]) async {
    final isEdit = existing != null;
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final dateCtrl = TextEditingController(
      text: existing?.targetDate ?? DateTime.now().add(const Duration(days: 60)).toIso8601String().substring(0, 10),
    );
    final progressCtrl = TextEditingController(
      text: existing != null ? (existing.progress * 100).round().toString() : '50',
    );
    String category = existing?.category ?? 'Academic';

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          backgroundColor: DSColors.paperWhite,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DSRadius.card)),
          title: Text(
            isEdit ? 'Edit Academic Goal' : 'Add Academic Goal',
            style: GoogleFonts.playfairDisplay(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: DSColors.deepForestGreen,
            ),
          ),
          content: SingleChildScrollView(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 440),
              width: double.infinity,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DSTextField(
                    labelText: 'Goal Title *',
                    hintText: 'e.g. Maintain 3.8+ GPA in Semester 5',
                    controller: titleCtrl,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Category',
                              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: DSColors.charcoal),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              decoration: BoxDecoration(
                                color: DSColors.warmIvory,
                                borderRadius: BorderRadius.circular(DSRadius.md),
                                border: Border.all(color: DSColors.softBorder),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: category,
                                  isExpanded: true,
                                  items: ['Academic', 'Exam', 'Skill', 'Project'].map((c) {
                                    return DropdownMenuItem<String>(
                                      value: c,
                                      child: Text(c, style: GoogleFonts.inter(fontSize: 14, color: DSColors.charcoal)),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) setDlgState(() => category = val);
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DSTextField(
                          labelText: 'Target Date',
                          hintText: 'e.g. 2026-12-31',
                          controller: dateCtrl,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  DSTextField(
                    labelText: 'Current Progress (%)',
                    hintText: 'e.g. 60',
                    keyboardType: TextInputType.number,
                    controller: progressCtrl,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text('Cancel', style: GoogleFonts.inter(color: DSColors.charcoal)),
            ),
            DSButton.primary(
              text: isEdit ? 'Save Changes' : 'Create Goal',
              onPressed: () async {
                final title = titleCtrl.text.trim();
                if (title.isEmpty) {
                  DSSnackBar.show(context, message: 'Please enter goal title', isError: true);
                  return;
                }

                final percent = double.tryParse(progressCtrl.text.trim()) ?? 0.0;
                final progressVal = (percent / 100.0).clamp(0.0, 1.0);

                final payload = {
                  'title': title,
                  'category': category,
                  'target_date': dateCtrl.text.trim().isEmpty ? null : dateCtrl.text.trim(),
                  'progress': progressVal,
                  'status': progressVal >= 1.0 ? 'Completed' : 'Active',
                };

                try {
                  Navigator.of(ctx).pop();
                  if (isEdit) {
                    await ApiService.updateStudentGoal(existing.id, payload);
                    DSSnackBar.show(context, message: 'Goal updated!');
                  } else {
                    await ApiService.createStudentGoal(payload);
                    DSSnackBar.show(context, message: 'New academic goal created!');
                  }
                  await _loadAllData(showSpinner: false);
                } catch (e) {
                  DSSnackBar.show(context, message: 'Failed to save goal: $e', isError: true);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteGoal(StudentGoalModel goal) async {
    try {
      await ApiService.deleteStudentGoal(goal.id);
      DSSnackBar.show(context, message: 'Goal deleted');
      await _loadAllData(showSpinner: false);
    } catch (e) {
      DSSnackBar.show(context, message: 'Failed to delete goal: $e', isError: true);
    }
  }

  Future<void> _applyAIScheduleRebalance() async {
    final lagging = _subjects.where((s) => s.isLagging || s.progress < 0.6).toList();
    final targetSubject = lagging.isNotEmpty
        ? lagging.first
        : (_subjects.isNotEmpty ? _subjects.first : null);

    final subjectName = targetSubject?.name ?? 'Comprehensive Academic Review';
    final subjectId = targetSubject?.id;
    final topic = targetSubject != null
        ? '${targetSubject.name}: Targeted Revision & Practice Problem Set'
        : 'Deep Work Synthesis & Concept Consolidation';

    try {
      await ApiService.createStudentScheduleItem({
        'subject_id': subjectId,
        'subject_name': subjectName,
        'topic': topic,
        'time_slot': '04:00 PM - 05:30 PM',
        'duration_minutes': 90,
        'date': DateTime.now().toIso8601String().substring(0, 10),
        'is_boosted': true,
        'status': 'Pending',
        'color': '#C47C62',
        'notes': 'Auto-scheduled by AI Academic Companion to reinforce high-impact syllabus concepts.',
      });

      DSSnackBar.show(
        context,
        message: 'AI Optimizer added a 90-minute boosted session for "$subjectName"!',
      );
      await _loadAllData(showSpinner: false);
    } catch (e) {
      DSSnackBar.show(context, message: 'Failed to apply AI rebalance: $e', isError: true);
    }
  }

  // ─── UI BUILDERS ────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DSColors.warmIvory,
      body: RefreshIndicator(
        onRefresh: () => _loadAllData(showSpinner: false),
        color: DSColors.deepForestGreen,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              _buildAcademicHeroHeader(),
              _buildSectionTabs(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: _buildMainContent(),
              ),
              const TactileFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAcademicHeroHeader() {
    final studentName = ApiService.userName ?? 'Scholar';
    final course = ApiService.studentDegree ?? _dashboardSummary?['course'] ?? 'Computer Science & Engineering';
    final semester = ApiService.studentSemester ?? _dashboardSummary?['semester'] ?? 'Semester 5';
    final college = ApiService.studentCollege ?? _dashboardSummary?['college'] ?? 'Academic Library Archive';

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: DSColors.deepForestGreen,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            DSColors.deepForestGreen,
            DSColors.deepForestGreen,
            DSColors.secondaryGreen,
          ],
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(DSRadius.pill),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.school, size: 14, color: DSColors.paperWhite),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                '$course • $semester'.toUpperCase(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                  color: DSColors.paperWhite,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.refresh, color: DSColors.paperWhite),
                      tooltip: 'Refresh Academic Data',
                      onPressed: () => _loadAllData(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Academic Companion',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: DSColors.mutedTerracotta,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Welcome, $studentName',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: DSColors.paperWhite,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  college,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: DSColors.paperWhite.withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(height: 24),
                _buildMetricTiles(),
                const SizedBox(height: 20),
                _buildQuickActionButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricTiles() {
    final completedSessions = _schedule.where((s) => s.isCompleted).length;
    final totalSessions = _schedule.length;
    final pendingAssignments = _assignments.where((a) => !a.isCompleted).length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 650;
        final tiles = [
          _buildMetricCard(
            title: 'Overall Progress',
            value: '${(_overallProgress * 100).round()}%',
            subtitle: 'Target: 85%',
            icon: Icons.trending_up,
            accentColor: DSColors.mutedTerracotta,
          ),
          _buildMetricCard(
            title: 'Enrolled Subjects',
            value: '${_subjects.length}',
            subtitle: '${_subjects.where((s) => s.isLagging).length} Need Attention',
            icon: Icons.menu_book,
            accentColor: DSColors.info,
          ),
          _buildMetricCard(
            title: "Today's Study",
            value: '$completedSessions / $totalSessions',
            subtitle: 'Sessions Finished',
            icon: Icons.timer_outlined,
            accentColor: DSColors.paperWhite,
          ),
          _buildMetricCard(
            title: 'Upcoming Tasks',
            value: '$pendingAssignments',
            subtitle: 'Pending Deadlines',
            icon: Icons.assignment_outlined,
            accentColor: DSColors.mutedTerracotta,
          ),
        ];

        if (isCompact) {
          return GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.25,
            children: tiles,
          );
        }

        return Row(
          children: tiles.map((t) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: t))).toList(),
        );
      },
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(DSRadius.card),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: DSColors.paperWhite.withValues(alpha: 0.8),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Icon(icon, size: 16, color: accentColor),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.playfairDisplay(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: DSColors.paperWhite,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: DSColors.paperWhite.withValues(alpha: 0.65),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButtons() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        ElevatedButton.icon(
          onPressed: () => _showAddSubjectDialog(),
          icon: const Icon(Icons.add, size: 16),
          label: const Text('Add Subject'),
          style: ElevatedButton.styleFrom(
            backgroundColor: DSColors.paperWhite,
            foregroundColor: DSColors.deepForestGreen,
            elevation: 0,
            textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DSRadius.md)),
          ),
        ),
        ElevatedButton.icon(
          onPressed: () => _showScheduleSessionDialog(),
          icon: const Icon(Icons.calendar_today, size: 15),
          label: const Text('Schedule Session'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white.withValues(alpha: 0.15),
            foregroundColor: DSColors.paperWhite,
            elevation: 0,
            textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DSRadius.md),
              side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
            ),
          ),
        ),
        ElevatedButton.icon(
          onPressed: () => _showAddAssignmentDialog(),
          icon: const Icon(Icons.assignment_add, size: 16),
          label: const Text('Add Assignment'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white.withValues(alpha: 0.15),
            foregroundColor: DSColors.paperWhite,
            elevation: 0,
            textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DSRadius.md),
              side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
            ),
          ),
        ),
        OutlinedButton.icon(
          onPressed: _applyAIScheduleRebalance,
          icon: const Icon(Icons.auto_awesome, size: 15, color: DSColors.mutedTerracotta),
          label: Text('AI Rebalance', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: DSColors.paperWhite)),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: DSColors.mutedTerracotta),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DSRadius.md)),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTabs() {
    final tabs = ['Overview', 'Planner', 'Subjects', 'Assignments', 'Goals'];

    return Container(
      color: DSColors.paperWhite,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: Row(
              children: tabs.map((tab) {
                final isSel = _selectedTab == tab;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(tab),
                    selected: isSel,
                    onSelected: (val) {
                      if (val) setState(() => _selectedTab = tab);
                    },
                    selectedColor: DSColors.deepForestGreen,
                    backgroundColor: DSColors.warmIvory,
                    labelStyle: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: isSel ? FontWeight.w600 : FontWeight.w500,
                      color: isSel ? DSColors.paperWhite : DSColors.charcoal,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    if (_isLoading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 80),
          child: Column(
            children: [
              const CircularProgressIndicator(color: DSColors.deepForestGreen),
              const SizedBox(height: 20),
              Text(
                'Synchronizing Academic Records...',
                style: GoogleFonts.inter(fontSize: 14, color: DSColors.charcoal),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return DSErrorState(
        title: 'Connection Issue',
        message: _errorMessage!,
        onRetry: () => _loadAllData(),
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: Builder(
          builder: (context) {
            switch (_selectedTab) {
              case 'Planner':
                return _buildPlannerTab();
              case 'Subjects':
                return _buildSubjectsTab();
              case 'Assignments':
                return _buildAssignmentsTab();
              case 'Goals':
                return _buildGoalsTab();
              case 'Overview':
              default:
                return _buildOverviewTab();
            }
          },
        ),
      ),
    );
  }

  // ─── TAB 1: OVERVIEW ────────────────────────────────────────────────────────

  Widget _buildOverviewTab() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 950;

        if (isDesktop) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Column: Daily Planner & Subjects
              Expanded(
                flex: 7,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTodayScheduleSection(),
                    const SizedBox(height: 32),
                    _buildSubjectsOverviewSection(),
                    const SizedBox(height: 32),
                    _buildRecommendedTextbooksSection(),
                  ],
                ),
              ),
              const SizedBox(width: 28),
              // Right Column: Deadlines & Study Goals
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildUpcomingAssignmentsCard(),
                    const SizedBox(height: 24),
                    _buildStudyGoalsCard(),
                  ],
                ),
              ),
            ],
          );
        }

        // Mobile / Tablet Stack
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTodayScheduleSection(),
            const SizedBox(height: 28),
            _buildUpcomingAssignmentsCard(),
            const SizedBox(height: 28),
            _buildSubjectsOverviewSection(),
            const SizedBox(height: 28),
            _buildStudyGoalsCard(),
            const SizedBox(height: 28),
            _buildRecommendedTextbooksSection(),
          ],
        );
      },
    );
  }

  Widget _buildTodayScheduleSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: DSColors.paperWhite,
        borderRadius: BorderRadius.circular(DSRadius.card),
        border: Border.all(color: DSColors.softBorder),
        boxShadow: DSShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.today, size: 20, color: DSColors.deepForestGreen),
                  const SizedBox(width: 10),
                  Text(
                    'Daily Study Schedule',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: DSColors.deepForestGreen,
                    ),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: () => setState(() => _selectedTab = 'Planner'),
                icon: const Icon(Icons.calendar_month, size: 15),
                label: const Text('Full Planner'),
                style: TextButton.styleFrom(
                  foregroundColor: DSColors.deepForestGreen,
                  textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_schedule.isEmpty)
            DSEmptyState(
              icon: Icons.event_available,
              title: 'No Sessions Scheduled for Today',
              description: 'Schedule a study block to stay ahead of your semester coursework.',
              actionLabel: 'Schedule Session',
              onAction: () => _showScheduleSessionDialog(),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _schedule.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (ctx, i) => _buildScheduleItemCard(_schedule[i]),
            ),
        ],
      ),
    );
  }

  Widget _buildScheduleItemCard(StudentScheduleModel item) {
    Color itemColor = DSColors.deepForestGreen;
    if (item.color.startsWith('#')) {
      try {
        itemColor = Color(int.parse(item.color.replaceFirst('#', '0xFF')));
      } catch (_) {}
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: item.isCompleted ? DSColors.warmIvory.withValues(alpha: 0.6) : DSColors.warmIvory,
        borderRadius: BorderRadius.circular(DSRadius.card),
        border: Border.all(
          color: item.isCompleted ? DSColors.softBorder : itemColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            icon: Icon(
              item.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
              color: item.isCompleted ? DSColors.deepForestGreen : DSColors.charcoal.withValues(alpha: 0.4),
            ),
            onPressed: () => _toggleScheduleStatus(item),
            tooltip: item.isCompleted ? 'Mark Pending' : 'Mark Completed',
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      item.timeSlot,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: itemColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (item.isBoosted)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: DSColors.mutedTerracotta.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '⚡ AI Boost',
                          style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: DSColors.mutedTerracotta),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  item.topic,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: item.isCompleted ? DSColors.charcoal.withValues(alpha: 0.5) : DSColors.charcoal,
                    decoration: item.isCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${item.subjectName} • ${item.durationMinutes} mins',
                  style: GoogleFonts.inter(fontSize: 12, color: DSColors.charcoal.withValues(alpha: 0.6)),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, size: 18),
            onSelected: (val) {
              if (val == 'edit') {
                _showScheduleSessionDialog(item);
              } else if (val == 'delete') {
                _deleteScheduleItem(item);
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(value: 'edit', child: Text('Edit')),
              const PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectsOverviewSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: DSColors.paperWhite,
        borderRadius: BorderRadius.circular(DSRadius.card),
        border: Border.all(color: DSColors.softBorder),
        boxShadow: DSShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Enrolled Curriculum & Progress',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: DSColors.deepForestGreen,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add, color: DSColors.deepForestGreen),
                tooltip: 'Add Subject',
                onPressed: () => _showAddSubjectDialog(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_subjects.isEmpty)
            DSEmptyState(
              icon: Icons.library_books,
              title: 'No Subjects Registered',
              description: 'Register your current semester courses to track progress and study schedules.',
              actionLabel: 'Add First Subject',
              onAction: () => _showAddSubjectDialog(),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _subjects.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (ctx, i) => _buildSubjectCard(_subjects[i]),
            ),
        ],
      ),
    );
  }

  Widget _buildSubjectCard(StudentSubjectModel subject) {
    Color subjectColor = DSColors.deepForestGreen;
    if (subject.color.startsWith('#')) {
      try {
        subjectColor = Color(int.parse(subject.color.replaceFirst('#', '0xFF')));
      } catch (_) {}
    }

    final progressPct = (subject.progress * 100).round();
    final targetPct = (subject.target * 100).round();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: DSColors.warmIvory,
        borderRadius: BorderRadius.circular(DSRadius.card),
        border: Border.all(color: DSColors.softBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (subject.code != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: subjectColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(DSRadius.sm),
                            ),
                            child: Text(
                              subject.code!,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: subjectColor,
                              ),
                            ),
                          ),
                        Text(
                          '${subject.credits} Credits • ${subject.hoursPerWeek} hrs/wk',
                          style: GoogleFonts.inter(fontSize: 12, color: DSColors.charcoal.withValues(alpha: 0.6)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subject.name,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: DSColors.charcoal,
                      ),
                    ),
                    if (subject.instructor != null)
                      Text(
                        'Instructor: ${subject.instructor}',
                        style: GoogleFonts.inter(fontSize: 12, color: DSColors.charcoal.withValues(alpha: 0.65)),
                      ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_horiz),
                onSelected: (val) {
                  if (val == 'edit') {
                    _showAddSubjectDialog(subject);
                  } else if (val == 'delete') {
                    _deleteSubject(subject);
                  }
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit Subject')),
                  const PopupMenuItem(value: 'delete', child: Text('Delete Subject')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Syllabus Mastery: $progressPct%',
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: DSColors.charcoal),
              ),
              Text(
                'Target: $targetPct%',
                style: GoogleFonts.inter(fontSize: 12, color: DSColors.charcoal.withValues(alpha: 0.6)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(DSRadius.sm),
            child: LinearProgressIndicator(
              value: subject.progress,
              minHeight: 7,
              backgroundColor: Colors.black12,
              valueColor: AlwaysStoppedAnimation<Color>(subjectColor),
            ),
          ),
          if (subject.syllabus != null && subject.syllabus!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Key Topics: ${subject.syllabus}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(fontSize: 11, color: DSColors.charcoal.withValues(alpha: 0.65)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUpcomingAssignmentsCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: DSColors.paperWhite,
        borderRadius: BorderRadius.circular(DSRadius.card),
        border: Border.all(color: DSColors.softBorder),
        boxShadow: DSShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.assignment, size: 18, color: DSColors.deepForestGreen),
                  const SizedBox(width: 8),
                  Text(
                    'Upcoming Deadlines',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: DSColors.deepForestGreen,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.add, size: 20),
                onPressed: () => _showAddAssignmentDialog(),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (_assignments.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'No assignments due. All caught up!',
                  style: GoogleFonts.inter(fontSize: 13, color: DSColors.charcoal.withValues(alpha: 0.6)),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _assignments.take(5).length,
              separatorBuilder: (_, __) => const Divider(height: 18, color: DSColors.softBorder),
              itemBuilder: (ctx, i) {
                final a = _assignments[i];
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: a.isCompleted,
                      activeColor: DSColors.deepForestGreen,
                      onChanged: (_) => _toggleAssignmentStatus(a),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            a.title,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: a.isCompleted ? DSColors.charcoal.withValues(alpha: 0.4) : DSColors.charcoal,
                              decoration: a.isCompleted ? TextDecoration.lineThrough : null,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              if (a.dueDate != null)
                                Text(
                                  'Due: ${a.dueDate}',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: a.priority == 'High' ? Colors.red.shade700 : DSColors.charcoal.withValues(alpha: 0.6),
                                    fontWeight: a.priority == 'High' ? FontWeight.w600 : FontWeight.normal,
                                  ),
                                ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: a.priority == 'High'
                                      ? Colors.red.shade50
                                      : DSColors.warmIvory,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  a.priority,
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    color: a.priority == 'High' ? Colors.red.shade800 : DSColors.charcoal,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildStudyGoalsCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: DSColors.paperWhite,
        borderRadius: BorderRadius.circular(DSRadius.card),
        border: Border.all(color: DSColors.softBorder),
        boxShadow: DSShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.flag_outlined, size: 18, color: DSColors.deepForestGreen),
                  const SizedBox(width: 8),
                  Text(
                    'Academic & Exam Goals',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: DSColors.deepForestGreen,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.add, size: 20),
                onPressed: () => _showAddGoalDialog(),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (_goals.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'Set target GPAs, exam scores, or research milestones.',
                  style: GoogleFonts.inter(fontSize: 13, color: DSColors.charcoal.withValues(alpha: 0.6)),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _goals.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (ctx, i) {
                final g = _goals[i];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            g.title,
                            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: DSColors.charcoal),
                          ),
                        ),
                        Text(
                          '${g.percent}%',
                          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: DSColors.deepForestGreen),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: g.progress,
                        minHeight: 6,
                        backgroundColor: DSColors.warmIvory,
                        valueColor: const AlwaysStoppedAnimation<Color>(DSColors.deepForestGreen),
                      ),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildRecommendedTextbooksSection() {
    return BlocBuilder<HomeBloc, HomeState>(
      builder: (context, state) {
        List<Book> books = [];
        if (state is HomeLoaded) {
          books = state.catalogBooks.isNotEmpty
              ? state.catalogBooks
              : state.featuredBooks;
        }

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: DSColors.paperWhite,
            borderRadius: BorderRadius.circular(DSRadius.card),
            border: Border.all(color: DSColors.softBorder),
            boxShadow: DSShadows.sm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.auto_stories, size: 20, color: DSColors.deepForestGreen),
                      const SizedBox(width: 10),
                      Text(
                        'Recommended Textbooks & Editions',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: DSColors.deepForestGreen,
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () => context.go('/browse'),
                    child: Text('Explore All', style: GoogleFonts.inter(color: DSColors.deepForestGreen, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (books.isEmpty)
                _buildStaticTextbookRow()
              else
                SizedBox(
                  height: 240,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: books.take(6).length,
                    separatorBuilder: (_, __) => const SizedBox(width: 16),
                    itemBuilder: (ctx, i) {
                      final b = books[i];
                      return Container(
                        width: 170,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: DSColors.warmIvory,
                          borderRadius: BorderRadius.circular(DSRadius.card),
                          border: Border.all(color: DSColors.softBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black12,
                                  borderRadius: BorderRadius.circular(8),
                                  image: b.coverUrl.isNotEmpty
                                      ? DecorationImage(
                                          image: NetworkImage(b.coverUrl),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                                ),
                                child: b.coverUrl.isEmpty
                                    ? const Center(child: Icon(Icons.book, size: 36, color: DSColors.deepForestGreen))
                                    : null,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              b.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: DSColors.charcoal),
                            ),
                            Text(
                              b.author,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(fontSize: 11, color: DSColors.charcoal.withValues(alpha: 0.65)),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '₹${b.price.toStringAsFixed(0)}',
                                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: DSColors.deepForestGreen),
                                ),
                                GestureDetector(
                                  onTap: () => context.push('/book/${b.id}'),
                                  child: const Text('Rent', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: DSColors.mutedTerracotta)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStaticTextbookRow() {
    final defaultBooks = [
      {'title': 'Designing Data-Intensive Applications', 'author': 'Martin Kleppmann', 'tag': 'CS501 Core'},
      {'title': 'Deep Learning with PyTorch', 'author': 'Eli Stevens', 'tag': 'CS502 Match'},
      {'title': 'Compilers: Principles & Techniques', 'author': 'Aho, Ullman (Dragon Book)', 'tag': 'CS504 Essential'},
    ];

    return Row(
      children: defaultBooks.map((b) {
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 6),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: DSColors.warmIvory,
              borderRadius: BorderRadius.circular(DSRadius.card),
              border: Border.all(color: DSColors.softBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: DSColors.deepForestGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    b['tag']!,
                    style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: DSColors.deepForestGreen),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  b['title']!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.playfairDisplay(fontSize: 14, fontWeight: FontWeight.bold, color: DSColors.charcoal),
                ),
                const SizedBox(height: 4),
                Text(
                  b['author']!,
                  style: GoogleFonts.inter(fontSize: 11, color: DSColors.charcoal.withValues(alpha: 0.65)),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => context.go('/browse'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DSColors.deepForestGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Search in Library', style: TextStyle(fontSize: 11)),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ─── TAB 2: PLANNER ────────────────────────────────────────────────────────

  Widget _buildPlannerTab() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: DSColors.paperWhite,
        borderRadius: BorderRadius.circular(DSRadius.card),
        border: Border.all(color: DSColors.softBorder),
        boxShadow: DSShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Academic Study Planner',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: DSColors.deepForestGreen,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Time-blocked revision sessions synchronized with your semester curriculum.',
                    style: GoogleFonts.inter(fontSize: 13, color: DSColors.charcoal.withValues(alpha: 0.7)),
                  ),
                ],
              ),
              DSButton.primary(
                text: 'Schedule Session',
                icon: Icons.add,
                onPressed: () => _showScheduleSessionDialog(),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (_schedule.isEmpty)
            DSEmptyState(
              icon: Icons.event_note,
              title: 'Your Planner Is Clean',
              description: 'Create time-blocked study blocks to master complex topics before exams.',
              actionLabel: 'Schedule First Session',
              onAction: () => _showScheduleSessionDialog(),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _schedule.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (ctx, i) => _buildScheduleItemCard(_schedule[i]),
            ),
        ],
      ),
    );
  }

  // ─── TAB 3: SUBJECTS ───────────────────────────────────────────────────────

  Widget _buildSubjectsTab() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: DSColors.paperWhite,
        borderRadius: BorderRadius.circular(DSRadius.card),
        border: Border.all(color: DSColors.softBorder),
        boxShadow: DSShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Curriculum & Syllabus Mastery',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: DSColors.deepForestGreen,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Track individual subject targets, credits, and key syllabus concepts.',
                    style: GoogleFonts.inter(fontSize: 13, color: DSColors.charcoal.withValues(alpha: 0.7)),
                  ),
                ],
              ),
              DSButton.primary(
                text: 'Add Subject',
                icon: Icons.add,
                onPressed: () => _showAddSubjectDialog(),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (_subjects.isEmpty)
            DSEmptyState(
              icon: Icons.library_books,
              title: 'No Subjects Configured',
              description: 'Add your semester subjects to start tracking topic mastery.',
              actionLabel: 'Add Subject',
              onAction: () => _showAddSubjectDialog(),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _subjects.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (ctx, i) => _buildSubjectCard(_subjects[i]),
            ),
        ],
      ),
    );
  }

  // ─── TAB 4: ASSIGNMENTS ────────────────────────────────────────────────────

  Widget _buildAssignmentsTab() {
    final filtered = _assignments.where((a) {
      if (_assignmentFilter == 'Pending') return !a.isCompleted;
      if (_assignmentFilter == 'Completed') return a.isCompleted;
      if (_assignmentFilter == 'High Priority') return a.priority == 'High';
      return true;
    }).toList();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: DSColors.paperWhite,
        borderRadius: BorderRadius.circular(DSRadius.card),
        border: Border.all(color: DSColors.softBorder),
        boxShadow: DSShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Assignments & Deadlines',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: DSColors.deepForestGreen,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Stay ahead of submission dates, problem sets, and lab evaluations.',
                    style: GoogleFonts.inter(fontSize: 13, color: DSColors.charcoal.withValues(alpha: 0.7)),
                  ),
                ],
              ),
              DSButton.primary(
                text: 'Add Assignment',
                icon: Icons.add,
                onPressed: () => _showAddAssignmentDialog(),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['All', 'Pending', 'High Priority', 'Completed'].map((f) {
                final isSel = _assignmentFilter == f;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(f),
                    selected: isSel,
                    onSelected: (val) {
                      if (val) setState(() => _assignmentFilter = f);
                    },
                    selectedColor: DSColors.deepForestGreen,
                    backgroundColor: DSColors.warmIvory,
                    labelStyle: TextStyle(color: isSel ? Colors.white : DSColors.charcoal),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),
          if (filtered.isEmpty)
            DSEmptyState(
              icon: Icons.assignment_turned_in,
              title: 'No Assignments in this View',
              description: 'You have no assignments matching this filter.',
              actionLabel: 'Add Assignment',
              onAction: () => _showAddAssignmentDialog(),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (ctx, i) {
                final a = filtered[i];
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: a.isCompleted ? DSColors.warmIvory.withValues(alpha: 0.6) : DSColors.warmIvory,
                    borderRadius: BorderRadius.circular(DSRadius.card),
                    border: Border.all(color: DSColors.softBorder),
                  ),
                  child: Row(
                    children: [
                      Checkbox(
                        value: a.isCompleted,
                        activeColor: DSColors.deepForestGreen,
                        onChanged: (_) => _toggleAssignmentStatus(a),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              a.title,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: a.isCompleted ? DSColors.charcoal.withValues(alpha: 0.5) : DSColors.charcoal,
                                decoration: a.isCompleted ? TextDecoration.lineThrough : null,
                              ),
                            ),
                            if (a.description != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                a.description!,
                                style: GoogleFonts.inter(fontSize: 12, color: DSColors.charcoal.withValues(alpha: 0.65)),
                              ),
                            ],
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                if (a.dueDate != null)
                                  Text(
                                    'Due: ${a.dueDate}',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: a.priority == 'High' ? Colors.red.shade700 : DSColors.charcoal.withValues(alpha: 0.6),
                                      fontWeight: a.priority == 'High' ? FontWeight.w600 : FontWeight.normal,
                                    ),
                                  ),
                                const SizedBox(width: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: a.priority == 'High' ? Colors.red.shade50 : Colors.white,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: DSColors.softBorder),
                                  ),
                                  child: Text(
                                    a.priority,
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: a.priority == 'High' ? Colors.red.shade800 : DSColors.charcoal,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, size: 18),
                        onSelected: (val) {
                          if (val == 'edit') {
                            _showAddAssignmentDialog(a);
                          } else if (val == 'delete') {
                            _deleteAssignment(a);
                          }
                        },
                        itemBuilder: (ctx) => [
                          const PopupMenuItem(value: 'edit', child: Text('Edit')),
                          const PopupMenuItem(value: 'delete', child: Text('Delete')),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // ─── TAB 5: GOALS ──────────────────────────────────────────────────────────

  Widget _buildGoalsTab() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: DSColors.paperWhite,
        borderRadius: BorderRadius.circular(DSRadius.card),
        border: Border.all(color: DSColors.softBorder),
        boxShadow: DSShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Academic Goals & Exam Targets',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: DSColors.deepForestGreen,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Set and track major milestones, target GPAs, and competitive exam preparation.',
                    style: GoogleFonts.inter(fontSize: 13, color: DSColors.charcoal.withValues(alpha: 0.7)),
                  ),
                ],
              ),
              DSButton.primary(
                text: 'New Goal',
                icon: Icons.add,
                onPressed: () => _showAddGoalDialog(),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (_goals.isEmpty)
            DSEmptyState(
              icon: Icons.flag,
              title: 'No Academic Goals Recorded',
              description: 'Create long-term targets to stay inspired throughout the academic year.',
              actionLabel: 'Create Goal',
              onAction: () => _showAddGoalDialog(),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _goals.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (ctx, i) {
                final g = _goals[i];
                return Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: DSColors.warmIvory,
                    borderRadius: BorderRadius.circular(DSRadius.card),
                    border: Border.all(color: DSColors.softBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: DSColors.deepForestGreen.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(DSRadius.sm),
                                ),
                                child: Text(
                                  g.category.toUpperCase(),
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: DSColors.deepForestGreen,
                                  ),
                                ),
                              ),
                              if (g.targetDate != null) ...[
                                const SizedBox(width: 8),
                                Text(
                                  'Target: ${g.targetDate}',
                                  style: GoogleFonts.inter(fontSize: 11, color: DSColors.charcoal.withValues(alpha: 0.6)),
                                ),
                              ],
                            ],
                          ),
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_horiz),
                            onSelected: (val) {
                              if (val == 'edit') {
                                _showAddGoalDialog(g);
                              } else if (val == 'delete') {
                                _deleteGoal(g);
                              }
                            },
                            itemBuilder: (ctx) => [
                              const PopupMenuItem(value: 'edit', child: Text('Edit')),
                              const PopupMenuItem(value: 'delete', child: Text('Delete')),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        g.title,
                        style: GoogleFonts.playfairDisplay(fontSize: 16, fontWeight: FontWeight.bold, color: DSColors.charcoal),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Progress: ${g.percent}%', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                          Text(g.status, style: GoogleFonts.inter(fontSize: 12, color: DSColors.deepForestGreen, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(DSRadius.sm),
                        child: LinearProgressIndicator(
                          value: g.progress,
                          minHeight: 8,
                          backgroundColor: Colors.black12,
                          valueColor: const AlwaysStoppedAnimation<Color>(DSColors.deepForestGreen),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
