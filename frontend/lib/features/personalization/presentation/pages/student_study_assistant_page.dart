import '../../../../core/design_system/tokens/ds_colors.dart';
import '../../../../core/design_system/tokens/ds_radius.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:libri_flow/core/services/api_service.dart';

class StudentStudyAssistantPage extends StatefulWidget {
  const StudentStudyAssistantPage({super.key});

  @override
  State<StudentStudyAssistantPage> createState() => _StudentStudyAssistantPageState();
}

class StudyTopicModule {
  final String id;
  final String title;
  final List<String> bulletPoints;
  bool isCompleted;

  StudyTopicModule({
    required this.id,
    required this.title,
    required this.bulletPoints,
    this.isCompleted = false,
  });
}

class _StudentStudyAssistantPageState extends State<StudentStudyAssistantPage> {
  final TextEditingController _queryController = TextEditingController();
  String _activeAction = 'Explain Concept';
  bool _isLoading = false;
  String? _rawResponseOutput;

  // Parsed structured data
  String _breakdownTitle = 'Study Breakdown';
  List<StudyTopicModule> _studyModules = [];
  String? _examTip;
  String? _additionalNotes;

  // Quick action presets
  final List<String> _quickActions = [
    '💡 Explain Concept',
    '❓ Generate Quiz',
    '📇 Flashcards',
    '📝 Exam Prep',
    '📅 Study Plan',
  ];

  // Focus & Target Completion Timer state
  Timer? _timer;
  int _timerPresetMinutes = 25;
  int _timerTotalSeconds = 25 * 60;
  int _timerSecondsRemaining = 25 * 60;
  bool _isTimerRunning = false;
  bool _isTimerCompleted = false;

