import 'package:flutter/material.dart';
import 'package:libri_flow/core/design_system/design_system.dart';
import 'package:libri_flow/core/services/api_service.dart';

class ReaderReadingCompanionPage extends StatefulWidget {
  const ReaderReadingCompanionPage({super.key});

  @override
  State<ReaderReadingCompanionPage> createState() => _ReaderReadingCompanionPageState();
}

class _ReaderReadingCompanionPageState extends State<ReaderReadingCompanionPage> {
  final TextEditingController _queryController = TextEditingController();
  String _activeAction = 'Chapter Discussion';
  bool _isLoading = false;
  String? _responseOutput;

  final List<String> _quickActions = [
    '📖 Chapter Discussion',
    '💡 Themes & Reflection',
    '✍️ Reading Prompts',
    '💬 Book Club Questions',
  ];

  @override
  void initState() {
    super.initState();
    _queryController.text = 'I am on Chapter 4 of my current book. What key themes and reflection prompts should I consider?';
  }

  Future<void> _handleAsk() async {
    final queryText = _queryController.text.trim();
    if (queryText.isEmpty) return;

    setState(() {
      _isLoading = true;
      _responseOutput = null;
    });

    final formattedQuery = "[$_activeAction] $queryText";
    final result = await ApiService.askReadingCompanion(formattedQuery);

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      _responseOutput = result;
    });
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rp = ApiService.readerProfileData;
    final goal = rp?['reading_goal'] ?? 'Read 12 books this year';
    final genres = (rp?['genres'] as List?)?.cast<String>() ?? ['Fiction', 'Philosophy'];

    return Scaffold(
      backgroundColor: DSColors.background,
      appBar: AppBar(
        backgroundColor: DSColors.primary,
        foregroundColor: Colors.white,
        title: const Text('AI Reading Companion', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(DSSpacing.lg),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Context Banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(DSSpacing.md),
                    decoration: BoxDecoration(
                      color: DSColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(DSRadius.md),
                      border: Border.all(color: DSColors.primary.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.bookmark_outline, color: DSColors.primary, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Active Reader Context: Goal: $goal • Genres: ${genres.join(', ')}',
                            style: const TextStyle(
                              color: DSColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: DSSpacing.lg),

                  // Quick Action Chips
                  Text(
                    'Select Companion Action',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: DSColors.textDark,
                        ),
                  ),
                  const SizedBox(height: DSSpacing.xs),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _quickActions.map((action) {
                      final cleanName = action.replaceAll(RegExp(r'^[^\w]+'), '').trim();
                      final isSelected = _activeAction == cleanName;
                      return ChoiceChip(
                        label: Text(action),
                        selected: isSelected,
                        selectedColor: DSColors.primary,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : DSColors.textDark,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _activeAction = cleanName;
                            });
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: DSSpacing.lg),

                  // Query Input Field
                  TextFormField(
                    controller: _queryController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Share your current reading progress or chapter thoughts...',
                      filled: true,
                      fillColor: DSColors.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(DSRadius.md),
                        borderSide: BorderSide(color: DSColors.border),
                      ),
                    ),
                  ),
                  const SizedBox(height: DSSpacing.md),

                  // Action Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _handleAsk,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Icon(Icons.chat_bubble_outline, size: 18),
                      label: Text(_isLoading ? 'Generating Literary Insights...' : 'Get Literary Companion Insights'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: DSColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(DSRadius.md),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: DSSpacing.xl),

                  // Response Output Section
                  if (_responseOutput != null) ...[
                    Text(
                      'Companion Insights & Discussion',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: DSColors.textDark,
                          ),
                    ),
                    const SizedBox(height: DSSpacing.xs),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(DSSpacing.xl),
                      decoration: BoxDecoration(
                        color: DSColors.surface,
                        borderRadius: BorderRadius.circular(DSRadius.lg),
                        border: Border.all(color: DSColors.border),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Text(
                        _responseOutput!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: DSColors.textDark,
                              height: 1.6,
                            ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
