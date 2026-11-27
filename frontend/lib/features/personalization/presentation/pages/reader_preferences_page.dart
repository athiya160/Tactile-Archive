import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:libri_flow/core/design_system/design_system.dart';
import 'package:libri_flow/core/services/api_service.dart';

class ReaderPreferencesPage extends StatefulWidget {
  const ReaderPreferencesPage({super.key});

  @override
  State<ReaderPreferencesPage> createState() => _ReaderPreferencesPageState();
}

class _ReaderPreferencesPageState extends State<ReaderPreferencesPage> {
  final List<String> _selectedGenres = ['Fiction', 'Mystery & Thriller', 'Philosophy'];
  final TextEditingController _authorsController = TextEditingController(text: 'Haruki Murakami, Virginia Woolf');
  String _readingGoal = 'Read 12 books this year';
  int _preferredDuration = 30;
  bool _isLoading = false;
  String? _errorMessage;

  final List<String> _availableGenres = [
    'Fiction & Literature',
    'Non-Fiction',
    'Mystery & Thriller',
    'Sci-Fi & Fantasy',
    'Tech & Programming',
    'Self-Improvement',
    'Academics & Textbooks',
    'Business & Finance',
    'History & Biography',
    'Arts & Photography',
    'Graphic Novels & Comics',
    'Rare & Antique Editions',
  ];

  final List<String> _readingGoals = [
    'Read 12 books this year',
    'Read 24 books this year',
    'Read 50 books this year',
    'Casual reading without annual target',
  ];

  Future<void> _handleSave() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final authorsList = _authorsController.text
        .split(',')
        .map((a) => a.trim())
        .where((a) => a.isNotEmpty)
        .toList();

    final success = await ApiService.saveReaderProfile(
      genres: _selectedGenres,
      favoriteAuthors: authorsList,
      readingGoal: _readingGoal,
      preferredDuration: _preferredDuration,
    );

    if (!mounted) return;

    if (success) {
      context.go('/reader');
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to save reading preferences. Please try again.';
      });
    }
  }

  @override
  void dispose() {
    _authorsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DSColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: DSSpacing.lg, vertical: DSSpacing.xl),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badge Header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: DSColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(DSRadius.pill),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.auto_stories, size: 14, color: DSColors.primary),
                        const SizedBox(width: 6),
                        Text(
                          'READER PERSONALIZATION',
                          style: TextStyle(
                            color: DSColors.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: DSSpacing.md),

                  Text(
                    'Curate Your Reading Journey',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: DSColors.textDark,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tell us about your favorite literary genres and authors to customize your recommendations and virtual shelf.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: DSColors.textLight,
                        ),
                  ),
                  const SizedBox(height: DSSpacing.xl),

                  if (_errorMessage != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(DSSpacing.md),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        border: Border.all(color: Colors.red.shade200),
                        borderRadius: BorderRadius.circular(DSRadius.md),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red.shade900),
                      ),
                    ),
                    const SizedBox(height: DSSpacing.lg),
                  ],

                  // 1. Favorite Genres
                  _buildSectionTitle('1. Favorite Literary Genres'),
                  const SizedBox(height: DSSpacing.xs),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _availableGenres.map((g) {
                      final isSelected = _selectedGenres.contains(g);
                      return FilterChip(
                        label: Text(g),
                        selected: isSelected,
                        selectedColor: DSColors.primary.withValues(alpha: 0.15),
                        checkmarkColor: DSColors.primary,
                        labelStyle: TextStyle(
                          color: isSelected ? DSColors.primary : DSColors.textDark,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedGenres.add(g);
                            } else {
                              _selectedGenres.remove(g);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: DSSpacing.lg),

                  // 2. Favorite Authors
                  _buildSectionTitle('2. Favorite Authors (Comma Separated)'),
                  const SizedBox(height: DSSpacing.xs),
                  TextFormField(
                    controller: _authorsController,
                    decoration: _inputDecoration(hint: 'e.g. Haruki Murakami, Virginia Woolf, George Orwell'),
                  ),
                  const SizedBox(height: DSSpacing.lg),

                  // 3. Reading Goal
                  _buildSectionTitle('3. Annual Reading Target'),
                  const SizedBox(height: DSSpacing.xs),
                  DropdownButtonFormField<String>(
                    initialValue: _readingGoal,
                    decoration: _inputDecoration(),
                    items: _readingGoals
                        .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _readingGoal = val);
                    },
                  ),
                  const SizedBox(height: DSSpacing.lg),

                  // 4. Preferred Reading Session
                  _buildSectionTitle('4. Preferred Daily Reading: $_preferredDuration Minutes'),
                  Slider(
                    value: _preferredDuration.toDouble(),
                    min: 15,
                    max: 120,
                    divisions: 7,
                    activeColor: DSColors.primary,
                    label: '$_preferredDuration mins',
                    onChanged: (val) => setState(() => _preferredDuration = val.round()),
                  ),
                  const SizedBox(height: DSSpacing.xl),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: DSButton(
                      text: _isLoading ? 'Saving Preferences...' : 'Complete Setup & Enter Reader Sanctuary',
                      onPressed: _isLoading ? null : _handleSave,
                    ),
                  ),
                  const SizedBox(height: DSSpacing.lg),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: DSColors.textDark,
      ),
    );
  }

  InputDecoration _inputDecoration({String? hint}) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: DSColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DSRadius.md),
        borderSide: BorderSide(color: DSColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DSRadius.md),
        borderSide: BorderSide(color: DSColors.border),
      ),
    );
  }
}
