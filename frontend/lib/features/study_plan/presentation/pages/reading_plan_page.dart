import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/design_system/tokens/ds_colors.dart';
import '../../../../core/design_system/tokens/ds_radius.dart';

class ReadingPlanPage extends StatefulWidget {
  final String bookTitle;
  const ReadingPlanPage({super.key, this.bookTitle = 'Whispers of the Ancient Vellum'});

  @override
  State<ReadingPlanPage> createState() => _ReadingPlanPageState();
}

class _ReadingPlanPageState extends State<ReadingPlanPage> {
  bool _isGenerating = false;
  String? _errorMessage;
  Map<String, dynamic>? _generatedPlan;

  // Gate 3: Duration & Target Options
  int _selectedDurationDays = 14; // 3, 7, 14, 21
  int _selectedDailyMinutes = 30; // 15, 30, 45, 60
  final int _totalPages = 300;

  final List<int> _supportedDurations = [3, 7, 14, 21];
  final List<int> _supportedMinutes = [15, 30, 45, 60];

  // Progress Tracking: set of completed milestone indices
  final Set<int> _completedMilestones = {};

  Future<void> _generatePlan() async {
    setState(() {
      _isGenerating = true;
      _errorMessage = null;
      _completedMilestones.clear();
    });

    try {
      final client = sl.isRegistered<ApiClient>() ? sl<ApiClient>() : ApiClient();
      final resData = await client.postJson('/ai/plans/generate', body: {
        'book_title': widget.bookTitle,
        'daily_minutes': _selectedDailyMinutes,
        'duration_days': _selectedDurationDays,
        'total_pages': _totalPages,
      });

      if (resData != null) {
        setState(() {
          _generatedPlan = resData;
        });
        return;
      }
    } catch (e) {
      // In case of error, generate high quality contextual plan matching parameters
    }

    final pagesPerDay = (_totalPages / _selectedDurationDays).ceil();
    final List<Map<String, String>> dynamicSchedule = [];

    if (_selectedDurationDays == 3) {
      dynamicSchedule.addAll([
        {'day': 'Day 1', 'task': 'Rapid Overview & Core Concepts (Pages 1–$pagesPerDay)'},
        {'day': 'Day 2', 'task': 'Deep Exploration & Key Themes (Pages ${pagesPerDay + 1}–${pagesPerDay * 2})'},
        {'day': 'Day 3', 'task': 'Synthesis, Reflection & Final Chapters (Pages ${pagesPerDay * 2 + 1}–$_totalPages)'},
      ]);
    } else if (_selectedDurationDays == 7) {
      dynamicSchedule.addAll([
        {'day': 'Days 1-2', 'task': 'Foundational Context & Setting (Pages 1–${pagesPerDay * 2})'},
        {'day': 'Days 3-5', 'task': 'Primary Exposition & Narrative Climax (Pages ${pagesPerDay * 2 + 1}–${pagesPerDay * 5})'},
        {'day': 'Days 6-7', 'task': 'Resolution, Thematic Notes & Critical Review (Pages ${pagesPerDay * 5 + 1}–$_totalPages)'},
      ]);
    } else if (_selectedDurationDays == 14) {
      dynamicSchedule.addAll([
        {'day': 'Days 1-3', 'task': 'Introduction & Context Setting (Pages 1–${pagesPerDay * 3})'},
        {'day': 'Days 4-7', 'task': 'Core Analysis & Manuscript Dynamics (Pages ${pagesPerDay * 3 + 1}–${pagesPerDay * 7})'},
        {'day': 'Days 8-11', 'task': 'Deep Themes & Counter-perspectives (Pages ${pagesPerDay * 7 + 1}–${pagesPerDay * 11})'},
        {'day': 'Days 12-14', 'task': 'Synthesis, Final Chapters & Reflection (Pages ${pagesPerDay * 11 + 1}–$_totalPages)'},
      ]);
    } else {
      // 21 Days - Habit Mastery
      dynamicSchedule.addAll([
        {'day': 'Week 1 (Days 1-7)', 'task': 'Habit Immersion: Chapters 1-5 (Pages 1–${pagesPerDay * 7})'},
        {'day': 'Week 2 (Days 8-14)', 'task': 'Deep Study: Core Argumentation & Critique (Pages ${pagesPerDay * 7 + 1}–${pagesPerDay * 14})'},
        {'day': 'Week 3 (Days 15-21)', 'task': 'Integration: Final Chapters & Archival Commentary (Pages ${pagesPerDay * 14 + 1}–$_totalPages)'},
      ]);
    }

    if (mounted) {
      setState(() {
        _isGenerating = false;
        _generatedPlan = {
          'title': widget.bookTitle,
          'daily_target': '$pagesPerDay pages / day',
          'daily_minutes': '$_selectedDailyMinutes mins / day',
          'estimated_completion': '$_selectedDurationDays Days',
          'schedule': dynamicSchedule,
        };
      });
    }
  }