  @override
  void initState() {
    super.initState();
    _queryController.text = 'Explain Database Normalization (1NF, 2NF, 3NF, BCNF)';
    // Automatically generate initial breakdown so page opens with rich content
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleAsk();
    });
  }

  @override
  void dispose() {
    _queryController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _handleAsk([String? customPrompt]) async {
    final queryText = customPrompt ?? _queryController.text.trim();
    if (queryText.isEmpty) return;

    setState(() {
      _isLoading = true;
      _rawResponseOutput = null;
      _studyModules = [];
      _examTip = null;
      _additionalNotes = null;
    });

    final formattedQuery = "[$_activeAction] $queryText";
    final result = await ApiService.askStudyAssistant(formattedQuery);

    if (!mounted) return;

    _parseResponseToModules(result);

    setState(() {
      _isLoading = false;
      _rawResponseOutput = result;
    });
  }

  void _parseResponseToModules(String raw) {
    final lines = raw.split('\n');
    String title = 'Study Breakdown & Concept Notes';
    final List<StudyTopicModule> modules = [];
    String? tip;
    final List<String> otherLines = [];

    StudyTopicModule? currentModule;
    int moduleCounter = 1;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      // Extract main header
      if (i == 0 || line.startsWith('📚') || line.startsWith('📇') || line.startsWith('#')) {
        title = _stripMarkdown(line);
        continue;
      }

      // Extract Exam Tip or summary callouts
      if (line.startsWith('💡') || line.toLowerCase().contains('exam tip') || line.toLowerCase().contains('pro tip')) {
        tip = line.replaceFirst(RegExp(r'^[💡\s*#]+'), '').trim();
        continue;
      }

      // Numbered items: 1. **1NF (First Normal Form)**: or 1. Topic...
      final isNumberedStart = RegExp(r'^\d+[\.\)]').hasMatch(line) || (line.startsWith('• **Card') || line.startsWith('**'));

      if (isNumberedStart && (line.contains('**') || line.contains(':'))) {
        if (currentModule != null) {
          modules.add(currentModule);
        }

        String itemTitle = _stripMarkdown(line);
        itemTitle = itemTitle
            .replaceFirst(RegExp(r'^[•\-\*\d\.\)\s]+'), '')
            .trim()
            .replaceFirst(RegExp(r':$'), '')
            .trim();

        currentModule = StudyTopicModule(
          id: 'mod_${moduleCounter++}',
          title: itemTitle.isEmpty ? 'Topic $moduleCounter' : itemTitle,
          bulletPoints: [],
          isCompleted: false,
        );
      } else if (line.startsWith('•') || line.startsWith('-') || line.startsWith('*')) {
        final cleanPoint = line.replaceFirst(RegExp(r'^[•\-\*]\s*'), '').trim();
        if (currentModule != null) {
          currentModule.bulletPoints.add(cleanPoint);
        } else {
          otherLines.add(cleanPoint);
        }
      } else {
        final trimmed = line.trim();
        if (currentModule != null) {
          currentModule.bulletPoints.add(trimmed);
        } else {
          otherLines.add(trimmed);
        }
      }
    }

    if (currentModule != null) {
      modules.add(currentModule);
    }

    // Fallback if no numbered modules parsed
    if (modules.isEmpty && raw.isNotEmpty) {
      final paragraphs = raw.split('\n\n').where((p) => p.trim().isNotEmpty).toList();
      for (int i = 0; i < paragraphs.length; i++) {
        final p = paragraphs[i].trim();
        if (p.startsWith('💡') || p.toLowerCase().contains('exam tip')) {
          tip = _stripMarkdown(p);
        } else {
          final pLines = p.split('\n');
          final modTitle = _stripMarkdown(pLines.first)
              .replaceFirst(RegExp(r'^[•\-\*\d\.\)\s]+'), '')
              .trim()
              .replaceFirst(RegExp(r':$'), '')
              .trim();
          modules.add(
            StudyTopicModule(
              id: 'mod_${i + 1}',
              title: modTitle.isEmpty ? 'Module ${i + 1}' : modTitle,
              bulletPoints: pLines
                  .skip(1)
                  .map((l) => l.replaceFirst(RegExp(r'^[•\-\*]\s*'), '').trim())
                  .where((l) => l.isNotEmpty)
                  .toList(),
              isCompleted: false,
            ),
          );
        }
      }
    }

    _breakdownTitle = title;
    _studyModules = modules;
    _examTip = tip;
    if (otherLines.isNotEmpty) {
      _additionalNotes = otherLines.join('\n');
    }
  }

  String _stripMarkdown(String text) {
    return text
        .replaceAllMapped(RegExp(r'\*\*([^*]+)\*\*'), (m) => m[1] ?? '')
        .replaceAllMapped(RegExp(r'\*([^*]+)\*'), (m) => m[1] ?? '')
        .replaceAll(RegExp(r'^#+\s*'), '')
        .trim();
  }

  // Professional Target Completion Timer controls
  void _setTimerPreset(int minutes) {
    _timer?.cancel();
    setState(() {
      _isTimerRunning = false;
      _timerPresetMinutes = minutes;
      _timerTotalSeconds = minutes * 60;
      _timerSecondsRemaining = minutes * 60;
      _isTimerCompleted = false;
    });
  }

  void _addExtraTime(int minutes) {
    setState(() {
      _timerTotalSeconds += minutes * 60;
      _timerSecondsRemaining += minutes * 60;
      _isTimerCompleted = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('⏳ Added +$minutes minutes to your focus session!'),
        duration: const Duration(seconds: 2),
        backgroundColor: DSColors.deepForestGreen,
      ),
    );
  }

  void _toggleTimer() {
    if (_isTimerRunning) {
      _timer?.cancel();
      setState(() => _isTimerRunning = false);
    } else {
      if (_timerSecondsRemaining <= 0) {
        _timerSecondsRemaining = _timerTotalSeconds;
        _isTimerCompleted = false;
      }
      setState(() => _isTimerRunning = true);
      _timer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (_timerSecondsRemaining > 0) {
          setState(() => _timerSecondsRemaining--);
        } else {
          t.cancel();
          HapticFeedback.heavyImpact();
          setState(() {
            _isTimerRunning = false;
            _isTimerCompleted = true;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('🎉 Target study time is up! Take a 5-minute break to recharge.'),
                backgroundColor: DSColors.secondaryGreen,
                duration: Duration(seconds: 4),
              ),
            );
          }
        }
      });
    }
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _isTimerRunning = false;
      _isTimerCompleted = false;
      _timerSecondsRemaining = _timerTotalSeconds;
    });
  }

  String _formatTimerTime(int totalSeconds) {
    final m = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final sp = ApiService.studentProfileData;
    final course = sp?['course'] ?? 'Computer Science';
    final examGoal = sp?['exam_goal'] ?? 'Semester Exams';

    final totalModules = _studyModules.length;
    final completedCount = _studyModules.where((m) => m.isCompleted).length;
    final progress = totalModules > 0 ? (completedCount / totalModules) : 0.0;

    return Scaffold(
      backgroundColor: DSColors.warmIvory,
      appBar: AppBar(
        backgroundColor: DSColors.deepForestGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'AI Study Assistant & Planner',
          style: GoogleFonts.playfairDisplay(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        actions: [
          // Dynamic Timer Header Pill
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            decoration: BoxDecoration(
              color: _isTimerRunning ? DSColors.antiqueGold : Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: _toggleTimer,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isTimerRunning ? Icons.timer : Icons.timer_outlined,
                        size: 15,
                        color: _isTimerRunning ? Colors.black87 : Colors.white,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        _formatTimerTime(_timerSecondsRemaining),
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _isTimerRunning ? Colors.black87 : Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Timer Options',
            icon: const Icon(Icons.tune, size: 20),
            onPressed: _showTimerDialog,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Context Banner
                  _buildContextBanner(course, examGoal),
                  const SizedBox(height: 16),

                  // 2. Action Selector Chips
                  _buildActionSelector(),
                  const SizedBox(height: 16),

                  // 3. Query Input Field & Generate Button
                  _buildQueryInput(),
                  const SizedBox(height: 20),

                  // 4. Professional Student Focus & Milestone Timer Card
                  _buildProfessionalStudentTimerCard(completedCount, totalModules),
                  const SizedBox(height: 20),

                  // 5. Loading State
                  if (_isLoading) _buildLoadingCard(),

                  // 6. Rich Study Planner & Breakdown Output
                  if (!_isLoading && _studyModules.isNotEmpty) ...[
                    // Progress & Planner Dashboard Card
                    _buildStudyPlannerProgressCard(completedCount, totalModules, progress),
                    const SizedBox(height: 16),

                    // Study Module Checklist Cards
                    ..._studyModules.map((module) => _buildModuleChecklistCard(module)),

                    // Exam Tip / Pro Tip Highlight
                    if (_examTip != null) ...[
                      const SizedBox(height: 8),
                      _buildExamTipCard(_examTip!),
                    ],

                    // Additional Notes
                    if (_additionalNotes != null && _additionalNotes!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _buildAdditionalNotesCard(_additionalNotes!),
                    ],

                    const SizedBox(height: 20),

                    // Quick Study Tools Toolbar (Add to Plan, Copy, Quiz)
                    _buildActionToolbar(),
                  ],

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- Context Banner ---
  Widget _buildContextBanner(String course, String examGoal) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: DSColors.warmIvory,
        borderRadius: BorderRadius.circular(DSRadius.card),
        border: Border.all(color: DSColors.softBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: DSColors.deepForestGreen,
              borderRadius: BorderRadius.circular(DSRadius.md),
            ),
            child: const Icon(Icons.school_outlined, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Academic Context • $course',
                  style: GoogleFonts.inter(
                    color: DSColors.deepForestGreen,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                Text(
                  'Target Goal: $examGoal',
                  style: GoogleFonts.inter(
                    color: DSColors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: DSColors.warmIvory,
              borderRadius: BorderRadius.circular(DSRadius.sm),
              border: Border.all(color: DSColors.antiqueGold),
            ),
            child: Text(
              '🎓 Pro Assistant',
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: DSColors.antiqueGold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Learning Action Selector ---
  Widget _buildActionSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose Learning Mode',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: DSColors.charcoal,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _quickActions.map((action) {
            final cleanName = action.replaceAll(RegExp(r'^[^\w]+'), '').trim();
            final isSelected = _activeAction == cleanName;
            return ChoiceChip(
              label: Text(action),
              selected: isSelected,
              selectedColor: DSColors.deepForestGreen,
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(DSRadius.md),
                side: BorderSide(
                  color: isSelected ? DSColors.deepForestGreen : DSColors.softBorder,
                ),
              ),
              labelStyle: GoogleFonts.inter(
                color: isSelected ? Colors.white : DSColors.textLight,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 12,
              ),
              onSelected: (selected) {
                if (selected) {
                  setState(() => _activeAction = cleanName);
                  _handleAsk();
                }
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  // --- Query Input & Button ---
  Widget _buildQueryInput() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DSColors.softBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: _queryController,
            maxLines: 2,
            style: GoogleFonts.inter(fontSize: 14, color: DSColors.charcoal),
            decoration: InputDecoration(
              hintText: 'Enter topic or question (e.g. "Explain B-Trees in DBMS")',
              hintStyle: GoogleFonts.inter(color: DSColors.textMuted, fontSize: 13),
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : () => _handleAsk(),
              icon: const Icon(Icons.auto_awesome, size: 16),
              label: Text(
                'Generate Interactive Study Plan',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: DSColors.deepForestGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DSRadius.md)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Professional Student Focus & Target Completion Timer Card ---
  Widget _buildProfessionalStudentTimerCard(int completedCount, int totalModules) {
    final elapsedSeconds = (_timerTotalSeconds - _timerSecondsRemaining).clamp(0, _timerTotalSeconds);
    final timerProgress = _timerTotalSeconds > 0
        ? (elapsedSeconds / _timerTotalSeconds).clamp(0.0, 1.0)
        : 0.0;
    final allModulesDone = totalModules > 0 && completedCount == totalModules;

    Color statusColor = DSColors.textLight;
    String statusLabel = 'Standby';
    IconData statusIcon = Icons.hourglass_empty;

    if (_isTimerCompleted) {
      statusColor = DSColors.error;
      statusLabel = 'Time Expired';
      statusIcon = Icons.alarm_off;
    } else if (_isTimerRunning) {
      statusColor = DSColors.secondaryGreen;
      statusLabel = 'Focus Active';
      statusIcon = Icons.bolt;
    } else if (elapsedSeconds > 0) {
      statusColor = DSColors.antiqueGold;
      statusLabel = 'Paused';
      statusIcon = Icons.pause_circle_outline;
    }

    final clockWidget = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _formatTimerTime(_timerSecondsRemaining),
          style: GoogleFonts.playfairDisplay(
            fontSize: 34,
            fontWeight: FontWeight.bold,
            color: _timerSecondsRemaining <= 60 && _timerSecondsRemaining > 0
                ? DSColors.error
                : DSColors.deepForestGreen,
            letterSpacing: 1.5,
          ),
        ),
        Text(
          _isTimerCompleted
              ? 'Session target elapsed'
              : '${(_timerSecondsRemaining ~/ 60)}m remaining of ${_timerPresetMinutes}m target',
          style: GoogleFonts.inter(
            fontSize: 11,
            color: DSColors.textMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );

    final buttonControls = Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        ElevatedButton.icon(
          onPressed: _toggleTimer,
          icon: Icon(
            _isTimerRunning ? Icons.pause : Icons.play_arrow,
            size: 16,
          ),
          label: Text(_isTimerRunning ? 'Pause' : (_isTimerCompleted ? 'Restart' : 'Start Focus')),
          style: ElevatedButton.styleFrom(
            backgroundColor: DSColors.deepForestGreen,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DSRadius.md)),
          ),
        ),
        OutlinedButton(
          onPressed: () => _addExtraTime(5),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DSRadius.md)),
            side: const BorderSide(color: DSColors.softBorder),
          ),
          child: Text(
            '+5m',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: DSColors.deepForestGreen,
            ),
          ),
        ),
        IconButton(
          tooltip: 'Reset Timer',
          onPressed: _resetTimer,
          icon: const Icon(Icons.refresh, size: 20, color: DSColors.textMuted),
        ),
      ],
    );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(DSRadius.card),
        border: Border.all(
          color: _isTimerRunning ? DSColors.deepForestGreen : DSColors.softBorder,
          width: _isTimerRunning ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: _isTimerRunning
                ? DSColors.deepForestGreen.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.02),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Icon, Title, Status Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _isTimerRunning ? DSColors.warmIvory : DSColors.warmIvory,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _isTimerRunning ? DSColors.success : DSColors.softBorder,
                        ),
                      ),
                      child: Icon(
                        Icons.timer_outlined,
                        color: _isTimerRunning ? DSColors.deepForestGreen : DSColors.textMuted,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Target Study Session Timer',
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: DSColors.deepForestGreen,
                            ),
                          ),
                          Text(
                            'Complete all modules within target time window',
                            style: GoogleFonts.inter(fontSize: 11, color: DSColors.textMuted),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 13, color: statusColor),
                    const SizedBox(width: 4),
                    Text(
                      statusLabel,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Preset Chips Row: 15m, 25m, 45m, 60m
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Target Duration:',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: DSColors.textLight,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _buildPresetChip(15, '15m Sprint'),
                    _buildPresetChip(25, '25m Pomodoro'),
                    _buildPresetChip(45, '45m Deep Work'),
                    _buildPresetChip(60, '60m Exam Prep'),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Main Timer Display Area
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: DSColors.warmIvory,
              borderRadius: BorderRadius.circular(DSRadius.card),
              border: Border.all(color: DSColors.softBorder),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 460) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      clockWidget,
                      const SizedBox(height: 12),
                      buttonControls,
                    ],
                  );
                }
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    clockWidget,
                    buttonControls,
                  ],
                );
              },
            ),
          ),

          const SizedBox(height: 12),

          // Linear Progress Indicator for Elapsed Session
          ClipRRect(
            borderRadius: BorderRadius.circular(DSRadius.sm),
            child: LinearProgressIndicator(
              value: timerProgress,
              backgroundColor: DSColors.softBorder,
              color: _isTimerCompleted
                  ? DSColors.error
                  : _timerProgressToColor(timerProgress),
              minHeight: 6,
            ),
          ),

          const SizedBox(height: 12),

          // Milestone target link to study modules
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: allModulesDone ? DSColors.warmIvory : DSColors.warmIvory,
              borderRadius: BorderRadius.circular(DSRadius.md),
              border: Border.all(
                color: allModulesDone ? DSColors.softBorder : DSColors.softBorder,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  allModulesDone ? Icons.check_circle : Icons.flag_outlined,
                  size: 15,
                  color: allModulesDone ? DSColors.secondaryGreen : DSColors.textLight,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    totalModules > 0
                        ? (allModulesDone
                            ? '🏆 Goal Achieved! Mastered all $totalModules topics before deadline!'
                            : 'Target: Complete all $totalModules topics before timer runs out ($completedCount completed)')
                        : 'Generate topics below to link your checklist with this focus timer.',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: allModulesDone ? FontWeight.bold : FontWeight.w500,
                      color: allModulesDone ? DSColors.secondaryGreen : DSColors.textLight,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _timerProgressToColor(double progress) {
    if (progress < 0.6) return DSColors.deepForestGreen;
    if (progress < 0.85) return DSColors.antiqueGold;
    return DSColors.accentTerracotta;
  }

  Widget _buildPresetChip(int minutes, String label) {
    final isSelected = _timerPresetMinutes == minutes;
    return InkWell(
      onTap: () => _setTimerPreset(minutes),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? DSColors.deepForestGreen : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? DSColors.deepForestGreen : DSColors.softBorder,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : DSColors.textLight,
          ),
        ),
      ),
    );
  }

  // --- Loading Card ---
  Widget _buildLoadingCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DSColors.softBorder),
      ),
      child: Column(
        children: [
          const CircularProgressIndicator(color: DSColors.deepForestGreen, strokeWidth: 3),
          const SizedBox(height: 16),
          Text(
            'Crafting structured study plan...',
            style: GoogleFonts.playfairDisplay(fontSize: 16, fontWeight: FontWeight.bold, color: DSColors.deepForestGreen),
          ),
          const SizedBox(height: 4),
          Text(
            'Analyzing concepts, milestones, and exam checkpoints',
            style: GoogleFonts.inter(fontSize: 12, color: DSColors.textMuted),
          ),
        ],
      ),
    );
  }

  // --- Study Planner Progress Dashboard ---
  Widget _buildStudyPlannerProgressCard(int completed, int total, double progress) {
    final isAllDone = total > 0 && completed == total;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(DSRadius.card),
        border: Border.all(color: DSColors.softBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  _breakdownTitle,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: DSColors.deepForestGreen,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isAllDone ? DSColors.softBorder : DSColors.warmIvory,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isAllDone ? DSColors.success : DSColors.softBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isAllDone ? Icons.check_circle : Icons.trending_up,
                      size: 13,
                      color: isAllDone ? DSColors.secondaryGreen : DSColors.deepForestGreen,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isAllDone ? 'Mastered 🎉' : '$completed of $total Done (${(progress * 100).toInt()}%)',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isAllDone ? DSColors.secondaryGreen : DSColors.deepForestGreen,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(DSRadius.sm),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: DSColors.softBorder,
              color: isAllDone ? DSColors.success : DSColors.deepForestGreen,
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 14),
          // Quick actions on study plan
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Track your learning progress:',
                style: GoogleFonts.inter(fontSize: 11, color: DSColors.textMuted),
              ),
              Row(
                children: [
                  InkWell(
                    onTap: () {
                      setState(() {
                        for (var m in _studyModules) {
                          m.isCompleted = true;
                        }
                      });
                    },
                    child: Text(
                      'Mark All Done',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: DSColors.deepForestGreen,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  InkWell(
                    onTap: () {
                      setState(() {
                        for (var m in _studyModules) {
                          m.isCompleted = false;
                        }
                      });
                    },
                    child: Text(
                      'Reset',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: DSColors.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- Interactive Module Card with Checkbox ---
  Widget _buildModuleChecklistCard(StudyTopicModule module) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: module.isCompleted ? DSColors.paperWhite : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: module.isCompleted ? DSColors.softBorder : DSColors.softBorder,
          width: module.isCompleted ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            setState(() {
              module.isCompleted = !module.isCompleted;
            });
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Custom Checkbox
                Transform.scale(
                  scale: 1.1,
                  child: Checkbox(
                    value: module.isCompleted,
                    activeColor: DSColors.deepForestGreen,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DSRadius.sm)),
                    onChanged: (val) {
                      setState(() {
                        module.isCompleted = val ?? false;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                // Module Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              module.title,
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                decoration: module.isCompleted ? TextDecoration.lineThrough : null,
                                color: module.isCompleted ? DSColors.textMuted : DSColors.deepForestGreen,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: module.isCompleted ? DSColors.softBorder : DSColors.softBorder,
                              borderRadius: BorderRadius.circular(DSRadius.sm),
                            ),
                            child: Text(
                              module.isCompleted ? 'Done ✓' : 'To Learn',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: module.isCompleted ? DSColors.secondaryGreen : DSColors.textLight,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (module.bulletPoints.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        ...module.bulletPoints.map(
                          (point) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  margin: const EdgeInsets.only(top: 6),
                                  width: 5,
                                  height: 5,
                                  decoration: BoxDecoration(
                                    color: module.isCompleted ? DSColors.textMuted : DSColors.antiqueGold,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _renderFormattedText(
                                    point,
                                    isStrikethrough: module.isCompleted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Formatted Rich Text without raw ** stars ---
  Widget _renderFormattedText(String text, {bool isStrikethrough = false}) {
    final List<TextSpan> spans = [];
    final RegExp boldPattern = RegExp(r'\*\*([^*]+)\*\*');
    int lastIndex = 0;

    for (final match in boldPattern.allMatches(text)) {
      if (match.start > lastIndex) {
        spans.add(
          TextSpan(
            text: text.substring(lastIndex, match.start),
            style: GoogleFonts.inter(
              fontSize: 13,
              color: isStrikethrough ? DSColors.textMuted : DSColors.textLight,
              decoration: isStrikethrough ? TextDecoration.lineThrough : null,
              height: 1.4,
            ),
          ),
        );
      }

      final boldContent = match.group(1) ?? '';
      spans.add(
        TextSpan(
          text: boldContent,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: isStrikethrough ? DSColors.textMuted : DSColors.deepForestGreen,
            decoration: isStrikethrough ? TextDecoration.lineThrough : null,
            height: 1.4,
          ),
        ),
      );

      lastIndex = match.end;
    }

    if (lastIndex < text.length) {
      spans.add(
        TextSpan(
          text: text.substring(lastIndex),
          style: GoogleFonts.inter(
            fontSize: 13,
            color: isStrikethrough ? DSColors.textMuted : DSColors.textLight,
            decoration: isStrikethrough ? TextDecoration.lineThrough : null,
            height: 1.4,
          ),
        ),
      );
    }

    return RichText(text: TextSpan(children: spans));
  }

  // --- Exam Tip Callout ---
  Widget _buildExamTipCard(String tip) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DSColors.warmIvory,
        borderRadius: BorderRadius.circular(DSRadius.card),
        border: Border.all(color: DSColors.antiqueGold),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('💡', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Key Exam Tip',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: DSColors.antiqueGold,
                  ),
                ),
                const SizedBox(height: 4),
                _renderFormattedText(tip),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Additional Notes Card ---
  Widget _buildAdditionalNotesCard(String notes) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(DSRadius.card),
        border: Border.all(color: DSColors.softBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Summary Notes',
            style: GoogleFonts.playfairDisplay(fontSize: 14, fontWeight: FontWeight.bold, color: DSColors.deepForestGreen),
          ),
          const SizedBox(height: 6),
          _renderFormattedText(notes),
        ],
      ),
    );
  }

  // --- Action Toolbar (Copy, Add to Plan, Self Quiz) ---
  Widget _buildActionToolbar() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(DSRadius.card),
        border: Border.all(color: DSColors.softBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Copy Clean Notes
          TextButton.icon(
            onPressed: () {
              if (_rawResponseOutput != null) {
                Clipboard.setData(ClipboardData(text: _stripMarkdown(_rawResponseOutput!)));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('📋 Study notes copied cleanly to clipboard!'),
                    backgroundColor: DSColors.deepForestGreen,
                  ),
                );
              }
            },
            icon: const Icon(Icons.copy, size: 16, color: DSColors.deepForestGreen),
            label: Text(
              'Copy Notes',
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: DSColors.deepForestGreen),
            ),
          ),
          Container(height: 20, width: 1, color: DSColors.softBorder),
          // Add to Study Plan
          TextButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('📅 Added "$_breakdownTitle" to your active Semester Plan!'),
                  backgroundColor: DSColors.secondaryGreen,
                ),
              );
            },
            icon: const Icon(Icons.bookmark_add_outlined, size: 16, color: DSColors.deepForestGreen),
            label: Text(
              'Save to Plan',
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: DSColors.deepForestGreen),
            ),
          ),
          Container(height: 20, width: 1, color: DSColors.softBorder),
          // Focus Timer Toggle
          TextButton.icon(
            onPressed: _showTimerDialog,
            icon: const Icon(Icons.timer_outlined, size: 16, color: DSColors.deepForestGreen),
            label: Text(
              '25m Timer',
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: DSColors.deepForestGreen),
            ),
          ),
        ],
      ),
    );
  }

  // --- Focus Timer Dialog ---
  void _showTimerDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  const Icon(Icons.timer, color: DSColors.deepForestGreen),
                  const SizedBox(width: 8),
                  Text(
                    'Study Focus Timer',
                    style: GoogleFonts.playfairDisplay(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Time-box this study session to finish modules before deadline.',
                    style: GoogleFonts.inter(fontSize: 12, color: DSColors.textMuted),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    alignment: WrapAlignment.center,
                    children: [15, 25, 45, 60].map((mins) {
                      final isSel = _timerPresetMinutes == mins;
                      return InkWell(
                        onTap: () {
                          _setTimerPreset(mins);
                          setDialogState(() {});
                          setState(() {});
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isSel ? DSColors.deepForestGreen : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSel ? DSColors.deepForestGreen : DSColors.softBorder,
                            ),
                          ),
                          child: Text(
                            '${mins}m',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                              color: isSel ? Colors.white : DSColors.textLight,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      color: DSColors.warmIvory,
                      shape: BoxShape.circle,
                      border: Border.all(color: DSColors.deepForestGreen, width: 3),
                    ),
                    child: Center(
                      child: Text(
                        _formatTimerTime(_timerSecondsRemaining),
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: DSColors.deepForestGreen,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          _toggleTimer();
                          setDialogState(() {});
                          setState(() {});
                        },
                        icon: Icon(_isTimerRunning ? Icons.pause : Icons.play_arrow, size: 18),
                        label: Text(_isTimerRunning ? 'Pause' : (_isTimerCompleted ? 'Restart' : 'Start Focus')),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: DSColors.deepForestGreen,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DSRadius.md)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: () {
                          _addExtraTime(5);
                          setDialogState(() {});
                          setState(() {});
                        },
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DSRadius.md)),
                        ),
                        child: const Text('+5m'),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: () {
                          _resetTimer();
                          setDialogState(() {});
                          setState(() {});
                        },
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DSRadius.md)),
                        ),
                        child: const Text('Reset'),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