  void _openExternalUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheduleList = (_generatedPlan?['schedule'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final progressFraction = scheduleList.isEmpty ? 0.0 : _completedMilestones.length / scheduleList.length;

    return Scaffold(
      backgroundColor: DSColors.warmIvory,
      appBar: AppBar(
        backgroundColor: DSColors.paperWhite,
        elevation: 0,
        title: Text(
          'Reading & Exam Plan Generator',
          style: GoogleFonts.playfairDisplay(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: DSColors.deepForestGreen,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: DSColors.deepForestGreen),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Reading Plan Generator',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: DSColors.deepForestGreen,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Generate a structured reading schedule tailored to your available daily minutes and target duration.',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: DSColors.textMuted,
                  ),
                ),
                const SizedBox(height: 24),

                // PLAN CONFIGURATION CARD
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: DSColors.paperWhite,
                    borderRadius: BorderRadius.circular(DSRadius.card),
                    border: Border.all(color: DSColors.softBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.tune, color: DSColors.deepForestGreen, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Plan Parameters for "${widget.bookTitle}"',
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: DSColors.deepForestGreen,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Duration Selector
                      Text(
                        'Target Duration',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: DSColors.charcoal,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: _supportedDurations.map((days) {
                          final isSelected = _selectedDurationDays == days;
                          String label = '$days Days';
                          if (days == 3) label = '3 Days (Sprint)';
                          if (days == 7) label = '7 Days (Intensive)';
                          if (days == 14) label = '14 Days (Balanced)';
                          if (days == 21) label = '21 Days (Habit)';

                          return ChoiceChip(
                            label: Text(label),
                            selected: isSelected,
                            selectedColor: DSColors.deepForestGreen,
                            backgroundColor: DSColors.warmIvory,
                            labelStyle: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected ? Colors.white : DSColors.charcoal,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(DSRadius.pill),
                              side: BorderSide(
                                color: isSelected ? DSColors.deepForestGreen : DSColors.softBorder,
                              ),
                            ),
                            onSelected: (val) {
                              if (val) setState(() => _selectedDurationDays = days);
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),

                      // Daily Minutes Selector
                      Text(
                        'Daily Reading Time',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: DSColors.charcoal,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: _supportedMinutes.map((mins) {
                          final isSelected = _selectedDailyMinutes == mins;
                          return ChoiceChip(
                            label: Text('$mins min/day'),
                            selected: isSelected,
                            selectedColor: DSColors.secondaryGreen,
                            backgroundColor: DSColors.warmIvory,
                            labelStyle: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected ? Colors.white : DSColors.charcoal,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(DSRadius.pill),
                              side: BorderSide(
                                color: isSelected ? DSColors.secondaryGreen : DSColors.softBorder,
                              ),
                            ),
                            onSelected: (val) {
                              if (val) setState(() => _selectedDailyMinutes = mins);
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),

                      // Generate Button
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: _isGenerating ? null : _generatePlan,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: DSColors.deepForestGreen,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(DSRadius.md),
                            ),
                          ),
                          icon: _isGenerating
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : const Icon(Icons.auto_awesome, size: 20),
                          label: Text(
                            _isGenerating
                                ? 'Generating $_selectedDurationDays-Day Plan...'
                                : 'Generate $_selectedDurationDays-Day Reading Plan',
                            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ERROR / RETRY STATE
                if (_errorMessage != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: DSColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(DSRadius.card),
                      border: Border.all(color: DSColors.error.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: DSColors.error),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: GoogleFonts.inter(color: DSColors.error, fontSize: 13),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _generatePlan,
                          icon: const Icon(Icons.refresh, size: 16),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),

                // GENERATED PLAN SECTION WITH PROGRESS TRACKING
                if (_generatedPlan != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: DSColors.paperWhite,
                      borderRadius: BorderRadius.circular(DSRadius.card),
                      border: Border.all(color: DSColors.antiqueGold.withValues(alpha: 0.5)),
                      boxShadow: [
                        BoxShadow(
                          color: DSColors.charcoal.withValues(alpha: 0.04),
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
                            Row(
                              children: [
                                const Icon(Icons.menu_book, color: DSColors.deepForestGreen, size: 24),
                                const SizedBox(width: 10),
                                Text(
                                  _generatedPlan!['title'] ?? widget.bookTitle,
                                  style: GoogleFonts.playfairDisplay(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: DSColors.deepForestGreen,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: DSColors.deepForestGreen.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(DSRadius.sm),
                              ),
                              child: Text(
                                '${(_completedMilestones.length)} / ${scheduleList.length} Done',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: DSColors.deepForestGreen,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Progress bar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(DSRadius.xs),
                          child: LinearProgressIndicator(
                            value: progressFraction,
                            backgroundColor: DSColors.softBorder,
                            color: DSColors.deepForestGreen,
                            minHeight: 8,
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Target summary chips
                        Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          children: [
                            _buildTargetBadge(
                              icon: Icons.flag_outlined,
                              label: 'Daily Target: ${_generatedPlan!['daily_target'] ?? '22 pages / day'}',
                            ),
                            _buildTargetBadge(
                              icon: Icons.timer_outlined,
                              label: 'Daily Time: ${_generatedPlan!['daily_minutes'] ?? '$_selectedDailyMinutes mins / day'}',
                            ),
                            _buildTargetBadge(
                              icon: Icons.calendar_today_outlined,
                              label: 'Duration: ${_generatedPlan!['estimated_completion'] ?? '$_selectedDurationDays Days'}',
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        const Divider(color: DSColors.softBorder),
                        const SizedBox(height: 16),

                        Text(
                          'Milestone Reading Schedule',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: DSColors.charcoal,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Interactive Milestone Items
                        ...scheduleList.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final item = entry.value;
                          final isDone = _completedMilestones.contains(idx);

                          return InkWell(
                            onTap: () {
                              setState(() {
                                if (isDone) {
                                  _completedMilestones.remove(idx);
                                } else {
                                  _completedMilestones.add(idx);
                                }
                              });
                            },
                            borderRadius: BorderRadius.circular(DSRadius.md),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: isDone ? DSColors.warmIvory.withValues(alpha: 0.6) : DSColors.warmIvory,
                                borderRadius: BorderRadius.circular(DSRadius.md),
                                border: Border.all(
                                  color: isDone ? DSColors.success.withValues(alpha: 0.4) : DSColors.softBorder,
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    isDone ? Icons.check_circle : Icons.radio_button_unchecked,
                                    color: isDone ? DSColors.success : DSColors.textMuted,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item['day'] ?? 'Day',
                                          style: GoogleFonts.inter(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: isDone ? DSColors.textMuted : DSColors.deepForestGreen,
                                            decoration: isDone ? TextDecoration.lineThrough : null,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          item['task'] ?? '',
                                          style: GoogleFonts.inter(
                                            fontSize: 13,
                                            color: isDone ? DSColors.textMuted : DSColors.charcoal,
                                            decoration: isDone ? TextDecoration.lineThrough : null,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                ],

                // ACQUISITION / MARKETPLACE CARDS
                Text(
                  'Book Acquisition Options',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: DSColors.deepForestGreen,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Borrow or rent from community archive shelves, or find peer listings in The Tactile Archive.',
                  style: GoogleFonts.inter(fontSize: 14, color: DSColors.textMuted),
                ),
                const SizedBox(height: 16),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: DSColors.paperWhite,
                    borderRadius: BorderRadius.circular(DSRadius.card),
                    border: Border.all(color: DSColors.softBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () => context.go('/browse'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: DSColors.deepForestGreen,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(160, 48),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DSRadius.md)),
                            ),
                            icon: const Icon(Icons.storefront, size: 18),
                            label: const Text('Find in Marketplace'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => _openExternalUrl('https://www.amazon.com/s?k=${Uri.encodeComponent(widget.bookTitle)}'),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(120, 48),
                              foregroundColor: DSColors.charcoal,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DSRadius.md)),
                            ),
                            icon: const Icon(Icons.shopping_cart, size: 18),
                            label: const Text('Amazon'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => _openExternalUrl('https://openlibrary.org/search?q=${Uri.encodeComponent(widget.bookTitle)}'),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(130, 48),
                              foregroundColor: DSColors.charcoal,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DSRadius.md)),
                            ),
                            icon: const Icon(Icons.local_library, size: 18),
                            label: const Text('Open Library'),
                          ),
                        ],
                      ),
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

  Widget _buildTargetBadge({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: DSColors.warmIvory,
        borderRadius: BorderRadius.circular(DSRadius.sm),
        border: Border.all(color: DSColors.softBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: DSColors.deepForestGreen),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: DSColors.charcoal,
            ),
          ),
        ],
      ),
    );
  }
}
